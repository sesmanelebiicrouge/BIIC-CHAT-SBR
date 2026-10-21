-- Keep status-view upserts scoped to statuses the viewer is allowed to see.
-- The INSERT policy already checks visibility; UPDATE must enforce the same rule
-- because PostgREST upsert uses UPDATE when (status_id, viewer_id) already exists.
drop policy if exists "status_views_update_self" on public.status_views;

create policy "status_views_update_visible_self"
on public.status_views
for update
to authenticated
using (viewer_id = (select auth.uid()))
with check (
  viewer_id = (select auth.uid())
  and exists (
    select 1
    from public.statuses s
    where s.id = status_views.status_id
      and s.expires_at > now()
      and (
        s.user_id = (select auth.uid())
        or (
          not public.users_blocked_between((select auth.uid()), s.user_id)
          and (
            s.audience = 'everyone'
            or exists (
              select 1
              from public.imported_contacts c
              where c.user_id = (select auth.uid())
                and c.matched_user_id = s.user_id
            )
          )
        )
      )
  )
);
