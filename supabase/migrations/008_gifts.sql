-- Real room gifts.
create table if not exists public.gifts(id text primary key,name text not null,emoji text not null,price bigint not null check(price>0),is_active boolean not null default true);
create table if not exists public.gift_transactions(id uuid primary key default gen_random_uuid(),room_id uuid not null references public.rooms(id) on delete cascade,sender_id uuid not null references public.profiles(id),recipient_id uuid not null references public.profiles(id),gift_id text not null references public.gifts(id),amount bigint not null,created_at timestamptz not null default now());
alter table public.gifts enable row level security; alter table public.gift_transactions enable row level security;
create policy "gifts_select_active" on public.gifts for select to authenticated using(is_active=true);
create policy "gift_transactions_select_self" on public.gift_transactions for select to authenticated using(sender_id=auth.uid() or recipient_id=auth.uid());
insert into public.gifts(id,name,emoji,price) values('rose','وردة','🌹',100),('heart','قلب','❤️',500),('diamond','ماسة','💎',1000),('crown','تاج','👑',5000),('dragon','تنين','🐉',10000),('lion','أسد','🦁',25000) on conflict(id) do update set name=excluded.name,emoji=excluded.emoji,price=excluded.price;
create or replace function public.send_gift(p_room_id uuid,p_recipient_id text,p_gift_id text) returns public.gift_transactions language plpgsql security definer set search_path=public as $$
declare g public.gifts; s bigint; r uuid; t public.gift_transactions;
begin
if auth.uid() is null then raise exception 'not authenticated'; end if;
select * into g from gifts where id=p_gift_id and is_active=true;
if g.id is null then raise exception 'gift not found'; end if;
select id into r from profiles where id::text=p_recipient_id or username=p_recipient_id limit 1;
if r is null then raise exception 'recipient not found'; end if;
if r=auth.uid() then raise exception 'cannot gift yourself'; end if;
select balance into s from wallets where user_id=auth.uid() for update;
if s is null or s<g.price then raise exception 'insufficient coins'; end if;
update wallets set balance=balance-g.price,updated_at=now() where user_id=auth.uid();
insert into wallets(user_id,balance) values(r,g.price) on conflict(user_id) do update set balance=wallets.balance+g.price,updated_at=now();
insert into coin_transactions(from_user_id,to_user_id,amount,reason) values(auth.uid(),r,g.price,'gift:'||g.id);
insert into gift_transactions(room_id,sender_id,recipient_id,gift_id,amount) values(p_room_id,auth.uid(),r,g.id,g.price) returning * into t;
return t;
end; $$;
revoke all on function public.send_gift(uuid,text,text) from public;
grant execute on function public.send_gift(uuid,text,text) to authenticated;
