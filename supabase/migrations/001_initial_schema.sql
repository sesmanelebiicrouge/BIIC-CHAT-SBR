create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  display_name text not null,
  avatar_url text,
  bio text,
  status text not null default 'offline',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.blocked_users (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  blocked_user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, blocked_user_id),
  check (user_id <> blocked_user_id)
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  name text not null default '',
  created_by uuid references public.users(id) on delete set null,
  is_group boolean not null default false,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversation_members (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  unique(conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid references public.users(id) on delete set null,
  content text not null default '',
  media_url text,
  media_type text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (length(trim(content)) > 0 or media_url is not null)
);

alter table public.users enable row level security;
alter table public.blocked_users enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

create policy "users_read_authenticated" on public.users
  for select to authenticated using (true);

create policy "users_update_self" on public.users
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

create policy "blocked_manage_self" on public.blocked_users
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "members_read_own" on public.conversation_members
  for select to authenticated using (auth.uid() = user_id);

create policy "members_insert_self_or_creator" on public.conversation_members
  for insert to authenticated
  with check (
    auth.uid() = user_id or exists (
      select 1 from public.conversations c
      where c.id = conversation_id and c.created_by = auth.uid()
    )
  );

create policy "conversations_read_member" on public.conversations
  for select to authenticated using (
    exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = conversations.id and cm.user_id = auth.uid()
    )
  );

create policy "conversations_insert_self" on public.conversations
  for insert to authenticated with check (created_by = auth.uid());

create policy "conversations_update_creator" on public.conversations
  for update to authenticated using (created_by = auth.uid())
  with check (created_by = auth.uid());

create policy "messages_read_member" on public.messages
  for select to authenticated using (
    exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = messages.conversation_id and cm.user_id = auth.uid()
    )
  );

create policy "messages_insert_member" on public.messages
  for insert to authenticated with check (
    sender_id = auth.uid() and exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = messages.conversation_id and cm.user_id = auth.uid()
    )
  );

create index if not exists conversation_members_user_idx
  on public.conversation_members(user_id);

create index if not exists messages_conversation_created_idx
  on public.messages(conversation_id, created_at);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists users_touch_updated_at on public.users;
create trigger users_touch_updated_at before update on public.users
for each row execute function public.touch_updated_at();

drop trigger if exists conversations_touch_updated_at on public.conversations;
create trigger conversations_touch_updated_at before update on public.conversations
for each row execute function public.touch_updated_at();

drop trigger if exists messages_touch_updated_at on public.messages;
create trigger messages_touch_updated_at before update on public.messages
for each row execute function public.touch_updated_at();
