-- ASMAR CHAT — COMBINED DATABASE SETUP
-- Run this entire file once in Supabase SQL Editor.

-- ===== 001_initial_schema.sql =====
-- Asmar Chat production database foundation.
-- Apply this migration in the user's Supabase project.
-- RLS is enabled on every application table.

create extension if not exists pgcrypto;

create type public.app_role as enum (
  'CEO',
  'SUPER_ADMIN',
  'MANAGER',
  'ADMIN',
  'HOST',
  'AGENT',
  'USER'
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text not null default '',
  avatar_url text,
  role public.app_role not null default 'USER',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wallets (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  balance bigint not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.coin_transactions (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid references public.profiles(id),
  to_user_id uuid references public.profiles(id),
  amount bigint not null check (amount > 0),
  reason text not null default 'transfer',
  created_at timestamptz not null default now()
);

create table if not exists public.agencies (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  manager_id uuid references public.profiles(id),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.agency_members (
  agency_id uuid not null references public.agencies(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'HOST',
  joined_at timestamptz not null default now(),
  primary key (agency_id, user_id)
);

create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid references public.profiles(id),
  livekit_room_name text unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.room_members (
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  primary key (room_id, user_id)
);

alter table public.profiles enable row level security;
alter table public.wallets enable row level security;
alter table public.coin_transactions enable row level security;
alter table public.agencies enable row level security;
alter table public.agency_members enable row level security;
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;

-- Users can read their own profile and public active profiles.
create policy "profiles_select_authenticated"
on public.profiles for select
to authenticated
using (is_active = true or id = auth.uid());

create policy "profiles_update_self"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy "wallet_select_self"
on public.wallets for select
to authenticated
using (user_id = auth.uid());

create policy "transactions_select_involved"
on public.coin_transactions for select
to authenticated
using (from_user_id = auth.uid() or to_user_id = auth.uid());

create policy "agencies_select_authenticated"
on public.agencies for select
to authenticated
using (is_active = true);

create policy "agency_members_select_authenticated"
on public.agency_members for select
to authenticated
using (true);

create policy "rooms_select_active"
on public.rooms for select
to authenticated
using (is_active = true);

create policy "room_members_select_authenticated"
on public.room_members for select
to authenticated
using (true);

-- IMPORTANT:
-- Coin transfers and role changes must NOT be performed by the client.
-- Implement them in a Supabase Edge Function using a transactional server-side
-- operation and authorization checks. Do not expose a service-role key in Flutter.

-- Automatically create a USER profile and zero-balance wallet for every new Auth user.
-- Roles are never taken from client metadata; every new account starts as USER.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username, display_name, role)
  values (
    new.id,
    null,
    coalesce(new.raw_user_meta_data ->> 'display_name', ''),
    'USER'
  )
  on conflict (id) do nothing;

  insert into public.wallets (user_id, balance)
  values (new.id, 0)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();


-- Privileged access helpers. These functions read the caller's server-side role.
create or replace function public.has_role(required_roles public.app_role[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and is_active = true
      and role = any(required_roles)
  );
$$;

create or replace function public.transfer_coins(
  p_to_user_id uuid,
  p_amount bigint,
  p_reason text default 'admin_transfer'
)
returns public.coin_transactions
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_role public.app_role;
  sender_balance bigint;
  result_tx public.coin_transactions;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select role into caller_role
  from public.profiles
  where id = auth.uid() and is_active = true;

  if caller_role is null or caller_role not in ('CEO','SUPER_ADMIN','MANAGER','ADMIN') then
    raise exception 'insufficient permissions';
  end if;

  if p_amount <= 0 then
    raise exception 'amount must be greater than zero';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = p_to_user_id and is_active = true
  ) then
    raise exception 'recipient not found';
  end if;

  select balance into sender_balance
  from public.wallets
  where user_id = auth.uid()
  for update;

  if sender_balance is null or sender_balance < p_amount then
    raise exception 'insufficient balance';
  end if;

  update public.wallets
  set balance = balance - p_amount, updated_at = now()
  where user_id = auth.uid();

  update public.wallets
  set balance = balance + p_amount, updated_at = now()
  where user_id = p_to_user_id;

  insert into public.coin_transactions(from_user_id, to_user_id, amount, reason)
  values (auth.uid(), p_to_user_id, p_amount, p_reason)
  returning * into result_tx;

  return result_tx;
end;
$$;

revoke all on function public.transfer_coins(uuid,bigint,text) from public;
grant execute on function public.transfer_coins(uuid,bigint,text) to authenticated;

drop policy if exists "wallet_select_privileged" on public.wallets;
create policy "wallet_select_privileged"
on public.wallets for select
to authenticated
using (
  user_id = auth.uid()
  or public.has_role(array['CEO','SUPER_ADMIN','MANAGER','ADMIN']::public.app_role[])
);

drop policy if exists "profiles_update_privileged" on public.profiles;
create policy "profiles_update_privileged"
on public.profiles for update
to authenticated
using (
  id = auth.uid()
  or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])
)
with check (
  id = auth.uid()
  or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])
);

drop policy if exists "rooms_insert_privileged" on public.rooms;
create policy "rooms_insert_privileged"
on public.rooms for insert
to authenticated
with check (
  owner_id = auth.uid()
  or public.has_role(array['CEO','SUPER_ADMIN','MANAGER','ADMIN']::public.app_role[])
);

drop policy if exists "rooms_update_privileged" on public.rooms;
create policy "rooms_update_privileged"
on public.rooms for update
to authenticated
using (
  owner_id = auth.uid()
  or public.has_role(array['CEO','SUPER_ADMIN','MANAGER','ADMIN']::public.app_role[])
)
with check (
  owner_id = auth.uid()
  or public.has_role(array['CEO','SUPER_ADMIN','MANAGER','ADMIN']::public.app_role[])
);


