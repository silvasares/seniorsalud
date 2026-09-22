-- Fix RLS policies so users can only see their own data
-- Uses a custom session variable set by the app after login

-- 1. Create a function to set the current user ID in session
-- This must be called after login to enable RLS
CREATE OR REPLACE FUNCTION set_current_user_id(p_user_id uuid)
RETURNS void AS $$
BEGIN
  PERFORM set_config('app.current_user_id', p_user_id::text, true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create a function to get the current user ID from session
CREATE OR REPLACE FUNCTION public.get_current_user_id()
RETURNS uuid AS $$
  SELECT nullif(current_setting('app.current_user_id', true), '')::uuid;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 3. Create a function to check if current user is admin (bypasses RLS)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
DECLARE
  v_role text;
BEGIN
  SELECT role INTO v_role FROM users WHERE id = public.get_current_user_id();
  RETURN v_role = 'admin';
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 4. Create login function that bypasses RLS (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.login_user(p_username text, p_password text)
RETURNS json AS $$
DECLARE
  v_user json;
BEGIN
  SELECT row_to_json(u) INTO v_user
  FROM (
    SELECT id, name, username, phone, role, status, age, created_at
    FROM users
    WHERE username = p_username AND password = p_password
  ) u;
  
  RETURN v_user;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin functions that bypass RLS (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.admin_get_users()
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_agg(row_to_json(u))
    FROM (
      SELECT id, name, username, phone, role, status, age, created_at
      FROM users
      WHERE role = 'patient'
      ORDER BY created_at DESC
    ) u
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_get_all_readings()
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_agg(row_to_json(r))
    FROM (
      SELECT r.id, r.user_id, r.systolic, r.diastolic, r.heart_rate, 
             r.glucose, r.weight, r.temperature, r.spo2, r.notes, r.created_at,
             u.name as user_name, u.username as user_username
      FROM blood_pressure_readings r
      LEFT JOIN users u ON r.user_id = u.id
      ORDER BY r.created_at DESC
    ) r
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_get_all_alerts()
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_agg(row_to_json(a))
    FROM (
      SELECT a.id, a.user_id, a.alert_type, a.message, a.is_read, a.created_at,
             u.name as user_name, u.phone as user_phone
      FROM health_alerts a
      LEFT JOIN users u ON a.user_id = u.id
      ORDER BY a.created_at DESC
    ) a
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_get_all_schedules()
RETURNS json AS $$
BEGIN
  RETURN (
    SELECT json_agg(row_to_json(s))
    FROM (
      SELECT s.id, s.user_id, s.scheduled_date, s.notes, s.created_at,
             u.name as user_name, u.username as user_username
      FROM bp_schedule s
      LEFT JOIN users u ON s.user_id = u.id
      ORDER BY s.scheduled_date ASC
    ) s
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Drop ALL existing policies first (robust approach)
DO $$
BEGIN
  -- Drop all policies on bp_schedule
  DROP POLICY IF EXISTS "Public access bp_schedule" ON bp_schedule;
  DROP POLICY IF EXISTS "Admin manage schedules" ON bp_schedule;
  DROP POLICY IF EXISTS "Users view own schedules" ON bp_schedule;
  DROP POLICY IF EXISTS "Public view schedules" ON bp_schedule;
  DROP POLICY IF EXISTS "Users see own schedule" ON bp_schedule;
  DROP POLICY IF EXISTS "Users insert own schedule" ON bp_schedule;
  DROP POLICY IF EXISTS "Users delete own schedule" ON bp_schedule;
  DROP POLICY IF EXISTS "Admins manage schedules" ON bp_schedule;
  
  -- Drop all policies on blood_pressure_readings
  DROP POLICY IF EXISTS "Public access blood_pressure_readings" ON blood_pressure_readings;
  DROP POLICY IF EXISTS "Users see own readings" ON blood_pressure_readings;
  DROP POLICY IF EXISTS "Users insert own readings" ON blood_pressure_readings;
  DROP POLICY IF EXISTS "Admins manage readings" ON blood_pressure_readings;
  
  -- Drop all policies on health_alerts
  DROP POLICY IF EXISTS "Public access health_alerts" ON health_alerts;
  DROP POLICY IF EXISTS "Users see own alerts" ON health_alerts;
  DROP POLICY IF EXISTS "Users update own alerts" ON health_alerts;
  DROP POLICY IF EXISTS "Admins manage alerts" ON health_alerts;
  
  -- Drop all policies on users
  DROP POLICY IF EXISTS "Public access users" ON users;
  DROP POLICY IF EXISTS "Users see own profile" ON users;
  DROP POLICY IF EXISTS "Users update own profile" ON users;
  DROP POLICY IF EXISTS "Admins manage users" ON users;
END $$;

-- 5. Create RLS policies for each table

-- USERS: Users can only see their own profile, admins see all
CREATE POLICY "Users see own profile" ON users
FOR SELECT
USING (id = public.get_current_user_id() OR public.is_admin());

CREATE POLICY "Users update own profile" ON users
FOR UPDATE
USING (id = public.get_current_user_id() OR public.is_admin());

CREATE POLICY "Admins manage users" ON users
FOR ALL
USING (public.is_admin());

-- BLOOD PRESSURE READINGS: Users see only their own readings
CREATE POLICY "Users see own readings" ON blood_pressure_readings
FOR SELECT
USING (user_id = public.get_current_user_id() OR public.is_admin());

CREATE POLICY "Users insert own readings" ON blood_pressure_readings
FOR INSERT
WITH CHECK (user_id = public.get_current_user_id());

CREATE POLICY "Admins manage readings" ON blood_pressure_readings
FOR ALL
USING (public.is_admin());

-- BP SCHEDULE: Users see only their own schedule
CREATE POLICY "Users see own schedule" ON bp_schedule
FOR SELECT
USING (user_id = public.get_current_user_id() OR public.is_admin());

CREATE POLICY "Users insert own schedule" ON bp_schedule
FOR INSERT
WITH CHECK (user_id = public.get_current_user_id());

CREATE POLICY "Users delete own schedule" ON bp_schedule
FOR DELETE
USING (user_id = public.get_current_user_id());

CREATE POLICY "Admins manage schedules" ON bp_schedule
FOR ALL
USING (public.is_admin());

-- HEALTH ALERTS: Users see only their own alerts
CREATE POLICY "Users see own alerts" ON health_alerts
FOR SELECT
USING (user_id = public.get_current_user_id() OR public.is_admin());

CREATE POLICY "Users update own alerts" ON health_alerts
FOR UPDATE
USING (user_id = public.get_current_user_id());

CREATE POLICY "Admins manage alerts" ON health_alerts
FOR ALL
USING (public.is_admin());

-- 4. Verify policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
