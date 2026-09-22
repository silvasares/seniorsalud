-- SeniorSalud Database Setup
-- Run this in your Supabase SQL Editor

-- 1. Create users table if not exists
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  username TEXT UNIQUE,
  phone TEXT,
  password TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'patient',
  status TEXT NOT NULL DEFAULT 'approved',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create blood_pressure_readings table if not exists
CREATE TABLE IF NOT EXISTS blood_pressure_readings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  systolic INTEGER,
  diastolic INTEGER,
  heart_rate INTEGER,
  glucose INTEGER,
  weight NUMERIC(5,2),
  temperature NUMERIC(4,1),
  spo2 INTEGER,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create health_alerts table if not exists
CREATE TABLE IF NOT EXISTS health_alerts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL DEFAULT 'stable',
  message TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Add missing columns if table exists but columns don't
DO $$ 
BEGIN
  -- Add username column if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'username') THEN
    ALTER TABLE users ADD COLUMN username TEXT UNIQUE;
  END IF;
  
  -- Add password column if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'password') THEN
    ALTER TABLE users ADD COLUMN password TEXT DEFAULT '';
  END IF;
  
  -- Add role column if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'role') THEN
    ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'patient';
  END IF;
  
  -- Add status column if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'status') THEN
    ALTER TABLE users ADD COLUMN status TEXT DEFAULT 'approved';
  END IF;
  
  -- Add phone column if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'phone') THEN
    ALTER TABLE users ADD COLUMN phone TEXT;
  END IF;
  
  -- Add age column if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'age') THEN
    ALTER TABLE users ADD COLUMN age INTEGER;
  END IF;
END $$;

-- 5. Create admin user
INSERT INTO users (name, username, password, role, status)
VALUES ('Administrador', 'admin', 'admin123', 'admin', 'approved')
ON CONFLICT (username) DO NOTHING;

-- 6. Enable Row Level Security (optional but recommended)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE blood_pressure_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_alerts ENABLE ROW LEVEL SECURITY;

-- 7. Create policies for public access (for development)
DROP POLICY IF EXISTS "Public access users" ON users;
CREATE POLICY "Public access users" ON users FOR ALL USING (true);

DROP POLICY IF EXISTS "Public access readings" ON blood_pressure_readings;
CREATE POLICY "Public access readings" ON blood_pressure_readings FOR ALL USING (true);

DROP POLICY IF EXISTS "Public access alerts" ON health_alerts;
CREATE POLICY "Public access alerts" ON health_alerts FOR ALL USING (true);
