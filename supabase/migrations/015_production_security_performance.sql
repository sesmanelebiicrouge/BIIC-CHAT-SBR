revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.sync_auth_user_profile() from public, anon, authenticated;
revoke execute on function public.touch_updated_at() from public, anon, authenticated;
revoke execute on function public.touch_conversation_on_message() from public, anon, authenticated;
revoke execute on function public.set_message_read_conversation() from public, anon, authenticated;

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
revoke execute on function public.get_or_create_direct_conversation(uuid, uuid, text) from public, anon;
grant execute on function public.get_or_create_direct_conversation(uuid, uuid, text) to authenticated;
revoke execute on function public.is_conversation_member(uuid) from public, anon;
grant execute on function public.is_conversation_member(uuid) to authenticated;
revoke execute on function public.list_conversation_members(uuid) from public, anon;
grant execute on function public.list_conversation_members(uuid) to authenticated;
revoke execute on function public.list_public_users() from public, anon;
grant execute on function public.list_public_users() to authenticated;
revoke execute on function public.sync_device_contacts(jsonb) from public, anon;
grant execute on function public.sync_device_contacts(jsonb) to authenticated;
revoke execute on function public.users_blocked_between(uuid, uuid) from public, anon;
grant execute on function public.users_blocked_between(uuid, uuid) to authenticated;

create index if not exists blocked_users_blocked_user_idx on public.blocked_users(blocked_user_id);
create index if not exists conversations_created_by_idx on public.conversations(created_by);
create index if not exists imported_contacts_matched_user_idx on public.imported_contacts(matched_user_id);
create index if not exists user_reports_reporter_idx on public.user_reports(reporter_id, created_at desc);
