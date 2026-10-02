-- Secure agent recharge by app ID/username.
create table if not exists public.agent_recharges (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references public.profiles(id),
  recipient_id uuid not null references public.profiles(id),
  amount bigint not null check (amount > 0),
  coins_per_usd bigint not null default 10000 check (coins_per_usd > 0),
  created_at timestamptz not null default now()
);

alter table public.agent_recharges enable row level security;

drop policy if exists "agent_recharges_select_involved" on public.agent_recharges;
create policy "agent_recharges_select_involved"
on public.agent_recharges for select to authenticated
using (agent_id = auth.uid() or recipient_id = auth.uid());

create or replace function public.agent_recharge(
  p_recipient_id text,
  p_amount bigint
)
returns public.agent_recharges
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_role public.app_role;
  recipient uuid;
  agent_balance bigint;
  result_row public.agent_recharges;
  rate bigint := 10000;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;

  select role into caller_role from public.profiles
  where id = auth.uid() and is_active = true;

  if caller_role <> 'AGENT' then raise exception 'agent permission required'; end if;
  if p_amount <= 0 then raise exception 'amount must be greater than zero'; end if;

  select id into recipient from public.profiles
  where is_active = true
    and (id::text = trim(p_recipient_id) or username = trim(p_recipient_id))
  limit 1;

  if recipient is null then raise exception 'recipient not found'; end if;
  if recipient = auth.uid() then raise exception 'cannot recharge yourself'; end if;

  select balance into agent_balance from public.wallets
  where user_id = auth.uid() for update;

  if agent_balance is null or agent_balance < p_amount then
    raise exception 'insufficient agent balance';
  end if;

  update public.wallets
  set balance = balance - p_amount, updated_at = now()
  where user_id = auth.uid();

  update public.wallets
  set balance = balance + p_amount, updated_at = now()
  where user_id = recipient;

  insert into public.coin_transactions(from_user_id, to_user_id, amount, reason)
  values (auth.uid(), recipient, p_amount, 'agent_recharge');

  insert into public.agent_recharges(agent_id, recipient_id, amount, coins_per_usd)
  values (auth.uid(), recipient, p_amount, rate)
  returning * into result_row;

  return result_row;
end;
$$;

revoke all on function public.agent_recharge(text,bigint) from public;
grant execute on function public.agent_recharge(text,bigint) to authenticated;
