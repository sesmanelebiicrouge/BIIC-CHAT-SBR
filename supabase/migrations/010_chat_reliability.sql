-- BIIC CHAT reliability improvements: conversation ordering and realtime read receipts.

create or replace function public.touch_conversation_on_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations
     set updated_at = now()
   where id = coalesce(new.conversation_id, old.conversation_id);
  return coalesce(new, old);
end;
$$;

drop trigger if exists messages_touch_conversation on public.messages;
create trigger messages_touch_conversation
after insert or update or delete on public.messages
for each row execute function public.touch_conversation_on_message();

do $$
begin
  begin
    alter publication supabase_realtime add table public.message_reads;
  exception when duplicate_object then null;
  end;
end $$;

create index if not exists conversations_updated_at_idx
  on public.conversations(updated_at desc);
