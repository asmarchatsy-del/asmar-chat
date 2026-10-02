-- Harden editable public IDs and protect the ASMAR owner identity.

create unique index if not exists profiles_public_id_unique_idx
  on public.profiles(public_id)
  where public_id is not null;

create unique index if not exists profiles_single_ceo_idx
  on public.profiles(role)
  where role = 'CEO'::public.app_role;

create or replace function public.protect_public_id()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.public_id is distinct from old.public_id then
    if old.id = '9910c8a7-c89f-4f1c-a49a-1fc978b96824'::uuid
       and new.public_id <> 'ASMAR' then
      raise exception 'ASMAR owner ID is reserved';
    end if;

    if auth.uid() is null
       or not exists (
         select 1
         from public.profiles
         where id = auth.uid()
           and role = 'CEO'::public.app_role
           and is_active = true
       ) then
      raise exception 'Only CEO can change public IDs';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists protect_public_id_changes on public.profiles;
create trigger protect_public_id_changes
before update of public_id on public.profiles
for each row execute function public.protect_public_id();

create or replace function public.admin_set_public_id(p_user_id uuid, p_public_id text)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_value text := trim(p_public_id);
  v_profile public.profiles;
begin
  if auth.uid() is null
     or not public.has_role(array['CEO']::public.app_role[]) then
    raise exception 'Only CEO can change public IDs';
  end if;

  if v_value is null or v_value = '' then
    raise exception 'Public ID cannot be empty';
  end if;

  if length(v_value) > 32 then
    raise exception 'Public ID too long';
  end if;

  if not (v_value ~ '^[A-Za-z0-9_أ-ي]+$') then
    raise exception 'Public ID may contain Arabic/English letters, numbers and underscore only';
  end if;

  if p_user_id = '9910c8a7-c89f-4f1c-a49a-1fc978b96824'::uuid
     and v_value <> 'ASMAR' then
    raise exception 'ASMAR owner ID is reserved';
  end if;

  update public.profiles
     set public_id = v_value, updated_at = now()
   where id = p_user_id
  returning * into v_profile;

  if not found then
    raise exception 'User not found';
  end if;

  if v_value ~ '^[0-9]+$' then
    perform setval(
      'public.user_public_id_seq',
      greatest(
        v_value::bigint,
        coalesce((select last_value from public.user_public_id_seq), 257305)
      ),
      true
    );
  end if;

  return v_profile;
end;
$$;

revoke all on function public.admin_set_public_id(uuid,text) from public, anon;
grant execute on function public.admin_set_public_id(uuid,text) to authenticated;

create or replace function public.admin_set_user_role(
  p_user_id uuid,
  p_role public.app_role
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null
     or not public.has_role(array['CEO']::public.app_role[]) then
    raise exception 'not authorized';
  end if;

  if p_user_id = '9910c8a7-c89f-4f1c-a49a-1fc978b96824'::uuid
     and p_role <> 'CEO'::public.app_role then
    raise exception 'ASMAR owner cannot be demoted';
  end if;

  if p_role = 'CEO'::public.app_role
     and p_user_id <> '9910c8a7-c89f-4f1c-a49a-1fc978b96824'::uuid then
    raise exception 'Only ASMAR can be CEO';
  end if;

  update public.profiles
     set role = p_role, updated_at = now()
   where id = p_user_id;

  return found;
end;
$$;

revoke all on function public.admin_set_user_role(uuid,public.app_role) from public, anon;
grant execute on function public.admin_set_user_role(uuid,public.app_role) to authenticated;

-- Keep SECURITY DEFINER RPCs off the anonymous/public API surface.
do $$
declare r record;
begin
  for r in
    select p.oid, n.nspname, p.proname,
           pg_get_function_identity_arguments(p.oid) as args
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prosecdef
  loop
    execute format('revoke execute on function %I.%I(%s) from anon, public',
      r.nspname, r.proname, r.args);
    if r.proname <> 'rls_auto_enable' then
      execute format('grant execute on function %I.%I(%s) to authenticated',
        r.nspname, r.proname, r.args);
    end if;
  end loop;
end $$;

-- Cover foreign keys used by joins, RLS checks, and dashboard lookups.
create index if not exists agencies_bd_id_idx on public.agencies(bd_id);
create index if not exists agencies_manager_id_idx on public.agencies(manager_id);
create index if not exists agencies_opened_by_idx on public.agencies(opened_by);
create index if not exists agencies_owner_id_idx on public.agencies(owner_id);
create index if not exists agencies_super_admin_id_idx on public.agencies(super_admin_id);
create index if not exists agency_commission_ledger_agency_id_idx on public.agency_commission_ledger(agency_id);
create index if not exists agent_recharges_agent_id_idx on public.agent_recharges(agent_id);
create index if not exists agent_recharges_recipient_id_idx on public.agent_recharges(recipient_id);
create index if not exists coin_transactions_from_user_id_idx on public.coin_transactions(from_user_id);
create index if not exists coin_transactions_to_user_id_idx on public.coin_transactions(to_user_id);
create index if not exists host_earnings_agency_id_idx on public.host_earnings(agency_id);
create index if not exists rooms_owner_id_idx on public.rooms(owner_id);
