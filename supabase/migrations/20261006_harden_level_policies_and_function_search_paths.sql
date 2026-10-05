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