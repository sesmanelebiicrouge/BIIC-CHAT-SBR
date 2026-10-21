-- Enforce symmetric blocks for status visibility. The helper only returns block state
-- when the caller is one of the two users, so it cannot be used to enumerate others.
drop policy if exists "status_select_visible" on public.statuses;
create policy "status_select_visible" on public.statuses
for select to authenticated
using (
  user_id = (select auth.uid())
  or (
    expires_at > now()
    and not public.users_blocked_between((select auth.uid()), user_id)
    and (
      audience = 'everyone'
      or exists (
        select 1 from public.imported_contacts c
        where c.user_id = (select auth.uid()) and c.matched_user_id = statuses.user_id
      )
    )
  )
);

drop policy if exists "status_views_insert_self" on public.status_views;
create policy "status_views_insert_self" on public.status_views
for insert to authenticated
with check (
  viewer_id = (select auth.uid())
  and exists (
    select 1 from public.statuses s
    where s.id = status_views.status_id
      and s.expires_at > now()
      and not public.users_blocked_between((select auth.uid()), s.user_id)
      and (
        s.user_id = (select auth.uid())
        or s.audience = 'everyone'
        or exists (
          select 1 from public.imported_contacts c
          where c.user_id = (select auth.uid()) and c.matched_user_id = s.user_id
        )
      )
  )
);

drop policy if exists "status_media_select_visible" on storage.objects;
create policy "status_media_select_visible" on storage.objects
for select to authenticated
using (
  bucket_id = 'status-media'
  and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or exists (
      select 1 from public.statuses s
      where s.media_path = storage.objects.name
        and s.expires_at > now()
        and (
          s.user_id = (select auth.uid())
          or (
            not public.users_blocked_between((select auth.uid()), s.user_id)
            and (
              s.audience = 'everyone'
              or exists (
                select 1 from public.imported_contacts c
                where c.user_id = (select auth.uid()) and c.matched_user_id = s.user_id
              )
            )
          )
        )
    )
  )
);

drop policy if exists "call_logs_update_participant" on public.call_logs;
create index if not exists call_logs_conversation_idx on public.call_logs (conversation_id);
