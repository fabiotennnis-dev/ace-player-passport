-- ══════════════════════════════════════════════
-- ACE Player Passport — Scout Pós-Torneio
-- Execute no Supabase SQL Editor
-- ══════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS tournament_evaluations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id   UUID REFERENCES alunos(id) ON DELETE CASCADE,
  academia_id  UUID REFERENCES academias(id),
  coach_id     UUID,

  -- Dados da partida
  torneio       TEXT NOT NULL,
  data_partida  DATE,
  adversario    TEXT,
  resultado     TEXT CHECK (resultado IN ('vitoria','derrota')),
  placar        TEXT,

  -- Saque (1-5 ou contagem)
  saque_primeiro_pct  SMALLINT CHECK (saque_primeiro_pct  BETWEEN 1 AND 5),
  saque_duplas_faltas SMALLINT,
  saque_aces          SMALLINT,
  saque_efic_primeiro SMALLINT CHECK (saque_efic_primeiro BETWEEN 1 AND 5),
  saque_efic_segundo  SMALLINT CHECK (saque_efic_segundo  BETWEEN 1 AND 5),

  -- Devolução (1-5)
  dev_erros_primeiro SMALLINT CHECK (dev_erros_primeiro BETWEEN 1 AND 5),
  dev_erros_segundo  SMALLINT CHECK (dev_erros_segundo  BETWEEN 1 AND 5),
  dev_agressividade  SMALLINT CHECK (dev_agressividade  BETWEEN 1 AND 5),

  -- Erros & Winners (1-5)
  erros_nao_forcados SMALLINT CHECK (erros_nao_forcados BETWEEN 1 AND 5),
  erros_forcados     SMALLINT CHECK (erros_forcados     BETWEEN 1 AND 5),
  winners            SMALLINT CHECK (winners            BETWEEN 1 AND 5),

  -- Mental & Tático (1-5)
  mental_pontos_imp   SMALLINT CHECK (mental_pontos_imp   BETWEEN 1 AND 5),
  mental_reacao       SMALLINT CHECK (mental_reacao       BETWEEN 1 AND 5),
  mental_concentracao SMALLINT CHECK (mental_concentracao BETWEEN 1 AND 5),
  mental_tatica       SMALLINT CHECK (mental_tatica       BETWEEN 1 AND 5),
  mental_atitude      SMALLINT CHECK (mental_atitude      BETWEEN 1 AND 5),

  -- Físico (1-5)
  fisico_movimentacao SMALLINT CHECK (fisico_movimentacao BETWEEN 1 AND 5),
  fisico_recuperacao  SMALLINT CHECK (fisico_recuperacao  BETWEEN 1 AND 5),
  fisico_resistencia  SMALLINT CHECK (fisico_resistencia  BETWEEN 1 AND 5),

  -- Análise geral
  analise    TEXT,
  nota_geral SMALLINT CHECK (nota_geral BETWEEN 1 AND 10),

  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE tournament_evaluations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "te_all" ON tournament_evaluations FOR ALL USING (true);
