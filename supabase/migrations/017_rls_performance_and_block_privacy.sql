-- Keep auth.uid() as an initplan so it is evaluated once per statement.
alter policy blocked_manage_self on public.blocked_users
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

alter policy members_insert_creator_only on public.conversation_members
  with check (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_members.conversation_id
        and c.created_by = (select auth.uid())
    )
  );

alter policy conversations_insert_self on public.conversations
  with check (created_by = (select auth.uid()));

alter policy conversations_update_creator on public.conversations
  using (created_by = (select auth.uid()))
  with check (created_by = (select auth.uid()));

alter policy imported_contacts_manage_self on public.imported_contacts
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

alter policy message_reads_insert_self on public.message_reads
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.messages m
      where m.id = message_reads.message_id
        and is_conversation_member(m.conversation_id)
    )
  );

alter policy message_reads_select_member on public.message_reads
  using (
    exists (
      select 1 from public.messages m
      where m.id = message_reads.message_id
        and is_conversation_member(m.conversation_id)
    )
  );

alter policy messages_insert_member on public.messages
  with check (
    sender_id = (select auth.uid())
    and is_conversation_member(conversation_id)
    and not exists (
      select 1
      from public.conversation_members cm
      where cm.conversation_id = messages.conversation_id
        and cm.user_id <> (select auth.uid())
        and users_blocked_between((select auth.uid()), cm.user_id)
    )
  );

alter policy reports_insert_self on public.user_reports
  with check (
    reporter_id = (select auth.uid())
    and reported_user_id <> (select auth.uid())
  );

alter policy reports_read_self on public.user_reports
  using (reporter_id = (select auth.uid()));

alter policy users_read_self on public.users
  using ((select auth.uid()) = id);

alter policy users_update_self on public.users
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create or replace function public.users_blocked_between(first_user uuid, second_user uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $function$
  select
    auth.uid() is not null
    and auth.uid() in (first_user, second_user)
    and exists (
      select 1 from public.blocked_users b
      where (b.user_id = first_user and b.blocked_user_id = second_user)
         or (b.user_id = second_user and b.blocked_user_id = first_user)
    );
$function$;

revoke execute on function public.users_blocked_between(uuid, uuid) from public, anon;
grant execute on function public.users_blocked_between(uuid, uuid) to authenticated;
