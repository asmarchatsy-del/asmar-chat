revoke execute on function public.admin_delete_company_game_link(uuid) from anon;
revoke execute on function public.admin_upsert_company_game_link(uuid,text,text,text,text,text,boolean,integer) from anon;
revoke execute on function public.asmar_can_manage_role(public.app_role) from anon;
revoke execute on function public.asmar_equip_badge(uuid) from anon;
revoke execute on function public.asmar_profile_role_badge_trigger() from anon;
revoke execute on function public.asmar_set_user_role(uuid,public.app_role) from anon;
revoke execute on function public.asmar_sync_role_badge(uuid) from anon;