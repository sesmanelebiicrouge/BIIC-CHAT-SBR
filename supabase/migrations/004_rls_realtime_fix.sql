-- Fix membership visibility without recursive RLS and enable realtime replication.

create or replace function public.is_conversation_member(target_conversation_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.conversation_members
    where conversation_id = target_conversation_id
      and user_id = auth.uid()
  );
$$;

revoke all on function public.is_conversation_member(uuid) from public;
grant execute on function public.is_conversation_member(uuid) to authenticated;

drop policy if exists "members_read_own" on public.conversation_members;
create policy "members_read_conversation_members"
on public.conversation_members for select to authenticated
using (public.is_conversation_member(conversation_id));

drop policy if exists "conversations_read_member" on public.conversations;
create policy "conversations_read_member"
on public.conversations for select to authenticated
using (public.is_conversation_member(id));

drop policy if exists "messages_read_member" on public.messages;
create policy "messages_read_member"
on public.messages for select to authenticated
using (public.is_conversation_member(conversation_id));

drop policy if exists "messages_insert_member" on public.messages;
create policy "messages_insert_member"
on public.messages for insert to authenticated
with check (
  sender_id = auth.uid()
  and public.is_conversation_member(conversation_id)
);

do $$
begin
  begin
    alter publication supabase_realtime add table public.conversations;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.conversation_members;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.messages;
  exception when duplicate_object then null;
  end;
end $$;
