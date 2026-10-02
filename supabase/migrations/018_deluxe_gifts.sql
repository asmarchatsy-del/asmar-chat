-- Deluxe gift catalog, admin controls, and public gift ticker.
alter table public.gifts
  add column if not exists category text not null default 'normal',
  add column if not exists banner_enabled boolean not null default false,
  add column if not exists banner_min_price bigint not null default 4000,
  add column if not exists luck_min_win bigint not null default 3000;

create table if not exists public.gift_public_banners(
  id uuid primary key default gen_random_uuid(),
  gift_id text not null references public.gifts(id) on delete cascade,
  amount bigint not null,
  created_at timestamptz not null default now()
);
alter table public.gift_public_banners enable row level security;
drop policy if exists gift_public_banners_select on public.gift_public_banners;
create policy gift_public_banners_select on public.gift_public_banners
for select to authenticated using (true);

do $$ begin
  alter publication supabase_realtime add table public.gift_public_banners;
exception when duplicate_object then null; when undefined_object then null; end $$;

insert into public.gifts(id,name,emoji,price,category,banner_enabled) values
('rose','وردة','🌹',100,'normal',false),
('heart','قلب','❤️',500,'love',false),
('kiss','قبلة','💋',1000,'love',false),
('love_letter','رسالة حب','💌',4000,'love',true),
('love_ring','خاتم حب','💍',10000,'love',true),
('love_couple','ثنائي الحب','💞',50000,'love',true),
('diamond','ماسة','💎',2500,'luxury',false),
('crown','تاج ملكي','👑',10000,'luxury',true),
('royal_car','سيارة ملكية','🚘',50000,'luxury',true),
('gold_castle','قصر ذهبي','🏰',100000,'luxury',true),
('gold_dragon','تنين ذهبي','🐉',250000,'luxury',true),
('royal_throne','عرش ملكي','👑',500000,'luxury',true),
('asmar_kingdom','مملكة Asmar','🏯',1000000,'luxury',true),
('cp','CP','🫶',4000,'cp',true),
('cp_royal','CP ملكي','💎',25000,'cp',true),
('brother','علاقة أخوة','🤝',4000,'brotherhood',true),
('brother_gold','أخوة ذهبية','🫂',25000,'brotherhood',true),
('brother_royal','رابطة إخوة ملكية','🛡️',100000,'brotherhood',true),
('luck_10','حظ 10','🍀',10,'luck',false),
('luck_50','حظ 50','🍀',50,'luck',false),
('luck_100','حظ 100','🍀',100,'luck',false),
('luck_500','حظ 500','🎰',500,'luck',false),
('luck_1000','حظ 1,000','🎰',1000,'luck',false),
('luck_3000','حظ 3,000','✨',3000,'luck',false),
('luck_5000','حظ 5,000','✨',5000,'luck',true),
('dragon','تنين','🐉',10000,'normal',true),
('lion','أسد','🦁',25000,'normal',true),
('supernova','سوبر نوفا','🌌',100000,'luxury',true)
on conflict(id) do update set
 name=excluded.name,emoji=excluded.emoji,price=excluded.price,category=excluded.category,banner_enabled=excluded.banner_enabled;

create or replace function public.send_gift(p_room_id uuid,p_recipient_id text,p_gift_id text)
returns public.gift_transactions language plpgsql security definer set search_path=public as $$
declare g public.gifts; s bigint; r uuid; t public.gift_transactions;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 select * into g from gifts where id=p_gift_id and is_active=true;
 if g.id is null then raise exception 'gift not found'; end if;
 select id into r from profiles where id::text=p_recipient_id or username=p_recipient_id or public_id=p_recipient_id limit 1;
 if r is null then raise exception 'recipient not found'; end if;
 if r=auth.uid() then raise exception 'cannot gift yourself'; end if;
 select balance into s from wallets where user_id=auth.uid() for update;
 if s is null or s<g.price then raise exception 'insufficient coins'; end if;
 update wallets set balance=balance-g.price,updated_at=now() where user_id=auth.uid();
 insert into wallets(user_id,balance) values(r,g.price) on conflict(user_id) do update set balance=wallets.balance+g.price,updated_at=now();
 insert into coin_transactions(from_user_id,to_user_id,amount,reason) values(auth.uid(),r,g.price,'gift:'||g.id);
 insert into gift_transactions(room_id,sender_id,recipient_id,gift_id,amount) values(p_room_id,auth.uid(),r,g.id,g.price) returning * into t;
 if g.banner_enabled and g.price >= greatest(g.banner_min_price,4000) then
   insert into gift_public_banners(gift_id,amount) values(g.id,g.price);
 end if;
 return t;
end; $$;

create or replace function public.admin_update_gift(
 p_id text,p_name text,p_emoji text,p_price bigint,p_category text,p_is_active boolean,
 p_banner_enabled boolean,p_banner_min_price bigint,p_luck_min_win bigint
) returns public.gifts language plpgsql security definer set search_path=public as $$
declare g public.gifts;
begin
 if auth.uid() is null or not public.has_role(array['CEO','SUPER_ADMIN']::public.app_role[]) then raise exception 'not authorized'; end if;
 if p_price < 1 or p_banner_min_price < 0 or p_luck_min_win < 0 then raise exception 'invalid values'; end if;
 update public.gifts set name=p_name,emoji=p_emoji,price=p_price,category=p_category,is_active=p_is_active,
   banner_enabled=p_banner_enabled,banner_min_price=p_banner_min_price,luck_min_win=p_luck_min_win
 where id=p_id returning * into g;
 if g.id is null then raise exception 'gift not found'; end if;
 return g;
end; $$;
revoke all on function public.admin_update_gift(text,text,text,bigint,text,boolean,boolean,bigint,bigint) from public;
grant execute on function public.admin_update_gift(text,text,text,bigint,text,boolean,boolean,bigint,bigint) to authenticated;
