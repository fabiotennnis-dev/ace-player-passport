-- ============================================================
-- ACE Player Passport — Admin table
-- Raw Tennis, Brasília
-- ============================================================
-- Run this in the Supabase SQL editor to create the admins table.
-- ============================================================

CREATE TABLE IF NOT EXISTS admins (
  user_id    uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome       text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS so the anon key cannot enumerate admins
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- Each admin can only read their own row (used by admin.html to verify access)
DROP POLICY IF EXISTS "Admin pode ver admins" ON admins;
CREATE POLICY "Admin pode ver admins"
  ON admins FOR SELECT
  USING (user_id = auth.uid());

-- ============================================================
-- To add the first (or any) admin, run in the SQL editor:
--
--   INSERT INTO admins (user_id, nome)
--   VALUES ('<your-user-uuid>', 'Fábio Rocha');
--
-- You can find the UUID in Authentication > Users in the dashboard.
-- ============================================================
