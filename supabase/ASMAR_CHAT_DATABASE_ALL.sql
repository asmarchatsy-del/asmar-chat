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

