-- Self-registration must always create a PENDING patient account.
-- Only an admin can approve it (admin_update_user_status / admin panel).

-- Any insert that does not state a status explicitly is now pending.
ALTER TABLE users ALTER COLUMN status SET DEFAULT 'pending';

-- Public registration RPC: role and status are forced, they cannot be passed in.
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
AS $$
DECLARE
  v_user json;
BEGIN
  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'El nombre es obligatorio';
  END IF;

  IF p_username IS NULL OR trim(p_username) = '' THEN
    RAISE EXCEPTION 'El usuario es obligatorio';
  END IF;

  IF p_password IS NULL OR length(p_password) < 6 THEN
    RAISE EXCEPTION 'La contrasena debe tener al menos 6 caracteres';
  END IF;

  IF EXISTS (SELECT 1 FROM users WHERE lower(username) = lower(trim(p_username))) THEN
    RAISE EXCEPTION 'El usuario ya existe';
  END IF;

  INSERT INTO users (name, username, phone, password, role, status, age)
  VALUES (trim(p_name), lower(trim(p_username)), trim(p_phone), p_password, 'patient', 'pending', p_age)
  RETURNING row_to_json(users.*) INTO v_user;

  RETURN v_user;
END;
$$;

GRANT EXECUTE ON FUNCTION public.register_user(text, text, text, text, integer) TO anon, authenticated;
