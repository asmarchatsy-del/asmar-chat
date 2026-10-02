create table if not exists public.rocket_levels (
  id integer primary key check (id between 1 and 5),
  name text not null,
  bg1 text not null,
  bg2 text not null,
  line text not null,
  coins bigint not null default 0 check (coins >= 0),
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.rocket_levels enable row level security;
drop policy if exists "rocket_levels_select_active" on public.rocket_levels;
create policy "rocket_levels_select_active" on public.rocket_levels for select to authenticated using (is_active = true);
drop policy if exists "rocket_levels_admin_update" on public.rocket_levels;
create policy "rocket_levels_admin_update" on public.rocket_levels for update to authenticated
using (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]))
with check (public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]));
insert into public.rocket_levels(id,name,bg1,bg2,line,coins) values
(1,'LV1 عادي','#2A1E0F','#1A1109','#FFD700',1000),
(2,'LV2 زمرد','#0F2A1E','#05140A','#00FF88',3000),
(3,'LV3 ياقوت ازرق','#0F1E4A','#050A2A','#3A7BFF',5000),
(4,'LV4 روبي احمر','#4A0F0F','#2A0505','#FF2A2A',7000),
(5,'LV5 ملكي بنفسجي','#3A0F4A','#1A052A','#AA2AFF',10000)
on conflict(id) do update set name=excluded.name,bg1=excluded.bg1,bg2=excluded.bg2,line=excluded.line,coins=excluded.coins,updated_at=now();
