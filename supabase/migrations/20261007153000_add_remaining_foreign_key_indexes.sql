-- Cover the final foreign keys reported by Supabase's performance advisor.
create index if not exists idx_blacklist_blocked_user_id on public.blacklist (blocked_user_id);
create index if not exists idx_cp_relations_partner_id on public.cp_relations (partner_id);
create index if not exists idx_family_members_user_id on public.family_members (user_id);
create index if not exists idx_messages_receiver_id on public.messages (receiver_id);
create index if not exists idx_moment_likes_user_id on public.moment_likes (user_id);
create index if not exists idx_room_admins_user_id on public.room_admins (user_id);
create index if not exists idx_room_likes_user_id on public.room_likes (user_id);
create index if not exists idx_room_members_user_id on public.room_members (user_id);
create index if not exists idx_room_treasure_claims_user_id on public.room_treasure_claims (user_id);
create index if not exists idx_siblings_sibling_id on public.siblings (sibling_id);
create index if not exists idx_user_daily_tasks_task_id on public.user_daily_tasks (task_id);
create index if not exists idx_visitors_visitor_id on public.visitors (visitor_id);
