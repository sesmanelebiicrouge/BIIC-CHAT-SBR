-- BIIC CHAT production safety and profile/reporting features.

create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.users(id) on delete cascade,
  reported_user_id uuid not null references public.users(id) on delete cascade,
  reason text not null,
  details text,
  created_at timestamptz not null default now(),
  check (reporter_id <> reported_user_id)
);

alter table public.user_reports enable row level security;
drop policy if exists "reports_insert_self" on public.user_reports;
create policy "reports_insert_self" on public.user_reports
  for insert to authenticated
  with check (reporter_id = auth.uid() and reported_user_id <> auth.uid());

drop policy if exists "reports_read_self" on public.user_reports;
create policy "reports_read_self" on public.user_reports
  for select to authenticated
  using (reporter_id = auth.uid());

create index if not exists blocked_users_pair_idx
  on public.blocked_users(user_id, blocked_user_id);

create index if not exists user_reports_reported_idx
  on public.user_reports(reported_user_id, created_at desc);

create or replace function public.users_blocked_between(first_user uuid, second_user uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.blocked_users b
    where (b.user_id = first_user and b.blocked_user_id = second_user)
       or (b.user_id = second_user and b.blocked_user_id = first_user)
  );
$$;

revoke all on function public.users_blocked_between(uuid, uuid) from public;
grant execute on function public.users_blocked_between(uuid, uuid) to authenticated;

drop policy if exists "messages_insert_member" on public.messages;
create policy "messages_insert_member"
on public.messages for insert to authenticated
with check (
  sender_id = auth.uid()
  and public.is_conversation_member(conversation_id)
  and not exists (
    select 1
    from public.conversation_members cm
    where cm.conversation_id = messages.conversation_id
      and cm.user_id <> auth.uid()
      and public.users_blocked_between(auth.uid(), cm.user_id)
  )
);

drop policy if exists "conversations_insert_self" on public.conversations;
create policy "conversations_insert_self"
on public.conversations for insert to authenticated
with check (created_by = auth.uid());

-- Private avatar storage.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false)
on conflict (id) do update set public = false;

drop policy if exists "avatars_insert_self" on storage.objects;
create policy "avatars_insert_self"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "avatars_read_authenticated" on storage.objects;
create policy "avatars_read_authenticated"
on storage.objects for select to authenticated
using (bucket_id = 'avatars');

drop policy if exists "avatars_update_self" on storage.objects;
create policy "avatars_update_self"
on storage.objects for update to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_delete_self" on storage.objects;
create policy "avatars_delete_self"
on storage.objects for delete to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