-- Real-time room chat messages.
create table if not exists public.room_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  message text not null check (char_length(trim(message)) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index if not exists room_messages_room_created_idx
  on public.room_messages(room_id, created_at);

alter table public.room_messages enable row level security;

drop policy if exists "room_messages_select_authenticated" on public.room_messages;
create policy "room_messages_select_authenticated"
on public.room_messages for select to authenticated
using (
  exists (select 1 from public.rooms r where r.id = room_id and r.is_active = true)
);

drop policy if exists "room_messages_insert_authenticated" on public.room_messages;
create policy "room_messages_insert_authenticated"
on public.room_messages for insert to authenticated
with check (
  user_id = auth.uid()
  and exists (select 1 from public.rooms r where r.id = room_id and r.is_active = true)
);

do $$
begin
  alter publication supabase_realtime add table public.room_messages;
exception when duplicate_object then null;
end $$;


-- ===== 002_frame_store.sql =====
-- Real profile-frame store.
create table if not exists public.frame_items (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  price bigint not null check (price >= 0),
  style_key text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.user_frames (
  user_id uuid not null references public.profiles(id) on delete cascade,
  frame_id uuid not null references public.frame_items(id) on delete cascade,
  purchased_at timestamptz not null default now(),
  primary key (user_id, frame_id)
);
alter table public.frame_items enable row level security;
alter table public.user_frames enable row level security;
drop policy if exists "frame_items_select_active" on public.frame_items;
create policy "frame_items_select_active" on public.frame_items for select to authenticated using (is_active = true);
drop policy if exists "user_frames_select_self" on public.user_frames;
create policy "user_frames_select_self" on public.user_frames for select to authenticated using (user_id = auth.uid());
insert into public.frame_items (name, price, style_key) values
('الإطار الذهبي',500,'gold'),('إطار الماس',1500,'diamond'),('إطار النار',2500,'fire'),('إطار VIP',5000,'vip'),('إطار SVIP',10000,'svip')
on conflict (name) do nothing;
create or replace function public.purchase_frame(p_frame_id uuid)
returns public.user_frames language plpgsql security definer set search_path=public as $$
declare item public.frame_items; balance bigint; result_row public.user_frames;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 select * into item from public.frame_items where id=p_frame_id and is_active=true;
 if item.id is null then raise exception 'frame not found'; end if;
 if exists(select 1 from public.user_frames where user_id=auth.uid() and frame_id=p_frame_id) then raise exception 'frame already owned'; end if;
 select w.balance into balance from public.wallets w where w.user_id=auth.uid() for update;
 if balance is null or balance<item.price then raise exception 'insufficient coins'; end if;
 update public.wallets set balance=balance-item.price,updated_at=now() where user_id=auth.uid();
 insert into public.coin_transactions(from_user_id,to_user_id,amount,reason) values(auth.uid(),null,item.price,'frame_purchase');
 insert into public.user_frames(user_id,frame_id) values(auth.uid(),p_frame_id) returning * into result_row;
 return result_row;
end; $$;
revoke all on function public.purchase_frame(uuid) from public;
grant execute on function public.purchase_frame(uuid) to authenticated;


-- ===== 002_store_vip.sql =====
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


-- ===== 003_admin_store.sql =====
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


-- ===== 004_agent_recharge.sql =====
-- Secure agent recharge by app ID/username.
create table if not exists public.agent_recharges (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references public.profiles(id),
  recipient_id uuid not null references public.profiles(id),
  amount bigint not null check (amount > 0),
  coins_per_usd bigint not null default 10000 check (coins_per_usd > 0),
  created_at timestamptz not null default now()
);

alter table public.agent_recharges enable row level security;

drop policy if exists "agent_recharges_select_involved" on public.agent_recharges;
create policy "agent_recharges_select_involved"
on public.agent_recharges for select to authenticated
using (agent_id = auth.uid() or recipient_id = auth.uid());

create or replace function public.agent_recharge(
  p_recipient_id text,
  p_amount bigint
)
returns public.agent_recharges
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_role public.app_role;
  recipient uuid;
  agent_balance bigint;
  result_row public.agent_recharges;
  rate bigint := 10000;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;

  select role into caller_role from public.profiles
  where id = auth.uid() and is_active = true;

  if caller_role <> 'AGENT' then raise exception 'agent permission required'; end if;
  if p_amount <= 0 then raise exception 'amount must be greater than zero'; end if;

  select id into recipient from public.profiles
  where is_active = true
    and (id::text = trim(p_recipient_id) or username = trim(p_recipient_id))
  limit 1;

  if recipient is null then raise exception 'recipient not found'; end if;
  if recipient = auth.uid() then raise exception 'cannot recharge yourself'; end if;

  select balance into agent_balance from public.wallets
  where user_id = auth.uid() for update;

  if agent_balance is null or agent_balance < p_amount then
    raise exception 'insufficient agent balance';
  end if;

  update public.wallets
  set balance = balance - p_amount, updated_at = now()
  where user_id = auth.uid();

  update public.wallets
  set balance = balance + p_amount, updated_at = now()
  where user_id = recipient;

  insert into public.coin_transactions(from_user_id, to_user_id, amount, reason)
  values (auth.uid(), recipient, p_amount, 'agent_recharge');

  insert into public.agent_recharges(agent_id, recipient_id, amount, coins_per_usd)
  values (auth.uid(), recipient, p_amount, rate)
  returning * into result_row;

  return result_row;
end;
$$;

revoke all on function public.agent_recharge(text,bigint) from public;
grant execute on function public.agent_recharge(text,bigint) to authenticated;


-- ===== 005_app_promotions.sql =====
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
  (is_active = true and starts_at <= now() and (ends_at is null or ends_at >= now()))
  or public.has_role(array['CEO','SUPER_ADMIN','MANAGER']::public.app_role[])
);

drop policy if exists "admins_manage_promotions" on public.app_promotions;
create policy "admins_manage_promotions"
on public.app_promotions
for all to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN','MANAGER']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN','MANAGER']::public.app_role[]));

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


-- ===== 006_country_flags.sql =====
-- Country/flag support. Syria is rendered in-app as the independence flag:
-- green / white / black with three red stars.
alter table public.profiles add column if not exists country_code text;
create index if not exists profiles_country_code_idx on public.profiles(country_code);


