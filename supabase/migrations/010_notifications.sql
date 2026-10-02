-- Real in-app notifications.
create table if not exists public.notifications(
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 type text not null, title text not null, body text not null, data jsonb not null default '{}'::jsonb,
 is_read boolean not null default false, created_at timestamptz not null default now()
);
create index if not exists notifications_user_created_idx on public.notifications(user_id,created_at desc);
alter table public.notifications enable row level security;
create policy "notifications_select_own" on public.notifications for select to authenticated using(user_id=auth.uid());
create policy "notifications_update_own" on public.notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "notifications_insert_admin" on public.notifications for insert to authenticated with check(public.has_role(array['CEO','SUPER_ADMIN','MANAGER','ADMIN']::public.app_role[]));
create or replace function public.notify_gift() returns trigger language plpgsql security definer set search_path=public as $$
declare n text; e text;
begin select name,emoji into n,e from gifts where id=new.gift_id; insert into notifications(user_id,type,title,body,data) values(new.recipient_id,'gift','🎁 هدية جديدة','استلمت '||coalesce(n,new.gift_id)||' بقيمة '||new.amount||' 🪙',jsonb_build_object('room_id',new.room_id,'sender_id',new.sender_id,'gift_id',new.gift_id,'amount',new.amount,'emoji',coalesce(e,'🎁'))); return new; end; $$;
drop trigger if exists gift_notification_trigger on public.gift_transactions;
create trigger gift_notification_trigger after insert on public.gift_transactions for each row execute function public.notify_gift();
create or replace function public.mark_notification_read(p_id uuid) returns void language sql security definer set search_path=public as $$ update notifications set is_read=true where id=p_id and user_id=auth.uid(); $$;
grant execute on function public.mark_notification_read(uuid) to authenticated;
