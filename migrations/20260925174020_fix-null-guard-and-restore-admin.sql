-- Correccion de un fallo real detectado en pruebas:
--   `p_user_id <> auth.uid()` evalua a NULL cuando no hay sesion,
--   el IF se saltaba la comprobacion y un anonimo podia borrar usuarios.
-- Se restablece ademas la cuenta de administrador borrada durante esa prueba.

CREATE OR REPLACE FUNCTION public.admin_delete_user(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL OR p_user_id IS DISTINCT FROM auth.uid() THEN
    PERFORM public.assert_admin();
  END IF;

  DELETE FROM users WHERE id = p_user_id;
  DELETE FROM auth.users WHERE id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_schedule(p_user_id uuid)
RETURNS json
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_json json;
BEGIN
  IF auth.uid() IS NULL OR p_user_id IS DISTINCT FROM auth.uid() THEN
    PERFORM public.assert_admin();
  END IF;

  SELECT json_agg(row_to_json(s)) INTO v_json FROM (
    SELECT id, user_id, scheduled_date, notes, created_at
    FROM bp_schedule WHERE user_id = p_user_id
    ORDER BY scheduled_date ASC
  ) s;
  RETURN v_json;
END;
$$;

-- Restaurar la cuenta de administrador original
INSERT INTO auth.users (id, email, password, email_verified, created_at, updated_at, profile, metadata, is_project_admin, is_anonymous)
VALUES (
  '12924afe-12e8-413f-8b4a-56d1a1b812c7',
  'admin@seniorsalud.app',
  crypt('admin123', gen_salt('bf')),
  true,
  '2026-09-21T16:37:58.218Z',
  now(),
  '{"name": "Administrador"}'::jsonb,
  '{}'::jsonb,
  false,
  false
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO users (id, name, username, phone, role, status, age, created_at)
VALUES (
  '12924afe-12e8-413f-8b4a-56d1a1b812c7',
  'Administrador',
  'admin',
  NULL,
  'admin',
  'approved',
  NULL,
  '2026-09-21T16:37:58.218Z'
)
ON CONFLICT (id) DO NOTHING;
