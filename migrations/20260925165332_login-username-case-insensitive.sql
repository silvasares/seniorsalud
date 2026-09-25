-- Usernames are matched case-insensitively on login and uniqueness checks,
-- since register_user normalises them to lowercase.
CREATE OR REPLACE FUNCTION public.login_user(p_username text, p_password text)
RETURNS json
LANGUAGE sql
STABLE
AS $$
  SELECT row_to_json(u) FROM (
    SELECT id, name, username, phone, role, status, age, created_at
    FROM users
    WHERE lower(username) = lower(trim(p_username)) AND password = p_password
  ) u;
$$;

CREATE OR REPLACE FUNCTION public.check_username_exists(p_username text)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (SELECT 1 FROM users WHERE lower(username) = lower(trim(p_username)));
$$;
