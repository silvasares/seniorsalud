-- Temporary probe: used to verify that a user JWT (Bearer accessToken)
-- is propagated to Postgres so auth.uid() returns the signed-in user.
CREATE OR REPLACE FUNCTION public.probe_uid()
RETURNS json
LANGUAGE sql
STABLE
AS $$
  SELECT json_build_object(
    'uid', auth.uid(),
    'role', auth.role(),
    'email', auth.email()
  );
$$;
