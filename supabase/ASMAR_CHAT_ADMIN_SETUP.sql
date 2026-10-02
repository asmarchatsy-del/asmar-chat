create extension if not exists pgcrypto;
do $$begin create type public.app_role as enum('CEO','SUPER_ADMIN','MANAGER','ADMIN','HOST','AGENT','USER'); exception when duplicate_object then null; end$$;

do $$begin alter type public.app_role add value if not exists 'BD'; exception when duplicate_object then null; end$$;

create table if not exists public.profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 username text unique,display_name text not null default '',avatar_url text,
 role public.app_role not null default 'USER',is_active boolean not null default true,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 activity_admin_badge boolean not null default false,customer_service_badge boolean not null default false,is_verified boolean not null default false);
create sequence if not exists public.user_public_id_seq start with 257305;
alter table public.profiles add column if not exists public_id text;
alter sequence public.user_public_id_seq owned by public.profiles.public_id;
alter table public.profiles alter column public_id set default nextval('public.user_public_id_seq')::text;
update public.profiles set public_id=case when upper(coalesce(username,''))='ASMAR' or role='CEO' then 'ASMAR' else nextval('public.user_public_id_seq')::text end where public_id is null;
create unique index if not exists profiles_public_id_unique on public.profiles(public_id);
alter table public.profiles add column if not exists vip_level text;
alter table public.profiles add column if not exists activity_admin_badge boolean not null default false;
alter table public.profiles add column if not exists customer_service_badge boolean not null default false;
alter table public.profiles add column if not exists is_verified boolean not null default false;
create table if not exists public.wallets(user_id uuid primary key references public.profiles(id) on delete cascade,balance bigint not null default 0 check(balance>=0),updated_at timestamptz not null default now());
alter table public.wallets add column if not exists updated_at timestamptz not null default now();
create table if not exists public.coin_transactions(id uuid primary key default gen_random_uuid(),from_user_id uuid references public.profiles(id),to_user_id uuid references public.profiles(id),amount bigint not null check(amount>0),reason text not null default 'transfer',created_at timestamptz not null default now());
alter table public.coin_transactions add column if not exists reason text not null default 'transfer';
create table if not exists public.agencies(id uuid primary key default gen_random_uuid(),name text not null unique,manager_id uuid references public.profiles(id),bd_id uuid references public.profiles(id),owner_id uuid references public.profiles(id),is_active boolean not null default true,created_at timestamptz not null default now());
create table if not exists public.rooms(id uuid primary key default gen_random_uuid(),name text not null,owner_id uuid references public.profiles(id),livekit_room_name text unique,is_active boolean not null default true,created_at timestamptz not null default now());
create table if not exists public.frame_items(id uuid primary key default gen_random_uuid(),name text not null unique,style_key text not null,price bigint not null default 0 check(price>=0),is_active boolean not null default true,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.coin_packages(id uuid primary key default gen_random_uuid(),name text not null unique,coins bigint not null check(coins>0),price_usd numeric(12,2) not null check(price_usd>=0),is_active boolean not null default true,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.vip_levels(id text primary key,animal text not null,image text not null,price_coins bigint not null default 0,duration_days integer not null default 30,perks jsonb not null default '[]',is_active boolean not null default true,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.gifts(id text primary key,name text not null,emoji text not null,price bigint not null check(price>0),is_active boolean not null default true,category text not null default 'normal',banner_enabled boolean not null default false,banner_min_price bigint not null default 4000,luck_min_win bigint not null default 3000);
create table if not exists public.rocket_levels(id integer primary key check(id between 1 and 5),name text not null,bg1 text not null default '',bg2 text not null default '',line text not null default '',coins bigint not null default 0,is_active boolean not null default true,updated_at timestamptz not null default now());
create table if not exists public.asmar_policy(level integer primary key,target bigint not null default 0,host_base bigint not null default 0,agent_base bigint not null default 0,host_total bigint not null default 0,agent_total bigint not null default 0);
create table if not exists public.app_promotions(id uuid primary key default gen_random_uuid(),title text not null,subtitle text,image_url text,first_place text,second_place text,third_place text,first_prize text,second_prize text,third_prize text,button_text text default 'شارك الآن',button_url text,starts_at timestamptz not null default now(),ends_at timestamptz,is_active boolean not null default true,created_at timestamptz not null default now());

alter table public.profiles enable row level security;alter table public.agencies enable row level security;alter table public.wallets enable row level security;alter table public.rooms enable row level security;alter table public.frame_items enable row level security;alter table public.coin_packages enable row level security;alter table public.vip_levels enable row level security;alter table public.gifts enable row level security;alter table public.rocket_levels enable row level security;alter table public.asmar_policy enable row level security;alter table public.app_promotions enable row level security;

create or replace function public.has_role(required_roles public.app_role[]) returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from public.profiles where id=auth.uid() and is_active and role=any(required_roles))$$;

drop policy if exists profiles_self on public.profiles;create policy profiles_self on public.profiles for select to authenticated using(id=auth.uid() or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists profiles_admin_update on public.profiles;create policy profiles_admin_update on public.profiles for update to authenticated using(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])) with check(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists wallets_read on public.wallets;create policy wallets_read on public.wallets for select to authenticated using(user_id=auth.uid() or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists rooms_read on public.rooms;create policy rooms_read on public.rooms for select to authenticated using(is_active or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists frames_read on public.frame_items;create policy frames_read on public.frame_items for select to authenticated using(is_active or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists frames_admin on public.frame_items;create policy frames_admin on public.frame_items for all to authenticated using(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])) with check(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists packages_read on public.coin_packages;create policy packages_read on public.coin_packages for select to authenticated using(is_active or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists packages_admin on public.coin_packages;create policy packages_admin on public.coin_packages for all to authenticated using(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])) with check(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists vip_read on public.vip_levels;create policy vip_read on public.vip_levels for select to authenticated using(is_active or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists vip_admin on public.vip_levels;create policy vip_admin on public.vip_levels for all to authenticated using(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])) with check(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists gifts_read on public.gifts;create policy gifts_read on public.gifts for select to authenticated using(is_active or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists gifts_admin on public.gifts;create policy gifts_admin on public.gifts for update to authenticated using(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])) with check(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists rocket_read on public.rocket_levels;create policy rocket_read on public.rocket_levels for select to authenticated using(is_active or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists rocket_admin on public.rocket_levels;create policy rocket_admin on public.rocket_levels for update to authenticated using(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])) with check(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists policy_read on public.asmar_policy;create policy policy_read on public.asmar_policy for select to authenticated using(true);
drop policy if exists promo_read on public.app_promotions;create policy promo_read on public.app_promotions for select to authenticated using(is_active or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
drop policy if exists promo_admin on public.app_promotions;create policy promo_admin on public.app_promotions for all to authenticated using(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])) with check(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists agencies_read on public.agencies;create policy agencies_read on public.agencies for select to authenticated using(is_active or public.has_role(array['CEO','SUPER_ADMIN','MANAGER','BD']::public.app_role[]));
drop policy if exists agencies_admin on public.agencies;create policy agencies_admin on public.agencies for all to authenticated using(public.has_role(array['CEO','SUPER_ADMIN','MANAGER']::public.app_role[])) with check(public.has_role(array['CEO','SUPER_ADMIN','MANAGER']::public.app_role[]));
grant select on public.profiles,public.agencies,public.wallets,public.rooms,public.frame_items,public.coin_packages,public.vip_levels,public.gifts,public.rocket_levels,public.asmar_policy,public.app_promotions to authenticated;

insert into public.frame_items(name,style_key,price) values('الإطار الذهبي','gold',500),('إطار الماس','diamond',1500),('إطار النار','fire',2500),('إطار VIP','vip',5000),('إطار SVIP','svip',10000) on conflict(name) do nothing;
insert into public.coin_packages(name,coins,price_usd) values('Starter',1000,.99),('Popular',5500,4.99),('VIP',12000,9.99),('SVIP',30000,24.99) on conflict(name) do nothing;
insert into public.vip_levels(id,name,animal,image,price_coins) values('VIP1','VIP 1','الغزال','assets/vip/deer.png',10000),('VIP2','VIP 2','الذئب','assets/vip/wolf.png',20000),('VIP3','VIP 3','التمساح','assets/vip/crocodile.png',30000),('VIP4','VIP 4','الفيل','assets/vip/elephant.png',40000),('VIP5','VIP 5','النسر','assets/vip/eagle.png',50000),('VIP6','VIP 6','الدب','assets/vip/bear.png',60000),('VIP7','VIP 7','الفهد','assets/vip/leopard.png',70000),('VIP8','VIP 8','النمر','assets/vip/tiger.png',80000),('VIP9','VIP 9','التنين','assets/vip/dragon.png',90000),('VIP10','VIP 10','الأسد','assets/vip/lion.png',100000),('SVIP','SVIP','ملكي','assets/vip/svip.png',250000) on conflict(id) do nothing;
insert into public.rocket_levels(id,name,bg1,bg2,line,coins) values(1,'LV1 عادي','#2A1E0F','#1A1109','#FFD700',1000),(2,'LV2 زمرد','#0F2A1E','#05140A','#00FF88',3000),(3,'LV3 ياقوت ازرق','#0F1E4A','#050A2A','#3A7BFF',5000),(4,'LV4 روبي احمر','#4A0F0F','#2A0505','#FF2A2A',7000),(5,'LV5 ملكي بنفسجي','#3A0F4A','#1A052A','#AA2AFF',10000) on conflict(id) do nothing;
insert into public.gifts(id,name,emoji,price,category,banner_enabled) values('rose','وردة','🌹',100,'normal',false),('heart','قلب','❤️',500,'love',false),('diamond','ماسة','💎',2500,'luxury',false),('crown','تاج ملكي','👑',10000,'luxury',true),('royal_car','سيارة ملكية','🚘',50000,'luxury',true),('gold_dragon','تنين ذهبي','🐉',250000,'luxury',true),('asmar_kingdom','مملكة Asmar','🏯',1000000,'luxury',true) on conflict(id) do nothing;
insert into public.app_promotions(title,subtitle,starts_at) select 'ASMAR CHAT — حدث الشحن','نافس على المراكز واربح جوائز الحدث',now() where not exists(select 1 from public.app_promotions);
insert into public.wallets(user_id,balance) select id,10000000000 from public.profiles where role='CEO' and not exists(select 1 from public.wallets w where w.user_id=profiles.id);
update public.wallets w set balance=10000000000,updated_at=now() from public.profiles p where p.id=w.user_id and p.role='CEO' and w.balance<10000000000;

create or replace function public.admin_set_user_active(p_user_id uuid,p_active boolean) returns boolean language plpgsql security definer set search_path=public as $$begin if not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then raise exception 'not authorized';end if;update public.profiles set is_active=p_active,updated_at=now() where id=p_user_id;return p_active;end$$;
create or replace function public.admin_set_room_active(p_room_id uuid,p_active boolean) returns boolean language plpgsql security definer set search_path=public as $$begin if not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then raise exception 'not authorized';end if;update public.rooms set is_active=p_active where id=p_room_id;return p_active;end$$;
create or replace function public.admin_adjust_wallet(p_user_id uuid,p_amount bigint) returns bigint language plpgsql security definer set search_path=public as $$declare b bigint;begin if not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then raise exception 'not authorized';end if;insert into public.wallets(user_id,balance) values(p_user_id,0) on conflict do nothing;update public.wallets set balance=balance+p_amount,updated_at=now() where user_id=p_user_id and balance+p_amount>=0 returning balance into b;if b is null then raise exception 'insufficient balance';end if;return b;end$$;
create or replace function public.admin_update_gift(p_id text,p_name text,p_emoji text,p_price bigint,p_category text,p_is_active boolean,p_banner_enabled boolean,p_banner_min_price bigint,p_luck_min_win bigint) returns public.gifts language plpgsql security definer set search_path=public as $$declare g public.gifts;begin if not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then raise exception 'not authorized';end if;update public.gifts set name=p_name,emoji=p_emoji,price=p_price,category=p_category,is_active=p_is_active,banner_enabled=p_banner_enabled,banner_min_price=p_banner_min_price,luck_min_win=p_luck_min_win where id=p_id returning * into g;if g.id is null then raise exception 'gift not found';end if;return g;end$$;
grant execute on function public.admin_set_user_active(uuid,boolean),public.admin_set_room_active(uuid,boolean),public.admin_adjust_wallet(uuid,bigint),public.admin_update_gift(text,text,text,bigint,text,boolean,boolean,bigint,bigint) to authenticated;
create or replace function public.admin_grant_vip(p_user_id uuid,p_vip_level text) returns text language plpgsql security definer set search_path=public as $$declare actor_role public.app_role; target_level integer; max_level integer;begin select role into actor_role from public.profiles where id=auth.uid() and is_active;if actor_role is null then raise exception 'not authorized';end if;target_level:=case when upper(p_vip_level) like 'VIP%' then regexp_replace(upper(p_vip_level),'[^0-9]','','g')::integer else 0 end;max_level:=case actor_role when 'CEO' then 10 when 'SUPER_ADMIN' then 6 else 0 end;if target_level<1 or target_level>max_level then raise exception 'VIP level not permitted for this role';end if;update public.profiles set vip_level=upper(p_vip_level),updated_at=now() where id=p_user_id;return upper(p_vip_level);end$$;
grant execute on function public.admin_grant_vip(uuid,text) to authenticated;

create table if not exists public.agency_commission_settings(
 id boolean primary key default true,
 app_share_percent numeric(5,2) not null default 20 check(app_share_percent between 0 and 100),
 owner_work_percent numeric(5,2) not null default 0 check(owner_work_percent between 0 and 100),
 super_admin_work_percent numeric(5,2) not null default 0 check(super_admin_work_percent between 0 and 100),
 manager_work_percent numeric(5,2) not null default 0 check(manager_work_percent between 0 and 100),
 bd_work_percent numeric(5,2) not null default 0 check(bd_work_percent between 0 and 100),
 admin_work_percent numeric(5,2) not null default 0 check(admin_work_percent between 0 and 100),
 updated_at timestamptz not null default now()
);
insert into public.agency_commission_settings(id) values(true) on conflict(id) do nothing;
alter table public.agencies add column if not exists opened_by uuid references public.profiles(id);
alter table public.agencies add column if not exists super_admin_id uuid references public.profiles(id);
alter table public.agencies add column if not exists work_share_percent numeric(5,2) not null default 0;
alter table public.agencies add column if not exists created_by_role text;
alter table public.agencies add column if not exists updated_at timestamptz not null default now();

create table if not exists public.agency_commission_ledger(
 id uuid primary key default gen_random_uuid(),
 agency_id uuid not null references public.agencies(id) on delete cascade,
 source_amount bigint not null check(source_amount >= 0),
 app_share_amount bigint not null default 0,
 work_share_amount bigint not null default 0,
 owner_amount bigint not null default 0,
 super_admin_amount bigint not null default 0,
 manager_amount bigint not null default 0,
 bd_amount bigint not null default 0,
 admin_amount bigint not null default 0,
 created_at timestamptz not null default now()
);
alter table public.agency_commission_settings enable row level security;
drop policy if exists commission_settings_read on public.agency_commission_settings;
create policy commission_settings_read on public.agency_commission_settings for select to authenticated using(public.has_role(array['CEO','SUPER_ADMIN','MANAGER','BD','ADMIN']::public.app_role[]));
drop policy if exists commission_settings_owner on public.agency_commission_settings;
create policy commission_settings_owner on public.agency_commission_settings for all to authenticated using(public.has_role(array['CEO']::public.app_role[])) with check(public.has_role(array['CEO']::public.app_role[]));
alter table public.agency_commission_ledger enable row level security;
drop policy if exists commission_ledger_read on public.agency_commission_ledger;
create policy commission_ledger_read on public.agency_commission_ledger for select to authenticated using(
 public.has_role(array['CEO','SUPER_ADMIN','MANAGER','BD','ADMIN']::public.app_role[])
);
create or replace function public.agency_open(
 p_name text,
 p_manager_id uuid default null,
 p_bd_id uuid default null
) returns uuid language plpgsql security definer set search_path=public as $$
declare actor_role public.app_role; aid uuid; aid_owner uuid; aid_manager uuid; aid_bd uuid;
begin
 select role into actor_role from public.profiles where id=auth.uid() and is_active;
 if actor_role is null or actor_role not in ('CEO','SUPER_ADMIN','MANAGER','BD') then raise exception 'not authorized'; end if;
 aid_owner:=case when actor_role='CEO' then auth.uid() else null end;
 aid_manager:=case when actor_role='MANAGER' then auth.uid() else p_manager_id end;
 aid_bd:=case when actor_role='BD' then auth.uid() else p_bd_id end;
 insert into public.agencies(name,manager_id,bd_id,owner_id,opened_by,super_admin_id,created_by_role)
 values(trim(p_name),aid_manager,aid_bd,aid_owner,auth.uid(),case when actor_role='SUPER_ADMIN' then auth.uid() else null end,actor_role::text)
 returning id into aid;
 return aid;
end $$;
grant execute on function public.agency_open(text,uuid,uuid) to authenticated;

alter table public.profiles add column if not exists agency_id uuid references public.agencies(id);
alter table public.profiles add column if not exists agency_joined_at timestamptz;
create index if not exists profiles_agency_id_idx on public.profiles(agency_id);

create or replace function public.agency_assign_host(p_host_id uuid,p_agency_id uuid) returns boolean
language plpgsql security definer set search_path=public as $$
declare actor_role public.app_role; host_role public.app_role;
begin
 select role into actor_role from public.profiles where id=auth.uid() and is_active;
 select role into host_role from public.profiles where id=p_host_id;
 if actor_role is null or host_role <> 'HOST' then raise exception 'not authorized'; end if;
 if actor_role='AGENT' then
   if not exists(select 1 from public.agencies a where a.id=p_agency_id and a.is_active and a.owner_id=auth.uid()) then raise exception 'agency not owned by agent'; end if;
 elsif actor_role='CEO' then null;
 elsif actor_role in ('SUPER_ADMIN','MANAGER','BD','ADMIN') then
   if not exists(select 1 from public.agencies a where a.id=p_agency_id and a.is_active and
     (actor_role='SUPER_ADMIN' or a.manager_id=auth.uid() or a.bd_id=auth.uid())) then raise exception 'agency outside scope'; end if;
 else raise exception 'not authorized'; end if;
 update public.profiles set agency_id=p_agency_id,agency_joined_at=now(),updated_at=now() where id=p_host_id;
 return true;
end $$;
grant execute on function public.agency_assign_host(uuid,uuid) to authenticated;

create or replace function public.record_agency_work(
 p_agency_id uuid,p_source_amount bigint
) returns uuid language plpgsql security definer set search_path=public as $$
declare s public.agency_commission_settings%rowtype; a public.agencies%rowtype; wid uuid;
begin
 if p_source_amount<=0 then raise exception 'amount must be positive'; end if;
 select * into a from public.agencies where id=p_agency_id and is_active;
 if a.id is null then raise exception 'agency not found'; end if;
 select * into s from public.agency_commission_settings where id=true;
 insert into public.agency_commission_ledger(
 agency_id,source_amount,app_share_amount,work_share_amount,owner_amount,super_admin_amount,manager_amount,bd_amount,admin_amount)
 values(
 a.id,p_source_amount,
 round(p_source_amount*s.app_share_percent/100),
 round(p_source_amount*(100-s.app_share_percent)/100),
 round(p_source_amount*(100-s.app_share_percent)/100*s.owner_work_percent/100),
 round(p_source_amount*(100-s.app_share_percent)/100*s.super_admin_work_percent/100),
 round(p_source_amount*(100-s.app_share_percent)/100*s.manager_work_percent/100),
 round(p_source_amount*(100-s.app_share_percent)/100*s.bd_work_percent/100),
 round(p_source_amount*(100-s.app_share_percent)/100*s.admin_work_percent/100))
 returning id into wid;
 return wid;
end $$;
grant execute on function public.record_agency_work(uuid,bigint) to authenticated;

create table if not exists public.host_earnings(
 id uuid primary key default gen_random_uuid(),
 host_id uuid not null references public.profiles(id) on delete cascade,
 agency_id uuid references public.agencies(id) on delete set null,
 source_amount bigint not null check(source_amount>0),
 host_amount bigint not null default 0 check(host_amount>=0),
 created_at timestamptz not null default now()
);
create index if not exists host_earnings_host_idx on public.host_earnings(host_id,created_at desc);
alter table public.host_earnings enable row level security;
drop policy if exists host_earnings_read on public.host_earnings;
create policy host_earnings_read on public.host_earnings for select to authenticated using(
 host_id=auth.uid() or public.has_role(array['CEO','SUPER_ADMIN','MANAGER','BD','ADMIN']::public.app_role[])
 or exists(select 1 from public.agencies a where a.id=host_earnings.agency_id and a.owner_id=auth.uid())
);

create or replace function public.admin_set_commission_settings(
 p_app_share numeric,p_owner_work numeric,p_super_admin_work numeric,p_manager_work numeric,p_bd_work numeric,p_admin_work numeric
) returns boolean language plpgsql security definer set search_path=public as $$
declare total_work numeric;
begin
 if not public.has_role(array['CEO']::public.app_role[]) then raise exception 'not authorized'; end if;
 total_work:=coalesce(p_owner_work,0)+coalesce(p_super_admin_work,0)+coalesce(p_manager_work,0)+coalesce(p_bd_work,0)+coalesce(p_admin_work,0);
 if p_app_share<0 or p_app_share>100 or total_work<0 or total_work>100 then raise exception 'invalid commission percentages'; end if;
 update public.agency_commission_settings set app_share_percent=p_app_share,owner_work_percent=p_owner_work,super_admin_work_percent=p_super_admin_work,manager_work_percent=p_manager_work,bd_work_percent=p_bd_work,admin_work_percent=p_admin_work,updated_at=now() where id=true;
 return true;
end $$;
grant execute on function public.admin_set_commission_settings(numeric,numeric,numeric,numeric,numeric,numeric) to authenticated;

create or replace function public.record_host_earning(p_host_id uuid,p_source_amount bigint) returns uuid
language plpgsql security definer set search_path=public as $$
declare h public.profiles%rowtype; a public.agencies%rowtype; eid uuid; host_amount bigint;
begin
 if p_source_amount<=0 then raise exception 'amount must be positive'; end if;
 select * into h from public.profiles where id=p_host_id and is_active and role='HOST';
 if h.id is null then raise exception 'host not found'; end if;
 if auth.uid()<>p_host_id and not public.has_role(array['CEO','SUPER_ADMIN','MANAGER','BD','ADMIN']::public.app_role[]) then
   raise exception 'not authorized';
 end if;
 select * into a from public.agencies where id=h.agency_id;
 host_amount:=p_source_amount;
 insert into public.host_earnings(host_id,agency_id,source_amount,host_amount) values(h.id,a.id,p_source_amount,host_amount) returning id into eid;
 return eid;
end $$;
grant execute on function public.record_host_earning(uuid,bigint) to authenticated;

create or replace function public.get_my_host_earnings() returns table(total_source bigint,total_earned bigint,entries bigint)
language sql security definer set search_path=public as $$
 select coalesce(sum(source_amount),0)::bigint,coalesce(sum(host_amount),0)::bigint,count(*)::bigint
 from public.host_earnings where host_id=auth.uid();
$$;
grant execute on function public.get_my_host_earnings() to authenticated;


-- FINAL HARDENING: scoped role-center access
drop policy if exists profiles_role_center_read on public.profiles;
create policy profiles_role_center_read on public.profiles
for select to authenticated
using(
  id=auth.uid()
  or public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])
  or (
    public.has_role(array['MANAGER','BD','ADMIN']::public.app_role[])
    and role in ('HOST','AGENT','USER')
  )
  or (
    public.has_role(array['AGENT']::public.app_role[])
    and agency_id=(select p.agency_id from public.profiles p where p.id=auth.uid())
  )
);

drop policy if exists commission_settings_owner on public.agency_commission_settings;
create policy commission_settings_owner on public.agency_commission_settings
for all to authenticated
using(public.has_role(array['CEO']::public.app_role[]))
with check(public.has_role(array['CEO']::public.app_role[]));

alter table public.agencies add column if not exists admin_id uuid references public.profiles(id);
create index if not exists agencies_admin_id_idx on public.agencies(admin_id);

drop policy if exists agencies_read on public.agencies;
create policy agencies_read on public.agencies
for select to authenticated
using(
 public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])
 or (public.has_role(array['MANAGER']::public.app_role[]) and manager_id=auth.uid())
 or (public.has_role(array['BD']::public.app_role[]) and bd_id=auth.uid())
 or (public.has_role(array['ADMIN']::public.app_role[]) and admin_id=auth.uid())
 or (public.has_role(array['AGENT']::public.app_role[]) and owner_id=auth.uid())
);

