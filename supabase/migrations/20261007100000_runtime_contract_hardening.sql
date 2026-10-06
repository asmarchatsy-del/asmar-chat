-- Production compatibility and integrity hardening for the current Flutter runtime.
-- Keeps legacy RPCs intact while exposing the exact contracts used by the app.

alter table public.room_seats add column if not exists is_locked boolean not null default false;

create or replace function public.asmar_join_room(p_room_id uuid)
returns void
language plpgsql security definer set search_path=public
as $$
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists (select 1 from public.rooms where id=p_room_id and is_active=true) then
    raise exception 'ROOM_NOT_FOUND';
  end if;
  insert into public.room_members(room_id,user_id,left_at)
  values(p_room_id,auth.uid(),null)
  on conflict (room_id,user_id) do update set joined_at=now(),left_at=null;
end;
$$;

create or replace function public.asmar_leave_room(p_room_id uuid)
returns void
language plpgsql security definer set search_path=public
as $$
begin
  if auth.uid() is null then return; end if;
  delete from public.room_seats where room_id=p_room_id and user_id=auth.uid();
  update public.room_members set left_at=now()
  where room_id=p_room_id and user_id=auth.uid() and left_at is null;
end;
$$;

create or replace function public.create_room_full(
  p_name text,
  p_seat_count integer default 8,
  p_room_type text default 'party',
  p_tags text[] default '{}',
  p_country_code text default 'JO',
  p_cover_url text default null
)
returns public.rooms
language plpgsql security definer set search_path=public
as $$
declare r public.rooms;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  insert into public.rooms(name,owner_id,is_active,seat_count,country_code,cover_url,livekit_room_name)
  values(
    trim(p_name), auth.uid(), true,
    case when p_seat_count in (6,8,10,12,15,20) then p_seat_count else 8 end,
    upper(coalesce(nullif(trim(p_country_code),''),'JO')),
    nullif(trim(coalesce(p_cover_url,'')),''),
    'asmar-'||gen_random_uuid()::text
  ) returning * into r;
  insert into public.room_members(room_id,user_id) values(r.id,auth.uid())
  on conflict (room_id,user_id) do nothing;
  return r;
end;
$$;

create or replace function public.join_room_seat(p_room_id uuid,p_seat_index smallint)
returns public.room_seats
language plpgsql security definer set search_path=public
as $$
declare r public.room_seats;
begin
  if not exists(select 1 from public.room_members where room_id=p_room_id and user_id=auth.uid() and left_at is null)
    then raise exception 'NOT_ROOM_MEMBER'; end if;
  if exists(select 1 from public.room_seats where room_id=p_room_id and seat_index=p_seat_index and is_locked)
    then raise exception 'SEAT_LOCKED'; end if;
  r := public.claim_room_seat(p_room_id,p_seat_index);
  return r;
end;
$$;

create or replace function public.leave_room_seat(p_room_id uuid,p_seat_index smallint)
returns void
language plpgsql security definer set search_path=public
as $$
begin
  delete from public.room_seats
  where room_id=p_room_id and seat_index=p_seat_index and user_id=auth.uid();
end;
$$;

create or replace function public.set_room_mute(p_room_id uuid,p_muted boolean)
returns void
language plpgsql security definer set search_path=public
as $$
begin
  update public.room_seats set is_muted=p_muted,updated_at=now()
  where room_id=p_room_id and user_id=auth.uid();
end;
$$;

create or replace function public.set_room_seat_locked(p_room_id uuid,p_seat_index smallint,p_locked boolean)
returns void
language plpgsql security definer set search_path=public
as $$
begin
  if not exists(
    select 1 from public.rooms
    where id=p_room_id and owner_id=auth.uid()
  ) and not public.has_role(array['CEO','SUPER_ADMIN','MANAGER','ADMIN']::public.app_role[])
  then raise exception 'FORBIDDEN'; end if;
  update public.room_seats
  set is_locked=p_locked,updated_at=now()
  where room_id=p_room_id and seat_index=p_seat_index;
  if not found then
    insert into public.room_seats(room_id,seat_index,is_locked)
    values(p_room_id,p_seat_index,p_locked);
  end if;
