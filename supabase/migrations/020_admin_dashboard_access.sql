-- Fix external admin dashboard access for authenticated admin accounts.
-- Safe: grants table access to authenticated users; RLS remains the authorization boundary.
grant select on public.profiles to authenticated;
grant select on public.wallets to authenticated;
grant select on public.rooms to authenticated;
grant select on public.store_items to authenticated;
grant select on public.asmar_policy to authenticated;
grant select, insert, update on public.app_promotions to authenticated;
grant select, update on public.gifts to authenticated;
grant select, update on public.rocket_levels to authenticated;

drop policy if exists "profiles_select_admin" on public.profiles;
create policy "profiles_select_admin"
on public.profiles for select
to authenticated
using (
  id = auth.uid()
  or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])
);

drop policy if exists "store_items_admin" on public.store_items;
create policy "store_items_admin"
on public.store_items for update
to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "promotions_admin_insert" on public.app_promotions;
create policy "promotions_admin_insert"
on public.app_promotions for insert
to authenticated
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists "promotions_admin_update" on public.app_promotions;
create policy "promotions_admin_update"
on public.app_promotions for update
to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
