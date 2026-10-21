alter table public.users add column if not exists registered_phone text, add column if not exists phone_verified_at timestamptz;
create unique index if not exists users_registered_phone_unique_idx on public.users(registered_phone) where registered_phone is not null and phone_verified_at is not null;
create index if not exists users_registered_phone_lookup_idx on public.users(public.normalize_phone_digits(registered_phone)) where registered_phone is not null and phone_verified_at is not null;

create table if not exists public.phone_registration_codes (
 user_id uuid primary key references auth.users(id) on delete cascade,
 phone text not null, code_hash text not null, expires_at timestamptz not null,
 attempts integer not null default 0 check (attempts >= 0),
 last_sent_at timestamptz not null default now(), consumed_at timestamptz,
 created_at timestamptz not null default now()
);
alter table public.phone_registration_codes enable row level security;
revoke all on public.phone_registration_codes from anon, authenticated;
grant all on public.phone_registration_codes to service_role;

-- Preserve the existing member directory by display name. Phone-based
-- discovery remains restricted to the verified-phone lookup RPC below and
-- sync_device_contacts; this list does not expose phone numbers.
create or replace function public.list_public_users()
returns table(id uuid, display_name text, avatar_url text, bio text, status text)
language sql security definer stable set search_path = public as $list_public_users$
 select u.id,u.display_name,u.avatar_url,u.bio,u.status from public.users u
 where auth.uid() is not null
 order by u.display_name;
$list_public_users$;
revoke all on function public.list_public_users() from public, anon;
grant execute on function public.list_public_users() to authenticated;

create or replace function public.sync_device_contacts(p_contacts jsonb)
returns table(phone text, display_name text, matched_user_id uuid, matched_display_name text, matched_status text)
language plpgsql security definer volatile set search_path = public, extensions as $$
declare item jsonb; raw_phone text; normalized_phone text; hash_value text; contact_name text;
match_id uuid; match_name text; match_status text;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if p_contacts is null or jsonb_typeof(p_contacts) <> 'array' then return; end if;
 if jsonb_array_length(p_contacts) > 1000 then raise exception 'Too many contacts in one request'; end if;
 for item in select value from jsonb_array_elements(p_contacts) loop
  raw_phone := trim(coalesce(item->>'phone',''));
  contact_name := left(trim(coalesce(item->>'display_name','')),120);
  normalized_phone := public.normalize_phone_digits(raw_phone);
  if normalized_phone is null or length(normalized_phone)<8 then continue; end if;
  hash_value := encode(digest(normalized_phone,'sha256'),'hex');
  match_id := null; match_name := null; match_status := null;
  select u.id,u.display_name,u.status into match_id,match_name,match_status from public.users u
   where u.phone_verified_at is not null and u.registered_phone is not null
   and public.normalize_phone_digits(u.registered_phone)=normalized_phone and u.id<>auth.uid() limit 1;
  insert into public.imported_contacts(user_id,phone_hash,display_name,matched_user_id,updated_at)
   values(auth.uid(),hash_value,contact_name,match_id,now())
   on conflict(user_id,phone_hash) do update set display_name=excluded.display_name,matched_user_id=excluded.matched_user_id,updated_at=now();
  phone:=raw_phone; display_name:=contact_name; matched_user_id:=match_id; matched_display_name:=match_name; matched_status:=match_status;
  return next;
 end loop;
end; $$;
revoke all on function public.sync_device_contacts(jsonb) from public, anon;
grant execute on function public.sync_device_contacts(jsonb) to authenticated;