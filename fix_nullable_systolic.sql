-- Fix: Allow null values in systolic and diastolic columns
-- This allows saving readings without blood pressure data (e.g., just heart rate, glucose, etc.)

-- Remove NOT NULL constraint from systolic
ALTER TABLE blood_pressure_readings 
ALTER COLUMN systolic DROP NOT NULL;

-- Remove NOT NULL constraint from diastolic (if exists)
ALTER TABLE blood_pressure_readings 
ALTER COLUMN diastolic DROP NOT NULL;
