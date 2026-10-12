-- BIIC CHAT: normalize Côte d'Ivoire phone numbers consistently during contact matching.
-- Supports local 10-digit numbers, +225XXXXXXXXXX and 00225XXXXXXXXXX.
-- Imported contact numbers remain hashed in imported_contacts.

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
    normalized_phone := public.normalize_ci_phone_digits(raw_phone);

    if normalized_phone is null then
      continue;
    end if;

    hash_value := encode(digest(normalized_phone, 'sha256'), 'hex');

    select u.id, u.display_name, u.status
      into match_id, match_name, match_status
      from public.users u
     where public.normalize_ci_phone_digits(u.phone) = normalized_phone
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
