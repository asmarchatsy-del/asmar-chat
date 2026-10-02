-- Private 1-to-1 messaging between friends.
create table if not exists public.private_messages(
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references public.profiles(id) on delete cascade,
 receiver_id uuid not null references public.profiles(id) on delete cascade,
 message text not null check(length(trim(message)) between 1 and 2000),
 created_at timestamptz not null default now(),
 read_at timestamptz
);
create index if not exists private_messages_pair_idx on public.private_messages(sender_id,receiver_id,created_at desc);
alter table public.private_messages enable row level security;
create policy "private_messages_select_own" on public.private_messages for select to authenticated using(sender_id=auth.uid() or receiver_id=auth.uid());
create policy "private_messages_insert_sender" on public.private_messages for insert to authenticated with check(sender_id=auth.uid() and exists(select 1 from friendships f where f.user_id=auth.uid() and f.friend_id=receiver_id));
create policy "private_messages_update_receiver" on public.private_messages for update to authenticated using(receiver_id=auth.uid()) with check(receiver_id=auth.uid());
create or replace function public.send_private_message(p_receiver uuid,p_message text) returns uuid language plpgsql security definer set search_path=public as $$
declare mid uuid;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 if p_receiver=auth.uid() then raise exception 'cannot message yourself'; end if;
 if not exists(select 1 from friendships where user_id=auth.uid() and friend_id=p_receiver) then raise exception 'not friends'; end if;
 insert into private_messages(sender_id,receiver_id,message) values(auth.uid(),p_receiver,trim(p_message)) returning id into mid;
 insert into notifications(user_id,type,title,body,data) values(p_receiver,'private_message','💬 رسالة جديدة','لديك رسالة خاصة جديدة',jsonb_build_object('message_id',mid,'sender_id',auth.uid()));
 return mid;
end; $$;
grant execute on function public.send_private_message(uuid,text) to authenticated;
alter publication supabase_realtime add table public.private_messages;
