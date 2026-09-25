-- Se elimina la funcion auxiliar usada solo para validar en pruebas
-- que el JWT de usuario llega a Postgres (auth.uid()).
DROP FUNCTION IF EXISTS public.probe_uid();
