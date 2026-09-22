-- Verificar si hay lecturas en la base de datos
SELECT COUNT(*) as total FROM blood_pressure_readings;

-- Ver lecturas recientes
SELECT id, user_id, systolic, diastolic, heart_rate, glucose, weight, temperature, notes, created_at 
FROM blood_pressure_readings 
ORDER BY created_at DESC 
LIMIT 10;

-- Verificar relación users
SELECT id, name, username, role FROM users LIMIT 5;
