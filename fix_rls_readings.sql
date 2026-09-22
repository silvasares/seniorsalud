-- Fix RLS policies to allow admin to view all readings

-- Drop existing policy
DROP POLICY IF EXISTS "Public access readings" ON blood_pressure_readings;

-- Create new policy that allows all access
CREATE POLICY "Public access readings" ON blood_pressure_readings 
FOR ALL 
USING (true)
WITH CHECK (true);

-- Verify the policy
SELECT * FROM pg_policies WHERE tablename = 'blood_pressure_readings';
