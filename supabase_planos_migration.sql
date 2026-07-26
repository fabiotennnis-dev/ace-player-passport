-- ══════════════════════════════════════════════
-- ACE Player Passport — Planos & Billing
-- Execute no Supabase SQL Editor
-- ══════════════════════════════════════════════

-- 1. Adiciona campos de plano na tabela academias
ALTER TABLE academias
  ADD COLUMN IF NOT EXISTS plano            TEXT    DEFAULT 'starter',
  ADD COLUMN IF NOT EXISTS limite_alunos    INTEGER DEFAULT 30,
  ADD COLUMN IF NOT EXISTS asaas_customer_id      TEXT,
  ADD COLUMN IF NOT EXISTS asaas_subscription_id  TEXT;

-- 2. Atualiza academias existentes com o plano correto baseado na quantidade atual de alunos
-- (você pode ajustar manualmente depois se preferir)
UPDATE academias SET plano = 'starter', limite_alunos = 30 WHERE limite_alunos IS NULL;

-- 3. Tabela de histórico de cobranças (para referência futura)
CREATE TABLE IF NOT EXISTS billing_events (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  academia_id  UUID REFERENCES academias(id) ON DELETE CASCADE,
  evento       TEXT NOT NULL,   -- 'payment_confirmed', 'subscription_created', 'plan_changed', etc.
  plano        TEXT,
  valor        NUMERIC(10,2),
  asaas_id     TEXT,
  criado_em    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE billing_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "billing_all" ON billing_events FOR ALL USING (true);
