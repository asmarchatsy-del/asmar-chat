create table if not exists public.app_promotions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  image_url text,
  first_place text,
  second_place text,
  third_place text,
  first_prize text,
  second_prize text,
  third_prize text,
  button_text text default 'شارك الآن',
  button_url text,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.app_promotions enable row level security;

drop policy if exists "active_promotions_read" on public.app_promotions;
create policy "active_promotions_read"
on public.app_promotions
for select to authenticated
using (
  is_active = true
  and starts_at <= now()
  and (ends_at is null or ends_at >= now())
);

drop policy if exists "admins_manage_promotions" on public.app_promotions;
create policy "admins_manage_promotions"
on public.app_promotions
for all to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN','MANAGER']::public.app_role[]))
with check (public.has_role(auth.uid(), array['CEO','SUPER_ADMIN','MANAGER']::public.app_role[]));

insert into public.app_promotions
  (title, subtitle, first_place, second_place, third_place, first_prize, second_prize, third_prize, button_text, starts_at, is_active)
select
  'ASMAR CHAT — حدث الشحن',
  'نافس على المراكز واربح جوائز الحدث',
  'المركز الأول',
  'المركز الثاني',
  'المركز الثالث',
  'جائزة المركز الأول',
  'جائزة المركز الثاني',
  'جائزة المركز الثالث',
  'شارك الآن',
  now(),
  true
where not exists (select 1 from public.app_promotions);

grant select on public.app_promotions to authenticated;