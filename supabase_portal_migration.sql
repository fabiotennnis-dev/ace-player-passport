-- ══════════════════════════════════════════════
-- ACE Player Passport — Portal Migration
-- Execute in Supabase SQL Editor
-- ══════════════════════════════════════════════

-- 1. Add access_code to alunos
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS access_code VARCHAR(10) UNIQUE;

-- Generate codes for existing students that don't have one
UPDATE alunos
SET access_code = 'PP-' || upper(substring(md5(random()::text), 1, 4))
WHERE access_code IS NULL;

-- 2. Portal accounts (links Supabase auth user → student)
CREATE TABLE IF NOT EXISTS portal_accounts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id    UUID REFERENCES alunos(id) ON DELETE CASCADE,
  academia_id   UUID REFERENCES academias(id),
  auth_user_id  UUID UNIQUE,          -- Supabase auth.users.id
  email         TEXT,
  role          TEXT CHECK (role IN ('parent','student')) DEFAULT 'parent',
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Coach notes (parents see, students don't)
CREATE TABLE IF NOT EXISTS coach_notes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id  UUID REFERENCES alunos(id) ON DELETE CASCADE,
  coach_id    UUID,
  academia_id UUID REFERENCES academias(id),
  note        TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Portal permissions per student
CREATE TABLE IF NOT EXISTS portal_permissions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id        UUID REFERENCES alunos(id) ON DELETE CASCADE UNIQUE,
  show_planejador   BOOLEAN DEFAULT TRUE,
  show_boneco       BOOLEAN DEFAULT TRUE,
  show_historico    BOOLEAN DEFAULT TRUE,
  show_fundamentos  BOOLEAN DEFAULT TRUE
);

-- ── RLS ──
ALTER TABLE portal_accounts   ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_notes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE portal_permissions ENABLE ROW LEVEL SECURITY;

-- portal_accounts: anyone can insert (registration), owner can select
CREATE POLICY "portal_insert" ON portal_accounts FOR INSERT WITH CHECK (true);
CREATE POLICY "portal_select_own" ON portal_accounts FOR SELECT USING (auth_user_id = auth.uid());
-- coaches can also select (to check status)
CREATE POLICY "portal_select_coach" ON portal_accounts FOR SELECT USING (true);

-- coach_notes: coaches insert/update, portal users select their own student's notes
CREATE POLICY "notes_insert" ON coach_notes FOR INSERT WITH CHECK (true);
CREATE POLICY "notes_update" ON coach_notes FOR UPDATE USING (coach_id = auth.uid());
CREATE POLICY "notes_select" ON coach_notes FOR SELECT USING (true);
CREATE POLICY "notes_delete" ON coach_notes FOR DELETE USING (coach_id = auth.uid());

-- portal_permissions: coaches manage
CREATE POLICY "perms_all" ON portal_permissions FOR ALL USING (true);
