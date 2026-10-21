-- Restrict direct profile writes to the fields exposed by ProfileService.
-- Applied to production as migration 20261021133521.
-- Phone and email identity fields must be changed through verified Auth flows.

revoke all on table public.users from anon;
revoke insert, update on table public.users from authenticated;
revoke insert (id, phone, email, display_name, avatar_url, bio, status, created_at, updated_at)
  on table public.users from anon, authenticated;
revoke update (id, phone, email, display_name, avatar_url, bio, status, created_at, updated_at)
  on table public.users from anon, authenticated;
grant update (display_name, avatar_url, bio, status)
  on table public.users to authenticated;
