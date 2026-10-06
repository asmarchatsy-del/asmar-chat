-- Production runtime hardening and Ayome-style social features.
-- Applied to Supabase production on 2026-10-07 and tracked here for reproducibility.

create table if not exists public.room_treasure_boxes (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  created_by uuid not null references public.profiles(id) on delete cascade,
  total_coins bigint not null check (total_coins > 0),
  remaining_coins bigint not null check (remaining_coins >= 0),
  max_claims integer not null check (max_claims between 1 and 1000),
  remaining_claims integer not null check (remaining_claims >= 0),
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  check (remaining_coins <= total_coins),
  check (remaining_claims <= max_claims)
);

create table if not exists public.room_treasure_claims (
  id uuid primary key default gen_random_uuid(),
  box_id uuid not null references public.room_treasure_boxes(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount bigint not null check (amount > 0),
  created_at timestamptz not null default now(),
  unique (box_id, user_id)
);

alter table public.room_treasure_boxes enable row level security;
alter table public.room_treasure_claims enable row level security;
revoke all on public.room_treasure_boxes from anon, authenticated;
revoke all on public.room_treasure_claims from anon, authenticated;

create or replace function public.asmar_create_family(p_name text, p_description text default '', p_avatar_url text default null)
returns uuid language plpgsql security definer set search_path=''
as $$ declare v_uid uuid := auth.uid(); v_family uuid;
begin
  if v_uid is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if length(trim(coalesce(p_name,''))) not between 2 and 40 then raise exception 'INVALID_FAMILY_NAME'; end if;
  if exists(select 1 from public.family_members where user_id=v_uid) then raise exception 'ALREADY_IN_FAMILY'; end if;
  insert into public.families(name,owner_id,avatar_url,description)
  values(trim(p_name),v_uid,nullif(trim(p_avatar_url),''),left(coalesce(p_description,''),300))
  returning id into v_family;
  insert into public.family_members(family_id,user_id,role) values(v_family,v_uid,'owner');
  return v_family;
end $$;

create or replace function public.asmar_join_family(p_family_id uuid)
returns boolean language plpgsql security definer set search_path=''
as $$ declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not exists(select 1 from public.families where id=p_family_id) then raise exception 'FAMILY_NOT_FOUND'; end if;
  if exists(select 1 from public.family_members where user_id=v_uid) then raise exception 'ALREADY_IN_FAMILY'; end if;
  insert into public.family_members(family_id,user_id,role) values(p_family_id,v_uid,'member');
  return true;
end $$;

create or replace function public.asmar_leave_family()
returns boolean language plpgsql security definer set search_path=''
as $$ declare v_uid uuid := auth.uid(); v_family uuid; v_role text;
begin
  if v_uid is null then raise exception 'NOT_AUTHENTICATED'; end if;
  select family_id,role into v_family,v_role from public.family_members where user_id=v_uid;
  if v_family is null then return false; end if;
  if v_role='owner' then raise exception 'OWNER_CANNOT_LEAVE'; end if;
  delete from public.family_members where user_id=v_uid;
  return true;
end $$;

create or replace function public.asmar_request_cp(p_partner_id uuid)
returns uuid language plpgsql security definer set search_path=''
as $$ declare v_uid uuid := auth.uid(); v_id uuid;
begin
  if v_uid is null or p_partner_id is null or p_partner_id=v_uid then raise exception 'INVALID_PARTNER'; end if;
  if not exists(select 1 from public.profiles where id=p_partner_id and is_active=true) then raise exception 'PARTNER_NOT_FOUND'; end if;
  if exists(select 1 from public.cp_relations where status='accepted' and ((requester_id=v_uid and partner_id=p_partner_id) or (requester_id=p_partner_id and partner_id=v_uid))) then raise exception 'CP_ALREADY_ACTIVE'; end if;
  insert into public.cp_relations(requester_id,partner_id,status) values(v_uid,p_partner_id,'pending') on conflict do nothing returning id into v_id;
  if v_id is null then raise exception 'CP_REQUEST_EXISTS'; end if;
  return v_id;
end $$;

create or replace function public.asmar_respond_cp(p_relation_id uuid,p_accept boolean)
returns boolean language plpgsql security definer set search_path=''
as $$ declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'NOT_AUTHENTICATED'; end if;
  update public.cp_relations set status=case when p_accept then 'accepted' else 'rejected' end, accepted_at=case when p_accept then now() else null end
  where id=p_relation_id and partner_id=v_uid and status='pending';
  if not found then raise exception 'CP_REQUEST_NOT_FOUND'; end if;
  return true;
end $$;

create or replace function public.asmar_weekly_gift_leaderboard(p_limit integer default 20)
returns table(rank_no bigint,user_id uuid,display_name text,avatar_url text,score bigint)
language sql security definer set search_path=''
as $$
  with ranked as (
    select gt.recipient_id user_id,coalesce(p.display_name,p.username,'') display_name,p.avatar_url,
           sum(gt.amount)::bigint score,row_number() over(order by sum(gt.amount) desc,gt.recipient_id) rn
    from public.gift_transactions gt join public.profiles p on p.id=gt.recipient_id
    where gt.created_at >= date_trunc('week',now())
    group by gt.recipient_id,p.display_name,p.username,p.avatar_url
  )
  select rn,user_id,display_name,avatar_url,score from ranked where rn <= greatest(1,least(p_limit,100)) order by rn;
$$;

create or replace function public.asmar_create_room_treasure_box(p_room_id uuid,p_total_coins bigint,p_claims integer,p_minutes integer default 30)
returns uuid language plpgsql security definer set search_path=''
as $$ declare v_uid uuid := auth.uid(); v_id uuid;
begin
  if v_uid is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if p_total_coins < 100 or p_claims < 1 or p_claims > 1000 or p_total_coins < p_claims then raise exception 'INVALID_TREASURE_BOX'; end if;
  if p_minutes < 1 or p_minutes > 1440 then raise exception 'INVALID_EXPIRY'; end if;
  if not exists(select 1 from public.rooms r where r.id=p_room_id and r.is_active and
      (r.owner_id=v_uid or exists(select 1 from public.room_admins ra where ra.room_id=r.id and ra.user_id=v_uid))) then raise exception 'ROOM_ADMIN_REQUIRED'; end if;
  insert into public.room_treasure_boxes(room_id,created_by,total_coins,remaining_coins,max_claims,remaining_claims,expires_at)
  values(p_room_id,v_uid,p_total_coins,p_total_coins,p_claims,p_claims,now()+(p_minutes||' minutes')::interval) returning id into v_id;
  return v_id;
end $$;

create or replace function public.asmar_claim_room_treasure_box(p_box_id uuid)
returns bigint language plpgsql security definer set search_path=''
as $$ declare v_uid uuid := auth.uid(); v_box public.room_treasure_boxes%rowtype; v_amount bigint;
begin
  if v_uid is null then raise exception 'NOT_AUTHENTICATED'; end if;
  select * into v_box from public.room_treasure_boxes where id=p_box_id for update;
  if not found then raise exception 'TREASURE_BOX_NOT_FOUND'; end if;
  if v_box.expires_at < now() or v_box.remaining_claims <= 0 or v_box.remaining_coins <= 0 then raise exception 'TREASURE_BOX_EMPTY'; end if;
  if not exists(select 1 from public.room_members where room_id=v_box.room_id and user_id=v_uid and left_at is null)
     and not exists(select 1 from public.rooms where id=v_box.room_id and owner_id=v_uid) then raise exception 'ROOM_MEMBERSHIP_REQUIRED'; end if;
  if exists(select 1 from public.room_treasure_claims where box_id=p_box_id and user_id=v_uid) then raise exception 'ALREADY_CLAIMED'; end if;
  if v_box.remaining_claims=1 then v_amount:=v_box.remaining_coins;
  else v_amount:=greatest(1,least(v_box.remaining_coins-(v_box.remaining_claims-1),1+floor(random()*greatest(1,(v_box.remaining_coins/v_box.remaining_claims)*2))::bigint)); end if;
  insert into public.wallets(user_id,balance) values(v_uid,0) on conflict(user_id) do nothing;
  update public.wallets set balance=balance+v_amount,updated_at=now() where user_id=v_uid;
  insert into public.room_treasure_claims(box_id,user_id,amount) values(p_box_id,v_uid,v_amount);
  update public.room_treasure_boxes set remaining_coins=remaining_coins-v_amount,remaining_claims=remaining_claims-1 where id=p_box_id;
  insert into public.wallet_transactions(user_id,amount,transaction_type,reference_id,description)
  values(v_uid,v_amount,'treasure_box',p_box_id,'Room treasure box reward');
  return v_amount;
end $$;

revoke execute on function public.asmar_create_family(text,text,text) from public,anon; grant execute on function public.asmar_create_family(text,text,text) to authenticated;
revoke execute on function public.asmar_join_family(uuid) from public,anon; grant execute on function public.asmar_join_family(uuid) to authenticated;
revoke execute on function public.asmar_leave_family() from public,anon; grant execute on function public.asmar_leave_family() to authenticated;
revoke execute on function public.asmar_request_cp(uuid) from public,anon; grant execute on function public.asmar_request_cp(uuid) to authenticated;
revoke execute on function public.asmar_respond_cp(uuid,boolean) from public,anon; grant execute on function public.asmar_respond_cp(uuid,boolean) to authenticated;
revoke execute on function public.asmar_weekly_gift_leaderboard(integer) from public,anon; grant execute on function public.asmar_weekly_gift_leaderboard(integer) to authenticated;
revoke execute on function public.asmar_create_room_treasure_box(uuid,bigint,integer,integer) from public,anon; grant execute on function public.asmar_create_room_treasure_box(uuid,bigint,integer,integer) to authenticated;
revoke execute on function public.asmar_claim_room_treasure_box(uuid) from public,anon; grant execute on function public.asmar_claim_room_treasure_box(uuid) to authenticated;