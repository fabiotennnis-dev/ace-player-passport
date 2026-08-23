-- ══════════════════════════════════════════════
-- ACE — Portal acesso por nome (sem código)
-- Execute no Supabase SQL Editor
-- ══════════════════════════════════════════════

-- RPC pública: busca aluno pelo nome dentro de uma academia específica
-- Retorna até 5 correspondências para o pai escolher o filho certo
CREATE OR REPLACE FUNCTION lookup_student_by_name(
  p_nome       TEXT,
  p_academia_id UUID
)
RETURNS TABLE (
  student_id   UUID,
  student_name TEXT,
  pulseira     TEXT,
  coach_nome   TEXT,
  academia_id  UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id              AS student_id,
    a.nome            AS student_name,
    a.pulseira        AS pulseira,
    COALESCE(ca.coach_nome, '') AS coach_nome,
    a.academia_id     AS academia_id
  FROM alunos a
  LEFT JOIN LATERAL (
    SELECT c.nome AS coach_nome
    FROM coaches_academia ca2
    JOIN auth.users c ON c.id = ca2.coach_id
    WHERE ca2.academia_id = a.academia_id AND ca2.ativo = true
    ORDER BY ca2.criado_em ASC
    LIMIT 1
  ) ca ON true
  WHERE
    a.academia_id = p_academia_id
    AND LOWER(UNACCENT(a.nome)) LIKE '%' || LOWER(UNACCENT(p_nome)) || '%'
    AND (a.inativo IS NULL OR a.inativo = false)
  LIMIT 5;
END;
$$;

-- Permissão pública para o form de inscrição dos pais chamarem
GRANT EXECUTE ON FUNCTION lookup_student_by_name(TEXT, UUID) TO anon, authenticated;

-- Garante que unaccent está disponível (geralmente já está no Supabase)
CREATE EXTENSION IF NOT EXISTS unaccent;
