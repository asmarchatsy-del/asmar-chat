create or replace function public.admin_adjust_wallet(p_user_id uuid, p_amount bigint)
returns bigint
language plpgsql
security definer
set search_path to 'public'
as $function$
declare b bigint;
begin
  if not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then raise exception 'not authorized'; end if;
  if p_amount = 0 then raise exception 'amount must not be zero'; end if;
  insert into public.wallets(user_id,balance) values(p_user_id,0) on conflict(user_id) do nothing;
  update public.wallets set balance=balance+p_amount,updated_at=now()
   where user_id=p_user_id and balance+p_amount>=0 returning balance into b;
  if b is null then raise exception 'insufficient coins or wallet not found'; end if;
  insert into public.wallet_transactions(user_id,currency,amount,balance_after,type,reference_id,description)
  values(p_user_id,'coins',p_amount,b,'admin_adjustment',auth.uid()::text,case when p_amount>0 then 'Admin coin grant' else 'Admin coin deduction' end);
  if p_amount > 0 then
    insert into public.coin_transactions(from_user_id,to_user_id,amount,transaction_type,reason)
    values(auth.uid(),p_user_id,p_amount,'admin_adjustment','admin_adjustment');
  else
    insert into public.coin_transactions(from_user_id,to_user_id,amount,transaction_type,reason)
    values(p_user_id,auth.uid(),abs(p_amount),'admin_adjustment','admin_adjustment');
  end if;
  return b;
end
$function$;

create or replace function public.admin_grant_coins(p_user_id uuid, p_amount bigint, p_reason text default 'super_admin')
returns void
language plpgsql
set search_path to 'public'
as $function$
declare b bigint;
begin
  if not public.is_super_admin() then raise exception 'not authorized'; end if;
  if p_amount <= 0 then raise exception 'amount must be positive'; end if;
  insert into public.wallets(user_id,balance) values(p_user_id,0) on conflict do nothing;
  update public.wallets set balance=balance+p_amount,updated_at=now() where user_id=p_user_id returning balance into b;
  if b is null then raise exception 'wallet not found'; end if;
  insert into public.wallet_transactions(user_id,currency,amount,balance_after,type,reference_id,description)
  values(p_user_id,'coins',p_amount,b,'admin_grant',auth.uid()::text,coalesce(nullif(trim(p_reason),''),'super_admin'));
  insert into public.coin_transactions(from_user_id,to_user_id,amount,transaction_type,reason)
  values(auth.uid(),p_user_id,p_amount,'admin_grant',coalesce(nullif(trim(p_reason),''),'super_admin'));
  insert into public.admin_audit_logs(admin_id,action,target_id,details)
  values(auth.uid(),'grant_coins',p_user_id,jsonb_build_object('amount',p_amount,'reason',p_reason));
end
$function$;

create or replace function public.admin_approve_recharge(p_request_id uuid, p_approve boolean, p_note text default null)
returns text
language plpgsql
security definer
set search_path to 'public'
as $function$
declare r public.recharge_requests; nb bigint; lvl integer; svip_points bigint;
begin
  if not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then raise exception 'not authorized'; end if;
  select * into r from public.recharge_requests where id=p_request_id for update;
  if r.id is null then raise exception 'recharge request not found'; end if;
  if r.status <> 'pending' then raise exception 'request already processed'; end if;
  if p_approve then
    insert into public.wallets(user_id,balance) values(r.user_id,0) on conflict do nothing;
    update public.wallets set balance=balance+r.coins,updated_at=now() where user_id=r.user_id returning balance into nb;
    if nb is null then raise exception 'wallet not found'; end if;
    svip_points := greatest(r.coins,0)/100;
    lvl := public.record_svip_recharge(r.user_id,r.coins);
    update public.recharge_requests set status='approved',admin_note=p_note,updated_at=now() where id=r.id;
    insert into public.wallet_transactions(user_id,currency,amount,balance_after,type,reference_id,description)
    values(r.user_id,'coins',r.coins,nb,'recharge',r.id::text,'Recharge approved');
    insert into public.coin_transactions(from_user_id,to_user_id,amount,transaction_type,reason)
    values(null,r.user_id,r.coins,'recharge','recharge_approved');
    insert into public.audit_logs(actor_id,action,target_user_id,target_id,amount,metadata)
    values(auth.uid(),'recharge_approved',r.user_id,r.id::text,r.coins,jsonb_build_object('points',svip_points,'svip_level',lvl));
    return 'approved';
  else
    update public.recharge_requests set status='rejected',admin_note=p_note,updated_at=now() where id=r.id;
    insert into public.audit_logs(actor_id,action,target_user_id,target_id,metadata)
    values(auth.uid(),'recharge_rejected',r.user_id,r.id::text,jsonb_build_object('note',p_note));
    return 'rejected';
  end if;
