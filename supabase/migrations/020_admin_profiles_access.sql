-- Allow the authenticated admin dashboard to read profiles safely.
-- The dashboard still checks that the current user's profile role is CEO/SUPER_ADMIN.

GRANT SELECT ON TABLE public.profiles TO authenticated;

DROP POLICY IF EXISTS "admin_profiles_select" ON public.profiles;
CREATE POLICY "admin_profiles_select"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  id = (select auth.uid())
  OR public.has_role(ARRAY['CEO','SUPER_ADMIN']::public.app_role[])
);
