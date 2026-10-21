-- BIIC CHAT status feed and call-attempt history.
create table if not exists public.statuses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  content text,
  media_path text,
  media_type text not null default 'text' check (media_type in ('text','image','video')),
  audience text not null default 'contacts' check (audience in ('contacts','everyone')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  constraint statuses_content_or_media check (
    (nullif(trim(content), '') is not null) or (nullif(trim(media_path), '') is not null)
  )
);
create index if not exists statuses_feed_idx on public.statuses (expires_at desc, created_at desc);
create index if not exists statuses_user_feed_idx on public.statuses (user_id, expires_at desc, created_at desc);
alter table public.statuses enable row level security;

create policy "status_select_visible" on public.statuses
for select to authenticated
using (
  user_id = (select auth.uid())
  or (
    expires_at > now()
    and not exists (
      select 1 from public.blocked_users b
      where (b.user_id = (select auth.uid()) and b.blocked_user_id = statuses.user_id)
         or (b.user_id = statuses.user_id and b.blocked_user_id = (select auth.uid()))
    )
    and (
      audience = 'everyone'
      or exists (
        select 1 from public.imported_contacts c
        where c.user_id = (select auth.uid()) and c.matched_user_id = statuses.user_id
      )
    )
  )
);
create policy "status_insert_own" on public.statuses
for insert to authenticated with check (user_id = (select auth.uid()));
create policy "status_update_own" on public.statuses
for update to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));
create policy "status_delete_own" on public.statuses
for delete to authenticated using (user_id = (select auth.uid()));

create table if not exists public.status_views (
  status_id uuid not null references public.statuses(id) on delete cascade,
  viewer_id uuid not null references public.users(id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (status_id, viewer_id)
);
create index if not exists status_views_viewer_idx on public.status_views (viewer_id, viewed_at desc);
alter table public.status_views enable row level security;
create policy "status_views_select_participants" on public.status_views
for select to authenticated
using (
  viewer_id = (select auth.uid())
  or exists (select 1 from public.statuses s where s.id = status_views.status_id and s.user_id = (select auth.uid()))
);
create policy "status_views_insert_self" on public.status_views
for insert to authenticated
with check (
  viewer_id = (select auth.uid())
  and exists (
    select 1 from public.statuses s
    where s.id = status_views.status_id and s.expires_at > now()
      and (
        s.user_id = (select auth.uid())
        or s.audience = 'everyone'
        or exists (select 1 from public.imported_contacts c where c.user_id = (select auth.uid()) and c.matched_user_id = s.user_id)
      )
  )
);
create policy "status_views_update_self" on public.status_views
for update to authenticated using (viewer_id = (select auth.uid()))
with check (viewer_id = (select auth.uid()));

create table if not exists public.call_logs (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete set null,
  caller_id uuid not null references public.users(id) on delete cascade,
  callee_id uuid not null references public.users(id) on delete cascade,
  call_type text not null check (call_type in ('audio','video')),
  status text not null default 'initiated' check (status in ('initiated','missed','completed','declined','failed')),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  constraint call_logs_distinct_users check (caller_id <> callee_id)
);
create index if not exists call_logs_caller_idx on public.call_logs (caller_id, started_at desc);
create index if not exists call_logs_callee_idx on public.call_logs (callee_id, started_at desc);
alter table public.call_logs enable row level security;
create policy "call_logs_select_participant" on public.call_logs
for select to authenticated using (caller_id = (select auth.uid()) or callee_id = (select auth.uid()));
create policy "call_logs_insert_caller" on public.call_logs
for insert to authenticated
with check (
  caller_id = (select auth.uid())
  and exists (select 1 from public.conversation_members cm where cm.conversation_id = call_logs.conversation_id and cm.user_id = (select auth.uid()))
  and exists (select 1 from public.conversation_members cm where cm.conversation_id = call_logs.conversation_id and cm.user_id = call_logs.callee_id)
);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('status-media', 'status-media', false, 52428800, array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime'])
on conflict (id) do update set public = false, file_size_limit = 52428800, allowed_mime_types = excluded.allowed_mime_types;

create policy "status_media_insert_own" on storage.objects
for insert to authenticated
with check (bucket_id = 'status-media' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "status_media_select_visible" on storage.objects
for select to authenticated
using (
  bucket_id = 'status-media'
  and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or exists (
      select 1 from public.statuses s
      where s.media_path = storage.objects.name and s.expires_at > now()
        and (
          s.user_id = (select auth.uid())
          or (
            not exists (
              select 1 from public.blocked_users b
              where (b.user_id = (select auth.uid()) and b.blocked_user_id = s.user_id)
                 or (b.user_id = s.user_id and b.blocked_user_id = (select auth.uid()))
            )
            and (s.audience = 'everyone' or exists (
              select 1 from public.imported_contacts c
              where c.user_id = (select auth.uid()) and c.matched_user_id = s.user_id
            ))
          )
        )
    )
  )
);
create policy "status_media_update_own" on storage.objects
for update to authenticated
using (bucket_id = 'status-media' and (storage.foldername(name))[1] = (select auth.uid())::text)
with check (bucket_id = 'status-media' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "status_media_delete_own" on storage.objects
for delete to authenticated
using (bucket_id = 'status-media' and (storage.foldername(name))[1] = (select auth.uid())::text);
