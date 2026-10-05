-- Runtime room lobby: country filters, admin pinning, and real room creation.
alter table public.rooms add column if not exists country_code text;
alter table public.rooms add column if not exists sort_order integer;
create index if not exists rooms_active_sort_idx on public.rooms(is_active, sort_order, hot_score desc, created_at desc);

create or replace function public.create_room(p_name text,p_country_code text default 'JO',p_seat_count integer default 15,p_cover_url text default null)
returns public.rooms language plpgsql security definer set search_path=public as $$
declare result public.rooms;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if trim(coalesce(p_name,''))='' then raise exception 'ROOM_NAME_REQUIRED'; end if;
  if p_seat_count not in (6,8,10,12,15,20) then raise exception 'INVALID_SEAT_COUNT'; end if;
  insert into public.rooms(name,owner_id,is_active,seat_count,country_code,cover_url,hot_score,livekit_room_name)
  values(trim(p_name),auth.uid(),true,p_seat_count,upper(trim(coalesce(p_country_code,'JO'))),nullif(trim(coalesce(p_cover_url,'')),''),0,'asmar-'||gen_random_uuid()::text)
  returning * into result;
  return result;
end;
$$;
revoke all on function public.create_room(text,text,integer,text) from public;
grant execute on function public.create_room(text,text,integer,text) to authenticated;

create or replace function public.admin_set_room_sort_order(p_room_id uuid,p_sort_order integer)
returns public.rooms language plpgsql security definer set search_path=public as $$
declare result public.rooms;
begin
  if not public.has_role(array['CEO','SUPER_ADMIN','MANAGER','ADMIN']::public.app_role[]) then raise exception 'FORBIDDEN'; end if;
  if p_sort_order is not null and p_sort_order not in (1,2) then raise exception 'SORT_ORDER_MUST_BE_1_OR_2'; end if;
  if p_sort_order is not null then update public.rooms set sort_order=null,updated_at=now() where sort_order=p_sort_order and id<>p_room_id; end if;
  update public.rooms set sort_order=p_sort_order,updated_at=now() where id=p_room_id returning * into result;
  if result.id is null then raise exception 'ROOM_NOT_FOUND'; end if;
  return result;
end;
$$;
revoke all on function public.admin_set_room_sort_order(uuid,integer) from public;
grant execute on function public.admin_set_room_sort_order(uuid,integer) to authenticated;
