CREATE TABLE IF NOT EXISTS exercicios_livres (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  academia_id uuid NOT NULL REFERENCES academias(id) ON DELETE CASCADE,
  coach_id    uuid NOT NULL,
  titulo      text NOT NULL,
  descricao   text NOT NULL,
  cue         text DEFAULT '',
  tags        text[] DEFAULT '{}',
  imagem_url  text DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE exercicios_livres ENABLE ROW LEVEL SECURITY;

-- Helper: check if current user is head coach
CREATE OR REPLACE FUNCTION is_head_coach()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM coaches_academia
    WHERE coach_id   = auth.uid()
      AND academia_id = get_my_academia_id()
      AND cargo IN ('Head Coach','Coordenador','Diretor','head_coach')
  );
$$;

-- All coaches can read
DROP POLICY IF EXISTS "Coach lê exercícios" ON exercicios_livres;
CREATE POLICY "Coach lê exercícios"
ON exercicios_livres FOR SELECT
USING (academia_id = get_my_academia_id());

-- Only head coaches can write
DROP POLICY IF EXISTS "Head coach gerencia exercícios" ON exercicios_livres;
CREATE POLICY "Head coach gerencia exercícios"
ON exercicios_livres FOR ALL
USING  (academia_id = get_my_academia_id() AND is_head_coach())
WITH CHECK (academia_id = get_my_academia_id() AND coach_id = auth.uid() AND is_head_coach());
