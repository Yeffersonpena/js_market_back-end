-- SP de consulta optimizado (lee de tabla pre-calculada)
-- Reemplaza al sp_Esquema_PDV original para consultas rápidas
CREATE PROCEDURE dbo.sp_Esquema_PDV_Resumen
    @año INT,
    @mes INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM dbo.PDV_OUT_ESQUEMA_RESUMEN
    WHERE AÑO = @año AND MES = @mes
    ORDER BY ZONAL, ACCION_1, DNI_RESPONSABLE;
END;

