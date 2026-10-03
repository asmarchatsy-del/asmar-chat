-- Dynamic voice-room seat system: 4..30 seats.
create table if not exists public.room_seats (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  seat_index integer not null check (seat_index between 1 and 30),
  is_locked boolean not null default false,
  occupant_id uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  unique(room_id, seat_index)
);

alter table public.rooms add column if not exists seat_count integer not null default 10;
alter table public.rooms drop constraint if exists rooms_seat_count_check;
alter table public.rooms add constraint rooms_seat_count_check check (seat_count between 4 and 30);

create or replace function public.ensure_room_seats(p_room_id uuid, p_seat_count integer)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_seat_count < 4 or p_seat_count > 30 then raise exception 'seat_count must be between 4 and 30'; end if;
  update public.rooms set seat_count = p_seat_count where id = p_room_id;
  insert into public.room_seats(room_id, seat_index)
    select p_room_id, g from generate_series(1, p_seat_count) g
    on conflict (room_id, seat_index) do nothing;
  delete from public.room_seats where room_id = p_room_id and seat_index > p_seat_count;
end $$;

create or replace function public.can_manage_room(p_room_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.rooms r
    left join public.profiles p on p.id = auth.uid()
    where r.id = p_room_id
      and (
        r.owner_id = auth.uid()
        or lower(coalesce(p.role, '')) in ('ceo','super_admin','superadmin','admin')
      )
  );
$$;

grant execute on function public.ensure_room_seats(uuid, integer) to authenticated;
grant execute on function public.can_manage_room(uuid) to authenticated;

alter table public.room_seats enable row level security;
drop policy if exists room_seats_read on public.room_seats;
create policy room_seats_read on public.room_seats for select to authenticated using (true);
drop policy if exists room_seats_manage on public.room_seats;
create policy room_seats_manage on public.room_seats for all to authenticated using (public.can_manage_room(room_id)) with check (public.can_manage_room(room_id));

-- Seed existing rooms with their configured/default seat count.
do $$
declare r record;
begin
  for r in select id, seat_count from public.rooms loop
    perform public.ensure_room_seats(r.id, greatest(4, least(30, coalesce(r.seat_count,10))));
  end loop;
end $$;
