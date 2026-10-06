-- Asmar company game catalog and room launch links.
-- External links are informational/game launch links only; no real-money wagering or cash-out is implemented here.

create table if not exists public.company_game_links (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 1 and 120),
  provider text not null default 'Asmar',
  url text not null check (url ~* '^https://'),
  icon_url text,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists company_game_links_active_idx
  on public.company_game_links(is_active, sort_order, created_at desc);

alter table public.company_game_links enable row level security;

drop policy if exists company_game_links_select_active on public.company_game_links;
create policy company_game_links_select_active
on public.company_game_links for select to authenticated
using (is_active = true);

create or replace function public.admin_upsert_company_game_link(
  p_id uuid default null,
  p_name text default null,
  p_provider text default 'Asmar',
  p_url text default null,
  p_icon_url text default null,
  p_description text default null,
  p_is_active boolean default true,
  p_sort_order integer default 0
)
returns public.company_game_links
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare r public.company_game_links;
begin
  if not public.has_role(array['CEO','SUPER_ADMIN','MANAGER']::public.app_role[]) then
    raise exception 'FORBIDDEN';
  end if;
  if coalesce(trim(p_name),'') = '' then raise exception 'GAME_NAME_REQUIRED'; end if;
  if coalesce(trim(p_url),'') !~* '^https://' then raise exception 'GAME_URL_MUST_BE_HTTPS'; end if;

  if p_id is null then
    insert into public.company_game_links(name,provider,url,icon_url,description,is_active,sort_order,created_by)
    values(trim(p_name),coalesce(nullif(trim(p_provider),''),'Asmar'),trim(p_url),nullif(trim(p_icon_url),''),nullif(trim(p_description),''),coalesce(p_is_active,true),coalesce(p_sort_order,0),auth.uid())
    returning * into r;
  else
    update public.company_game_links
    set name=trim(p_name),
        provider=coalesce(nullif(trim(p_provider),''),'Asmar'),
        url=trim(p_url),
        icon_url=nullif(trim(p_icon_url),''),
        description=nullif(trim(p_description),''),
        is_active=coalesce(p_is_active,true),
        sort_order=coalesce(p_sort_order,0),
        updated_at=now()
    where id=p_id
    returning * into r;
    if r.id is null then raise exception 'GAME_LINK_NOT_FOUND'; end if;
  end if;
  return r;
end;
$$;

create or replace function public.admin_delete_company_game_link(p_id uuid)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  select case
    when not public.has_role(array['CEO','SUPER_ADMIN','MANAGER']::public.app_role[])
      then public.raise_exception('FORBIDDEN')
    else null
  end;
  delete from public.company_game_links where id=p_id;
$$;

grant execute on function public.admin_upsert_company_game_link(uuid,text,text,text,text,text,boolean,integer) to authenticated;
grant execute on function public.admin_delete_company_game_link(uuid) to authenticated;
