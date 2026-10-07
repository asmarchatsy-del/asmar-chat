-- Ensure the external admin dashboard can verify CEO/SUPER_ADMIN access.
create or replace function public.admin_can_manage_dashboard()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null
    and public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]);
$$;

revoke all on function public.admin_can_manage_dashboard() from public;
grant execute on function public.admin_can_manage_dashboard() to authenticated;