-- ===== 007_vip_system.sql =====
-- Real VIP 1-10 system.
alter table public.profiles add column if not exists vip_level text;
create table if not exists public.vip_levels(id text primary key,animal text not null,price bigint not null check(price>=0),perks text[] not null default '{}',is_active boolean not null default true);
alter table public.vip_levels enable row level security;
drop policy if exists "vip_levels_select_active" on public.vip_levels;
create policy "vip_levels_select_active" on public.vip_levels for select to authenticated using(is_active=true);
insert into public.vip_levels(id,animal,price,perks) values ('VIP1','الغزال',10000,array['إطار VIP','شارة VIP','مزايا استلام العملات']),('VIP2','الذئب',25000,array['إطار VIP','شارة VIP','مزايا استلام العملات']),('VIP3','التمساح',50000,array['نمط حصري','اسم مستخدم مميز','إطار VIP']),('VIP4','الفيل',90000,array['نمط غرفة','نمط بطاقة التعريف','مزايا استلام العملات']),('VIP5','النسر',150000,array['مزايا الغرفة','اسم ميكروفون مجاني','رسائل غير محدودة']),('VIP6','الدب',250000,array['مزايا الغرفة','اسم ميكروفون مجاني','رسائل غير محدودة']),('VIP7','الفهد',400000,array['نمط بطاقة التعريف','اسم مجاني','مزايا استلام العملات']),('VIP8','النمر',650000,array['اسم مميز','شارة VIP','مزايا استلام العملات']),('VIP9','التنين',1000000,array['مزايا الغرفة','اسم ميكروفون مجاني','رسائل غير محدودة']),('VIP10','الأسد',1500000,array['ترحيب أسطوري','دخول الغرفة بتأثير','كل المميزات']) on conflict(id) do update set animal=excluded.animal,price=excluded.price,perks=excluded.perks;
create or replace function public.purchase_vip(p_vip_level text) returns public.profiles language plpgsql security definer set search_path=public as $$ declare v public.vip_levels;b bigint;p public.profiles;begin if auth.uid() is null then raise exception 'not authenticated';end if;select * into v from public.vip_levels where id=p_vip_level and is_active=true;if v.id is null then raise exception 'VIP not found';end if;select balance into b from public.wallets where user_id=auth.uid() for update;if b is null or b<v.price then raise exception 'insufficient coins';end if;update public.wallets set balance=balance-v.price,updated_at=now() where user_id=auth.uid();update public.profiles set vip_level=v.id,updated_at=now() where id=auth.uid() returning * into p;insert into public.coin_transactions(from_user_id,to_user_id,amount,reason) values(auth.uid(),null,v.price,'vip_purchase:'||v.id);return p;end;$$;
revoke all on function public.purchase_vip(text) from public;grant execute on function public.purchase_vip(text) to authenticated;


-- ===== 008_gifts.sql =====
-- Real room gifts.
create table if not exists public.gifts(id text primary key,name text not null,emoji text not null,price bigint not null check(price>0),is_active boolean not null default true);
create table if not exists public.gift_transactions(id uuid primary key default gen_random_uuid(),room_id uuid not null references public.rooms(id) on delete cascade,sender_id uuid not null references public.profiles(id),recipient_id uuid not null references public.profiles(id),gift_id text not null references public.gifts(id),amount bigint not null,created_at timestamptz not null default now());
alter table public.gifts enable row level security; alter table public.gift_transactions enable row level security;
create policy "gifts_select_active" on public.gifts for select to authenticated using(is_active=true);
create policy "gift_transactions_select_self" on public.gift_transactions for select to authenticated using(sender_id=auth.uid() or recipient_id=auth.uid());
insert into public.gifts(id,name,emoji,price) values('rose','وردة','🌹',100),('heart','قلب','❤️',500),('diamond','ماسة','💎',1000),('crown','تاج','👑',5000),('dragon','تنين','🐉',10000),('lion','أسد','🦁',25000) on conflict(id) do update set name=excluded.name,emoji=excluded.emoji,price=excluded.price;
create or replace function public.send_gift(p_room_id uuid,p_recipient_id text,p_gift_id text) returns public.gift_transactions language plpgsql security definer set search_path=public as $$
declare g public.gifts; s bigint; r uuid; t public.gift_transactions;
begin
if auth.uid() is null then raise exception 'not authenticated'; end if;
select * into g from gifts where id=p_gift_id and is_active=true;
if g.id is null then raise exception 'gift not found'; end if;
select id into r from profiles where id::text=p_recipient_id or username=p_recipient_id limit 1;
if r is null then raise exception 'recipient not found'; end if;
if r=auth.uid() then raise exception 'cannot gift yourself'; end if;
select balance into s from wallets where user_id=auth.uid() for update;
if s is null or s<g.price then raise exception 'insufficient coins'; end if;
update wallets set balance=balance-g.price,updated_at=now() where user_id=auth.uid();
insert into wallets(user_id,balance) values(r,g.price) on conflict(user_id) do update set balance=wallets.balance+g.price,updated_at=now();
insert into coin_transactions(from_user_id,to_user_id,amount,reason) values(auth.uid(),r,g.price,'gift:'||g.id);
insert into gift_transactions(room_id,sender_id,recipient_id,gift_id,amount) values(p_room_id,auth.uid(),r,g.id,g.price) returning * into t;
return t;
end; $$;
revoke all on function public.send_gift(uuid,text,text) from public;
grant execute on function public.send_gift(uuid,text,text) to authenticated;


-- ===== 009_gift_stats.sql =====
-- Gift statistics and receiver leaderboard.
create or replace function public.gift_stats(p_user_id uuid default auth.uid())
returns table(sent_count bigint, sent_coins bigint, received_count bigint, received_coins bigint)
language sql security definer set search_path=public as $$
  select
    (select count(*) from gift_transactions where sender_id=p_user_id),
    (select coalesce(sum(amount),0) from gift_transactions where sender_id=p_user_id),
    (select count(*) from gift_transactions where recipient_id=p_user_id),
    (select coalesce(sum(amount),0) from gift_transactions where recipient_id=p_user_id);
$$;
create or replace function public.top_gift_receivers(p_limit integer default 20)
returns table(user_id uuid, username text, role app_role, country_code text, vip_level text, gift_count bigint, received_coins bigint)
language sql security definer set search_path=public as $$
  select p.id,p.username,p.role,p.country_code,p.vip_level,count(gt.id),coalesce(sum(gt.amount),0)
  from gift_transactions gt join profiles p on p.id=gt.recipient_id
  group by p.id,p.username,p.role,p.country_code,p.vip_level
  order by coalesce(sum(gt.amount),0) desc, count(gt.id) desc
  limit greatest(1,least(coalesce(p_limit,20),100));
$$;
revoke all on function public.gift_stats(uuid) from public;
revoke all on function public.top_gift_receivers(integer) from public;
grant execute on function public.gift_stats(uuid) to authenticated;
grant execute on function public.top_gift_receivers(integer) to authenticated;


-- ===== 010_notifications.sql =====
-- Real in-app notifications.
create table if not exists public.notifications(
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 type text not null, title text not null, body text not null, data jsonb not null default '{}'::jsonb,
 is_read boolean not null default false, created_at timestamptz not null default now()
);
create index if not exists notifications_user_created_idx on public.notifications(user_id,created_at desc);
alter table public.notifications enable row level security;
create policy "notifications_select_own" on public.notifications for select to authenticated using(user_id=auth.uid());
create policy "notifications_update_own" on public.notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "notifications_insert_admin" on public.notifications for insert to authenticated with check(public.has_role(array['CEO','SUPER_ADMIN','MANAGER','ADMIN']::public.app_role[]));
create or replace function public.notify_gift() returns trigger language plpgsql security definer set search_path=public as $$
declare n text; e text;
begin select name,emoji into n,e from gifts where id=new.gift_id; insert into notifications(user_id,type,title,body,data) values(new.recipient_id,'gift','🎁 هدية جديدة','استلمت '||coalesce(n,new.gift_id)||' بقيمة '||new.amount||' 🪙',jsonb_build_object('room_id',new.room_id,'sender_id',new.sender_id,'gift_id',new.gift_id,'amount',new.amount,'emoji',coalesce(e,'🎁'))); return new; end; $$;
drop trigger if exists gift_notification_trigger on public.gift_transactions;
create trigger gift_notification_trigger after insert on public.gift_transactions for each row execute function public.notify_gift();
create or replace function public.mark_notification_read(p_id uuid) returns void language sql security definer set search_path=public as $$ update notifications set is_read=true where id=p_id and user_id=auth.uid(); $$;
grant execute on function public.mark_notification_read(uuid) to authenticated;


