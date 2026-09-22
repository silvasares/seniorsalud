-- SeniorSalud Database Schema for InsForge
-- Tables, Functions, and RLS Policies

-- ============================================================
-- 1. TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  username TEXT UNIQUE,
  phone TEXT,
  password TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL DEFAULT 'patient',
  status TEXT NOT NULL DEFAULT 'approved',
  age INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS blood_pressure_readings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  systolic INTEGER,
  diastolic INTEGER,
  heart_rate INTEGER,
  glucose INTEGER,
  weight NUMERIC(5,2),
  temperature NUMERIC(4,1),
  spo2 INTEGER,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS health_alerts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL DEFAULT 'stable',
  message TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bp_schedule (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  scheduled_date DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT bp_schedule_user_date_unique UNIQUE (user_id, scheduled_date)
);

CREATE TABLE IF NOT EXISTS medications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  dosage TEXT,
  frequency TEXT,
  time TEXT,
  reminder_times TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 2. RPC FUNCTIONS (no session variables - InsForge compatible)
-- ============================================================

-- Login user
CREATE OR REPLACE FUNCTION public.login_user(p_username text, p_password text)
RETURNS json
LANGUAGE sql
STABLE
AS $$
  SELECT row_to_json(u) FROM (
    SELECT id, name, username, phone, role, status, age, created_at
    FROM users WHERE username = p_username AND password = p_password
  ) u;
$$;

-- Check if username exists
CREATE OR REPLACE FUNCTION public.check_username_exists(p_username text)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (SELECT 1 FROM users WHERE username = p_username);
$$;

-- Admin: create user
CREATE OR REPLACE FUNCTION public.admin_create_user(
  p_name text,
  p_username text,
  p_phone text,
  p_password text,
  p_age integer DEFAULT NULL,
  p_role text DEFAULT 'patient',
  p_status text DEFAULT 'approved'
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user json;
BEGIN
  INSERT INTO users (name, username, phone, password, role, status, age)
  VALUES (p_name, p_username, p_phone, p_password, p_role, p_status, p_age)
  RETURNING row_to_json(users.*) INTO v_user;
  RETURN v_user;
END;
$$;

-- Admin: update user status
CREATE OR REPLACE FUNCTION public.admin_update_user_status(p_user_id uuid, p_status text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE users SET status = p_status WHERE id = p_user_id;
END;
$$;

-- Admin: delete user
CREATE OR REPLACE FUNCTION public.admin_delete_user(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM users WHERE id = p_user_id;
END;
$$;

-- Admin: get all users
CREATE OR REPLACE FUNCTION public.admin_get_users()
RETURNS json
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT json_agg(row_to_json(u)) FROM (
    SELECT id, name, username, phone, role, status, age, created_at
    FROM users ORDER BY created_at DESC
  ) u;
$$;

-- Admin: get all readings with user info
CREATE OR REPLACE FUNCTION public.admin_get_all_readings()
RETURNS json
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT json_agg(row_to_json(r)) FROM (
    SELECT r2.id, r2.user_id, r2.systolic, r2.diastolic, r2.heart_rate,
           r2.glucose, r2.weight, r2.temperature, r2.spo2, r2.notes,
           r2.created_at, u.name as user_name, u.username as user_username
    FROM blood_pressure_readings r2
    JOIN users u ON r2.user_id = u.id
    ORDER BY r2.created_at DESC
  ) r;
$$;

-- Admin: get all alerts with user info
CREATE OR REPLACE FUNCTION public.admin_get_all_alerts()
RETURNS json
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT json_agg(row_to_json(a)) FROM (
    SELECT a2.id, a2.user_id, a2.alert_type, a2.message, a2.is_read,
           a2.created_at, u.name as user_name, u.phone as user_phone
    FROM health_alerts a2
    JOIN users u ON a2.user_id = u.id
    ORDER BY a2.created_at DESC
  ) a;
$$;

-- Admin: get all schedules with user info
CREATE OR REPLACE FUNCTION public.admin_get_all_schedules()
RETURNS json
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT json_agg(row_to_json(s)) FROM (
    SELECT s2.id, s2.user_id, s2.scheduled_date, s2.notes, s2.created_at,
           u.name as user_name, u.username as user_username
    FROM bp_schedule s2
    JOIN users u ON s2.user_id = u.id
    ORDER BY s2.scheduled_date ASC
  ) s;
$$;

-- User: get own schedule
CREATE OR REPLACE FUNCTION public.get_user_schedule(p_user_id uuid)
RETURNS json
LANGUAGE sql
STABLE
AS $$
  SELECT json_agg(row_to_json(s)) FROM (
    SELECT id, user_id, scheduled_date, notes, created_at
    FROM bp_schedule WHERE user_id = p_user_id
    ORDER BY scheduled_date ASC
  ) s;
$$;

-- Admin: add schedule (upsert)
CREATE OR REPLACE FUNCTION public.admin_add_schedule(
  p_user_id uuid,
  p_date date,
  p_notes text DEFAULT ''
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO bp_schedule (user_id, scheduled_date, notes)
  VALUES (p_user_id, p_date, p_notes)
  ON CONFLICT (user_id, scheduled_date)
  DO UPDATE SET notes = EXCLUDED.notes;
END;
$$;

-- Admin: delete schedule
CREATE OR REPLACE FUNCTION public.admin_delete_schedule(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM bp_schedule WHERE id = p_id;
END;
$$;

-- Admin: get stats
CREATE OR REPLACE FUNCTION public.get_admin_stats()
RETURNS json
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT json_build_object(
    'totalUsers', (SELECT count(*) FROM users WHERE role = 'patient' AND status = 'approved'),
    'pendingUsers', (SELECT count(*) FROM users WHERE status = 'pending'),
    'criticalAlerts', (SELECT count(*) FROM health_alerts WHERE alert_type = 'critical' AND is_read = false),
    'stableUsers', (SELECT count(*) FROM health_alerts WHERE alert_type = 'stable' AND is_read = false),
    'followUpUsers', (SELECT count(*) FROM health_alerts WHERE alert_type = 'follow_up' AND is_read = false)
  );
$$;

-- ============================================================
-- 3. SEED DATA
-- ============================================================

INSERT INTO users (name, username, password, role, status)
VALUES ('Administrador', 'admin', 'admin123', 'admin', 'approved')
ON CONFLICT (username) DO NOTHING;

INSERT INTO users (name, username, password, phone, role, status)
VALUES ('Administrador CRA', 'CRA', '696969', 'ADMIN_CRA', 'admin', 'approved')
ON CONFLICT (username) DO NOTHING;

-- ============================================================
-- 4. ROW LEVEL SECURITY (public access for app-level auth)
-- ============================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE blood_pressure_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bp_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public access users" ON users;
CREATE POLICY "Public access users" ON users FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access readings" ON blood_pressure_readings;
CREATE POLICY "Public access readings" ON blood_pressure_readings FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access alerts" ON health_alerts;
CREATE POLICY "Public access alerts" ON health_alerts FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access schedule" ON bp_schedule;
CREATE POLICY "Public access schedule" ON bp_schedule FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access medications" ON medications;
CREATE POLICY "Public access medications" ON medications FOR ALL USING (true) WITH CHECK (true);
