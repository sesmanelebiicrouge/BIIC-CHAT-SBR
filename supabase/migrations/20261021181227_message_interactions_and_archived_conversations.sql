-- Message replies, edits/deletes, reactions, pinning and per-user archive support.
alter table public.messages
  add column if not exists reply_to_message_id uuid references public.messages(id) on delete set null,
  add column if not exists edited_at timestamptz,
  add column if not exists deleted_at timestamptz,
  add column if not exists is_pinned boolean not null default false;

create index if not exists messages_reply_idx on public.messages (reply_to_message_id);
create index if not exists messages_pinned_idx on public.messages (conversation_id, is_pinned) where is_pinned = true;

create policy "messages_update_own" on public.messages
for update to authenticated
using (sender_id = (select auth.uid()) and is_conversation_member(conversation_id))
with check (sender_id = (select auth.uid()) and is_conversation_member(conversation_id));
create policy "messages_delete_own" on public.messages
for delete to authenticated
using (sender_id = (select auth.uid()) and is_conversation_member(conversation_id));

create table if not exists public.message_reactions (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  reaction text not null check (reaction in ('👍','❤️','😂','😮','😢','🙏','🔥','👏')),
  created_at timestamptz not null default now(),
  primary key (message_id, user_id)
);
create index if not exists message_reactions_user_idx on public.message_reactions (user_id, created_at desc);
alter table public.message_reactions enable row level security;
create policy "message_reactions_select_member" on public.message_reactions
for select to authenticated
using (exists (select 1 from public.messages m where m.id = message_reactions.message_id and is_conversation_member(m.conversation_id)));
create policy "message_reactions_insert_self_member" on public.message_reactions
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (select 1 from public.messages m where m.id = message_reactions.message_id and is_conversation_member(m.conversation_id))
);
create policy "message_reactions_update_self_member" on public.message_reactions
for update to authenticated
using (user_id = (select auth.uid()))
with check (
  user_id = (select auth.uid())
  and exists (select 1 from public.messages m where m.id = message_reactions.message_id and is_conversation_member(m.conversation_id))
);
create policy "message_reactions_delete_self" on public.message_reactions
for delete to authenticated using (user_id = (select auth.uid()));

create table if not exists public.archived_conversations (
  user_id uuid not null references public.users(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  archived_at timestamptz not null default now(),
  primary key (user_id, conversation_id)
);
alter table public.archived_conversations enable row level security;
create policy "archived_conversations_manage_self" on public.archived_conversations
for all to authenticated
using (user_id = (select auth.uid()) and is_conversation_member(conversation_id))
with check (user_id = (select auth.uid()) and is_conversation_member(conversation_id));
