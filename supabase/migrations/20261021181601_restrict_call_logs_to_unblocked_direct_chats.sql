-- Call history records only direct, unblocked calls between conversation members.
drop policy if exists "call_logs_insert_caller" on public.call_logs;
create policy "call_logs_insert_caller" on public.call_logs
for insert to authenticated
with check (
  caller_id = (select auth.uid())
  and not public.users_blocked_between((select auth.uid()), callee_id)
  and exists (
    select 1 from public.conversations c
    where c.id = call_logs.conversation_id and c.is_group = false
  )
  and exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id = call_logs.conversation_id and cm.user_id = (select auth.uid())
  )
  and exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id = call_logs.conversation_id and cm.user_id = call_logs.callee_id
  )
);
