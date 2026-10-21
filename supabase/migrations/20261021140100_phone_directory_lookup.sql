-- Exact lookup by the phone explicitly registered and verified by the account owner.
create or replace function public.find_user_by_registered_phone(p_phone text)
returns table(id uuid, display_name text, avatar_url text, bio text, status text)
language plpgsql
security definer
stable
set search_path = public
as $$
declare normalized text;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  normalized := public.normalize_phone_digits(p_phone);
  if normalized is null or length(normalized) < 8 then return; end if;
  return query
    select u.id, u.display_name, u.avatar_url, u.bio, u.status
    from public.users u
    where u.phone_verified_at is not null
      and u.registered_phone is not null
      and public.normalize_phone_digits(u.registered_phone) = normalized
      and u.id <> auth.uid()
    limit 1;
end;
$$;
revoke all on function public.find_user_by_registered_phone(text) from public, anon;
grant execute on function public.find_user_by_registered_phone(text) to authenticated;
