-- Admin dashboard hardening: complete privileged reads and actions.
-- Safe to run after the existing migrations.

grant select on public.profiles, public.wallets, public.rooms, public.frame_items,
  public.coin_packages, public.vip_levels, public.gifts, public.rocket_levels,
  public.asmar_policy, public.app_promotions to authenticated;

drop policy if exists "rooms_select_privileged" on public.rooms;
create policy "rooms_select_privileged"
on public.rooms for select to authenticated
using (
  is_active = true
  or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])
);

drop policy if exists "gifts_select_privileged" on public.gifts;
create policy "gifts_select_privileged"
on public.gifts for select to authenticated
using (
  is_active = true
  or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])
);

drop policy if exists "promotions_admin_select_all" on public.app_promotions;
create policy "promotions_admin_select_all"
on public.app_promotions for select to authenticated
using (
  is_active = true
  or public.has_role(array['CEO','SUPER_ADMIN','MANAGER']::public.app_role[])
);

create or replace function public.admin_set_user_active(
  p_user_id uuid,
  p_active boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then
    raise exception 'not authorized';
  end if;
  if p_user_id = auth.uid() and not p_active then
    raise exception 'cannot deactivate current admin';
  end if;
  update public.profiles
    set is_active = p_active, updated_at = now()
  where id = p_user_id;
  if not found then raise exception 'user not found'; end if;
  return p_active;
end;
$$;

create or replace function public.admin_set_room_active(
  p_room_id uuid,
  p_active boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then
    raise exception 'not authorized';
  end if;
  update public.rooms set is_active = p_active where id = p_room_id;
  if not found then raise exception 'room not found'; end if;
  return p_active;
end;
$$;

create or replace function public.admin_adjust_wallet(
  p_user_id uuid,
  p_amount bigint
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare new_balance bigint;
begin
  if auth.uid() is null or not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then
    raise exception 'not authorized';
  end if;
  if p_amount = 0 then raise exception 'amount cannot be zero'; end if;

  insert into public.wallets(user_id,balance)
  values (p_user_id,0)
  on conflict(user_id) do nothing;

  update public.wallets
    set balance = balance + p_amount, updated_at = now()
  where user_id = p_user_id
    and balance + p_amount >= 0
  returning balance into new_balance;

  if new_balance is null then raise exception 'insufficient balance'; end if;

  insert into public.coin_transactions(from_user_id,to_user_id,amount,reason)
  values (
    case when p_amount < 0 then auth.uid() else null end,
    case when p_amount > 0 then p_user_id else null end,
    abs(p_amount),
    'admin_adjustment'
  );
  return new_balance;
end;
$$;

revoke all on function public.admin_set_user_active(uuid,boolean) from public;
grant execute on function public.admin_set_user_active(uuid,boolean) to authenticated;
revoke all on function public.admin_set_room_active(uuid,boolean) from public;
grant execute on function public.admin_set_room_active(uuid,boolean) to authenticated;
revoke all on function public.admin_adjust_wallet(uuid,bigint) from public;
grant execute on function public.admin_adjust_wallet(uuid,bigint) to authenticated;
