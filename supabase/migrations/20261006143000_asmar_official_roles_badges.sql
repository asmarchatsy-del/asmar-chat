-- Asmar official organizational roles + role badges.
-- Extends the existing role model without changing existing accounts.

alter type public.app_role add value if not exists 'BD';
alter type public.app_role add value if not exists 'COIN_SELLER';

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null default '',
  icon_key text not null default 'military_tech',
  role public.app_role,
  is_official boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.user_badges (
  user_id uuid not null references public.profiles(id) on delete cascade,
  badge_id uuid not null references public.badges(id) on delete cascade,
  granted_at timestamptz not null default now(),
  is_equipped boolean not null default false,
  primary key (user_id, badge_id)
);

create index if not exists user_badges_user_idx on public.user_badges(user_id);
create index if not exists badges_role_idx on public.badges(role);

alter table public.badges enable row level security;
alter table public.user_badges enable row level security;

drop policy if exists "badges_select_authenticated" on public.badges;
create policy "badges_select_authenticated" on public.badges
for select to authenticated using (is_active = true);

drop policy if exists "user_badges_select_authenticated" on public.user_badges;
create policy "user_badges_select_authenticated" on public.user_badges
for select to authenticated using (user_id = auth.uid());

create or replace function public.asmar_role_rank(p_role public.app_role)
returns integer
language sql immutable
as $$
  select case p_role
    when 'CEO' then 100
    when 'SUPER_ADMIN' then 90
    when 'MANAGER' then 80
    when 'BD' then 70
    when 'AGENT' then 60
    when 'HOST' then 50
    when 'COIN_SELLER' then 40
    when 'ADMIN' then 35
    else 0
  end;
$$;

create or replace function public.asmar_can_manage_role(p_target public.app_role)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.is_active = true
      and (
        p.role = 'CEO'
        or (p.role = 'SUPER_ADMIN' and public.asmar_role_rank(p_target) < public.asmar_role_rank('SUPER_ADMIN'))
        or (p.role = 'MANAGER' and p_target in ('BD','AGENT','HOST','COIN_SELLER','USER'))
      )
  );
$$;

insert into public.badges(code,name,description,icon_key,role)
values
 ('role_ceo','CEO','الرئيس التنفيذي — تحكم كامل وإدارة عليا','crown','CEO'),
 ('role_super_admin','SUPER ADMIN','المدير العام المتميز — إدارة المنصة','verified_user','SUPER_ADMIN'),
 ('role_manager','MANAGER','المدير — الإشراف والتنسيق اليومي','manage_accounts','MANAGER'),
 ('role_bd','BD','Business Developer — مطور الأعمال','campaign','BD'),
 ('role_agent','AGENT','الوكيل — إدارة المضيفين والبائعين','handshake','AGENT'),
 ('role_host','HOST','المضيف — غرفة صوتية واستقبال الهدايا','mic','HOST'),
 ('role_coin_seller','COIN SELLER','بائع العملات — شحن آمن وسريع','paid','COIN_SELLER')
on conflict (code) do update set
 name=excluded.name, description=excluded.description, icon_key=excluded.icon_key,
 role=excluded.role, is_official=true, is_active=true;

create or replace function public.asmar_sync_role_badge(p_user_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  r public.app_role;
  b uuid;
begin
  select role into r from public.profiles where id=p_user_id;
  if r is null then return; end if;

  select id into b from public.badges where role=r and is_active=true limit 1;
  if b is not null then
    insert into public.user_badges(user_id,badge_id,is_equipped)
    values(p_user_id,b,false)
    on conflict (user_id,badge_id) do nothing;
  end if;
end;
$$;

create or replace function public.asmar_profile_role_badge_trigger()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  perform public.asmar_sync_role_badge(new.id);
  return new;
end;
$$;

drop trigger if exists trg_asmar_role_badge on public.profiles;
create trigger trg_asmar_role_badge
after insert or update of role on public.profiles
for each row execute function public.asmar_profile_role_badge_trigger();

-- Backfill the official role badge for every existing account.
do $$
declare r record;
begin
  for r in select id from public.profiles loop
    perform public.asmar_sync_role_badge(r.id);
  end loop;
end $$;

create or replace function public.asmar_equip_badge(p_badge_id uuid)
returns boolean
language plpgsql security definer set search_path = public
as $$
begin
  if not exists (
    select 1 from public.user_badges
    where user_id=auth.uid() and badge_id=p_badge_id
  ) then raise exception 'badge not granted'; end if;

  update public.user_badges set is_equipped=false where user_id=auth.uid();
  update public.user_badges set is_equipped=true
    where user_id=auth.uid() and badge_id=p_badge_id;
  return true;
end;
$$;

revoke all on function public.asmar_equip_badge(uuid) from public;
grant execute on function public.asmar_equip_badge(uuid) to authenticated;

grant select on public.badges, public.user_badges to authenticated;
