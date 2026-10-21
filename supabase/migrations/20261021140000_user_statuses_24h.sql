-- 24-hour text statuses for BIIC CHAT.
create table if not exists public.user_statuses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  content text not null check (length(trim(content)) between 1 and 500),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  check (expires_at > created_at)
);

create index if not exists user_statuses_active_idx
  on public.user_statuses (expires_at desc, created_at desc);

create index if not exists user_statuses_user_active_idx
  on public.user_statuses (user_id, expires_at desc);

alter table public.user_statuses enable row level security;

drop policy if exists user_statuses_read_active on public.user_statuses;
create policy user_statuses_read_active
  on public.user_statuses for select to authenticated
  using (expires_at > now());

drop policy if exists user_statuses_insert_self on public.user_statuses;
create policy user_statuses_insert_self
  on public.user_statuses for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and expires_at > now()
    and expires_at <= now() + interval '24 hours' + interval '1 minute'
    and length(trim(content)) between 1 and 500
  );

drop policy if exists user_statuses_delete_self on public.user_statuses;
create policy user_statuses_delete_self
  on public.user_statuses for delete to authenticated
  using (user_id = (select auth.uid()));

grant select, insert, delete on public.user_statuses to authenticated;
revoke all on public.user_statuses from anon, public;
