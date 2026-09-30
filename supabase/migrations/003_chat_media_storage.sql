-- Private chat media bucket. Files are stored under chat/<conversation_id>/...
insert into storage.buckets (id, name, public)
values ('chat-media', 'chat-media', false)
on conflict (id) do update set public = false;

drop policy if exists "chat_media_insert_member" on storage.objects;
create policy "chat_media_insert_member"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'chat-media'
  and exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id::text = (storage.foldername(name))[2]
      and cm.user_id = auth.uid()
  )
);

drop policy if exists "chat_media_read_member" on storage.objects;
create policy "chat_media_read_member"
on storage.objects for select to authenticated
using (
  bucket_id = 'chat-media'
  and exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id::text = (storage.foldername(name))[2]
      and cm.user_id = auth.uid()
  )
);

drop policy if exists "chat_media_delete_owner" on storage.objects;
create policy "chat_media_delete_owner"
on storage.objects for delete to authenticated
using (
  bucket_id = 'chat-media'
  and owner_id = auth.uid()::text
);
