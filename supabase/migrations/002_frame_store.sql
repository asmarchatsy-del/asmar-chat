-- Real profile-frame store.
create table if not exists public.frame_items (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  price bigint not null check (price >= 0),
  style_key text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.user_frames (
  user_id uuid not null references public.profiles(id) on delete cascade,
  frame_id uuid not null references public.frame_items(id) on delete cascade,
  purchased_at timestamptz not null default now(),
  primary key (user_id, frame_id)
);
alter table public.frame_items enable row level security;
alter table public.user_frames enable row level security;
drop policy if exists "frame_items_select_active" on public.frame_items;
create policy "frame_items_select_active" on public.frame_items for select to authenticated using (is_active = true);
drop policy if exists "user_frames_select_self" on public.user_frames;
create policy "user_frames_select_self" on public.user_frames for select to authenticated using (user_id = auth.uid());
insert into public.frame_items (name, price, style_key) values
('الإطار الذهبي',500,'gold'),('إطار الماس',1500,'diamond'),('إطار النار',2500,'fire'),('إطار VIP',5000,'vip'),('إطار SVIP',10000,'svip')
on conflict (name) do nothing;
create or replace function public.purchase_frame(p_frame_id uuid)
returns public.user_frames language plpgsql security definer set search_path=public as $$
declare item public.frame_items; balance bigint; result_row public.user_frames;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 select * into item from public.frame_items where id=p_frame_id and is_active=true;
 if item.id is null then raise exception 'frame not found'; end if;
 if exists(select 1 from public.user_frames where user_id=auth.uid() and frame_id=p_frame_id) then raise exception 'frame already owned'; end if;
 select w.balance into balance from public.wallets w where w.user_id=auth.uid() for update;
 if balance is null or balance<item.price then raise exception 'insufficient coins'; end if;
 update public.wallets set balance=balance-item.price,updated_at=now() where user_id=auth.uid();
 insert into public.coin_transactions(from_user_id,to_user_id,amount,reason) values(auth.uid(),null,item.price,'frame_purchase');
 insert into public.user_frames(user_id,frame_id) values(auth.uid(),p_frame_id) returning * into result_row;
 return result_row;
end; $$;
revoke all on function public.purchase_frame(uuid) from public;
grant execute on function public.purchase_frame(uuid) to authenticated;
