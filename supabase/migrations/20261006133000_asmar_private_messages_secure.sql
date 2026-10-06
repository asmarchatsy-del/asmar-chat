create or replace function public.send_private_message(p_receiver uuid, p_message text)
returns public.messages
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  row_out public.messages;
  body_text text := trim(coalesce(p_message, ''));
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_receiver is null or p_receiver = uid then raise exception 'INVALID_RECEIVER'; end if;
  if body_text = '' then raise exception 'MESSAGE_EMPTY'; end if;
  if char_length(body_text) > 2000 then raise exception 'MESSAGE_TOO_LONG'; end if;
  if not exists(select 1 from public.profiles where id=p_receiver and is_active=true) then
    raise exception 'RECIPIENT_NOT_FOUND';
  end if;
  if exists(
    select 1 from public.blacklist
    where (user_id=uid and blocked_user_id=p_receiver)
       or (user_id=p_receiver and blocked_user_id=uid)
  ) then
    raise exception 'USER_BLOCKED';
  end if;
  insert into public.messages(sender_id, receiver_id, body, message_type)
  values(uid, p_receiver, body_text, 'text')
  returning * into row_out;
  return row_out;
end;
$$;

revoke all on function public.send_private_message(uuid,text) from public;
grant execute on function public.send_private_message(uuid,text) to authenticated;
