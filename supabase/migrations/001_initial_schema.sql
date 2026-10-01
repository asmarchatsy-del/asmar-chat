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
