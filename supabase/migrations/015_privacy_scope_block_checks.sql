-- BIIC CHAT privacy hardening: do not let a user probe block relationships
-- between two other users by calling users_blocked_between directly.

create or replace function public.users_blocked_between(first_user uuid, second_user uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select
    auth.uid() is not null
    and (
      auth.uid() = first_user
      or auth.uid() = second_user
    )
    and exists (
      select 1
      from public.blocked_users b
      where (b.user_id = first_user and b.blocked_user_id = second_user)
         or (b.user_id = second_user and b.blocked_user_id = first_user)
    );
$$;

revoke all on function public.users_blocked_between(uuid, uuid) from public;
grant execute on function public.users_blocked_between(uuid, uuid) to authenticated;
