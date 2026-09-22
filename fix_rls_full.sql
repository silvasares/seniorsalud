-- Deshabilitar RLS temporalmente para probar
ALTER TABLE blood_pressure_readings DISABLE ROW LEVEL SECURITY;

-- Verificar datos
SELECT id, user_id, systolic, diastolic, created_at 
FROM blood_pressure_readings 
ORDER BY created_at DESC 
LIMIT 5;

-- Si hay datos, volver a habilitar RLS con política correcta
ALTER TABLE blood_pressure_readings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public access readings" ON blood_pressure_readings;
CREATE POLICY "Public access readings" ON blood_pressure_readings FOR ALL USING (true);
