-- Enforce the official Asmar role hierarchy server-side.
create or replace function public.asmar_set_user_role(p_user_id uuid, p_role public.app_role)
returns public.app_role
language plpgsql security definer set search_path = public
as $$
declare
  caller public.app_role;
  current_role public.app_role;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;

  select role into caller from public.profiles where id=auth.uid() and is_active=true;
  select role into current_role from public.profiles where id=p_user_id;

  if caller is null or current_role is null then raise exception 'user not found'; end if;

  if caller <> 'CEO' then
    if caller = 'SUPER_ADMIN' then
      if public.asmar_role_rank(current_role) >= public.asmar_role_rank('SUPER_ADMIN')
         or public.asmar_role_rank(p_role) >= public.asmar_role_rank('SUPER_ADMIN') then
        raise exception 'cannot manage this rank';
      end if;
    elsif caller = 'MANAGER' then
      if current_role not in ('BD','AGENT','HOST','COIN_SELLER','USER')
         or p_role not in ('BD','AGENT','HOST','COIN_SELLER','USER') then
        raise exception 'cannot manage this rank';
      end if;
    else
      raise exception 'insufficient permissions';
    end if;
  end if;

  if p_user_id = auth.uid() and caller <> 'CEO' then
    raise exception 'cannot change own role';
  end if;

  update public.profiles set role=p_role, updated_at=now() where id=p_user_id;
  return p_role;
end;
$$;

revoke all on function public.asmar_set_user_role(uuid,public.app_role) from public;
grant execute on function public.asmar_set_user_role(uuid,public.app_role) to authenticated;

-- Keep only the current official role badge when a rank changes.
create or replace function public.asmar_sync_role_badge(p_user_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
declare
  r public.app_role;
  b uuid;
begin
  select role into r from public.profiles where id=p_user_id;
  if r is null then return; end if;

  delete from public.user_badges ub
  using public.badges b0
  where ub.badge_id=b0.id and ub.user_id=p_user_id
    and b0.role is not null and b0.role <> r;

  select id into b from public.badges where role=r and is_active=true limit 1;
  if b is not null then
    insert into public.user_badges(user_id,badge_id,is_equipped)
    values(p_user_id,b,false)
    on conflict (user_id,badge_id) do nothing;
  end if;
end;
$$;
