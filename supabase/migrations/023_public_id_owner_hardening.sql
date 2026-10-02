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
