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
