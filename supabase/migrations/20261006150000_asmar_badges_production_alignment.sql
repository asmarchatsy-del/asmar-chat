-- Final production alignment for Asmar official roles/badges.
-- The earlier 20261006142440/142512/142737 migrations were already applied
-- in production under these recorded migration names. Keep this migration
-- idempotent so fresh environments and production converge safely.

alter table public.badges
  add column if not exists code text,
  add column if not exists icon_key text not null default 'military_tech',
  add column if not exists role public.app_role,
  add column if not exists is_official boolean not null default true;

create unique index if not exists badges_code_unique_idx
  on public.badges(code) where code is not null;

insert into public.badges(id,name,description,code,icon_key,role,is_official,is_active)
select rb.id,rb.name,'شارة رسمية من Asmar للدور '||rb.role,
 case rb.role when 'CEO' then 'role_ceo' when 'SUPER_ADMIN' then 'role_super_admin'
 when 'MANAGER' then 'role_manager' when 'BD' then 'role_bd'
 when 'AGENT' then 'role_agent' when 'HOST' then 'role_host'
 when 'COIN_SELLER' then 'role_coin_seller' else 'role_'||lower(replace(rb.role,' ','_')) end,
 case rb.role when 'CEO' then 'crown' when 'SUPER_ADMIN' then 'verified_user'
 when 'MANAGER' then 'manage_accounts' when 'BD' then 'campaign'
 when 'AGENT' then 'handshake' when 'HOST' then 'mic'
 when 'COIN_SELLER' then 'paid' else 'military_tech' end,
 rb.role::public.app_role,true,rb.is_active
from public.role_badges rb
on conflict (id) do update set
 name=excluded.name,description=excluded.description,code=excluded.code,
 icon_key=excluded.icon_key,role=excluded.role,is_official=true,is_active=excluded.is_active;

insert into public.badges(code,name,description,icon_key,role,is_official,is_active)
values('role_coin_seller','COIN SELLER','بائع العملات — شحن آمن وسريع','paid','COIN_SELLER',true,true)
on conflict (code) do update set name=excluded.name,description=excluded.description,
 icon_key=excluded.icon_key,role=excluded.role,is_official=true,is_active=true;

alter table public.user_badges drop constraint if exists user_badges_badge_id_fkey;
alter table public.user_badges add constraint user_badges_badge_id_fkey
 foreign key (badge_id) references public.badges(id) on delete cascade;

alter table public.badges enable row level security;
alter table public.user_badges enable row level security;

drop policy if exists "badges_select_authenticated" on public.badges;
create policy "badges_select_authenticated" on public.badges
 for select to authenticated using (is_active=true);

drop policy if exists "user_badges_select_authenticated" on public.user_badges;
create policy "user_badges_select_authenticated" on public.user_badges
 for select to authenticated using (user_id=auth.uid());

create or replace function public.asmar_role_rank(p_role public.app_role)
returns integer language sql immutable set search_path=public as $$
 select case p_role when 'CEO' then 100 when 'SUPER_ADMIN' then 90
 when 'MANAGER' then 80 when 'BD' then 70 when 'AGENT' then 60
 when 'HOST' then 50 when 'COIN_SELLER' then 40 when 'ADMIN' then 35 else 0 end;
$$;

create or replace function public.asmar_can_manage_role(p_target public.app_role)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_active=true
 and (p.role='CEO'
 or (p.role='SUPER_ADMIN' and public.asmar_role_rank(p_target)<90)
 or (p.role='MANAGER' and p_target in ('BD','AGENT','HOST','COIN_SELLER','USER'))));
$$;

revoke all on function public.asmar_can_manage_role(public.app_role) from anon;
grant execute on function public.asmar_can_manage_role(public.app_role) to authenticated;
revoke all on function public.asmar_equip_badge(uuid) from anon;
grant execute on function public.asmar_equip_badge(uuid) to authenticated;
revoke all on function public.asmar_set_user_role(uuid,public.app_role) from anon;
grant execute on function public.asmar_set_user_role(uuid,public.app_role) to authenticated;
revoke all on function public.asmar_sync_role_badge(uuid) from anon;
revoke all on function public.asmar_profile_role_badge_trigger() from anon;