-- ===== 011_friends.sql =====
-- Friends / follow requests with notifications.
create table if not exists public.friend_requests(
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references public.profiles(id) on delete cascade,
 receiver_id uuid not null references public.profiles(id) on delete cascade,
 status text not null default 'pending' check(status in ('pending','accepted','rejected','cancelled')),
 created_at timestamptz not null default now(),
 responded_at timestamptz
);
create unique index if not exists friend_pending_unique on public.friend_requests(sender_id,receiver_id) where status='pending';
create table if not exists public.friendships(
 user_id uuid not null references public.profiles(id) on delete cascade,
 friend_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(user_id,friend_id)
);
alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
create policy "friend_requests_select_own" on public.friend_requests for select to authenticated using(sender_id=auth.uid() or receiver_id=auth.uid());
create policy "friend_requests_insert_self" on public.friend_requests for insert to authenticated with check(sender_id=auth.uid() and sender_id<>receiver_id);
create policy "friend_requests_update_receiver" on public.friend_requests for update to authenticated using(receiver_id=auth.uid()) with check(receiver_id=auth.uid());
create policy "friendships_select_own" on public.friendships for select to authenticated using(user_id=auth.uid());
create or replace function public.send_friend_request(p_receiver text) returns uuid language plpgsql security definer set search_path=public as $$
declare r uuid; rid uuid;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 select id into r from profiles where id::text=p_receiver or username=p_receiver limit 1;
 if r is null then raise exception 'user not found'; end if;
 if r=auth.uid() then raise exception 'cannot add yourself'; end if;
 if exists(select 1 from friendships where user_id=auth.uid() and friend_id=r) then raise exception 'already friends'; end if;
 select id into rid from friend_requests where sender_id=auth.uid() and receiver_id=r and status='pending' limit 1;
 if rid is not null then return rid; end if;
 insert into friend_requests(sender_id,receiver_id) values(auth.uid(),r) returning id into rid;
 insert into notifications(user_id,type,title,body,data) values(r,'friend_request','👥 طلب صداقة جديد','لديك طلب صداقة جديد',jsonb_build_object('request_id',rid,'sender_id',auth.uid()));
 return rid;
end; $$;
create or replace function public.respond_friend_request(p_request uuid,p_accept boolean) returns void language plpgsql security definer set search_path=public as $$
declare r friend_requests;
begin
 select * into r from friend_requests where id=p_request and receiver_id=auth.uid() and status='pending' for update;
 if r.id is null then raise exception 'request not found'; end if;
 update friend_requests set status=case when p_accept then 'accepted' else 'rejected' end,responded_at=now() where id=r.id;
 if p_accept then
   insert into friendships(user_id,friend_id) values(r.sender_id,r.receiver_id),(r.receiver_id,r.sender_id) on conflict do nothing;
   insert into notifications(user_id,type,title,body,data) values(r.sender_id,'friend_accepted','🤝 تم قبول طلب الصداقة','تم قبول طلب الصداقة الخاص بك',jsonb_build_object('friend_id',r.receiver_id));
 end if;
end; $$;
grant execute on function public.send_friend_request(text) to authenticated;
grant execute on function public.respond_friend_request(uuid,boolean) to authenticated;


-- ===== 012_private_messages.sql =====
-- Private 1-to-1 messaging between friends.
create table if not exists public.private_messages(
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references public.profiles(id) on delete cascade,
 receiver_id uuid not null references public.profiles(id) on delete cascade,
 message text not null check(length(trim(message)) between 1 and 2000),
 created_at timestamptz not null default now(),
 read_at timestamptz
);
create index if not exists private_messages_pair_idx on public.private_messages(sender_id,receiver_id,created_at desc);
alter table public.private_messages enable row level security;
create policy "private_messages_select_own" on public.private_messages for select to authenticated using(sender_id=auth.uid() or receiver_id=auth.uid());
create policy "private_messages_insert_sender" on public.private_messages for insert to authenticated with check(sender_id=auth.uid() and exists(select 1 from friendships f where f.user_id=auth.uid() and f.friend_id=receiver_id));
create policy "private_messages_update_receiver" on public.private_messages for update to authenticated using(receiver_id=auth.uid()) with check(receiver_id=auth.uid());
create or replace function public.send_private_message(p_receiver uuid,p_message text) returns uuid language plpgsql security definer set search_path=public as $$
declare mid uuid;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 if p_receiver=auth.uid() then raise exception 'cannot message yourself'; end if;
 if not exists(select 1 from friendships where user_id=auth.uid() and friend_id=p_receiver) then raise exception 'not friends'; end if;
 insert into private_messages(sender_id,receiver_id,message) values(auth.uid(),p_receiver,trim(p_message)) returning id into mid;
 insert into notifications(user_id,type,title,body,data) values(p_receiver,'private_message','💬 رسالة جديدة','لديك رسالة خاصة جديدة',jsonb_build_object('message_id',mid,'sender_id',auth.uid()));
 return mid;
end; $$;
grant execute on function public.send_private_message(uuid,text) to authenticated;
alter publication supabase_realtime add table public.private_messages;


-- ===== 013_private_conversations.sql =====
-- Private conversation list and unread counters.
create or replace function public.private_conversations() returns table(friend_id uuid,last_message text,last_at timestamptz,unread_count bigint)
language sql security definer set search_path=public as $$
 with msgs as (
  select case when sender_id=auth.uid() then receiver_id else sender_id end as fid,
         message,created_at,receiver_id,read_at
  from private_messages where sender_id=auth.uid() or receiver_id=auth.uid()
 ), ranked as (
  select *,row_number() over(partition by fid order by created_at desc) rn from msgs
 )
 select fid,
        max(message) filter(where rn=1),
        max(created_at) filter(where rn=1),
        count(*) filter(where receiver_id=auth.uid() and read_at is null)
 from ranked group by fid order by max(created_at) desc;
$$;
create or replace function public.mark_private_messages_read(p_friend uuid) returns void language sql security definer set search_path=public as $$
 update private_messages set read_at=now() where receiver_id=auth.uid() and sender_id=p_friend and read_at is null;
