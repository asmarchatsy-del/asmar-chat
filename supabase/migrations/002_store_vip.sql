-- Asmar Chat store, VIP/SVIP and profile-frame catalog.
-- This migration is safe to run after 001_initial_schema.sql.

create table if not exists public.frame_items (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  style_key text not null,
  price bigint not null default 0 check (price >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.coin_packages (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  coins bigint not null check (coins > 0),
  price_usd numeric(10,2) not null check (price_usd >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.vip_levels (
  id text primary key,
  animal text not null,
  image text not null,
  price_coins bigint not null default 0 check (price_coins >= 0),
  duration_days integer not null default 30 check (duration_days > 0),
  perks jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_vip (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  vip_level_id text not null references public.vip_levels(id),
  starts_at timestamptz not null default now(),
  expires_at timestamptz,
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_frames (
  user_id uuid not null references public.profiles(id) on delete cascade,
  frame_id uuid not null references public.frame_items(id) on delete cascade,
  purchased_at timestamptz not null default now(),
  is_equipped boolean not null default false,
  primary key (user_id, frame_id)
);

alter table public.frame_items enable row level security;
alter table public.coin_packages enable row level security;
alter table public.vip_levels enable row level security;
alter table public.user_vip enable row level security;
alter table public.user_frames enable row level security;

drop policy if exists "frame_items_select_authenticated" on public.frame_items;
create policy "frame_items_select_authenticated" on public.frame_items
for select to authenticated using (is_active = true or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "coin_packages_select_authenticated" on public.coin_packages;
create policy "coin_packages_select_authenticated" on public.coin_packages
for select to authenticated using (is_active = true or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "vip_levels_select_authenticated" on public.vip_levels;
create policy "vip_levels_select_authenticated" on public.vip_levels
for select to authenticated using (is_active = true or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "user_vip_select_self_or_admin" on public.user_vip;
create policy "user_vip_select_self_or_admin" on public.user_vip
for select to authenticated using (user_id = auth.uid() or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "user_frames_select_self_or_admin" on public.user_frames;
create policy "user_frames_select_self_or_admin" on public.user_frames
for select to authenticated using (user_id = auth.uid() or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

-- Catalog defaults. Prices can be changed later from the external admin panel.
insert into public.frame_items (name, style_key, price)
values
  ('إطار VIP', 'vip_gold', 5000),
  ('إطار SVIP', 'svip_royal', 15000)
on conflict (name) do nothing;

insert into public.coin_packages (name, coins, price_usd)
values
  ('حزمة 1000 كوين', 1000, 0.99),
  ('حزمة 5000 كوين', 5000, 4.99),
  ('حزمة 10000 كوين', 10000, 9.99),
  ('حزمة 50000 كوين', 50000, 49.99)
on conflict (name) do nothing;

insert into public.vip_levels (id, animal, image, price_coins, duration_days, perks)
values
  ('VIP1','الغزال','assets/vip/deer.png',10000,30,'["إطار VIP","شارة","العملات المستلمة"]'),
  ('VIP2','الذئب','assets/vip/wolf.png',20000,30,'["إطار VIP","شارة","العملات المستلمة"]'),
  ('VIP3','التمساح','assets/vip/crocodile.png',30000,30,'["نمط حصري","اسم مستخدم ملون","إطار VIP"]'),
  ('VIP4','الفيل','assets/vip/elephant.png',40000,30,'["نمط غرفة غير محدودة","نمط بطاقة التعريف","العملات المستلمة"]'),
  ('VIP5','النسر','assets/vip/eagle.png',50000,30,'["إلغاء الغرفة","اسم ميكروفون مجاني","رسائل غير محدودة"]'),
  ('VIP6','الدب','assets/vip/bear.png',60000,30,'["إلغاء الغرفة","اسم ميكروفون مجاني","رسائل غير محدودة"]'),
  ('VIP7','الفهد','assets/vip/leopard.png',70000,30,'["نمط بطاقة التعريف","اسم مجاني","العملات المستلمة"]'),
  ('VIP8','النمر','assets/vip/tiger.png',80000,30,'["اسم ملون","شارة","العملات المستلمة"]'),
  ('VIP9','التنين','assets/vip/dragon.png',90000,30,'["إلغاء الغرفة","اسم ميكروفون مجاني","رسائل غير محدودة"]'),
  ('VIP10','الأسد','assets/vip/lion.png',100000,30,'["ترحيب أسطوري","دخول الغرفة بتأثير","كل المميزات"]'),
  ('SVIP','ملكي','assets/vip/svip.png',250000,30,'["كل مميزات VIP","إطار SVIP","شارة ملكية"]')
on conflict (id) do nothing;

-- Only privileged administrators can modify the catalog.
drop policy if exists "frame_items_admin_update" on public.frame_items;
create policy "frame_items_admin_update" on public.frame_items
for update to authenticated using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "coin_packages_admin_update" on public.coin_packages;
create policy "coin_packages_admin_update" on public.coin_packages
for update to authenticated using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "vip_levels_admin_update" on public.vip_levels;
create policy "vip_levels_admin_update" on public.vip_levels
for update to authenticated using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
