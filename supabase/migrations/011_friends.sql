-- Friends / follow requests with notifications.
create table if not exists public.friend_requests(
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references public.profiles(id) on delete cascade,
 receiver_id uuid not null references public.profiles(id) on delete cascade,
 status text not null default 'pending' check(status in ('pending','accepted','rejected','cancelled')),
 created_at timestamptz not null default now(),
 responded_at timestamptz
);
create unique index if not exists friend_pending_unique on public.friend_requests(sender_id,receiver_id) where status='pending';
create table if not exists public.friendships(
 user_id uuid not null references public.profiles(id) on delete cascade,
 friend_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(user_id,friend_id)
);
alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
create policy "friend_requests_select_own" on public.friend_requests for select to authenticated using(sender_id=auth.uid() or receiver_id=auth.uid());
create policy "friend_requests_insert_self" on public.friend_requests for insert to authenticated with check(sender_id=auth.uid() and sender_id<>receiver_id);
create policy "friend_requests_update_receiver" on public.friend_requests for update to authenticated using(receiver_id=auth.uid()) with check(receiver_id=auth.uid());
create policy "friendships_select_own" on public.friendships for select to authenticated using(user_id=auth.uid());
create or replace function public.send_friend_request(p_receiver text) returns uuid language plpgsql security definer set search_path=public as $$
declare r uuid; rid uuid;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 select id into r from profiles where id::text=p_receiver or username=p_receiver limit 1;
 if r is null then raise exception 'user not found'; end if;
 if r=auth.uid() then raise exception 'cannot add yourself'; end if;
 if exists(select 1 from friendships where user_id=auth.uid() and friend_id=r) then raise exception 'already friends'; end if;
 select id into rid from friend_requests where sender_id=auth.uid() and receiver_id=r and status='pending' limit 1;
 if rid is not null then return rid; end if;
 insert into friend_requests(sender_id,receiver_id) values(auth.uid(),r) returning id into rid;
 insert into notifications(user_id,type,title,body,data) values(r,'friend_request','👥 طلب صداقة جديد','لديك طلب صداقة جديد',jsonb_build_object('request_id',rid,'sender_id',auth.uid()));
 return rid;
end; $$;
create or replace function public.respond_friend_request(p_request uuid,p_accept boolean) returns void language plpgsql security definer set search_path=public as $$
declare r friend_requests;
begin
 select * into r from friend_requests where id=p_request and receiver_id=auth.uid() and status='pending' for update;
 if r.id is null then raise exception 'request not found'; end if;
 update friend_requests set status=case when p_accept then 'accepted' else 'rejected' end,responded_at=now() where id=r.id;
 if p_accept then
   insert into friendships(user_id,friend_id) values(r.sender_id,r.receiver_id),(r.receiver_id,r.sender_id) on conflict do nothing;
   insert into notifications(user_id,type,title,body,data) values(r.sender_id,'friend_accepted','🤝 تم قبول طلب الصداقة','تم قبول طلب الصداقة الخاص بك',jsonb_build_object('friend_id',r.receiver_id));
 end if;
end; $$;
grant execute on function public.send_friend_request(text) to authenticated;
grant execute on function public.respond_friend_request(uuid,boolean) to authenticated;
