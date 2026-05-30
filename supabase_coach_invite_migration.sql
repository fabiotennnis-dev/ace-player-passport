-- ══════════════════════════════════════════════
-- ACE Player Passport — Coach Invite Migration
-- Execute no Supabase SQL Editor
-- ══════════════════════════════════════════════

-- 1. Tabela de convites para coaches
CREATE TABLE IF NOT EXISTS coach_invites (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token           VARCHAR(32) UNIQUE NOT NULL,
  academia_id     UUID REFERENCES academias(id),
  coach_record_id TEXT,        -- ID na tabela coaches_academia
  email           TEXT NOT NULL,
  used            BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE coach_invites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ci_insert" ON coach_invites FOR INSERT WITH CHECK (true);
CREATE POLICY "ci_select" ON coach_invites FOR SELECT USING (true);
CREATE POLICY "ci_update" ON coach_invites FOR UPDATE USING (true);

-- 2. Função RPC para validar convite (sem autenticação)
CREATE OR REPLACE FUNCTION lookup_coach_invite(p_token TEXT)
RETURNS TABLE(
  invite_id       UUID,
  academia_id     UUID,
  coach_record_id TEXT,
  email           TEXT,
  coach_name      TEXT,
  coach_funcao    TEXT
)
SECURITY DEFINER LANGUAGE SQL AS $$
  SELECT
    ci.id,
    ci.academia_id,
    ci.coach_record_id,
    ci.email,
    ca.nome,
    ca.funcao
  FROM coach_invites ci
  LEFT JOIN coaches_academia ca
    ON ca.id::text = ci.coach_record_id
  WHERE ci.token = p_token
    AND ci.used = false
  LIMIT 1;
$$;
