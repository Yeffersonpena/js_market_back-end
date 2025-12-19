-- Query completa para mostrar ventas de Postpago con todos los campos requeridos
-- Incluye: CANAL, NOMBRE PDV, NOMBRE VVDD, RECARGADOR, BONO, ESTADO ABONO, OBS

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
        AND E.AÑO = 2025
        AND E.MES = 12
        AND E.ESTADO = 'ACTIVO'
        -- Filtros de fecha en VentasLog
        AND YEAR(VL.FECHA) = 2025
        AND MONTH(VL.FECHA) = 12
        -- Filtro opcional de días específicos (descomentar y ajustar según necesidad)
        -- AND DAY(VL.FECHA) IN (4, 5, 6)
    GROUP BY
        VL.FECHA,
        E.ZONAL,
        E.ACCION_1,
        VL.DNI_RESPONSABLE,
        VL.DNI_VENDEDOR,
        E.NOMBRE_RESPONSABLE
)
SELECT
    VA.FECHA,
    VA.ZONAL AS [ZONAL JS],
    VA.ACCION_1 AS [ACCION JS],
    -- CANAL: Si DNI_RESPONSABLE == DNI_VENDEDOR entonces "PDV", sino "VVDD PDV"
    CASE
        WHEN VA.DNI_RESPONSABLE = VA.DNI_VENDEDOR THEN 'PDV'
        ELSE 'VVDD PDV'
    END AS [CANAL],
    VA.DNI_RESPONSABLE,
    -- NOMBRE PDV: De la tabla entregable
    VA.NOMBRE_RESPONSABLE AS [NOMBRE PDV],
    VA.DNI_VENDEDOR AS [DNI QUE VENDIÓ],
    -- NOMBRE VVDD: Si CANAL es "PDV" entonces es el mismo nombre del PDV, sino "-"
    CASE
        WHEN VA.DNI_RESPONSABLE = VA.DNI_VENDEDOR THEN VA.NOMBRE_RESPONSABLE
        ELSE '-'
    END AS [NOMBRE VVDD],
    -- RECARGADOR: De BASE_RECARGADORES, primer match (como VLOOKUP)
    ISNULL(CAST(R.NUM_RECARGA AS VARCHAR), '-') AS [RECARGADOR],
    -- Alta, Portabilidad, Total
    VA.[Alta],
    VA.[Portabilidad],
    VA.[Total general],
    -- BONO: =SI(I15<>"-";SI(L15>3;6;L15*2);0)
    -- I: numero recarga (RECARGADOR), L: total general
    CASE
        WHEN R.NUM_RECARGA IS NOT NULL THEN
            CASE
                WHEN VA.[Total general] > 3 THEN 6
                ELSE VA.[Total general] * 2
            END
        ELSE 0
    END AS [BONO],
    -- ESTADO ABONO: Si BONO = 0 entonces "PENDIENTE", sino "ABONADO"
    CASE
        WHEN (CASE
                WHEN R.NUM_RECARGA IS NOT NULL THEN
                    CASE
                        WHEN VA.[Total general] > 3 THEN 6
                        ELSE VA.[Total general] * 2
                    END
                ELSE 0
            END) = 0 THEN 'PENDIENTE'
        ELSE 'ABONADO'
    END AS [ESTADO ABONO],
    -- OBS: Si ESTADO ABONO es "ABONADO" entonces "ABONADO", sino "ENVIAR CREACION"
    CASE
        WHEN (CASE
                WHEN R.NUM_RECARGA IS NOT NULL THEN
                    CASE
                        WHEN VA.[Total general] > 3 THEN 6
                        ELSE VA.[Total general] * 2
                    END
                ELSE 0
            END) = 0 THEN 'ENVIAR CREACION'
        ELSE 'ABONADO'
    END AS [OBS]
FROM
    VentasAgrupadas VA
    -- LEFT JOIN con BASE_RECARGADORES para obtener el primer match (como VLOOKUP)
    OUTER APPLY (
        SELECT TOP 1 NUM_RECARGA
        FROM PORTAL_COMERCIAL.dbo.BASE_RECARGADORES BR
        WHERE BR.DNI = CAST(VA.DNI_VENDEDOR AS INT)
        ORDER BY BR.NUM_RECARGA ASC  -- Toma el primer NUM_RECARGA (como VLOOKUP)
    ) R
ORDER BY
    VA.FECHA,
    VA.ZONAL,
    VA.ACCION_1,
    VA.DNI_RESPONSABLE,
    VA.DNI_VENDEDOR;

