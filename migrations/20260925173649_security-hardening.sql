-- ============================================================
-- SeniorSalud: hardening de seguridad
--
-- 1. Cada perfil de `users` comparte id con su cuenta en `auth.users`
--    -> auth.uid() == users.id, asi el RLS puede funcionar.
-- 2. RLS: cada usuario solo ve/edita SUS datos; el admin ve todo.
-- 3. Todas las RPC administrativas comprueban el rol en el servidor.
-- 4. Se elimina la copia de contrasenas en texto plano (users.password)
--    y la RPC login_user (oracle de contrasenas).
-- ============================================================

-- ------------------------------------------------------------
-- 0. Limpiar cuentas de prueba creadas durante la validacion
-- ------------------------------------------------------------
DELETE FROM auth.users WHERE email LIKE 'probe%@seniorsalud.app';

-- ------------------------------------------------------------
-- 1. Ayudantes de autorizacion (SECURITY DEFINER -> sin recursion en RLS)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
      AND role = 'admin'
      AND status = 'approved'
  );
$$;

CREATE OR REPLACE FUNCTION public.assert_admin()
RETURNS void
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.new_account(
  p_name text,
  p_username text,
  p_password text,
  p_role text,
  p_status text,
  p_phone text DEFAULT NULL,
  p_age integer DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
  v_email text;
BEGIN
  IF p_password IS NULL OR length(p_password) < 1 THEN
    RAISE EXCEPTION 'La contrasena no puede estar vacia';
  END IF;

  v_email := lower(trim(p_username)) || '@seniorsalud.app';

  IF EXISTS (SELECT 1 FROM users WHERE lower(username) = lower(trim(p_username)))
     OR EXISTS (SELECT 1 FROM auth.users a WHERE lower(a.email) = v_email) THEN
    RAISE EXCEPTION 'El usuario ya existe';
  END IF;

  v_id := gen_random_uuid();

  INSERT INTO auth.users (id, email, password, email_verified, created_at, updated_at, profile, metadata, is_project_admin, is_anonymous)
  VALUES (v_id, v_email, crypt(p_password, gen_salt('bf')), true, now(), now(),
          jsonb_build_object('name', trim(p_name)), '{}'::jsonb, false, false);

  INSERT INTO users (id, name, username, phone, role, status, age, created_at)
  VALUES (v_id, trim(p_name), lower(trim(p_username)), trim(p_phone), p_role, p_status, p_age, now());

  RETURN v_id;
END;
$$;

-- ------------------------------------------------------------
-- 2. Registro publico: SIEMPRE paciente pendiente, con su cuenta de auth
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.register_user(
  p_name text,
  p_username text,
  p_phone text,
  p_password text,
  p_age integer DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
  v_user json;
BEGIN
  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'El nombre es obligatorio';
  END IF;
  IF p_username IS NULL OR trim(p_username) = '' THEN
    RAISE EXCEPTION 'El usuario es obligatorio';
  END IF;

  v_id := public.new_account(p_name, p_username, p_password, 'patient', 'pending', p_phone, p_age);

  SELECT row_to_json(u) INTO v_user FROM users u WHERE u.id = v_id;
  RETURN v_user;
END;
$$;

-- ------------------------------------------------------------
-- 3. RPCs de administracion: exigen admin aprobado
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_create_user(
  p_name text,
  p_username text,
  p_phone text,
  p_password text,
  p_age integer DEFAULT NULL,
  p_role text DEFAULT 'patient',
  p_status text DEFAULT 'approved',
  p_auth_uid uuid DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
  v_user json;
BEGIN
  PERFORM public.assert_admin();
  v_id := public.new_account(p_name, p_username, p_password, p_role, p_status, p_phone, p_age);
  SELECT row_to_json(u) INTO v_user FROM users u WHERE u.id = v_id;
  RETURN v_user;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_update_user_status(p_user_id uuid, p_status text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.assert_admin();
  IF p_status NOT IN ('approved', 'pending', 'rejected') THEN
    RAISE EXCEPTION 'Estado no valido';
  END IF;
  UPDATE users SET status = p_status WHERE id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_user(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- el usuario puede borrarse a si mismo; solo un admin puede borrar a otros
  IF p_user_id <> auth.uid() THEN
    PERFORM public.assert_admin();
  END IF;

  DELETE FROM users WHERE id = p_user_id;
  DELETE FROM auth.users WHERE id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_set_user_password(p_user_id uuid, p_password text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.assert_admin();
  IF p_password IS NULL OR length(p_password) < 1 THEN
    RAISE EXCEPTION 'La contrasena no puede estar vacia';
  END IF;
  UPDATE auth.users
  SET password = crypt(p_password, gen_salt('bf')), updated_at = now()
  WHERE id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Cuenta de acceso no encontrada';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_get_users()
RETURNS json
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_json json;
BEGIN
  PERFORM public.assert_admin();
  SELECT json_agg(row_to_json(u)) INTO v_json FROM (
    SELECT id, name, username, phone, role, status, age, created_at
    FROM users ORDER BY created_at DESC
  ) u;
  RETURN v_json;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_get_all_readings()
RETURNS json
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_json json;
BEGIN
  PERFORM public.assert_admin();
  SELECT json_agg(row_to_json(r)) INTO v_json FROM (
    SELECT r2.id, r2.user_id, r2.systolic, r2.diastolic, r2.heart_rate,
           r2.glucose, r2.weight, r2.temperature, r2.spo2, r2.notes,
           r2.created_at, u.name as user_name, u.username as user_username
    FROM blood_pressure_readings r2
    JOIN users u ON r2.user_id = u.id
    ORDER BY r2.created_at DESC
  ) r;
  RETURN v_json;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_get_all_alerts()
RETURNS json
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_json json;
BEGIN
  PERFORM public.assert_admin();
  SELECT json_agg(row_to_json(a)) INTO v_json FROM (
    SELECT a2.id, a2.user_id, a2.alert_type, a2.message, a2.is_read,
           a2.created_at, u.name as user_name, u.phone as user_phone
    FROM health_alerts a2
    JOIN users u ON a2.user_id = u.id
    ORDER BY a2.created_at DESC
  ) a;
  RETURN v_json;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_get_all_schedules()
RETURNS json
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_json json;
BEGIN
  PERFORM public.assert_admin();
  SELECT json_agg(row_to_json(s)) INTO v_json FROM (
    SELECT s2.id, s2.user_id, s2.scheduled_date, s2.notes, s2.created_at,
           u.name as user_name, u.username as user_username
    FROM bp_schedule s2
    JOIN users u ON s2.user_id = u.id
    ORDER BY s2.scheduled_date ASC
  ) s;
  RETURN v_json;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_add_schedule(
  p_user_id uuid,
  p_date date,
  p_notes text DEFAULT ''
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.assert_admin();
  INSERT INTO bp_schedule (user_id, scheduled_date, notes)
  VALUES (p_user_id, p_date, p_notes)
  ON CONFLICT (user_id, scheduled_date)
  DO UPDATE SET notes = EXCLUDED.notes;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_schedule(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.assert_admin();
  DELETE FROM bp_schedule WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_admin_stats()
RETURNS json
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_json json;
BEGIN
  PERFORM public.assert_admin();
  SELECT json_build_object(
    'totalUsers', (SELECT count(*) FROM users WHERE role = 'patient' AND status = 'approved'),
    'pendingUsers', (SELECT count(*) FROM users WHERE status = 'pending'),
    'criticalAlerts', (SELECT count(*) FROM health_alerts WHERE alert_type = 'critical' AND is_read = false),
    'stableUsers', (SELECT count(*) FROM health_alerts WHERE alert_type = 'stable' AND is_read = false),
    'followUpUsers', (SELECT count(*) FROM health_alerts WHERE alert_type = 'follow_up' AND is_read = false)
  ) INTO v_json;
  RETURN v_json;
END;
$$;

-- ------------------------------------------------------------
-- 4. RPC de usuario: solo los propios datos
-- ------------------------------------------------------------
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
  IF p_user_id <> auth.uid() THEN
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

-- login_user: eliminada (las contrasenas ahora las valida la autenticacion
-- de InsForge con hash bcrypt) y ya no es un oracle de contrasenas.
DROP FUNCTION IF EXISTS public.login_user(text, text);

-- ------------------------------------------------------------
-- 5. Migrar los usuarios existentes a cuentas de autenticacion
--    (id de auth.users = id del perfil)
-- ------------------------------------------------------------
INSERT INTO auth.users (id, email, password, email_verified, created_at, updated_at, profile, metadata, is_project_admin, is_anonymous)
SELECT u.id,
       lower(u.username) || '@seniorsalud.app',
       crypt(u.password, gen_salt('bf')),
       true,
       u.created_at,
       now(),
       jsonb_build_object('name', u.name),
       '{}'::jsonb,
       false,
       false
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM auth.users a WHERE a.id = u.id)
  AND u.password IS NOT NULL
  AND u.username IS NOT NULL;

-- ya no se guarda ninguna contrasena en texto plano en la tabla de perfiles
ALTER TABLE users DROP COLUMN IF EXISTS password;

-- ------------------------------------------------------------
-- 6. RLS: cada usuario solo accede a lo suyo; el admin a todo
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Public access users" ON users;
DROP POLICY IF EXISTS "Public access readings" ON blood_pressure_readings;
DROP POLICY IF EXISTS "Public access alerts" ON health_alerts;
DROP POLICY IF EXISTS "Public access schedule" ON bp_schedule;
DROP POLICY IF EXISTS "Public access medications" ON medications;

CREATE POLICY users_select ON users
  FOR SELECT USING (id = auth.uid() OR public.is_admin());

CREATE POLICY users_update ON users
  FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY users_delete ON users
  FOR DELETE USING (id = auth.uid() OR public.is_admin());

-- INSERT en users: solo via RPC SECURITY DEFINER (register_user / admin_create_user)

CREATE POLICY readings_select ON blood_pressure_readings
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY readings_insert ON blood_pressure_readings
  FOR INSERT WITH CHECK (user_id = auth.uid() OR public.is_admin());
CREATE POLICY readings_update ON blood_pressure_readings
  FOR UPDATE USING (user_id = auth.uid() OR public.is_admin())
  WITH CHECK (user_id = auth.uid() OR public.is_admin());
CREATE POLICY readings_delete ON blood_pressure_readings
  FOR DELETE USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY alerts_select ON health_alerts
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY alerts_insert ON health_alerts
  FOR INSERT WITH CHECK (user_id = auth.uid() OR public.is_admin());
CREATE POLICY alerts_update ON health_alerts
  FOR UPDATE USING (user_id = auth.uid() OR public.is_admin())
  WITH CHECK (user_id = auth.uid() OR public.is_admin());
CREATE POLICY alerts_delete ON health_alerts
  FOR DELETE USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY schedule_select ON bp_schedule
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY schedule_insert ON bp_schedule
  FOR INSERT WITH CHECK (user_id = auth.uid() OR public.is_admin());
CREATE POLICY schedule_update ON bp_schedule
  FOR UPDATE USING (user_id = auth.uid() OR public.is_admin())
  WITH CHECK (user_id = auth.uid() OR public.is_admin());
CREATE POLICY schedule_delete ON bp_schedule
  FOR DELETE USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY medications_select ON medications
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY medications_insert ON medications
  FOR INSERT WITH CHECK (user_id = auth.uid() OR public.is_admin());
CREATE POLICY medications_update ON medications
  FOR UPDATE USING (user_id = auth.uid() OR public.is_admin())
  WITH CHECK (user_id = auth.uid() OR public.is_admin());
CREATE POLICY medications_delete ON medications
  FOR DELETE USING (user_id = auth.uid() OR public.is_admin());
