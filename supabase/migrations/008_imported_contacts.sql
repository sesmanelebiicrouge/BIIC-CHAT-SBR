-- BIIC CHAT contact import and phone matching.
-- Contacts are stored as SHA-256 hashes of normalized phone numbers so the
-- server can match accounts without keeping the imported phone number itself.

create table if not exists public.imported_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  phone_hash text not null,
  display_name text not null default '',
  matched_user_id uuid references public.users(id) on delete set null,
  updated_at timestamptz not null default now(),
  unique(user_id, phone_hash)
);

alter table public.imported_contacts enable row level security;

drop policy if exists "imported_contacts_manage_self" on public.imported_contacts;
create policy "imported_contacts_manage_self"
on public.imported_contacts
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create index if not exists imported_contacts_user_idx
  on public.imported_contacts(user_id);

create index if not exists users_phone_digits_idx
  on public.users ((regexp_replace(coalesce(phone, ''), '[^0-9]', '', 'g')));

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
    normalized_phone := regexp_replace(raw_phone, '[^0-9]', '', 'g');

    if length(normalized_phone) < 8 then
      continue;
    end if;

    hash_value := encode(digest(normalized_phone, 'sha256'), 'hex');

    select u.id, u.display_name, u.status
      into match_id, match_name, match_status
      from public.users u
     where regexp_replace(coalesce(u.phone, ''), '[^0-9]', '', 'g') = normalized_phone
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
