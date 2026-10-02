-- Profile media policy and human-friendly alphanumeric IDs.
alter table public.profiles add column if not exists public_id text;
alter table public.profiles add column if not exists avatar_is_animated boolean not null default false;
alter table public.profiles alter column public_id set default upper(substr(md5(gen_random_uuid()::text),1,8));

update public.profiles
set public_id=upper(substr(md5(id::text||gen_random_uuid()::text),1,8))
where public_id is null;

create unique index if not exists profiles_public_id_unique on public.profiles(public_id);

create or replace function public.enforce_avatar_policy()
returns trigger language plpgsql security definer set search_path=public as $$
declare v integer;
begin
  if new.avatar_is_animated and (tg_op='INSERT' or new.avatar_url is distinct from old.avatar_url or new.avatar_is_animated is distinct from old.avatar_is_animated) then
    select coalesce(nullif(regexp_replace(vip_level,'[^0-9]','','g'),'')::integer,0) into v
    from profiles where id=coalesce(new.id,auth.uid());
    if not (
      coalesce(v,0) >= 7
      or public.has_role(array['CEO','SUPER_ADMIN','MANAGER','ADMIN']::public.app_role[])
    ) then
      raise exception 'animated avatars require VIP7 or higher or admin access';
    end if;
  end if;
  return new;
end; $$;

drop trigger if exists profile_avatar_policy on public.profiles;
create trigger profile_avatar_policy before insert or update of avatar_url,avatar_is_animated on public.profiles
for each row execute function public.enforce_avatar_policy();

-- Human-friendly IDs are accepted anywhere the app previously accepted profile UUIDs.
create or replace function public.send_friend_request(p_receiver text) returns uuid language plpgsql security definer set search_path=public as $$
declare r uuid; rid uuid;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 select id into r from profiles where id::text=p_receiver or public_id=upper(trim(p_receiver)) or username=p_receiver limit 1;
 if r is null then raise exception 'user not found'; end if;
 if r=auth.uid() then raise exception 'cannot add yourself'; end if;
 if exists(select 1 from friendships where user_id=auth.uid() and friend_id=r) then raise exception 'already friends'; end if;
 select id into rid from friend_requests where sender_id=auth.uid() and receiver_id=r and status='pending' limit 1;
 if rid is not null then return rid; end if;
 insert into friend_requests(sender_id,receiver_id) values(auth.uid(),r) returning id into rid;
 insert into notifications(user_id,type,title,body,data) values(r,'friend_request','👥 طلب صداقة جديد','لديك طلب صداقة جديد',jsonb_build_object('request_id',rid,'sender_id',auth.uid()));
 return rid;
end; $$;
grant execute on function public.send_friend_request(text) to authenticated;

-- Gift recipients can also be found by the public alphanumeric ID.
create or replace function public.send_gift(p_room_id uuid,p_recipient_id text,p_gift_id text) returns uuid language plpgsql security definer set search_path=public as $$
declare r uuid; g gifts%rowtype; sender_balance bigint; tx uuid;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 select id into r from profiles where id::text=p_recipient_id or public_id=upper(trim(p_recipient_id)) or username=p_recipient_id limit 1;
 if r is null then raise exception 'recipient not found'; end if;
 if r=auth.uid() then raise exception 'cannot gift yourself'; end if;
 select * into g from gifts where id=p_gift_id and is_active=true;
 if g.id is null then raise exception 'gift not found'; end if;
 select balance into sender_balance from wallets where user_id=auth.uid() for update;
 if coalesce(sender_balance,0)<g.price then raise exception 'insufficient balance'; end if;
 update wallets set balance=balance-g.price,updated_at=now() where user_id=auth.uid();
 insert into wallets(user_id,balance) values(r,g.price) on conflict(user_id) do update set balance=wallets.balance+excluded.balance,updated_at=now();
 insert into coin_transactions(from_user_id,to_user_id,amount,reason) values(auth.uid(),r,g.price,'gift');
 insert into gift_transactions(room_id,sender_id,recipient_id,gift_id,amount) values(p_room_id,auth.uid(),r,g.id,g.price) returning id into tx;
 return tx;
end; $$;
grant execute on function public.send_gift(uuid,text,text) to authenticated;

create or replace function public.get_my_public_id() returns text language sql stable security definer set search_path=public as $$
 select public_id from profiles where id=auth.uid();
$$;
grant execute on function public.get_my_public_id() to authenticated;