$$;
grant execute on function public.private_conversations() to authenticated;
grant execute on function public.mark_private_messages_read(uuid) to authenticated;


-- ===== 014_profile_media_ids.sql =====
-- Profile media policy and human-friendly alphanumeric IDs.
alter table public.profiles add column if not exists public_id text;
alter table public.profiles add column if not exists avatar_is_animated boolean not null default false;
alter table public.profiles alter column public_id set default upper(substr(md5(gen_random_uuid()::text),1,8));

update public.profiles
set public_id=upper(substr(md5(id::text||gen_random_uuid()::text),1,8))
where public_id is null;

create unique index if not exists profiles_public_id_unique on public.profiles(public_id);

create or replace function public.enforce_avatar_policy()
returns trigger language plpgsql security definer set search_path=public as $$
declare v integer;
begin
  if new.avatar_is_animated and (tg_op='INSERT' or new.avatar_url is distinct from old.avatar_url or new.avatar_is_animated is distinct from old.avatar_is_animated) then
    select coalesce(nullif(regexp_replace(vip_level,'[^0-9]','','g'),'')::integer,0) into v
    from profiles where id=coalesce(new.id,auth.uid());
    if not (
      coalesce(v,0) >= 7
      or public.has_role(array['CEO','SUPER_ADMIN','MANAGER','ADMIN']::public.app_role[])
    ) then
      raise exception 'animated avatars require VIP7 or higher or admin access';
    end if;
  end if;
  return new;
end; $$;

drop trigger if exists profile_avatar_policy on public.profiles;
create trigger profile_avatar_policy before insert or update of avatar_url,avatar_is_animated on public.profiles
for each row execute function public.enforce_avatar_policy();

-- Human-friendly IDs are accepted anywhere the app previously accepted profile UUIDs.
create or replace function public.send_friend_request(p_receiver text) returns uuid language plpgsql security definer set search_path=public as $$
declare r uuid; rid uuid;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 select id into r from profiles where id::text=p_receiver or public_id=upper(trim(p_receiver)) or username=p_receiver limit 1;
 if r is null then raise exception 'user not found'; end if;
 if r=auth.uid() then raise exception 'cannot add yourself'; end if;
 if exists(select 1 from friendships where user_id=auth.uid() and friend_id=r) then raise exception 'already friends'; end if;
 select id into rid from friend_requests where sender_id=auth.uid() and receiver_id=r and status='pending' limit 1;
 if rid is not null then return rid; end if;
 insert into friend_requests(sender_id,receiver_id) values(auth.uid(),r) returning id into rid;
 insert into notifications(user_id,type,title,body,data) values(r,'friend_request','👥 طلب صداقة جديد','لديك طلب صداقة جديد',jsonb_build_object('request_id',rid,'sender_id',auth.uid()));
 return rid;
end; $$;
grant execute on function public.send_friend_request(text) to authenticated;

-- Gift recipients can also be found by the public alphanumeric ID.
drop function if exists public.send_gift(uuid,text,text);
create or replace function public.send_gift(p_room_id uuid,p_recipient_id text,p_gift_id text) returns public.gift_transactions language plpgsql security definer set search_path=public as $$
declare g public.gifts; s bigint; r uuid; t public.gift_transactions;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 select * into g from gifts where id=p_gift_id and is_active=true;
 if g.id is null then raise exception 'gift not found'; end if;
 select id into r from profiles where id::text=p_recipient_id or public_id=upper(trim(p_recipient_id)) or username=p_recipient_id limit 1;
 if r is null then raise exception 'recipient not found'; end if;
 if r=auth.uid() then raise exception 'cannot gift yourself'; end if;
 select balance into s from wallets where user_id=auth.uid() for update;
 if s is null or s<g.price then raise exception 'insufficient coins'; end if;
 update wallets set balance=balance-g.price,updated_at=now() where user_id=auth.uid();
 insert into wallets(user_id,balance) values(r,g.price) on conflict(user_id) do update set balance=wallets.balance+excluded.balance,updated_at=now();
 insert into coin_transactions(from_user_id,to_user_id,amount,reason) values(auth.uid(),r,g.price,'gift:'||g.id);
 insert into gift_transactions(room_id,sender_id,recipient_id,gift_id,amount) values(p_room_id,auth.uid(),r,g.id,g.price) returning * into t;
 return t;
end; $$;
revoke all on function public.send_gift(uuid,text,text) from public;
grant execute on function public.send_gift(uuid,text,text) to authenticated;

create or replace function public.get_my_public_id() returns text language sql stable security definer set search_path=public as $$
 select public_id from profiles where id=auth.uid();
$$;
grant execute on function public.get_my_public_id() to authenticated;


