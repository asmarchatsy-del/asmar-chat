-- Extend Asmar's official organizational role enum.
alter type public.app_role add value if not exists 'BD';
alter type public.app_role add value if not exists 'COIN_SELLER';
