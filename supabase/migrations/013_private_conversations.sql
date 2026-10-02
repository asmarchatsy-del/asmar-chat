-- Private conversation list and unread counters.
create or replace function public.private_conversations() returns table(friend_id uuid,last_message text,last_at timestamptz,unread_count bigint)
language sql security definer set search_path=public as $$
 with msgs as (
  select case when sender_id=auth.uid() then receiver_id else sender_id end as fid,
         message,created_at,receiver_id,read_at
  from private_messages where sender_id=auth.uid() or receiver_id=auth.uid()
 ), ranked as (
  select *,row_number() over(partition by fid order by created_at desc) rn from msgs
 )
 select fid,
        max(message) filter(where rn=1),
        max(created_at) filter(where rn=1),
        count(*) filter(where receiver_id=auth.uid() and read_at is null)
 from ranked group by fid order by max(created_at) desc;
$$;
create or replace function public.mark_private_messages_read(p_friend uuid) returns void language sql security definer set search_path=public as $$
 update private_messages set read_at=now() where receiver_id=auth.uid() and sender_id=p_friend and read_at is null;
$$;
grant execute on function public.private_conversations() to authenticated;
grant execute on function public.mark_private_messages_read(uuid) to authenticated;
