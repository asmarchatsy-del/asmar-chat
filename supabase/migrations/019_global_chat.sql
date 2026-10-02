create table if not exists public.global_chat_messages(
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references auth.users(id) on delete cascade,
 message text not null check (char_length(trim(message)) between 1 and 1000),
 created_at timestamptz not null default now()
);
create index if not exists global_chat_messages_created_idx on public.global_chat_messages(created_at desc);
alter table public.global_chat_messages enable row level security;
drop policy if exists global_chat_select on public.global_chat_messages;
create policy global_chat_select on public.global_chat_messages for select to authenticated using (true);
drop policy if exists global_chat_insert on public.global_chat_messages;
create policy global_chat_insert on public.global_chat_messages for insert to authenticated with check (sender_id=auth.uid());
do $$ begin alter publication supabase_realtime add table public.global_chat_messages; exception when duplicate_object then null; when undefined_object then null; end $$;
grant select,insert on public.global_chat_messages to authenticated;
