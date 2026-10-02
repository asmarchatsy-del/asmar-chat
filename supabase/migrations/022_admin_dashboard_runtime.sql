-- Admin dashboard runtime permissions and owner wallet bootstrap.
-- Run after 021_admin_dashboard_hardening.sql.

-- Admins can read all profiles and edit admin-controlled profile flags.
drop policy if exists "profiles_admin_select" on public.profiles;
create policy "profiles_admin_select"
on public.profiles for select to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "profiles_admin_update" on public.profiles;
create policy "profiles_admin_update"
on public.profiles for update to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

-- Admins may manage catalog values from the dashboard.
drop policy if exists "frame_items_admin_manage" on public.frame_items;
create policy "frame_items_admin_manage"
on public.frame_items for all to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "coin_packages_admin_manage" on public.coin_packages;
create policy "coin_packages_admin_manage"
on public.coin_packages for all to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "vip_levels_admin_manage" on public.vip_levels;
create policy "vip_levels_admin_manage"
on public.vip_levels for all to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "rocket_levels_admin_manage" on public.rocket_levels;
create policy "rocket_levels_admin_manage"
on public.rocket_levels for all to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

-- Gift editor used by the dashboard.
create or replace function public.admin_update_gift(
  p_id uuid,
  p_name text,
  p_emoji text,
  p_price bigint,
  p_category text,
  p_is_active boolean,
  p_banner_enabled boolean,
  p_banner_min_price bigint,
  p_luck_min_win bigint
)
returns public.gifts
language plpgsql
security definer
set search_path = public
as $$
declare result_gift public.gifts;
begin
  if auth.uid() is null or not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then
    raise exception 'not authorized';
  end if;
  if p_price < 1 or p_banner_min_price < 0 or p_luck_min_win < 0 then
    raise exception 'invalid gift values';
  end if;

  update public.gifts
  set name=p_name,
      emoji=p_emoji,
      price=p_price,
      category=p_category,
      is_active=p_is_active,
      banner_enabled=p_banner_enabled,
      banner_min_price=p_banner_min_price,
      luck_min_win=p_luck_min_win
  where id=p_id
  returning * into result_gift;

  if result_gift.id is null then raise exception 'gift not found'; end if;
  return result_gift;
end;
$$;

revoke all on function public.admin_update_gift(uuid,text,text,bigint,text,boolean,boolean,bigint,bigint) from public;
grant execute on function public.admin_update_gift(uuid,text,text,bigint,text,boolean,boolean,bigint,bigint) to authenticated;

-- Keep the owner's CEO wallet at the requested 10 billion starting balance.
-- Only initializes/raises CEO wallet balances; it never reduces an existing balance.
insert into public.wallets(user_id,balance)
select p.id, 10000000000
from public.profiles p
where p.role = 'CEO'::public.app_role
  and not exists (select 1 from public.wallets w where w.user_id=p.id);

update public.wallets w
set balance = 10000000000, updated_at = now()
from public.profiles p
where p.id=w.user_id
  and p.role = 'CEO'::public.app_role
  and w.balance < 10000000000;
