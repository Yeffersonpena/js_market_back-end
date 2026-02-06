-- =============================================
-- Autor: Sistema
-- Fecha de creación: 2026-02-05
-- Descripción: Avance general de ventas Postpago (mes completo)
--              Incluye ventas sin cruce con entregable (LEFT JOIN)
--              Inusual (Alta > 2): si tiene Portabilidad se muestra con Alta=0 y sus portas; si no tiene portas se excluye
-- =============================================
CREATE PROCEDURE sp_Avance_pos
    @Año INT,
    @Mes INT
AS
BEGIN
    SET NOCOUNT ON;

    WITH VentasAgrupadas AS (
        SELECT
            VL.FECHA,
            COALESCE(E.ZONAL, VL.ZONAL) AS ZONAL,
            COALESCE(E.ACCION_1, VL.ACCION) AS ACCION_1,
            VL.DNI_RESPONSABLE,
            VL.DNI_VENDEDOR,
            E.NOMBRE_RESPONSABLE,
            E.NOMBRE_VENDEDOR1,
            SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) AS [Alta],
            SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Portabilidad],
            SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) +
            SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Total general]
        FROM
            PORTAL_COMERCIAL.dbo.VentasLog VL
            LEFT JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE E
                ON CAST(VL.DNI_RESPONSABLE AS INT) = E.DNI_RESPONSABLE
                AND E.AÑO = @Año
                AND E.MES = @Mes
                AND E.ESTADO = 'ACTIVO'
        WHERE
            VL.PRODUCT_NAME = 'Postpago'
            AND YEAR(VL.FECHA) = @Año
            AND MONTH(VL.FECHA) = @Mes
        GROUP BY
            VL.FECHA,
            VL.ZONAL,
            VL.ACCION,
            E.ZONAL,
            E.ACCION_1,
            VL.DNI_RESPONSABLE,
            VL.DNI_VENDEDOR,
            E.NOMBRE_RESPONSABLE,
            E.NOMBRE_VENDEDOR1
    )
    SELECT
        FECHA,
        ZONAL,
        ACCION_1,
        DNI_RESPONSABLE,
        DNI_VENDEDOR,
        NOMBRE_RESPONSABLE,
        NOMBRE_VENDEDOR1,
        CASE WHEN [Alta] > 2 THEN 0 ELSE [Alta] END AS [Alta],
        [Portabilidad],
        CASE WHEN [Alta] > 2 THEN [Portabilidad] ELSE [Total general] END AS [Total general]
    FROM
        VentasAgrupadas
    WHERE
        NOT ([Alta] > 2 AND [Portabilidad] = 0)
    ORDER BY
        FECHA;
END;
