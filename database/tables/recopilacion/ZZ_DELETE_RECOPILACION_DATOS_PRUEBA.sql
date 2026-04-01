-- =============================================
-- Script: ZZ_DELETE_RECOPILACION_DATOS_PRUEBA.sql
-- Descripción:
--   Elimina TODOS los datos transaccionales de recopilación
--   (visitas, respuestas, opciones, media, estado por sección),
--   sin tocar catálogos ni RC_CLIENTE_PDV.
--
--   Ejecutar SOLO cuando quieras limpiar completamente las
--   encuestas de prueba.
--
--   Importante:
--   - No usa GO (requerimiento del proyecto).
--   - Usa TRUNCATE donde no hay FKs referenciando.
-- ============================================

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -------------------------------------------------------------
    -- 1) Borrar media de respuestas (RC_RESPUESTA_MEDIA)
    -------------------------------------------------------------
    DELETE m
    FROM dbo.RC_RESPUESTA_MEDIA AS m;

    -------------------------------------------------------------
    -- 2) Borrar opciones marcadas (RC_RESPUESTA_OPCION)
    -------------------------------------------------------------
    DELETE ro
    FROM dbo.RC_RESPUESTA_OPCION AS ro;

    -------------------------------------------------------------
    -- 3) Borrar respuestas (RC_RESPUESTA)
    -------------------------------------------------------------
    DELETE r
    FROM dbo.RC_RESPUESTA AS r;

    -------------------------------------------------------------
    -- 4) Estado por sección (RC_VISITA_SECCION_ESTADO)
    -------------------------------------------------------------
    DELETE vse
    FROM dbo.RC_VISITA_SECCION_ESTADO AS vse;

    -------------------------------------------------------------
    -- 5) Cabeceras de visita/formulario (RC_VISITA_FORMULARIO)
    -------------------------------------------------------------
    DELETE v
    FROM dbo.RC_VISITA_FORMULARIO AS v;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();

    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;