-- ===== 015_avatar_storage.sql =====
-- Avatar storage bucket and secure upload policies.
insert into storage.buckets(id,name,public) values('avatars','avatars',true) on conflict(id) do update set public=true;
create policy "avatar_upload_own" on storage.objects for insert to authenticated with check(bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "avatar_update_own" on storage.objects for update to authenticated using(bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text) with check(bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "avatar_delete_own" on storage.objects for delete to authenticated using(bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text);


-- ===== 016_profile_badges_verification.sql =====
-- Appearance-only profile badges + admin account verification.
alter table public.profiles
  add column if not exists activity_admin_badge boolean not null default false,
  add column if not exists customer_service_badge boolean not null default false,
  add column if not exists is_verified boolean not null default false;

create index if not exists profiles_badges_idx
  on public.profiles(activity_admin_badge, customer_service_badge, is_verified);

drop policy if exists "admins_manage_profile_badges" on public.profiles;
create policy "admins_manage_profile_badges"
on public.profiles
for update to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

grant select on public.profiles to authenticated;


-- ===== 017_room_backgrounds.sql =====
-- Room and seat background rentals.
alter table public.rooms
  add column if not exists room_background_url text,
  add column if not exists room_background_expires_at timestamptz,
  add column if not exists seats_background_url text,
  add column if not exists seats_background_expires_at timestamptz;

create table if not exists public.room_background_purchases (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  buyer_id uuid not null references public.profiles(id),
  background_type text not null check(background_type in ('room','seats')),
  duration_days integer not null check(duration_days in (7,30)),
  price bigint not null check(price in (10000,35000)),
  background_url text not null,
  starts_at timestamptz not null default now(),
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.room_background_purchases enable row level security;

create policy "room_background_purchases_select_owner"
on public.room_background_purchases for select to authenticated
using (buyer_id=auth.uid() or exists (
  select 1 from public.rooms r where r.id=room_id and r.owner_id=auth.uid()
));

insert into storage.buckets(id,name,public)
values('room-backgrounds','room-backgrounds',true)
on conflict(id) do update set public=true;

create policy "room_background_upload_own"
on storage.objects for insert to authenticated
with check (
  bucket_id='room-backgrounds'
  and (storage.foldername(name))[1]=auth.uid()::text
);

create policy "room_background_update_own"
on storage.objects for update to authenticated
using (
  bucket_id='room-backgrounds'
  and (storage.foldername(name))[1]=auth.uid()::text
)
with check (
  bucket_id='room-backgrounds'
  and (storage.foldername(name))[1]=auth.uid()::text
);

create policy "room_background_delete_own"
on storage.objects for delete to authenticated
using (
  bucket_id='room-backgrounds'
  and (storage.foldername(name))[1]=auth.uid()::text
);

create or replace function public.purchase_room_background(
  p_room_id uuid,
  p_background_type text,
  p_background_url text,
  p_duration_days integer
) returns public.room_background_purchases
language plpgsql security definer set search_path=public
as $$
declare
  r public.rooms;
  w bigint;
  price_value bigint;
  expiry timestamptz;
  purchase public.room_background_purchases;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if p_background_type not in ('room','seats') then raise exception 'invalid background type'; end if;
  if p_duration_days not in (7,30) then raise exception 'invalid duration'; end if;
  if coalesce(trim(p_background_url),'')='' then raise exception 'background url required'; end if;

  select * into r from public.rooms where id=p_room_id for update;
  if r.id is null then raise exception 'room not found'; end if;
  if r.owner_id <> auth.uid() and not public.has_role(array['CEO','SUPER_ADMIN','MANAGER','ADMIN']::public.app_role[]) then
    raise exception 'only room owner or admin can change background';
  end if;

  price_value := case when p_duration_days=7 then 10000 else 35000 end;
  select balance into w from public.wallets where user_id=auth.uid() for update;
  if w is null or w < price_value then raise exception 'insufficient coins'; end if;

  expiry := now() + make_interval(days => p_duration_days);
  update public.wallets
    set balance=balance-price_value, updated_at=now()
    where user_id=auth.uid();

  insert into public.coin_transactions(from_user_id,to_user_id,amount,reason)
  values(auth.uid(),auth.uid(),price_value,
         'room_background:'||p_background_type||':'||p_duration_days||'d');

  if p_background_type='room' then
    update public.rooms set room_background_url=p_background_url, room_background_expires_at=expiry where id=p_room_id;
  else
    update public.rooms set seats_background_url=p_background_url, seats_background_expires_at=expiry where id=p_room_id;
  end if;

  insert into public.room_background_purchases(
    room_id,buyer_id,background_type,duration_days,price,background_url,expires_at
  ) values (
    p_room_id,auth.uid(),p_background_type,p_duration_days,price_value,p_background_url,expiry
  ) returning * into purchase;

  return purchase;
end;
$$;

revoke all on function public.purchase_room_background(uuid,text,text,integer) from public;
grant execute on function public.purchase_room_background(uuid,text,text,integer) to authenticated;


-- ===== 018_deluxe_gifts.sql =====
-- Deluxe gift catalog, admin controls, and public gift ticker.
alter table public.gifts
  add column if not exists category text not null default 'normal',
  add column if not exists banner_enabled boolean not null default false,
  add column if not exists banner_min_price bigint not null default 4000,
  add column if not exists luck_min_win bigint not null default 3000;

create table if not exists public.gift_public_banners(
  id uuid primary key default gen_random_uuid(),
  gift_id text not null references public.gifts(id) on delete cascade,
  amount bigint not null,
  created_at timestamptz not null default now()
);
alter table public.gift_public_banners enable row level security;
drop policy if exists gift_public_banners_select on public.gift_public_banners;
create policy gift_public_banners_select on public.gift_public_banners
for select to authenticated using (true);

do $$ begin
  alter publication supabase_realtime add table public.gift_public_banners;
exception when duplicate_object then null; when undefined_object then null; end $$;

insert into public.gifts(id,name,emoji,price,category,banner_enabled) values
('rose','وردة','🌹',100,'normal',false),
('heart','قلب','❤️',500,'love',false),
('kiss','قبلة','💋',1000,'love',false),
('love_letter','رسالة حب','💌',4000,'love',true),
('love_ring','خاتم حب','💍',10000,'love',true),
('love_couple','ثنائي الحب','💞',50000,'love',true),
('diamond','ماسة','💎',2500,'luxury',false),
('crown','تاج ملكي','👑',10000,'luxury',true),
('royal_car','سيارة ملكية','🚘',50000,'luxury',true),
('gold_castle','قصر ذهبي','🏰',100000,'luxury',true),
('gold_dragon','تنين ذهبي','🐉',250000,'luxury',true),
('royal_throne','عرش ملكي','👑',500000,'luxury',true),
('asmar_kingdom','مملكة Asmar','🏯',1000000,'luxury',true),
('cp','CP','🫶',4000,'cp',true),
('cp_royal','CP ملكي','💎',25000,'cp',true),
('brother','علاقة أخوة','🤝',4000,'brotherhood',true),
('brother_gold','أخوة ذهبية','🫂',25000,'brotherhood',true),
('brother_royal','رابطة إخوة ملكية','🛡️',100000,'brotherhood',true),
('luck_10','حظ 10','🍀',10,'luck',false),
('luck_50','حظ 50','🍀',50,'luck',false),
('luck_100','حظ 100','🍀',100,'luck',false),
('luck_500','حظ 500','🎰',500,'luck',false),
('luck_1000','حظ 1,000','🎰',1000,'luck',false),
('luck_3000','حظ 3,000','✨',3000,'luck',false),
('luck_5000','حظ 5,000','✨',5000,'luck',true),
('dragon','تنين','🐉',10000,'normal',true),
('lion','أسد','🦁',25000,'normal',true),
('supernova','سوبر نوفا','🌌',100000,'luxury',true)
on conflict(id) do update set
 name=excluded.name,emoji=excluded.emoji,price=excluded.price,category=excluded.category,banner_enabled=excluded.banner_enabled;

create or replace function public.send_gift(p_room_id uuid,p_recipient_id text,p_gift_id text)
returns public.gift_transactions language plpgsql security definer set search_path=public as $$
declare g public.gifts; s bigint; r uuid; t public.gift_transactions;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 select * into g from gifts where id=p_gift_id and is_active=true;
 if g.id is null then raise exception 'gift not found'; end if;
 select id into r from profiles where id::text=p_recipient_id or username=p_recipient_id or public_id=p_recipient_id limit 1;
 if r is null then raise exception 'recipient not found'; end if;
 if r=auth.uid() then raise exception 'cannot gift yourself'; end if;
 select balance into s from wallets where user_id=auth.uid() for update;
 if s is null or s<g.price then raise exception 'insufficient coins'; end if;
 update wallets set balance=balance-g.price,updated_at=now() where user_id=auth.uid();
 insert into wallets(user_id,balance) values(r,g.price) on conflict(user_id) do update set balance=wallets.balance+g.price,updated_at=now();
 insert into coin_transactions(from_user_id,to_user_id,amount,reason) values(auth.uid(),r,g.price,'gift:'||g.id);
 insert into gift_transactions(room_id,sender_id,recipient_id,gift_id,amount) values(p_room_id,auth.uid(),r,g.id,g.price) returning * into t;
 if g.banner_enabled and g.price >= greatest(g.banner_min_price,4000) then
   insert into gift_public_banners(gift_id,amount) values(g.id,g.price);
 end if;
 return t;
end; $$;

create or replace function public.admin_update_gift(
 p_id text,p_name text,p_emoji text,p_price bigint,p_category text,p_is_active boolean,
 p_banner_enabled boolean,p_banner_min_price bigint,p_luck_min_win bigint
) returns public.gifts language plpgsql security definer set search_path=public as $$
declare g public.gifts;
begin
 if auth.uid() is null or not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then raise exception 'not authorized'; end if;
 if p_price < 1 or p_banner_min_price < 0 or p_luck_min_win < 0 then raise exception 'invalid values'; end if;
 update public.gifts set name=p_name,emoji=p_emoji,price=p_price,category=p_category,is_active=p_is_active,
   banner_enabled=p_banner_enabled,banner_min_price=p_banner_min_price,luck_min_win=p_luck_min_win
 where id=p_id returning * into g;
 if g.id is null then raise exception 'gift not found'; end if;
 return g;
end; $$;
revoke all on function public.admin_update_gift(text,text,text,bigint,text,boolean,boolean,bigint,bigint) from public;
grant execute on function public.admin_update_gift(text,text,text,bigint,text,boolean,boolean,bigint,bigint) to authenticated;


-- ===== 019_global_chat.sql =====
create table if not exists public.global_chat_messages(
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references auth.users(id) on delete cascade,
 message text not null check (char_length(trim(message)) between 1 and 1000),
 created_at timestamptz not null default now()
);
create index if not exists global_chat_messages_created_idx on public.global_chat_messages(created_at desc);
alter table public.global_chat_messages enable row level security;
drop policy if exists global_chat_select on public.global_chat_messages;
create policy global_chat_select on public.global_chat_messages for select to authenticated using (true);
drop policy if exists global_chat_insert on public.global_chat_messages;
create policy global_chat_insert on public.global_chat_messages for insert to authenticated with check (sender_id=auth.uid());
do $$ begin alter publication supabase_realtime add table public.global_chat_messages; exception when duplicate_object then null; when undefined_object then null; end $$;
grant select,insert on public.global_chat_messages to authenticated;


-- ===== 019_global_chat_200_coins.sql =====
-- Global public chat: 200 coins per sent message
create table if not exists public.global_chat_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  message text not null check (char_length(trim(message)) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index if not exists global_chat_messages_created_at_idx
  on public.global_chat_messages(created_at desc);

alter table public.global_chat_messages enable row level security;

drop policy if exists "authenticated_read_global_chat" on public.global_chat_messages;
create policy "authenticated_read_global_chat"
on public.global_chat_messages for select
to authenticated
using (true);

create or replace function public.send_global_chat_message(p_message text)
returns public.global_chat_messages
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_message text := trim(p_message);
  v_row public.global_chat_messages;
  v_balance bigint;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  if char_length(v_message) < 1 or char_length(v_message) > 1000 then
    raise exception 'INVALID_MESSAGE';
  end if;

  select coin_balance into v_balance
  from public.wallets
  where user_id = v_user
  for update;

  if coalesce(v_balance, 0) < 200 then
    raise exception 'INSUFFICIENT_COINS';
  end if;

  update public.wallets
  set coin_balance = coin_balance - 200
  where user_id = v_user;

  insert into public.coin_transactions(user_id, amount, transaction_type, description)
  values (v_user, -200, 'global_chat', 'رسالة دردشة عامة');

  insert into public.global_chat_messages(sender_id, message)
  values (v_user, v_message)
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.send_global_chat_message(text) from public;
grant execute on function public.send_global_chat_message(text) to authenticated;

alter table public.global_chat_messages replica identity full;
do $$
begin
  alter publication supabase_realtime add table public.global_chat_messages;
exception when duplicate_object then
  null;
end $$;


-- ===== 019_rocket_levels.sql =====
create table if not exists public.rocket_levels (
  id integer primary key check (id between 1 and 5),
  name text not null,
  bg1 text not null,
  bg2 text not null,
  line text not null,
  coins bigint not null default 0 check (coins >= 0),
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.rocket_levels enable row level security;
drop policy if exists "rocket_levels_select_active" on public.rocket_levels;
create policy "rocket_levels_select_active" on public.rocket_levels for select to authenticated using (is_active = true);
drop policy if exists "rocket_levels_admin_update" on public.rocket_levels;
create policy "rocket_levels_admin_update" on public.rocket_levels for update to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
insert into public.rocket_levels(id,name,bg1,bg2,line,coins) values
(1,'LV1 عادي','#2A1E0F','#1A1109','#FFD700',1000),
(2,'LV2 زمرد','#0F2A1E','#05140A','#00FF88',3000),
(3,'LV3 ياقوت ازرق','#0F1E4A','#050A2A','#3A7BFF',5000),
(4,'LV4 روبي احمر','#4A0F0F','#2A0505','#FF2A2A',7000),
(5,'LV5 ملكي بنفسجي','#3A0F4A','#1A052A','#AA2AFF',10000)
on conflict(id) do update set name=excluded.name,bg1=excluded.bg1,bg2=excluded.bg2,line=excluded.line,coins=excluded.coins,updated_at=now();


-- ===== 020_admin_dashboard_access.sql =====
-- Fix external admin dashboard access for authenticated admin accounts.
-- Safe: grants table access to authenticated users; RLS remains the authorization boundary.
grant select on public.profiles to authenticated;
grant select on public.wallets to authenticated;
grant select on public.rooms to authenticated;
grant select on public.store_items to authenticated;
grant select on public.asmar_policy to authenticated;
grant select, insert, update on public.app_promotions to authenticated;
grant select, update on public.gifts to authenticated;
grant select, update on public.rocket_levels to authenticated;

drop policy if exists "profiles_select_admin" on public.profiles;
create policy "profiles_select_admin"
on public.profiles for select
to authenticated
using (
  id = auth.uid()
  or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])
);

drop policy if exists "store_items_admin" on public.store_items;
create policy "store_items_admin"
on public.store_items for update
to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "promotions_admin_insert" on public.app_promotions;
create policy "promotions_admin_insert"
on public.app_promotions for insert
to authenticated
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "promotions_admin_update" on public.app_promotions;
create policy "promotions_admin_update"
on public.app_promotions for update
to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));


-- ===== 020_admin_profiles_access.sql =====
-- Allow the authenticated admin dashboard to read profiles safely.
-- The dashboard still checks that the current user's profile role is CEO/SUPER_ADMIN.

GRANT SELECT ON TABLE public.profiles TO authenticated;

DROP POLICY IF EXISTS "admin_profiles_select" ON public.profiles;
CREATE POLICY "admin_profiles_select"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  id = (select auth.uid())
  OR public.has_role(ARRAY['CEO','SUPER_ADMIN']::public.app_role[])
);


