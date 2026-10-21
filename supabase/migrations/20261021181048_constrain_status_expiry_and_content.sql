-- Prevent clients from publishing statuses that never expire or oversized text.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'statuses_expiry_window_check'
      and conrelid = 'public.statuses'::regclass
  ) then
    alter table public.statuses
      add constraint statuses_expiry_window_check
      check (expires_at > created_at and expires_at <= created_at + interval '24 hours');
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'statuses_content_length_check'
      and conrelid = 'public.statuses'::regclass
  ) then
    alter table public.statuses
      add constraint statuses_content_length_check
      check (content is null or char_length(content) <= 700);
  end if;
end
$$;
