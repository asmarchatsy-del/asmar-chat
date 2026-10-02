-- Global public chat: 200 coins per sent message
create table if not exists public.global_chat_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  message text not null check (char_length(trim(message)) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index if not exists global_chat_messages_created_at_idx
  on public.global_chat_messages(created_at desc);

alter table public.global_chat_messages enable row level security;

drop policy if exists "authenticated_read_global_chat" on public.global_chat_messages;
create policy "authenticated_read_global_chat"
on public.global_chat_messages for select
to authenticated
using (true);

create or replace function public.send_global_chat_message(p_message text)
returns public.global_chat_messages
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_message text := trim(p_message);
  v_row public.global_chat_messages;
  v_balance bigint;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  if char_length(v_message) < 1 or char_length(v_message) > 1000 then
    raise exception 'INVALID_MESSAGE';
  end if;

  select coin_balance into v_balance
  from public.wallets
  where user_id = v_user
  for update;

  if coalesce(v_balance, 0) < 200 then
    raise exception 'INSUFFICIENT_COINS';
  end if;

  update public.wallets
  set coin_balance = coin_balance - 200
  where user_id = v_user;

  insert into public.coin_transactions(user_id, amount, transaction_type, description)
  values (v_user, -200, 'global_chat', 'رسالة دردشة عامة');

  insert into public.global_chat_messages(sender_id, message)
  values (v_user, v_message)
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.send_global_chat_message(text) from public;
grant execute on function public.send_global_chat_message(text) to authenticated;

alter table public.global_chat_messages replica identity full;
do $$
begin
  alter publication supabase_realtime add table public.global_chat_messages;
exception when duplicate_object then
  null;
end $$;
