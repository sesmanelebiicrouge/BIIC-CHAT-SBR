create table if not exists public.message_reads (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

alter table public.message_reads enable row level security;

create policy "message_reads_select_member"
on public.message_reads for select to authenticated
using (
  exists (
    select 1 from public.messages m
    where m.id = message_id
      and public.is_conversation_member(m.conversation_id)
  )
);

create policy "message_reads_insert_self"
on public.message_reads for insert to authenticated
with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.messages m
    where m.id = message_id
      and public.is_conversation_member(m.conversation_id)
  )
);

create index if not exists message_reads_user_idx
  on public.message_reads(user_id, read_at desc);
create index if not exists message_reads_message_idx
  on public.message_reads(message_id);
create index if not exists conversation_members_conversation_user_idx
  on public.conversation_members(conversation_id, user_id);
create index if not exists messages_sender_created_idx
  on public.messages(sender_id, created_at desc);
