-- Create schedule table for blood pressure appointment days
CREATE TABLE IF NOT EXISTS bp_schedule (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  scheduled_date DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, scheduled_date)
);

-- Enable RLS
ALTER TABLE bp_schedule ENABLE ROW LEVEL SECURITY;

-- Allow admins to manage all schedules
DROP POLICY IF EXISTS "Admin manage schedules" ON bp_schedule;
CREATE POLICY "Admin manage schedules" ON bp_schedule FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

-- Allow users to view their own schedules
DROP POLICY IF EXISTS "Users view own schedules" ON bp_schedule;
CREATE POLICY "Users view own schedules" ON bp_schedule FOR SELECT USING (
  user_id = auth.uid()
);

-- Allow users to view all schedules (for calendar display)
DROP POLICY IF EXISTS "Public view schedules" ON bp_schedule;
CREATE POLICY "Public view schedules" ON bp_schedule FOR SELECT USING (true);

-- Verify table
SELECT * FROM bp_schedule LIMIT 5;
