-- BIIC CHAT — réparation SQL ciblée
-- À exécuter une seule fois dans Supabase SQL Editor sur le projet BIIC CHAT.
-- Ce script corrige : normalisation des téléphones CI, recherche des contacts,
-- vérification des blocages côté serveur et confidentialité des blocages.
-- Il ne configure PAS les secrets Orange et ne déploie PAS la fonction Edge SMS.

begin;

create or replace function public.normalize_ci_phone_digits(raw_phone text)
returns text
language plpgsql
immutable
set search_path = public
as $$
declare
  digits text;
begin
  digits := regexp_replace(coalesce(raw_phone, ''), '[^0-9]', '', 'g');
  if length(digits) = 10 then
    return '225' || digits;
  elsif length(digits) = 13 and left(digits, 3) = '225' then
    return digits;
  elsif length(digits) = 15 and left(digits, 5) = '00225' then
    return substring(digits from 3);
  end if;
  return null;
end;
$$;

revoke all on function public.normalize_ci_phone_digits(text) from public;
grant execute on function public.normalize_ci_phone_digits(text) to authenticated;

create or replace function public.sync_device_contacts(p_contacts jsonb)
returns table (
  phone text,
  display_name text,
  matched_user_id uuid,
  matched_display_name text,
  matched_status text
)
language plpgsql
security definer
volatile
set search_path = public, extensions
as $$
declare
  item jsonb;
  raw_phone text;
  normalized_phone text;
  hash_value text;
  contact_name text;
  match_id uuid;
  match_name text;
  match_status text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if p_contacts is null or jsonb_typeof(p_contacts) <> 'array' then
    return;
  end if;
  if jsonb_array_length(p_contacts) > 1000 then
    raise exception 'Too many contacts in one request';
  end if;

  for item in select value from jsonb_array_elements(p_contacts)
  loop
    raw_phone := trim(coalesce(item->>'phone', ''));
    contact_name := left(trim(coalesce(item->>'display_name', '')), 120);
    normalized_phone := public.normalize_ci_phone_digits(raw_phone);
    if normalized_phone is null then continue; end if;

    hash_value := encode(digest(normalized_phone, 'sha256'), 'hex');
    match_id := null;
    match_name := null;
    match_status := null;

    select u.id, u.display_name, u.status
      into match_id, match_name, match_status
      from public.users u
     where public.normalize_ci_phone_digits(u.phone) = normalized_phone
       and u.id <> auth.uid()
     limit 1;

    insert into public.imported_contacts
      (user_id, phone_hash, display_name, matched_user_id, updated_at)
    values (auth.uid(), hash_value, contact_name, match_id, now())
    on conflict (user_id, phone_hash) do update
      set display_name = excluded.display_name,
          matched_user_id = excluded.matched_user_id,
          updated_at = now();

    phone := raw_phone;
    display_name := contact_name;
    matched_user_id := match_id;
    matched_display_name := match_name;
    matched_status := match_status;
    return next;
  end loop;
end;
$$;

revoke all on function public.sync_device_contacts(jsonb) from public;
grant execute on function public.sync_device_contacts(jsonb) to authenticated;

create or replace function public.users_blocked_between(first_user uuid, second_user uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select auth.uid() is not null
     and (auth.uid() = first_user or auth.uid() = second_user)
     and exists (
       select 1 from public.blocked_users b
       where (b.user_id = first_user and b.blocked_user_id = second_user)
          or (b.user_id = second_user and b.blocked_user_id = first_user)
     );
$$;

revoke all on function public.users_blocked_between(uuid, uuid) from public;
grant execute on function public.users_blocked_between(uuid, uuid) to authenticated;

create or replace function public.get_or_create_direct_conversation(
  target_user uuid,
  other_user uuid,
  other_name text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  conversation_id uuid;
  pair_key text;
  safe_name text;
begin
  if auth.uid() is null or auth.uid() <> target_user then
    raise exception 'Authentication required';
  end if;
  if target_user = other_user then
    raise exception 'A direct conversation needs two different users';
  end if;
  if not exists (select 1 from public.users where id = other_user) then
    raise exception 'Utilisateur introuvable';
  end if;
  if public.users_blocked_between(target_user, other_user) then
    raise exception 'Impossible d’ouvrir cette discussion.';
  end if;

  pair_key := least(target_user::text, other_user::text)
    || ':' || greatest(target_user::text, other_user::text);
  perform pg_advisory_xact_lock(hashtextextended(pair_key, 0));

  select c.id into conversation_id
    from public.conversations c
    join public.conversation_members cm on cm.conversation_id = c.id
   where c.is_group = false
   group by c.id
  having count(*) = 2
     and bool_and(cm.user_id in (target_user, other_user))
   order by max(c.updated_at) desc
   limit 1;

  if conversation_id is not null then return conversation_id; end if;

  safe_name := nullif(trim(coalesce(other_name, '')), '');
  insert into public.conversations (name, created_by, is_group)
  values (coalesce(safe_name, 'Conversation'), target_user, false)
  returning id into conversation_id;

  insert into public.conversation_members (conversation_id, user_id)
  values (conversation_id, target_user), (conversation_id, other_user);

  return conversation_id;
end;
$$;

revoke all on function public.get_or_create_direct_conversation(uuid, uuid, text) from public;
grant execute on function public.get_or_create_direct_conversation(uuid, uuid, text) to authenticated;

commit;
