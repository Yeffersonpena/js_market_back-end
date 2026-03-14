-- =============================================
-- UPDATE: RC_PREGUNTA - Habilitar fotos en preguntas
-- requiere_foto=1, min_fotos=0, max_fotos=10
-- Ejecutar cuando el catálogo ya fue insertado y no se re-ejecutan los INSERT.
-- =============================================

-- P15 (PASO_2_CAPA_2): ¿Qué marcas maneja en góndola?
UPDATE p
SET
    p.requiere_foto = 1,
    p.min_fotos = 0,
    p.max_fotos = 10
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.codigo = 'PASO_2_CAPA_2'
  AND p.codigo = 'P15';

-- P19 (PASO_2_CAPA_3): ¿Tiene vitrina o display activo de accesorios?
UPDATE p
SET
    p.requiere_foto = 1,
    p.min_fotos = 0,
    p.max_fotos = 10
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.codigo = 'PASO_2_CAPA_3'
  AND p.codigo = 'P19';

-- P21 (PASO_2_CAPA_3): ¿Tiene letrero o señalización visible de operador?
UPDATE p
SET
    p.requiere_foto = 1,
    p.min_fotos = 0,
    p.max_fotos = 10
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.codigo = 'PASO_2_CAPA_3'
  AND p.codigo = 'P21';
