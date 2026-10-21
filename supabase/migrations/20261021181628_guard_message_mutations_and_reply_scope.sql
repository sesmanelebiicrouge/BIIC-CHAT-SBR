-- Keep message identity, media and reply relationships immutable after insertion.
create or replace function public.guard_message_mutations()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.reply_to_message_id is not null and not exists (
    select 1 from public.messages reply
    where reply.id = new.reply_to_message_id
      and reply.conversation_id = new.conversation_id
      and reply.deleted_at is null
  ) then
    raise exception 'La réponse doit référencer un message de la même conversation.';
  end if;

  if tg_op = 'UPDATE' then
    if new.sender_id is distinct from old.sender_id
       or new.conversation_id is distinct from old.conversation_id
       or new.created_at is distinct from old.created_at
       or new.media_url is distinct from old.media_url
       or new.media_type is distinct from old.media_type
       or new.reply_to_message_id is distinct from old.reply_to_message_id then
      raise exception 'Les informations d’identité et les pièces jointes du message ne peuvent pas être modifiées.';
    end if;
    if old.deleted_at is not null and new.deleted_at is null then
      raise exception 'Un message supprimé ne peut pas être restauré.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_message_mutations on public.messages;
create trigger guard_message_mutations
before insert or update on public.messages
for each row execute function public.guard_message_mutations();

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'messages_content_length_check'
      and conrelid = 'public.messages'::regclass
  ) then
    alter table public.messages
      add constraint messages_content_length_check
      check (char_length(content) <= 4000);
  end if;
end
$$;