drop policy if exists agencies_admin on public.agencies;
create policy agencies_admin on public.agencies
for all to authenticated
using(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check(public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));

drop policy if exists commission_ledger_read on public.agency_commission_ledger;
create policy commission_ledger_read on public.agency_commission_ledger
for select to authenticated
using(
 public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[])
 or exists(select 1 from public.agencies a where a.id=agency_commission_ledger.agency_id and (
   (public.has_role(array['MANAGER']::public.app_role[]) and a.manager_id=auth.uid())
   or (public.has_role(array['BD']::public.app_role[]) and a.bd_id=auth.uid())
   or (public.has_role(array['ADMIN']::public.app_role[]) and a.admin_id=auth.uid())
 ))
);

-- Keep SECURITY DEFINER RPCs inaccessible to anonymous callers.
do $$declare r record; begin
 for r in
   select p.proname,pg_get_function_identity_arguments(p.oid) args
   from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.prosecdef
 loop
   execute format('revoke execute on function public.%I(%s) from anon',r.proname,r.args);
 end loop;
end$$;

revoke execute on function public.rls_auto_enable() from authenticated;
revoke execute on function public.transfer_coins(uuid,uuid,bigint) from authenticated;

-- CEO-only role management
create or replace function public.admin_set_user_role(p_user_id uuid,p_role public.app_role)
returns boolean language plpgsql security definer set search_path=public as $$
begin
  if not public.has_role(array['CEO']::public.app_role[]) then raise exception 'not authorized'; end if;
  if p_user_id=auth.uid() and p_role<>'CEO' then raise exception 'owner cannot demote self'; end if;
  update public.profiles set role=p_role,updated_at=now() where id=p_user_id;
  return found;
