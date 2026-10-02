-- Gift statistics and receiver leaderboard.
create or replace function public.gift_stats(p_user_id uuid default auth.uid())
returns table(sent_count bigint, sent_coins bigint, received_count bigint, received_coins bigint)
language sql security definer set search_path=public as $$
  select
    (select count(*) from gift_transactions where sender_id=p_user_id),
    (select coalesce(sum(amount),0) from gift_transactions where sender_id=p_user_id),
    (select count(*) from gift_transactions where recipient_id=p_user_id),
    (select coalesce(sum(amount),0) from gift_transactions where recipient_id=p_user_id);
$$;
create or replace function public.top_gift_receivers(p_limit integer default 20)
returns table(user_id uuid, username text, role app_role, country_code text, vip_level text, gift_count bigint, received_coins bigint)
language sql security definer set search_path=public as $$
  select p.id,p.username,p.role,p.country_code,p.vip_level,count(gt.id),coalesce(sum(gt.amount),0)
  from gift_transactions gt join profiles p on p.id=gt.recipient_id
  group by p.id,p.username,p.role,p.country_code,p.vip_level
  order by coalesce(sum(gt.amount),0) desc, count(gt.id) desc
  limit greatest(1,least(coalesce(p_limit,20),100));
$$;
revoke all on function public.gift_stats(uuid) from public;
revoke all on function public.top_gift_receivers(integer) from public;
grant execute on function public.gift_stats(uuid) to authenticated;
grant execute on function public.top_gift_receivers(integer) to authenticated;
