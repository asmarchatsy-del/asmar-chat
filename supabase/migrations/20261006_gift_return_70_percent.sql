-- Asmar gift return / host earnings alignment
-- Matches the existing Asmar 70% gift return rule used by asmar_send_gift,
-- while making the active send_gift_real path enforce it atomically.

create or replace function public.send_gift_real(
  p_room_id uuid,
  p_recipient_id uuid,
  p_gift_id text,
  p_quantity integer default 1
)
returns public.gift_transactions
language plpgsql
security definer
set search_path=public
as $$
declare
  g public.gifts;
  sender_coins bigint;
  t public.gift_transactions;
  total bigint;
  return_amount bigint;
  room_host uuid;
  room_name text;
  sender_name text;
  recipient_name text;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if p_quantity < 1 or p_quantity > 177 then raise exception 'invalid quantity'; end if;
  if not exists(select 1 from public.rooms where id=p_room_id and is_active=true) then raise exception 'room not found'; end if;
  if not exists(select 1 from public.room_members where room_id=p_room_id and user_id=auth.uid() and left_at is null) then raise exception 'sender is not in room'; end if;
  if not exists(select 1 from public.room_members where room_id=p_room_id and user_id=p_recipient_id and left_at is null) then raise exception 'recipient is not in room'; end if;

  select * into g from public.gifts where id=p_gift_id and is_active=true for update;
  if g.id is null then raise exception 'gift not found'; end if;

  total := g.price * p_quantity;
  return_amount := floor(total * 0.70);

  select coins into sender_coins from public.profiles where id=auth.uid() for update;
  if coalesce(sender_coins,0) < total then raise exception 'insufficient coins'; end if;

  update public.profiles
     set coins=coins-total,
         recharge_points=coalesce(recharge_points,0)+total,
         updated_at=now()
   where id=auth.uid();

  update public.profiles
     set diamonds=coalesce(diamonds,0)+return_amount,
         support_points=coalesce(support_points,0)+total,
         updated_at=now()
   where id=p_recipient_id;
  if not found then raise exception 'recipient not found'; end if;

  insert into public.coin_transactions(from_user_id,to_user_id,amount,reason)
  values(auth.uid(),p_recipient_id,total,'gift:'||g.id||':x'||p_quantity);

  insert into public.gift_transactions(room_id,sender_id,recipient_id,gift_id,amount)
  values(p_room_id,auth.uid(),p_recipient_id,g.id,total)
  returning * into t;

  select name,owner_id into room_name,room_host from public.rooms where id=p_room_id;
  if room_host is not null then
    insert into public.host_earnings(host_id,agency_id,source_amount,host_amount)
    select room_host,p.agency_id,total,return_amount
    from public.profiles p
    where p.id=room_host;
  end if;

  select coalesce(username,'User') into sender_name from public.profiles where id=auth.uid();
  select coalesce(username,'User') into recipient_name from public.profiles where id=p_recipient_id;

  insert into public.global_gift_events(
    sender_id,sender_name,receiver_id,receiver_name,gift_name,gift_value,room_id,room_name
  )
  values(
    auth.uid(),sender_name,p_recipient_id,recipient_name,g.name,total,p_room_id,coalesce(room_name,'')
  );

  return t;
end;
$$;

revoke all on function public.send_gift_real(uuid,uuid,text,integer) from public;
grant execute on function public.send_gift_real(uuid,uuid,text,integer) to authenticated;
