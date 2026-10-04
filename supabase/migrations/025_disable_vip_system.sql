-- Disable the legacy VIP membership while preserving SVIP.
-- VIP levels remain in the schema for compatibility/history, but are no longer active.
UPDATE public.profiles
SET vip_level = NULL,
    updated_at = now()
WHERE vip_level IS NOT NULL;

UPDATE public.vip_levels
SET is_active = false
WHERE id LIKE 'VIP%';

-- SVIP is intentionally preserved and remains active.
UPDATE public.vip_levels
SET is_active = true
WHERE id = 'SVIP';
