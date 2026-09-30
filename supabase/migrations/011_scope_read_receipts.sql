-- BIIC CHAT: scope read receipts to their conversation for efficient realtime updates.

alter table public.message_reads
  add column if not exists conversation_id uuid;

update public.message_reads mr
set conversation_id = m.conversation_id
from public.messages m
where m.id = mr.message_id
  and mr.conversation_id is null;

alter table public.message_reads
  alter column conversation_id set not null;

alter table public.message_reads
  drop constraint if exists message_reads_conversation_fk;

alter table public.message_reads
  add constraint message_reads_conversation_fk
  foreign key (conversation_id)
  references public.conversations(id)
  on delete cascade;

create index if not exists message_reads_conversation_idx
  on public.message_reads(conversation_id, read_at desc);

create or replace function public.set_message_read_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select m.conversation_id
    into new.conversation_id
    from public.messages m
   where m.id = new.message_id;

  if new.conversation_id is null then
    raise exception 'Message introuvable';
  end if;

  return new;
end;
$$;

drop trigger if exists message_reads_set_conversation on public.message_reads;
create trigger message_reads_set_conversation
before insert on public.message_reads
for each row execute function public.set_message_read_conversation();