end$$;

-- Agency assignment RPCs
create or replace function public.agency_assign_agent(p_agency_id uuid,p_agent_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_role public.app_role;
begin
 select role into v_role from public.profiles where id=p_agent_id and is_active=true;
 if v_role <> 'AGENT' then raise exception 'target must be AGENT'; end if;
 if public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then null;
 elsif public.has_role(array['MANAGER']::public.app_role[]) then
   if not exists(select 1 from public.agencies where id=p_agency_id and manager_id=auth.uid() and is_active) then raise exception 'agency outside manager scope'; end if;
 else raise exception 'not authorized'; end if;
 update public.agencies set owner_id=p_agent_id,updated_at=now() where id=p_agency_id;
 return found;
end$$;

create or replace function public.agency_assign_admin(p_agency_id uuid,p_admin_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_role public.app_role;
begin
 select role into v_role from public.profiles where id=p_admin_id and is_active=true;
 if v_role <> 'ADMIN' then raise exception 'target must be ADMIN'; end if;
 if public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then null;
 elsif public.has_role(array['MANAGER']::public.app_role[]) then
   if not exists(select 1 from public.agencies where id=p_agency_id and manager_id=auth.uid() and is_active) then raise exception 'agency outside manager scope'; end if;
 else raise exception 'not authorized'; end if;
 update public.agencies set admin_id=p_admin_id,updated_at=now() where id=p_agency_id;
 return found;
end$$;

revoke execute on function public.agency_assign_agent(uuid,uuid) from anon;
revoke execute on function public.agency_assign_admin(uuid,uuid) from anon;

-- Explicitly block anonymous execution of privileged RPCs
revoke all on function public.admin_adjust_wallet(uuid,bigint) from anon;
revoke all on function public.admin_grant_vip(uuid,text) from anon;
revoke all on function public.admin_is_authorized() from anon;
revoke all on function public.admin_set_commission_settings(numeric,numeric,numeric,numeric,numeric,numeric) from anon;
revoke all on function public.admin_set_room_active(uuid,boolean) from anon;
revoke all on function public.admin_set_user_active(uuid,boolean) from anon;
revoke all on function public.admin_set_user_role(uuid,public.app_role) from anon;
revoke all on function public.admin_transfer_coins(uuid,bigint,text) from anon;
revoke all on function public.agency_assign_admin(uuid,uuid) from anon;
revoke all on function public.agency_assign_agent(uuid,uuid) from anon;
revoke all on function public.agency_assign_host(uuid,uuid) from anon;
revoke all on function public.agency_open(text,uuid,uuid) from anon;
revoke all on function public.agent_recharge(text,bigint) from anon;
revoke all on function public.get_my_host_earnings() from anon;
revoke all on function public.has_role(public.app_role[]) from anon;
revoke all on function public.record_agency_work(uuid,bigint) from anon;
revoke all on function public.record_host_earning(uuid,bigint) from anon;


-- Public user IDs: sequential from 257305, editable by CEO; ASMAR is reserved for the owner account.
create or replace function public.admin_set_public_id(p_user_id uuid,p_public_id text)
returns public.profiles language plpgsql security invoker set search_path=public as $$
declare v_role public.app_role; v_value text; v_profile public.profiles;
begin
 select role into v_role from public.profiles where id=auth.uid();
 if v_role is distinct from 'CEO' then raise exception 'Only CEO can change public IDs'; end if;
 v_value:=upper(trim(p_public_id));
 if v_value is null or v_value='' then raise exception 'Public ID cannot be empty'; end if;
 if length(v_value)>32 then raise exception 'Public ID too long'; end if;
 if not (v_value ~ '^[A-Z0-9_]+$') then raise exception 'Public ID may contain only letters, numbers and underscore'; end if;
 if p_user_id=(select id from public.profiles where role='CEO' limit 1) and v_value<>'ASMAR' then raise exception 'ASMAR owner ID is reserved'; end if;
 update public.profiles set public_id=v_value,updated_at=now() where id=p_user_id returning * into v_profile;
 if not found then raise exception 'User not found'; end if;
 return v_profile;
end$$;
revoke all on function public.admin_set_public_id(uuid,text) from public,anon;
grant execute on function public.admin_set_public_id(uuid,text) to authenticated;
