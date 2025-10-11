-- SP para obtener datos de recargas por período desde tabla PP2025_N0
-- Retorna múltiples filas: una por cada período (N0, N1, N2, N3, N4)
CREATE PROCEDURE [dbo].[spRecargasPorPeriodoMultimarca]
    @dni INT,
    @año INT,
    @mes INT
AS
BEGIN
    SET NOCOUNT ON;
	
	declare @dateCalFunnel date;
	declare @n0 decimal(10,2);
	
    select @dateCalFunnel=max(FECHA_CARGA) from BD_PLANIFICACION.dbo.PP2025_N0
    where year(FECHA_CARGA)=@año and month(FECHA_CARGA)=@mes; 
	
	-- Caso especial para junio
	IF @mes = 6
        BEGIN
        select @n0=PagoRecargasNO from dbo.VentasMultimarca where DNIVendedor=@dni;
        
        ;WITH CTE AS (
            SELECT PERIODO_EVALUACION, ISNULL(SUM(CASE WHEN MONTO_RECARGADO >= 1 THEN MONTO_RECARGADO ELSE 0 END), 0) AS MONTO_RECARGADO
            FROM BD_PLANIFICACION.dbo.PP2025_N0
            WHERE DNI_VENDEDOR = @dni
                AND fecha BETWEEN '2025-06-01' AND '2025-11-30'
                AND FECHA_CARGA = @dateCalFunnel
            GROUP BY PERIODO_EVALUACION
        )
        SELECT
            @dni AS dni_vendedor,
            'N0' as PERIODO_EVALUACION,
            0 as MONTO_RECARGADO,
            @n0 AS ganaciaPorRecarga
        FROM CTE;
    END
    ELSE
        BEGIN
        ;WITH CTE AS (
        SELECT PERIODO_EVALUACION, ISNULL(SUM(CASE WHEN MONTO_RECARGADO >= 1 THEN MONTO_RECARGADO ELSE 0 END), 0) AS MONTO_RECARGADO
        FROM BD_PLANIFICACION.dbo.PP2025_N0
        WHERE DNI_VENDEDOR = @dni
            AND fecha BETWEEN '2025-06-01' AND '2025-11-30'
            AND FECHA_CARGA = @dateCalFunnel
        GROUP BY PERIODO_EVALUACION
    )
    -- Retornar datos de recargas por período (múltiples filas)
    SELECT 
        @dni AS dni_vendedor,
        COALESCE(cte.PERIODO_EVALUACION, 'N/A') AS PERIODO_EVALUACION,
        COALESCE(cte.MONTO_RECARGADO, 0) AS MONTO_RECARGADO,
        COALESCE(cte.MONTO_RECARGADO * 0.4, 0) AS ganaciaPorRecarga
    FROM (SELECT 1 AS dummy) AS base
    LEFT JOIN CTE cte ON 1=1;
    END

END
