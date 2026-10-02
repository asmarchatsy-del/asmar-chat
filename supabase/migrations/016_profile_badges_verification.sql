-- Appearance-only profile badges + admin account verification.
alter table public.profiles
  add column if not exists activity_admin_badge boolean not null default false,
  add column if not exists customer_service_badge boolean not null default false,
  add column if not exists is_verified boolean not null default false;

create index if not exists profiles_badges_idx
  on public.profiles(activity_admin_badge, customer_service_badge, is_verified);

drop policy if exists "admins_manage_profile_badges" on public.profiles;
create policy "admins_manage_profile_badges"
on public.profiles
for update to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

grant select on public.profiles to authenticated;
