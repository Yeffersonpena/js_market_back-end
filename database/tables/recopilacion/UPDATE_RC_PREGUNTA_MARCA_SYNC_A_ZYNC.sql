-- =============================================
-- Reemplazo de marca en catálogo: Sync → Zync (SYNC → ZYNC, sync → zync)
-- Tablas: RC_PREGUNTA (texto, texto_ayuda), RC_PREGUNTA_OPCION (etiqueta, valor)
-- Formulario: DATOS_PDV_VENTAS versión 1
-- Uso: producción / QA cuando ya existen datos con la marca anterior.
-- Nota: el tercer REPLACE (sync → zync) podría afectar palabras inglesas raras tipo "async";
--       en textos de este formulario no aplica. Revisar si amplían textos libres.
-- =============================================

DECLARE @FormularioCodigo VARCHAR(50) = 'DATOS_PDV_VENTAS';
DECLARE @Version INT = 1;
DECLARE @FormularioId INT;

SELECT @FormularioId = id
FROM dbo.RC_FORMULARIO
WHERE codigo = @FormularioCodigo
  AND version = @Version;

IF @FormularioId IS NULL
BEGIN
    THROW 52001, 'No existe RC_FORMULARIO DATOS_PDV_VENTAS v1.', 1;
END;

UPDATE p
SET
    texto = REPLACE(REPLACE(REPLACE(p.texto, N'SYNC', N'ZYNC'), N'Sync', N'Zync'), N'sync', N'zync'),
    texto_ayuda = CASE
        WHEN p.texto_ayuda IS NULL THEN NULL
        ELSE REPLACE(REPLACE(REPLACE(p.texto_ayuda, N'SYNC', N'ZYNC'), N'Sync', N'Zync'), N'sync', N'zync')
    END,
    fecha_actualizacion = GETDATE(),
    usuario_actualizacion = N'UPDATE_MARCA_SYNC_ZYNC'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId;

UPDATE o
SET
    etiqueta = REPLACE(REPLACE(REPLACE(o.etiqueta, N'SYNC', N'ZYNC'), N'Sync', N'Zync'), N'sync', N'zync'),
    valor = CASE
        WHEN o.valor IS NULL THEN NULL
        ELSE REPLACE(REPLACE(REPLACE(o.valor, N'SYNC', N'ZYNC'), N'Sync', N'Zync'), N'sync', N'zync')
    END,
    fecha_actualizacion = GETDATE(),
    usuario_actualizacion = N'UPDATE_MARCA_SYNC_ZYNC'
FROM dbo.RC_PREGUNTA_OPCION o
INNER JOIN dbo.RC_PREGUNTA p ON p.id = o.pregunta_id
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId;
