alter table public.asmar_agency_levels enable row level security;
drop policy if exists "asmar_agency_levels_read" on public.asmar_agency_levels;
create policy "asmar_agency_levels_read"
  on public.asmar_agency_levels
  for select to authenticated
  using (true);

alter table public.asmar_host_levels enable row level security;
drop policy if exists "asmar_host_levels_read" on public.asmar_host_levels;
create policy "asmar_host_levels_read"
  on public.asmar_host_levels
  for select to authenticated
  using (true);

alter function public.admin_close_room(uuid) set search_path = public;
alter function public.admin_grant_coins(uuid,bigint,text) set search_path = public;
alter function public.admin_set_user_blocked(uuid,boolean) set search_path = public;
alter function public.auto_create_withdrawals() set search_path = public;
alter function public.auto_grant_asmar_rewards() set search_path = public;
alter function public.get_eligible_salary(integer,integer,integer,boolean) set search_path = public;
alter function public.get_next_payout_date() set search_path = public;
alter function public.is_super_admin() set search_path = public;

-- Keep social coins as the single canonical user balance.
create or replace function public.admin_grant_coins(
  p_user_id uuid, p_amount bigint, p_reason text default 'super_admin'
) returns void
language plpgsql
set search_path = public
as $$
begin
  if not public.is_super_admin() then raise exception 'not authorized'; end if;
  if p_amount <= 0 then raise exception 'amount must be positive'; end if;
  update public.profiles
     set coins = coalesce(coins,0) + p_amount, updated_at = now()
   where id = p_user_id;
  if not found then raise exception 'profile not found'; end if;
  insert into public.admin_audit_logs(admin_id,action,target_id,details)
  values(auth.uid(),'grant_coins',p_user_id,
         jsonb_build_object('amount',p_amount,'reason',p_reason));
end $$;

create or replace function public.admin_approve_recharge(
  p_request_id uuid, p_approve boolean, p_note text default null
) returns text
language plpgsql security definer set search_path = public
as $$
declare r public.recharge_requests; nb bigint; lvl integer; svip_points bigint;
begin
 if not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then raise exception 'not authorized'; end if;
 select * into r from public.recharge_requests where id=p_request_id for update;
 if r.id is null then raise exception 'recharge request not found'; end if;
 if r.status <> 'pending' then raise exception 'request already processed'; end if;
 if p_approve then
   update public.profiles
      set coins=coalesce(coins,0)+r.coins, updated_at=now()
    where id=r.user_id
    returning coins into nb;
   if nb is null then raise exception 'profile not found'; end if;
   svip_points := greatest(r.coins,0)/100;
   lvl := public.record_svip_recharge(r.user_id,r.coins);
   update public.recharge_requests set status='approved',admin_note=p_note,updated_at=now() where id=r.id;
   insert into public.coin_transactions(from_user_id,to_user_id,amount,transaction_type,reason)
   values(null,r.user_id,r.coins,'recharge','recharge_approved');
   insert into public.audit_logs(actor_id,action,target_user_id,target_id,amount,metadata)
   values(auth.uid(),'recharge_approved',r.user_id,r.id::text,r.coins,
          jsonb_build_object('points',svip_points,'svip_level',lvl));
   return 'approved';
 else
   update public.recharge_requests set status='rejected',admin_note=p_note,updated_at=now() where id=r.id;
   insert into public.audit_logs(actor_id,action,target_user_id,target_id,metadata)
   values(auth.uid(),'recharge_rejected',r.user_id,r.id::text,jsonb_build_object('note',p_note));
   return 'rejected';
 end if;
end $$;

create or replace function public.admin_set_withdrawal_status(
  p_request_id uuid, p_status text, p_note text default null
) returns text
language plpgsql security definer set search_path = public
as $$
declare r public.withdrawal_requests; nb bigint;
begin
 if not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then raise exception 'not authorized'; end if;
 if p_status not in ('approved','paid','rejected') then raise exception 'invalid status'; end if;
 select * into r from public.withdrawal_requests where id=p_request_id for update;
 if r.id is null then raise exception 'withdrawal request not found'; end if;
 if p_status='approved' and r.status='pending' then
   update public.profiles
      set coins=coalesce(coins,0)-r.amount, updated_at=now()
    where id=r.user_id and coalesce(coins,0)>=r.amount
    returning coins into nb;
   if nb is null then raise exception 'insufficient coins'; end if;
 end if;
 update public.withdrawal_requests set status=p_status,admin_note=p_note,updated_at=now() where id=r.id;
 insert into public.audit_logs(actor_id,action,target_user_id,target_id,amount,metadata)
 values(auth.uid(),'withdrawal_'||p_status,r.user_id,r.id::text,r.amount,
        jsonb_build_object('fee',r.fee,'note',p_note));
 return p_status;
end $$;


create or replace function public.admin_adjust_wallet(p_user_id uuid,p_amount bigint)
returns bigint language plpgsql security definer set search_path=public
as $$
declare b bigint;
begin
 if not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then raise exception 'not authorized'; end if;
 update public.profiles set coins=coalesce(coins,0)+p_amount,updated_at=now()
 where id=p_user_id and coalesce(coins,0)+p_amount>=0 returning coins into b;
 if b is null then raise exception 'insufficient coins or profile not found'; end if;
 return b;
end $$;
