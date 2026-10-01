-- BIIC CHAT production reliability:
-- normalize Côte d'Ivoire local phone numbers consistently for contact matching,
-- and clean private storage objects when an account is deleted.

create or replace function public.normalize_phone_digits(raw_phone text)
returns text
language sql
immutable
strict
as $$
  with digits as (
    select regexp_replace(raw_phone, '[^0-9]', '', 'g') as value
  )
  select case
    when value like '225%' then value
    when value like '0%' and length(value) = 10 then '225' || substr(value, 2)
    else value
  end
  from digits;
$$;

revoke all on function public.normalize_phone_digits(text) from public;
grant execute on function public.normalize_phone_digits(text) to authenticated;

create index if not exists users_phone_normalized_idx
  on public.users (public.normalize_phone_digits(phone));

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
set search_path = public
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

  for item in select value from jsonb_array_elements(p_contacts)
  loop
    raw_phone := trim(coalesce(item->>'phone', ''));
    contact_name := left(trim(coalesce(item->>'display_name', '')), 120);
    normalized_phone := public.normalize_phone_digits(raw_phone);

    if length(normalized_phone) < 8 then
      continue;
    end if;

    hash_value := encode(digest(normalized_phone, 'sha256'), 'hex');

    select u.id, u.display_name, u.status
      into match_id, match_name, match_status
      from public.users u
     where public.normalize_phone_digits(u.phone) = normalized_phone
       and u.id <> auth.uid()
     limit 1;

    insert into public.imported_contacts (
      user_id, phone_hash, display_name, matched_user_id, updated_at
    )
    values (
      auth.uid(), hash_value, contact_name, match_id, now()
    )
    on conflict (user_id, phone_hash)
    do update set
      display_name = excluded.display_name,
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

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth, storage
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Authentication required';
  end if;

  delete from storage.objects
   where owner_id = uid::text
     and bucket_id in ('avatars', 'chat-media');

  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