end;
$$;

create or replace function public.remove_room_seat(p_room_id uuid,p_seat_index smallint)
returns void
language plpgsql security definer set search_path=public
as $$
begin
  if not exists(
    select 1 from public.rooms where id=p_room_id and owner_id=auth.uid()
  ) and not public.has_role(array['CEO','SUPER_ADMIN','MANAGER','ADMIN']::public.app_role[])
  then raise exception 'FORBIDDEN'; end if;
  delete from public.room_seats where room_id=p_room_id and seat_index=p_seat_index;
end;
$$;

create or replace function public.send_room_message(p_room_id uuid,p_message text)
returns public.room_messages
language plpgsql security definer set search_path=public
as $$
declare r public.room_messages;
begin
  if not exists(select 1 from public.room_members where room_id=p_room_id and user_id=auth.uid() and left_at is null)
    then raise exception 'NOT_ROOM_MEMBER'; end if;
  insert into public.room_messages(room_id,user_id,body)
  values(p_room_id,auth.uid(),trim(p_message))
  returning * into r;
  return r;
end;
$$;

create or replace function public.asmar_create_withdrawal_request(
  p_method_id uuid,p_amount bigint,p_details jsonb
)
returns public.withdrawal_requests
language plpgsql security definer set search_path=public
as $$
declare m public.withdrawal_methods; w bigint; f numeric; r public.withdrawal_requests;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  select * into m from public.withdrawal_methods where id=p_method_id and is_active=true for share;
  if m.id is null then raise exception 'METHOD_NOT_FOUND'; end if;
  if p_amount < m.min_amount or (m.max_amount > 0 and p_amount > m.max_amount) then raise exception 'INVALID_AMOUNT'; end if;
  f := coalesce(m.fee,0);
  select balance into w from public.wallets where user_id=auth.uid() for update;
  if coalesce(w,0) < p_amount + ceil(f)::bigint then raise exception 'INSUFFICIENT_COINS'; end if;
  update public.wallets set balance=balance-p_amount-ceil(f)::bigint,updated_at=now() where user_id=auth.uid();
  insert into public.coin_transactions(from_user_id,to_user_id,amount,reason)
  values(auth.uid(),null,p_amount,'withdrawal_pending');
  insert into public.withdrawal_requests(user_id,method_id,amount,fee,details,status)
  values(auth.uid(),p_method_id,p_amount,f,coalesce(p_details,'{}'::jsonb),'pending')
  returning * into r;
  return r;
end;
$$;

revoke all on function public.asmar_join_room(uuid) from public;
revoke all on function public.asmar_leave_room(uuid) from public;
revoke all on function public.create_room_full(text,integer,text,text[],text,text) from public;
revoke all on function public.join_room_seat(uuid,smallint) from public;
revoke all on function public.leave_room_seat(uuid,smallint) from public;
revoke all on function public.set_room_mute(uuid,boolean) from public;
revoke all on function public.set_room_seat_locked(uuid,smallint,boolean) from public;
revoke all on function public.remove_room_seat(uuid,smallint) from public;
revoke all on function public.send_room_message(uuid,text) from public;
revoke all on function public.asmar_create_withdrawal_request(uuid,bigint,jsonb) from public;

grant execute on function public.asmar_join_room(uuid) to authenticated;
grant execute on function public.asmar_leave_room(uuid) to authenticated;
grant execute on function public.create_room_full(text,integer,text,text[],text,text) to authenticated;
grant execute on function public.join_room_seat(uuid,smallint) to authenticated;
grant execute on function public.leave_room_seat(uuid,smallint) to authenticated;
grant execute on function public.set_room_mute(uuid,boolean) to authenticated;
grant execute on function public.set_room_seat_locked(uuid,smallint,boolean) to authenticated;
grant execute on function public.remove_room_seat(uuid,smallint) to authenticated;
grant execute on function public.send_room_message(uuid,text) to authenticated;
grant execute on function public.asmar_create_withdrawal_request(uuid,bigint,jsonb) to authenticated;
