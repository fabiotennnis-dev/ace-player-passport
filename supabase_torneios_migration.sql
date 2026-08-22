-- ══════════════════════════════════════════════
-- ACE Player Passport — Módulo Torneios
-- Execute no Supabase SQL Editor
-- ══════════════════════════════════════════════

-- 1. Tabela de torneios criados pela academia
CREATE TABLE IF NOT EXISTS torneios (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  academia_id            UUID REFERENCES academias(id) ON DELETE CASCADE,
  nome                   TEXT NOT NULL,
  local                  TEXT,
  data_inicio            DATE,
  data_fim               DATE,
  data_limite_inscricao  DATE,
  formato                TEXT DEFAULT 'Grupos + Semis + Final',
  pix_chave              TEXT,
  pix_nome               TEXT,
  pix_cnpj               TEXT,
  ativo                  BOOLEAN DEFAULT true,
  criado_em              TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Categorias de cada torneio (Vermelha, Laranja, Amarela, Verde, Dupla...)
CREATE TABLE IF NOT EXISTS categorias_torneio (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  torneio_id  UUID REFERENCES torneios(id) ON DELETE CASCADE,
  nome        TEXT NOT NULL,
  emoji       TEXT,
  cor         TEXT,
  idade_desc  TEXT,
  valor       NUMERIC(10,2),
  criado_em   TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Inscrições recebidas pelos pais/responsáveis
CREATE TABLE IF NOT EXISTS inscricoes_torneio (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  torneio_id       UUID REFERENCES torneios(id) ON DELETE CASCADE,
  academia_id      UUID REFERENCES academias(id),
  categoria_id     UUID REFERENCES categorias_torneio(id),
  nome_atleta      TEXT NOT NULL,
  data_nasc        DATE,
  sexo             TEXT,
  nome_resp        TEXT,
  whatsapp         TEXT,
  email            TEXT,
  valor            NUMERIC(10,2),
  status           TEXT DEFAULT 'aguardando',  -- aguardando | confirmada | recusada
  comprovante_url  TEXT,
  codigo           TEXT,
  obs_admin        TEXT,
  criado_em        TIMESTAMPTZ DEFAULT NOW()
);

-- 4. RLS — cada academia só vê seus próprios torneios e inscrições
ALTER TABLE torneios ENABLE ROW LEVEL SECURITY;
CREATE POLICY "torneios_academia" ON torneios FOR ALL USING (
  academia_id IN (
    SELECT academia_id FROM coaches_academia WHERE coach_id = auth.uid() AND ativo = true
  )
);

ALTER TABLE categorias_torneio ENABLE ROW LEVEL SECURITY;
CREATE POLICY "categorias_torneio_all" ON categorias_torneio FOR ALL USING (true);

ALTER TABLE inscricoes_torneio ENABLE ROW LEVEL SECURITY;
-- Inscrições: coaches da academia podem ver, anônimos podem inserir (para o form público)
CREATE POLICY "inscricoes_read" ON inscricoes_torneio FOR SELECT USING (
  academia_id IN (
    SELECT academia_id FROM coaches_academia WHERE coach_id = auth.uid() AND ativo = true
  )
);
CREATE POLICY "inscricoes_insert_public" ON inscricoes_torneio FOR INSERT WITH CHECK (true);
CREATE POLICY "inscricoes_update_coach" ON inscricoes_torneio FOR UPDATE USING (
  academia_id IN (
    SELECT academia_id FROM coaches_academia WHERE coach_id = auth.uid() AND ativo = true
  )
);

-- 5. Bucket para comprovantes (execute separadamente se não existir)
-- No painel Supabase: Storage → New Bucket → nome: "comprovantes" → Public: false
