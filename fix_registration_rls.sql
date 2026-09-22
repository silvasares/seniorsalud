-- Fix RLS policies to allow anonymous registration and username checks

-- 1. Create a function to check if a username exists (bypasses RLS)
CREATE OR REPLACE FUNCTION public.check_username_exists(p_username text)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users WHERE username = p_username
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create a function for admin to create users (bypasses RLS)
CREATE OR REPLACE FUNCTION public.admin_create_user(
  p_name text,
  p_username text,
  p_phone text,
  p_password text,
  p_age int,
  p_role text DEFAULT 'patient',
  p_status text DEFAULT 'approved'
)
RETURNS json AS $$
DECLARE
  v_user json;
BEGIN
  INSERT INTO users (name, username, phone, password, role, status, age)
  VALUES (p_name, p_username, p_phone, p_password, p_role, p_status, p_age)
  RETURNING row_to_json(users.*) INTO v_user;
  
  RETURN v_user;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Allow anonymous users to INSERT into users table for registration
-- We restrict this to role='patient' and status='pending' to avoid abuse
DROP POLICY IF EXISTS "Anonymous account request" ON users;
CREATE POLICY "Anonymous account request" ON users
FOR INSERT
WITH CHECK (
  role = 'patient' AND 
  status = 'pending' AND
  password IS NOT NULL AND
  name IS NOT NULL
);

-- 4. Función para actualizar estado de usuario (bypasses RLS)
CREATE OR REPLACE FUNCTION public.admin_update_user_status(
  p_user_id uuid,
  p_status text
)
RETURNS void AS $$
BEGIN
  UPDATE users
  SET status = p_status
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Función para eliminar usuario (bypasses RLS)
CREATE OR REPLACE FUNCTION public.admin_delete_user(
  p_user_id uuid
)
RETURNS void AS $$
BEGIN
  DELETE FROM users WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Ensure admins can perform ALL operations on users
DROP POLICY IF EXISTS "Admins manage users" ON users;
CREATE POLICY "Admins manage users" ON users
FOR ALL
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- 7. Verify policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'users';
