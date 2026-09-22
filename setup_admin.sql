-- 1. Limpiar datos de prueba
DELETE FROM health_alerts;
DELETE FROM blood_pressure_readings;

-- 2. Crear o actualizar usuario Admin CRA
INSERT INTO users (name, username, password, phone, role, status, created_at)
VALUES ('Administrador CRA', 'CRA', '696969', 'ADMIN_CRA', 'admin', 'approved', NOW())
ON CONFLICT (username) DO UPDATE SET
  name = 'Administrador CRA',
  password = '696969',
  role = 'admin',
  status = 'approved';

-- 3. Verificar que se creó correctamente
SELECT id, name, username, role, status FROM users WHERE username = 'CRA';
