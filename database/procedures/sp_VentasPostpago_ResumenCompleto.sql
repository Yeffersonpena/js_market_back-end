-- =============================================
-- Autor: Sistema
-- Fecha de creación: 2025-01-XX
-- Descripción: Obtiene resumen completo de ventas Postpago con cálculo de bonos
--              Incluye: CANAL, NOMBRE PDV, NOMBRE VVDD, RECARGADOR, BONO, ESTADO ABONO, OBS
-- =============================================
CREATE PROCEDURE PORTAL_COMERCIAL.dbo.sp_VentasPostpago_ResumenCompleto
    @Año INT = 2025,
    @Mes INT = 12,
    @EstadoEntregable VARCHAR(50) = 'ACTIVO',
    @DiasFiltro VARCHAR(MAX) = NULL  -- Ejemplo: '4,5,6' o NULL para todos los días
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE 1: Agrupar ventas por fecha, zonal, acción, DNI responsable y DNI vendedor
    WITH VentasAgrupadas AS (
        SELECT
            VL.FECHA,
            E.ZONAL,
            E.ACCION_1,
            VL.DNI_RESPONSABLE,
            VL.DNI_VENDEDOR,
            E.NOMBRE_RESPONSABLE,
            SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) AS [Alta],
            SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Portabilidad],
            SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) +
            SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Total general]
        FROM
            PORTAL_COMERCIAL.dbo.VentasLog VL
            INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE E
                ON CAST(VL.DNI_RESPONSABLE AS INT) = E.DNI_RESPONSABLE
        WHERE
            -- Filtro de producto
            VL.PRODUCT_NAME = 'Postpago'
            -- Filtros de tabla entregable
            AND E.AÑO = @Año
            AND E.MES = @Mes
            AND E.ESTADO = @EstadoEntregable
            -- Filtros de fecha en VentasLog
            AND YEAR(VL.FECHA) = @Año
            AND MONTH(VL.FECHA) = @Mes
            -- Filtro opcional de días específicos
            AND (@DiasFiltro IS NULL
                 OR DAY(VL.FECHA) IN (
                     SELECT CAST(LTRIM(RTRIM(value)) AS INT)
                     FROM STRING_SPLIT(@DiasFiltro, ',')
                     WHERE ISNUMERIC(LTRIM(RTRIM(value))) = 1
                 ))
        GROUP BY
            VL.FECHA,
            E.ZONAL,
            E.ACCION_1,
            VL.DNI_RESPONSABLE,
            VL.DNI_VENDEDOR,
            E.NOMBRE_RESPONSABLE
    ),
    -- CTE 2: Agregar información de recargador (primer match como VLOOKUP)
    VentasConRecargador AS (
        SELECT
            VA.*,
            R.NUM_RECARGA
        FROM
            VentasAgrupadas VA
            OUTER APPLY (
                SELECT TOP 1 NUM_RECARGA
                FROM PORTAL_COMERCIAL.dbo.BASE_RECARGADORES BR
                WHERE BR.DNI = CAST(VA.DNI_VENDEDOR AS INT)
                ORDER BY BR.NUM_RECARGA ASC  -- Toma el primer NUM_RECARGA (como VLOOKUP)
            ) R
    ),
    -- CTE 3: Calcular BONO para evitar repetir la lógica
    VentasConBono AS (
        SELECT
            VCR.*,
            -- BONO: =SI(I15<>"-";SI(L15>3;6;L15*2);0)
            -- I: numero recarga (RECARGADOR), L: total general
            CASE
                WHEN VCR.NUM_RECARGA IS NOT NULL THEN
                    CASE
                        WHEN VCR.[Total general] > 3 THEN 6
                        ELSE VCR.[Total general] * 2
                    END
                ELSE 0
            END AS [BONO]
        FROM
            VentasConRecargador VCR
    )
    -- SELECT final con todos los campos calculados
    SELECT
        VCB.FECHA,
        VCB.ZONAL AS [ZONAL JS],
        VCB.ACCION_1 AS [ACCION JS],
        -- CANAL: Si DNI_RESPONSABLE == DNI_VENDEDOR entonces "PDV", sino "VVDD PDV"
        CASE
            WHEN VCB.DNI_RESPONSABLE = VCB.DNI_VENDEDOR THEN 'PDV'
            ELSE 'VVDD PDV'
        END AS [CANAL],
        VCB.DNI_RESPONSABLE,
        -- NOMBRE PDV: De la tabla entregable
        VCB.NOMBRE_RESPONSABLE AS [NOMBRE PDV],
        VCB.DNI_VENDEDOR AS [DNI QUE VENDIÓ],
        -- NOMBRE VVDD: Si CANAL es "PDV" entonces es el mismo nombre del PDV, sino "-"
        CASE
            WHEN VCB.DNI_RESPONSABLE = VCB.DNI_VENDEDOR THEN VCB.NOMBRE_RESPONSABLE
            ELSE '-'
        END AS [NOMBRE VVDD],
        -- RECARGADOR: De BASE_RECARGADORES, primer match (como VLOOKUP)
        ISNULL(CAST(VCB.NUM_RECARGA AS VARCHAR), '-') AS [RECARGADOR],
        -- Alta, Portabilidad, Total
        VCB.[Alta],
        VCB.[Portabilidad],
        VCB.[Total general],
        -- BONO: Ya calculado en CTE anterior
        VCB.[BONO],
        -- ESTADO ABONO: Si BONO = 0 entonces "PENDIENTE", sino "ABONADO"
        CASE
            WHEN VCB.[BONO] = 0 THEN 'PENDIENTE'
            ELSE 'ABONADO'
        END AS [ESTADO ABONO],
        -- OBS: Si ESTADO ABONO es "ABONADO" entonces "ABONADO", sino "ENVIAR CREACION"
        CASE
            WHEN VCB.[BONO] = 0 THEN 'ENVIAR CREACION'
            ELSE 'ABONADO'
        END AS [OBS]
    FROM
        VentasConBono VCB
    ORDER BY
        VCB.FECHA,
        VCB.ZONAL,
        VCB.ACCION_1,
        VCB.DNI_RESPONSABLE,
        VCB.DNI_VENDEDOR;

END;
GO

