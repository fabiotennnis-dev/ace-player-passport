CREATE TABLE IF NOT EXISTS convites (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  academia_id uuid NOT NULL REFERENCES academias(id) ON DELETE CASCADE,
  convidado_por uuid NOT NULL,
  email       text NOT NULL,
  nome        text NOT NULL,
  cargo       text NOT NULL DEFAULT 'Coach',
  token       text NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(24), 'hex'),
  usado       boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now(),
  expires_at  timestamptz NOT NULL DEFAULT (now() + interval '7 days')
);

ALTER TABLE convites ENABLE ROW LEVEL SECURITY;

-- Any coach from the academia can create invites
DROP POLICY IF EXISTS "Head coach cria convites" ON convites;
CREATE POLICY "Head coach cria convites"
ON convites FOR INSERT
WITH CHECK (
  academia_id = get_my_academia_id()
  AND convidado_por = auth.uid()
);

-- Head coach can see invites of their academia
DROP POLICY IF EXISTS "Head coach vê convites" ON convites;
CREATE POLICY "Head coach vê convites"
ON convites FOR SELECT
USING (academia_id = get_my_academia_id());

-- Public read by token (for invite acceptance — anon user)
DROP POLICY IF EXISTS "Leitura pública por token" ON convites;
CREATE POLICY "Leitura pública por token"
ON convites FOR SELECT
USING (true);
