-- 1. `admin_create_user` quedo con dos sobrecargas: la original (sin
--    proteccion e insertando la columna password ya eliminada) y la nueva.
--    Se eliminan ambas y se recrea una unica version endurecida.
DROP FUNCTION IF EXISTS public.admin_create_user(text, text, text, text, integer, text, text);
DROP FUNCTION IF EXISTS public.admin_create_user(text, text, text, text, integer, text, text, uuid);

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
SET search_path = public
AS $$
DECLARE
  v_id uuid;
  v_user json;
BEGIN
  PERFORM public.assert_admin();

  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'El nombre es obligatorio';
  END IF;
  IF p_username IS NULL OR trim(p_username) = '' THEN
    RAISE EXCEPTION 'El usuario es obligatorio';
  END IF;
  IF p_role NOT IN ('patient', 'admin') THEN
    RAISE EXCEPTION 'Rol no valido';
  END IF;
  IF p_status NOT IN ('approved', 'pending', 'rejected') THEN
    RAISE EXCEPTION 'Estado no valido';
  END IF;

  v_id := public.new_account(p_name, p_username, p_password, p_role, p_status, p_phone, p_age);

  SELECT row_to_json(u) INTO v_user FROM users u WHERE u.id = v_id;
  RETURN v_user;
END;
$$;

-- 2. `new_account` es interno: solo lo usan las RPC con SECURITY DEFINER.
--    Sin este revoke, cualquiera con la anon key podia llamado directamente
--    y crearse una cuenta de administrador.
REVOKE ALL ON FUNCTION public.new_account(text, text, text, text, text, text, integer)
  FROM PUBLIC, anon, authenticated;
