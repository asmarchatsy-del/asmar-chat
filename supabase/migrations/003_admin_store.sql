-- Admin controls for the external Asmar Chat web dashboard.
create table if not exists public.coin_packages (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  coins bigint not null check (coins > 0),
  price_usd numeric(12,2) not null check (price_usd >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.coin_packages enable row level security;

drop policy if exists "coin_packages_select_active" on public.coin_packages;
create policy "coin_packages_select_active" on public.coin_packages
for select to authenticated using (is_active = true);

drop policy if exists "frame_items_admin_update" on public.frame_items;
create policy "frame_items_admin_update" on public.frame_items
for update to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "frame_items_admin_insert" on public.frame_items;
create policy "frame_items_admin_insert" on public.frame_items
for insert to authenticated
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "frame_items_admin_delete" on public.frame_items;
create policy "frame_items_admin_delete" on public.frame_items
for delete to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "coin_packages_admin_all" on public.coin_packages;
create policy "coin_packages_admin_all" on public.coin_packages
for all to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

insert into public.coin_packages (name, coins, price_usd) values
('Starter', 1000, 0.99),
('Popular', 5500, 4.99),
('VIP', 12000, 9.99),
('SVIP', 30000, 24.99)
on conflict (name) do nothing;
