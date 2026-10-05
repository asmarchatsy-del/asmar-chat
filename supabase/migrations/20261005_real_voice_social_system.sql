-- Asmar Chat: real-time room, seats, chat, gifts and SVIP foundation.
-- This migration is additive. It does not drop or rename existing tables.

create table if not exists public.room_seats (
  room_id uuid not null references public.rooms(id) on delete cascade,
  seat_index smallint not null check (seat_index between 0 and 29),
  user_id uuid references public.profiles(id) on delete set null,
  is_muted boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (room_id, seat_index),
  unique (room_id, user_id)
);

create table if not exists public.room_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index if not exists room_messages_room_created_idx
  on public.room_messages(room_id, created_at desc);

create table if not exists public.gift_catalog (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  price bigint not null check (price > 0),
  animation_url text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.gift_transactions (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  receiver_id uuid not null references public.profiles(id),
  gift_id uuid not null references public.gift_catalog(id),
  quantity integer not null default 1 check (quantity > 0 and quantity <= 100),
  total_cost bigint not null check (total_cost > 0),
  created_at timestamptz not null default now()
);

create index if not exists gift_transactions_room_created_idx
  on public.gift_transactions(room_id, created_at desc);

create table if not exists public.svip_memberships (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  level smallint not null default 0 check (level between 0 and 10),
  points bigint not null default 0 check (points >= 0),
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.room_seats enable row level security;
alter table public.room_messages enable row level security;
alter table public.gift_catalog enable row level security;
alter table public.gift_transactions enable row level security;
alter table public.svip_memberships enable row level security;

create policy "room_seats_select_authenticated"
on public.room_seats for select to authenticated using (true);

create policy "room_messages_select_authenticated"
on public.room_messages for select to authenticated using (true);

create policy "gift_catalog_select_authenticated"
on public.gift_catalog for select to authenticated using (active = true);

create policy "gift_transactions_select_involved"
on public.gift_transactions for select to authenticated
using (sender_id = auth.uid() or receiver_id = auth.uid());

create policy "svip_select_self"
on public.svip_memberships for select to authenticated using (user_id = auth.uid());

create or replace function public.claim_room_seat(
  p_room_id uuid,
  p_seat_index smallint
)
returns public.room_seats
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.room_seats;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if p_seat_index < 0 or p_seat_index > 29 then raise exception 'invalid seat'; end if;
  if not exists (select 1 from public.rooms where id = p_room_id and is_active = true) then
    raise exception 'room not found';
  end if;

  delete from public.room_seats where room_id = p_room_id and user_id = auth.uid();

  insert into public.room_seats(room_id, seat_index, user_id)
  values (p_room_id, p_seat_index, auth.uid())
  on conflict (room_id, seat_index) do update
    set user_id = excluded.user_id,
        is_muted = false,
        updated_at = now()
  where public.room_seats.user_id is null
  returning * into result;

  if result.room_id is null then raise exception 'seat is no longer available'; end if;
  return result;
end;
$$;

create or replace function public.leave_room_seat(p_room_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.room_seats
  where room_id = p_room_id and user_id = auth.uid();
$$;

create or replace function public.set_room_seat_mute(p_room_id uuid, p_muted boolean)
returns void
language sql
security definer
set search_path = public
as $$
  update public.room_seats
  set is_muted = p_muted, updated_at = now()
  where room_id = p_room_id and user_id = auth.uid();
$$;

create or replace function public.send_room_message(
  p_room_id uuid,
  p_body text
)
returns public.room_messages
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.room_messages;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if char_length(trim(p_body)) < 1 or char_length(trim(p_body)) > 1000 then
    raise exception 'invalid message';
  end if;
  if not exists (select 1 from public.rooms where id = p_room_id and is_active = true) then
    raise exception 'room not found';
  end if;

  insert into public.room_messages(room_id, user_id, body)
  values (p_room_id, auth.uid(), trim(p_body))
  returning * into result;

  return result;
end;
$$;

create or replace function public.send_gift(
  p_room_id uuid,
  p_receiver_id uuid,
  p_gift_id uuid,
  p_quantity integer default 1
)
returns public.gift_transactions
language plpgsql
security definer
set search_path = public
as $$
declare
  gift public.gift_catalog;
  sender_balance bigint;
  total bigint;
  result_tx public.gift_transactions;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if p_quantity < 1 or p_quantity > 100 then raise exception 'invalid quantity'; end if;
  if p_receiver_id = auth.uid() then raise exception 'cannot gift yourself'; end if;
  if not exists (select 1 from public.rooms where id = p_room_id and is_active = true) then
    raise exception 'room not found';
  end if;
  if not exists (select 1 from public.profiles where id = p_receiver_id and is_active = true) then
    raise exception 'receiver not found';
  end if;

  select * into gift from public.gift_catalog where id = p_gift_id and active = true;
  if gift.id is null then raise exception 'gift not found'; end if;
  total := gift.price * p_quantity;

  select balance into sender_balance
  from public.wallets
  where user_id = auth.uid()
  for update;

  if coalesce(sender_balance, 0) < total then raise exception 'insufficient coins'; end if;

  update public.wallets set balance = balance - total, updated_at = now()
  where user_id = auth.uid();

  insert into public.wallets(user_id, balance)
  values (p_receiver_id, total)
  on conflict (user_id) do update
    set balance = public.wallets.balance + excluded.balance,
        updated_at = now();

  insert into public.coin_transactions(from_user_id, to_user_id, amount, reason)
  values (auth.uid(), p_receiver_id, total, 'gift');

  insert into public.gift_transactions(room_id, sender_id, receiver_id, gift_id, quantity, total_cost)
  values (p_room_id, auth.uid(), p_receiver_id, p_gift_id, p_quantity, total)
  returning * into result_tx;

  return result_tx;
end;
$$;

grant execute on function public.claim_room_seat(uuid, smallint) to authenticated;
grant execute on function public.leave_room_seat(uuid) to authenticated;
grant execute on function public.set_room_seat_mute(uuid, boolean) to authenticated;
grant execute on function public.send_room_message(uuid, text) to authenticated;
grant execute on function public.send_gift(uuid, uuid, uuid, integer) to authenticated;

insert into public.gift_catalog(code, name, price)
values
  ('rose', 'Rose', 10),
  ('heart', 'Heart', 20),
  ('crown', 'Crown', 50),
  ('car', 'Car', 100),
  ('lion', 'Lion', 200),
  ('rocket', 'Rocket', 500),
  ('palace', 'Palace', 1000),
  ('ship', 'Ship', 2000),
  ('microphone', 'Microphone', 5000)
on conflict (code) do nothing;

do $$
begin
  begin alter publication supabase_realtime add table public.room_seats; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.room_messages; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.gift_transactions; exception when duplicate_object then null; end;
end $$;