-- ===== 021_admin_dashboard_hardening.sql =====
-- Admin dashboard hardening: complete privileged reads and actions.
-- Safe to run after the existing migrations.

grant select on public.profiles, public.wallets, public.rooms, public.frame_items,
  public.coin_packages, public.vip_levels, public.gifts, public.rocket_levels,
  public.asmar_policy, public.app_promotions to authenticated;

drop policy if exists "rooms_select_privileged" on public.rooms;
create policy "rooms_select_privileged"
on public.rooms for select to authenticated
using (
  is_active = true
  or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])
);

drop policy if exists "gifts_select_privileged" on public.gifts;
create policy "gifts_select_privileged"
on public.gifts for select to authenticated
using (
  is_active = true
  or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])
);

drop policy if exists "promotions_admin_select_all" on public.app_promotions;
create policy "promotions_admin_select_all"
on public.app_promotions for select to authenticated
using (
  is_active = true
  or public.has_role(array['CEO','SUPER_ADMIN','MANAGER']::public.app_role[])
);

create or replace function public.admin_set_user_active(
  p_user_id uuid,
  p_active boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then
    raise exception 'not authorized';
  end if;
  if p_user_id = auth.uid() and not p_active then
    raise exception 'cannot deactivate current admin';
  end if;
  update public.profiles
    set is_active = p_active, updated_at = now()
  where id = p_user_id;
  if not found then raise exception 'user not found'; end if;
  return p_active;
end;
$$;

create or replace function public.admin_set_room_active(
  p_room_id uuid,
  p_active boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then
    raise exception 'not authorized';
  end if;
  update public.rooms set is_active = p_active where id = p_room_id;
  if not found then raise exception 'room not found'; end if;
  return p_active;
end;
$$;

create or replace function public.admin_adjust_wallet(
  p_user_id uuid,
  p_amount bigint
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare new_balance bigint;
begin
  if auth.uid() is null or not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then
    raise exception 'not authorized';
  end if;
  if p_amount = 0 then raise exception 'amount cannot be zero'; end if;

  insert into public.wallets(user_id,balance)
  values (p_user_id,0)
  on conflict(user_id) do nothing;

  update public.wallets
    set balance = balance + p_amount, updated_at = now()
  where user_id = p_user_id
    and balance + p_amount >= 0
  returning balance into new_balance;

  if new_balance is null then raise exception 'insufficient balance'; end if;

  insert into public.coin_transactions(from_user_id,to_user_id,amount,reason)
  values (
    case when p_amount < 0 then auth.uid() else null end,
    case when p_amount > 0 then p_user_id else null end,
    abs(p_amount),
    'admin_adjustment'
  );
  return new_balance;
end;
$$;

revoke all on function public.admin_set_user_active(uuid,boolean) from public;
grant execute on function public.admin_set_user_active(uuid,boolean) to authenticated;
revoke all on function public.admin_set_room_active(uuid,boolean) from public;
grant execute on function public.admin_set_room_active(uuid,boolean) to authenticated;
revoke all on function public.admin_adjust_wallet(uuid,bigint) from public;
grant execute on function public.admin_adjust_wallet(uuid,bigint) to authenticated;


-- ===== 022_admin_dashboard_runtime.sql =====
-- Admin dashboard runtime permissions and owner wallet bootstrap.
-- Run after 021_admin_dashboard_hardening.sql.

-- Admins can read all profiles and edit admin-controlled profile flags.
drop policy if exists "profiles_admin_select" on public.profiles;
create policy "profiles_admin_select"
on public.profiles for select to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "profiles_admin_update" on public.profiles;
create policy "profiles_admin_update"
on public.profiles for update to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

-- Admins may manage catalog values from the dashboard.
drop policy if exists "frame_items_admin_manage" on public.frame_items;
create policy "frame_items_admin_manage"
on public.frame_items for all to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "coin_packages_admin_manage" on public.coin_packages;
create policy "coin_packages_admin_manage"
on public.coin_packages for all to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "vip_levels_admin_manage" on public.vip_levels;
create policy "vip_levels_admin_manage"
on public.vip_levels for all to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "rocket_levels_admin_manage" on public.rocket_levels;
create policy "rocket_levels_admin_manage"
on public.rocket_levels for all to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

-- Gift editor used by the dashboard.
create or replace function public.admin_update_gift(
  p_id uuid,
  p_name text,
  p_emoji text,
  p_price bigint,
  p_category text,
  p_is_active boolean,
  p_banner_enabled boolean,
  p_banner_min_price bigint,
  p_luck_min_win bigint
)
returns public.gifts
language plpgsql
security definer
set search_path = public
as $$
declare result_gift public.gifts;
begin
  if auth.uid() is null or not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then
    raise exception 'not authorized';
  end if;
  if p_price < 1 or p_banner_min_price < 0 or p_luck_min_win < 0 then
    raise exception 'invalid gift values';
  end if;

  update public.gifts
  set name=p_name,
      emoji=p_emoji,
      price=p_price,
      category=p_category,
      is_active=p_is_active,
      banner_enabled=p_banner_enabled,
      banner_min_price=p_banner_min_price,
      luck_min_win=p_luck_min_win
  where id=p_id
  returning * into result_gift;

  if result_gift.id is null then raise exception 'gift not found'; end if;
  return result_gift;
end;
$$;

revoke all on function public.admin_update_gift(uuid,text,text,bigint,text,boolean,boolean,bigint,bigint) from public;
grant execute on function public.admin_update_gift(uuid,text,text,bigint,text,boolean,boolean,bigint,bigint) to authenticated;

-- Keep the owner's CEO wallet at the requested 10 billion starting balance.
-- Only initializes/raises CEO wallet balances; it never reduces an existing balance.
insert into public.wallets(user_id,balance)
select p.id, 10000000000
from public.profiles p
where p.role = 'CEO'::public.app_role
  and not exists (select 1 from public.wallets w where w.user_id=p.id);

update public.wallets w
set balance = 10000000000, updated_at = now()
from public.profiles p
where p.id=w.user_id
  and p.role = 'CEO'::public.app_role
  and w.balance < 10000000000;