end
$function$;

create or replace function public.admin_set_withdrawal_status(p_request_id uuid, p_status text, p_note text default null)
returns text
language plpgsql
security definer
set search_path to 'public'
as $function$
declare r public.withdrawal_requests; nb bigint;
begin
  if not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then raise exception 'not authorized'; end if;
  if p_status not in ('approved','paid','rejected') then raise exception 'invalid status'; end if;
  select * into r from public.withdrawal_requests where id=p_request_id for update;
  if r.id is null then raise exception 'withdrawal request not found'; end if;
  if p_status='approved' and r.status='pending' then
    insert into public.wallets(user_id,balance) values(r.user_id,0) on conflict do nothing;
    update public.wallets set balance=balance-r.amount,updated_at=now()
      where user_id=r.user_id and balance>=r.amount returning balance into nb;
    if nb is null then raise exception 'insufficient coins'; end if;
    insert into public.wallet_transactions(user_id,currency,amount,balance_after,type,reference_id,description)
    values(r.user_id,'coins',-r.amount,nb,'withdrawal',r.id::text,'Withdrawal approved');
    insert into public.coin_transactions(from_user_id,to_user_id,amount,transaction_type,reason)
    values(r.user_id,null,r.amount,'withdrawal','withdrawal_approved');
  end if;
  update public.withdrawal_requests set status=p_status,admin_note=p_note,updated_at=now() where id=r.id;
  insert into public.audit_logs(actor_id,action,target_user_id,target_id,amount,metadata)
  values(auth.uid(),'withdrawal_'||p_status,r.user_id,r.id::text,r.amount,jsonb_build_object('fee',r.fee,'note',p_note));
  return p_status;
end
$function$;

create or replace function public.asmar_transfer_coins(p_to_user_id uuid, p_amount bigint)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare uid uuid:=auth.uid(); sender_balance bigint; receiver_balance bigint;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_to_user_id=uid then raise exception 'SELF_TRANSFER'; end if;
  if p_amount is null or p_amount<=0 then raise exception 'INVALID_AMOUNT'; end if;
  insert into public.wallets(user_id,balance) values(uid,0) on conflict do nothing;
  insert into public.wallets(user_id,balance) values(p_to_user_id,0) on conflict do nothing;
  select balance into sender_balance from public.wallets where user_id=uid for update;
  if sender_balance < p_amount then raise exception 'INSUFFICIENT_COINS'; end if;
  update public.wallets set balance=balance-p_amount,updated_at=now() where user_id=uid returning balance into sender_balance;
  update public.wallets set balance=balance+p_amount,updated_at=now() where user_id=p_to_user_id returning balance into receiver_balance;
  insert into public.wallet_transactions(user_id,currency,amount,balance_after,type,reference_id,description)
  values(uid,'coins',-p_amount,sender_balance,'transfer_sent',p_to_user_id::text,'تحويل Coins');
  insert into public.wallet_transactions(user_id,currency,amount,balance_after,type,reference_id,description)
  values(p_to_user_id,'coins',p_amount,receiver_balance,'transfer_received',uid::text,'استلام Coins');
  insert into public.coin_transactions(from_user_id,to_user_id,amount,transaction_type,reason)
  values(uid,p_to_user_id,p_amount,'transfer','coin_transfer');
