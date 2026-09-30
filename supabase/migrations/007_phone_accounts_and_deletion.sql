-- BIIC CHAT production account model and account deletion.
-- Phone/SMS is the primary authentication method. Email is optional.

alter table public.users
  alter column email drop not null;

alter table public.users
  add column if not exists phone text;

create unique index if not exists users_phone_unique_idx
  on public.users(phone)
  where phone is not null;

update public.users u
set phone = nullif(a.phone, ''),
    email = nullif(a.email, '')
from auth.users a
where a.id = u.id;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, phone, display_name)
  values (
    new.id,
    nullif(new.email, ''),
    nullif(new.phone, ''),
    coalesce(
      nullif(new.raw_user_meta_data ->> 'display_name', ''),
      nullif(new.phone, ''),
      'Utilisateur'
    )
  )
  on conflict (id) do update
    set email = nullif(excluded.email, ''),
        phone = nullif(excluded.phone, ''),
        display_name = case
          when excluded.display_name is not null
               and length(trim(excluded.display_name)) > 0
          then excluded.display_name
          else public.users.display_name
        end,
        updated_at = now();
  return new;
end;
$$;

create or replace function public.sync_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.users
  set email = nullif(new.email, ''),
      phone = nullif(new.phone, ''),
      updated_at = now()
  where id = new.id;
  return new;
end;
$$;

drop trigger if exists on_auth_user_updated on auth.users;
create trigger on_auth_user_updated
after update of email, phone on auth.users
for each row execute function public.sync_auth_user_profile();

-- Allows an authenticated user to delete their own account without exposing
-- service_role credentials to the Flutter application.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  -- Remove private files uploaded by the account before the auth row cascades.
  delete from storage.objects where owner_id = auth.uid()::text;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
