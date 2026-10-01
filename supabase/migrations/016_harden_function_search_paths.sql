create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.normalize_phone_digits(raw_phone text)
returns text
language sql
immutable
strict
set search_path = public
as $$
  with digits as (
    select regexp_replace(raw_phone, '[^0-9]', '', 'g') as value
  )
  select case
    when value like '225%' then value
    when value like '0%' and length(value) = 10 then '225' || substr(value, 2)
    else value
  end
  from digits;
$$;
