create or replace function public.asmar_transfer_coins(p_to_user_id uuid, p_amount bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  sender_balance bigint;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_to_user_id = uid then raise exception 'SELF_TRANSFER'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;
  select coins into sender_balance from public.profiles where id=uid for update;
  if sender_balance is null then raise exception 'SENDER_NOT_FOUND'; end if;
  if sender_balance < p_amount then raise exception 'INSUFFICIENT_COINS'; end if;
  if not exists(select 1 from public.profiles where id=p_to_user_id and is_active=true) then raise exception 'RECIPIENT_NOT_FOUND'; end if;
  update public.profiles set coins=coins-p_amount, updated_at=now() where id=uid;
  update public.profiles set coins=coins+p_amount, updated_at=now() where id=p_to_user_id;
  insert into public.wallet_transactions(user_id,currency,amount,type,description,reference_id)
  values(uid,'coins',-p_amount,'transfer_sent','تحويل Coins',p_to_user_id::text);
  insert into public.wallet_transactions(user_id,currency,amount,type,description,reference_id)
  values(p_to_user_id,'coins',p_amount,'transfer_received','استلام Coins',uid::text);
end;
$$;

revoke all on function public.asmar_transfer_coins(uuid,bigint) from public;
grant execute on function public.asmar_transfer_coins(uuid,bigint) to authenticated;
