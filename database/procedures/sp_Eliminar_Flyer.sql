CREATE PROCEDURE dbo.sp_Eliminar_Flyer
    @nombreImagen VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @registrosEliminadosFlyers INT = 0;
    DECLARE @registrosEliminadosCampanas INT = 0;

    -- Paso 1: Eliminar asignaciones a usuarios (PDV_OUT_FLYERS)
    -- Esto elimina todas las vinculaciones de ese flyer con los DNI
    DELETE FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS
    WHERE foto_esquema = @nombreImagen;

    SET @registrosEliminadosFlyers = @@ROWCOUNT;

    -- Paso 2: Eliminar la campaña (PDV_OUT_CAMPAÑAS_FLYERS)
    DELETE FROM PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS
    WHERE foto_esquema = @nombreImagen;

    SET @registrosEliminadosCampanas = @@ROWCOUNT;

    -- Retornar resultado
    SELECT
        @nombreImagen AS 'Flyer_Eliminado',
        @registrosEliminadosFlyers AS 'Asignaciones_Eliminadas',
        @registrosEliminadosCampanas AS 'Campaña_Eliminada',
        CASE
            WHEN @registrosEliminadosCampanas > 0 THEN 'Eliminación exitosa'
            ELSE 'No se encontró el flyer'
        END AS 'Estado';

END;

