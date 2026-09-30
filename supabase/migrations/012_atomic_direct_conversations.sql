-- BIIC CHAT: atomically create/reuse one direct conversation per user pair.
-- An advisory transaction lock prevents duplicate direct chats when both users
-- start a conversation at the same time.

create or replace function public.get_or_create_direct_conversation(
  target_user uuid,
  other_user uuid,
  other_name text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  conversation_id uuid;
  pair_key text;
  safe_name text;
begin
  if auth.uid() is null or auth.uid() <> target_user then
    raise exception 'Authentication required';
  end if;

  if target_user = other_user then
    raise exception 'A direct conversation needs two different users';
  end if;

  if not exists (select 1 from public.users where id = other_user) then
    raise exception 'Utilisateur introuvable';
  end if;

  pair_key := least(target_user::text, other_user::text)
    || ':' || greatest(target_user::text, other_user::text);

  perform pg_advisory_xact_lock(hashtextextended(pair_key, 0));

  select c.id
    into conversation_id
    from public.conversations c
    join public.conversation_members cm
      on cm.conversation_id = c.id
   where c.is_group = false
   group by c.id
  having count(*) = 2
     and bool_and(cm.user_id in (target_user, other_user))
   order by max(c.updated_at) desc
   limit 1;

  if conversation_id is not null then
    return conversation_id;
  end if;

  safe_name := nullif(trim(coalesce(other_name, '')), '');
  insert into public.conversations (name, created_by, is_group)
  values (coalesce(safe_name, 'Conversation'), target_user, false)
  returning id into conversation_id;

  insert into public.conversation_members (conversation_id, user_id)
  values (conversation_id, target_user), (conversation_id, other_user);

  return conversation_id;
end;
$$;

revoke all on function public.get_or_create_direct_conversation(uuid, uuid, text) from public;
grant execute on function public.get_or_create_direct_conversation(uuid, uuid, text) to authenticated;
