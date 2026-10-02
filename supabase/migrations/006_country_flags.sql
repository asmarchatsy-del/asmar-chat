-- Country/flag support. Syria is rendered in-app as the independence flag:
-- green / white / black with three red stars.
alter table public.profiles add column if not exists country_code text;
create index if not exists profiles_country_code_idx on public.profiles(country_code);
