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

-- All coaches can read exercises from their academia
DROP POLICY IF EXISTS "Coach lê exercícios" ON exercicios_livres;
CREATE POLICY "Coach lê exercícios"
ON exercicios_livres FOR SELECT
USING (academia_id = get_my_academia_id());

-- Any coach from the academia can manage exercises
-- (role restriction — Head Coach only — is enforced in the frontend UI)
DROP POLICY IF EXISTS "Coach gerencia exercícios" ON exercicios_livres;
CREATE POLICY "Coach gerencia exercícios"
ON exercicios_livres FOR ALL
USING  (academia_id = get_my_academia_id())
WITH CHECK (academia_id = get_my_academia_id() AND coach_id = auth.uid());
