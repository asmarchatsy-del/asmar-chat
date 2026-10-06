revoke execute on function public.asmar_prepare_room(uuid) from anon, authenticated, public;
revoke execute on function public.asmar_sync_role_badge(uuid) from anon, authenticated, public;
revoke execute on function public.ensure_room_seats(uuid) from anon, authenticated, public;
revoke execute on function public.record_agency_work(uuid,bigint) from anon, authenticated, public;
revoke execute on function public.record_svip_recharge(uuid,bigint) from anon, authenticated, public;
