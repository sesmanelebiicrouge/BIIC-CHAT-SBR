-- Save the e-mail supplied when a phone-based BIIC CHAT account is created.
-- Existing accounts with an e-mail already on their profile are backfilled.
alter table public.users
  add column if not exists registration_email text;

update public.users
set registration_email = lower(trim(email))
where registration_email is null
  and email is not null
  and trim(email) <> '';

create unique index if not exists users_registration_email_unique_idx
  on public.users (lower(trim(registration_email)))
  where registration_email is not null;

alter table public.phone_registration_codes
  add column if not exists email text;

-- Preserve the registration e-mail on the private profile when Auth creates a
-- phone account (Auth's own user.email is null for phone-only signups).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, phone, registration_email, display_name)
  values (
    new.id,
    nullif(new.email, ''),
    nullif(new.phone, ''),
    coalesce(
      nullif(lower(trim(new.raw_user_meta_data ->> 'registration_email')), ''),
      nullif(lower(trim(new.email)), '')
    ),
    coalesce(
      nullif(new.raw_user_meta_data ->> 'display_name', ''),
      nullif(new.phone, ''),
      'Utilisateur'
    )
  )
  on conflict (id) do update
    set email = nullif(excluded.email, ''),
        phone = nullif(excluded.phone, ''),
        registration_email = coalesce(
          public.users.registration_email,
          excluded.registration_email
        ),
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
