-- BIIC CHAT privacy hardening for public profiles and member directory.

-- Do not expose email addresses to every authenticated user.
drop policy if exists "users_read_authenticated" on public.users;
drop policy if exists "users_read_self" on public.users;
create policy "users_read_self" on public.users
  for select to authenticated
  using (auth.uid() = id);

-- Public profile directory: deliberately excludes email and is callable only by
-- authenticated users. The function checks the caller's authentication state.
create or replace function public.list_public_users()
returns table (
  id uuid,
  display_name text,
  avatar_url text,
  bio text,
  status text
)
language sql
security definer
stable
set search_path = public
as $$
  select u.id, u.display_name, u.avatar_url, u.bio, u.status
  from public.users u
  where auth.uid() is not null
  order by u.display_name;
$$;

revoke all on function public.list_public_users() from public;
grant execute on function public.list_public_users() to authenticated;

-- Conversation member directory: only members of the conversation may inspect
-- the other participants, and email is intentionally excluded.
create or replace function public.list_conversation_members(target_conversation uuid)
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  status text
)
language sql
security definer
stable
set search_path = public
as $$
  select u.id, u.display_name, u.avatar_url, u.status
  from public.conversation_members cm
  join public.users u on u.id = cm.user_id
  where cm.conversation_id = target_conversation
    and public.is_conversation_member(target_conversation);
$$;

revoke all on function public.list_conversation_members(uuid) from public;
grant execute on function public.list_conversation_members(uuid) to authenticated;

-- Helpful index for directory ordering/search.
create index if not exists users_display_name_idx
  on public.users(display_name);