end
$function$;

create or replace function public.asmar_send_gift(p_room_id uuid, p_to_user_id uuid, p_gift_id text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare sender uuid:=auth.uid(); price bigint; diamonds bigint; gift_name text; room_name text; host uuid; sender_balance bigint;
begin
  if sender is null then raise exception 'unauthorized'; end if;
  if not exists(select 1 from public.rooms where id=p_room_id and is_active=true) then raise exception 'room not found'; end if;
  select price,name into price,gift_name from public.gifts where id=p_gift_id and is_active=true for update;
  if price is null then raise exception 'gift not found'; end if;
  insert into public.wallets(user_id,balance) values(sender,0) on conflict do nothing;
  select balance into sender_balance from public.wallets where user_id=sender for update;
  if sender_balance < price then raise exception 'insufficient coins'; end if;
  update public.wallets set balance=balance-price,updated_at=now() where user_id=sender returning balance into sender_balance;
  diamonds=floor(price*0.70);
  update public.profiles set diamonds=coalesce(diamonds,0)+diamonds,support_points=coalesce(support_points,0)+price where id=p_to_user_id;
  if not found then raise exception 'recipient not found'; end if;
  insert into public.gift_transactions(room_id,sender_id,recipient_id,gift_id,amount) values(p_room_id,sender,p_to_user_id,p_gift_id,price);
  insert into public.wallet_transactions(user_id,currency,amount,balance_after,type,reference_id,description)
  values(sender,'coins',-price,sender_balance,'gift',p_gift_id,'Gift sent');
  insert into public.coin_transactions(from_user_id,to_user_id,amount,transaction_type,reason)
  values(sender,p_to_user_id,price,'gift','gift:'||p_gift_id);
  select name,owner_id into room_name,host from public.rooms where id=p_room_id;
  insert into public.global_gift_events(sender_id,sender_name,receiver_id,receiver_name,gift_name,gift_value,room_id,room_name)
  select sender,coalesce((select username from public.profiles where id=sender),'User'),p_to_user_id,coalesce((select username from public.profiles where id=p_to_user_id),'User'),gift_name,price,p_room_id,coalesce(room_name,'') where p_room_id is not null;
  if host is not null then insert into public.host_earnings(host_id,source_amount,host_amount) values(host,price,diamonds); end if;
  return jsonb_build_object('price',price,'diamonds',diamonds,'gift',gift_name);
end
$function$;

create or replace function public.send_gift_real(p_room_id uuid, p_recipient_id uuid, p_gift_id text, p_quantity integer default 1)
returns public.gift_transactions
language plpgsql
security definer
set search_path to 'public'
as $function$
declare g public.gifts; sender_balance bigint; t public.gift_transactions; total bigint; return_amount bigint; room_host uuid; room_name text; sender_name text; recipient_name text;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 if p_quantity<1 or p_quantity>177 then raise exception 'invalid quantity'; end if;
 if not exists(select 1 from public.rooms where id=p_room_id and is_active=true) then raise exception 'room not found'; end if;
 if not exists(select 1 from public.room_members where room_id=p_room_id and user_id=auth.uid() and left_at is null) then raise exception 'sender is not in room'; end if;
 if not exists(select 1 from public.room_members where room_id=p_room_id and user_id=p_recipient_id and left_at is null) then raise exception 'recipient is not in room'; end if;
 select * into g from public.gifts where id=p_gift_id and is_active=true for update;
 if g.id is null then raise exception 'gift not found'; end if;
 total:=g.price*p_quantity; return_amount:=floor(total*0.70);
 insert into public.wallets(user_id,balance) values(auth.uid(),0) on conflict do nothing;
 select balance into sender_balance from public.wallets where user_id=auth.uid() for update;
 if coalesce(sender_balance,0)<total then raise exception 'insufficient coins'; end if;
 update public.wallets set balance=balance-total,updated_at=now() where user_id=auth.uid() returning balance into sender_balance;
 update public.profiles set diamonds=coalesce(diamonds,0)+return_amount,support_points=coalesce(support_points,0)+total,updated_at=now() where id=p_recipient_id;
 if not found then raise exception 'recipient not found'; end if;
 insert into public.wallet_transactions(user_id,currency,amount,balance_after,type,reference_id,description)
 values(auth.uid(),'coins',-total,sender_balance,'gift',g.id||':x'||p_quantity,'Gift sent');
 insert into public.coin_transactions(from_user_id,to_user_id,amount,reason)
 values(auth.uid(),p_recipient_id,total,'gift:'||g.id||':x'||p_quantity);
 insert into public.gift_transactions(room_id,sender_id,recipient_id,gift_id,amount) values(p_room_id,auth.uid(),p_recipient_id,g.id,total) returning * into t;
 select name,owner_id into room_name,room_host from public.rooms where id=p_room_id;
 if room_host is not null then
   insert into public.host_earnings(host_id,agency_id,source_amount,host_amount)
   select room_host,p.agency_id,total,return_amount from public.profiles p where p.id=room_host;
 end if;
 select coalesce(username,'User') into sender_name from public.profiles where id=auth.uid();
 select coalesce(username,'User') into recipient_name from public.profiles where id=p_recipient_id;
 insert into public.global_gift_events(sender_id,sender_name,receiver_id,receiver_name,gift_name,gift_value,room_id,room_name)
 values(auth.uid(),sender_name,p_recipient_id,recipient_name,g.name,total,p_room_id,room_name);
 return t;
end
$function$;

create or replace function public.asmar_purchase_vip(p_vip_level_id text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare v_uid uuid:=auth.uid(); v_level public.vip_levels%rowtype; v_balance bigint; v_exp timestamptz;
begin
 if v_uid is null then raise exception 'not_authenticated'; end if;
 select * into v_level from public.vip_levels where id=p_vip_level_id and is_active=true;
 if not found then raise exception 'vip_level_not_found'; end if;
 insert into public.wallets(user_id,balance) values(v_uid,0) on conflict do nothing;
 select balance into v_balance from public.wallets where user_id=v_uid for update;
 if v_balance < v_level.price_coins then raise exception 'insufficient_coins'; end if;
 update public.wallets set balance=balance-v_level.price_coins,updated_at=now() where user_id=v_uid returning balance into v_balance;
 v_exp=now()+make_interval(days=>v_level.duration_days);
 update public.user_vip set is_active=false,updated_at=now() where user_id=v_uid;
 insert into public.user_vip(user_id,vip_level_id,starts_at,expires_at,is_active,updated_at) values(v_uid,v_level.id,now(),v_exp,true,now());
 insert into public.wallet_transactions(user_id,currency,amount,balance_after,type,reference_id,description)
 values(v_uid,'coins',-v_level.price_coins,v_balance,'vip_purchase',v_level.id,'VIP purchase');
 return jsonb_build_object('ok',true,'vip_level_id',v_level.id,'expires_at',v_exp);
end
$function$;

create or replace function public.purchase_aristocracy(p_level integer)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare v_uid uuid:=auth.uid(); v_level public.aristocracy_levels%rowtype; v_balance bigint; v_expires timestamptz;
begin
 if v_uid is null then raise exception 'not_authenticated'; end if;
 select * into v_level from public.aristocracy_levels where id=p_level and is_active for update;
 if not found then raise exception 'aristocracy_level_not_found'; end if;
 insert into public.wallets(user_id,balance) values(v_uid,0) on conflict do nothing;
 select balance into v_balance from public.wallets where user_id=v_uid for update;
 if v_balance < v_level.price then raise exception 'insufficient_gold'; end if;
 v_balance:=v_balance-v_level.price;
 update public.wallets set balance=v_balance,updated_at=now() where user_id=v_uid;
 v_expires:=now()+make_interval(days=>v_level.duration_days);
 update public.profiles set aristocracy_level=p_level,aristocracy_expires_at=v_expires,vip_level=p_level::text,golden_frame=true,updated_at=now() where id=v_uid;
 insert into public.user_aristocracy(user_id,level,expires_at,is_active,updated_at) values(v_uid,p_level,v_expires,true,now()) on conflict(user_id) do update set level=excluded.level,expires_at=excluded.expires_at,is_active=true,updated_at=now();
 insert into public.wallet_transactions(user_id,currency,amount,balance_after,type,reference_id,description) values(v_uid,'coins',-v_level.price,v_balance,'aristocracy_purchase',p_level::text,'Aristocracy '||v_level.name_en||' for '||v_level.duration_days||' days');
 return jsonb_build_object('level',p_level,'expiresAt',v_expires,'balance',v_balance);
end
$function$;

create or replace function public.purchase_aristocracy_package(p_package_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare uid uuid:=auth.uid(); pkg record; current_balance bigint; new_balance bigint;
begin
 if uid is null then raise exception 'not_authenticated'; end if;
 select * into pkg from public.aristocracy_packages where id=p_package_id and is_active=true for update;
 if not found then raise exception 'package_not_found'; end if;
 insert into public.wallets(user_id,balance) values(uid,0) on conflict do nothing;
 select balance into current_balance from public.wallets where user_id=uid for update;
 if current_balance < pkg.coin_price then raise exception 'insufficient_coins'; end if;
 new_balance:=current_balance-pkg.coin_price;
 update public.wallets set balance=new_balance,updated_at=now() where user_id=uid;
 update public.profiles set vip_level=case when pkg.tier='aristocracy' then pkg.billing_period else vip_level end,svip_level=case when pkg.tier='aristocracy_special' then greatest(svip_level,1) else svip_level end,golden_frame=case when pkg.tier='aristocracy' then true else golden_frame end,special_frame=case when pkg.tier='aristocracy_special' then true else special_frame end,updated_at=now() where id=uid;
 insert into public.wallet_transactions(user_id,currency,amount,balance_after,type,reference_id,description) values(uid,'coins',-pkg.coin_price,new_balance,'aristocracy_purchase',pkg.id::text,pkg.name);
 return jsonb_build_object('ok',true,'balance',new_balance,'tier',pkg.tier,'billing_period',pkg.billing_period);
end
$function$;

create or replace function public.asmar_claim_daily_task(p_task_id text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare t public.daily_tasks%rowtype; u public.user_daily_tasks%rowtype; v_balance bigint;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 select * into t from public.daily_tasks where id=p_task_id and is_active for update;
 if t.id is null then raise exception 'task not found'; end if;
 select * into u from public.user_daily_tasks where user_id=auth.uid() and task_id=p_task_id and task_date=current_date for update;
 if u.progress < t.target then raise exception 'task not completed'; end if;
 if u.claimed_at is not null then raise exception 'already claimed'; end if;
 insert into public.wallets(user_id,balance) values(auth.uid(),0) on conflict do nothing;
 select balance into v_balance from public.wallets where user_id=auth.uid() for update;
 v_balance:=v_balance+coalesce(t.reward_coins,0);
 update public.wallets set balance=v_balance,updated_at=now() where user_id=auth.uid();
 update public.profiles set diamonds=coalesce(diamonds,0)+coalesce(t.reward_diamonds,0) where id=auth.uid();
 update public.user_daily_tasks set claimed_at=now() where user_id=auth.uid() and task_id=p_task_id and task_date=current_date;
 if coalesce(t.reward_coins,0)<>0 then
   insert into public.wallet_transactions(user_id,currency,amount,balance_after,type,reference_id,description)
   values(auth.uid(),'coins',t.reward_coins,v_balance,'daily_task',p_task_id,'Daily task reward');
 end if;
 return jsonb_build_object('coins',t.reward_coins,'diamonds',t.reward_diamonds,'balance',v_balance);
end
$function$;
