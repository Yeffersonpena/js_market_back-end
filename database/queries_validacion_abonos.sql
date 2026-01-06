-- =============================================
-- QUERY 1: Verificar si hay ventas Postpago del 16 al 21 en VentasLog
-- =============================================
DECLARE @Año INT = YEAR(GETDATE());
DECLARE @Mes INT = MONTH(GETDATE());

SELECT
    DAY(VL.FECHA) AS Dia,
    COUNT(*) AS TotalVentas
FROM PORTAL_COMERCIAL.dbo.VentasLog VL
WHERE VL.PRODUCT_NAME = 'Postpago'
    AND YEAR(VL.FECHA) = @Año
    AND MONTH(VL.FECHA) = @Mes
    AND DAY(VL.FECHA) BETWEEN 16 AND 21
GROUP BY DAY(VL.FECHA)
ORDER BY Dia;

-- =============================================
-- QUERY 2: Verificar qué ventas del 16-21 NO cumplen los criterios del SP
-- =============================================
DECLARE @Año INT = YEAR(GETDATE());
DECLARE @Mes INT = MONTH(GETDATE());

SELECT
    DAY(VL.FECHA) AS Dia,
    VL.FECHA,
    VL.DNI_RESPONSABLE,
    SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) AS [Alta],
    CASE
        WHEN NOT EXISTS (
            SELECT 1 FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE E
            WHERE CAST(VL.DNI_RESPONSABLE AS INT) = E.DNI_RESPONSABLE
                AND E.AÑO = @Año AND E.MES = @Mes AND E.ESTADO = 'ACTIVO'
        ) THEN 'Sin PDV activo'
        WHEN VL.FECHA IN (
            SELECT DISTINCT FECHA FROM PORTAL_COMERCIAL.dbo.abonos_postpago_log
            WHERE YEAR(FECHA) = @Año AND MONTH(FECHA) = @Mes
        ) THEN 'Ya registrada'
        WHEN SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) > 2 THEN 'Alta > 2'
        ELSE 'OK'
    END AS Motivo
FROM PORTAL_COMERCIAL.dbo.VentasLog VL
WHERE VL.PRODUCT_NAME = 'Postpago'
    AND YEAR(VL.FECHA) = @Año
    AND MONTH(VL.FECHA) = @Mes
    AND DAY(VL.FECHA) BETWEEN 16 AND 21
GROUP BY VL.FECHA, VL.DNI_RESPONSABLE
HAVING
    NOT EXISTS (
        SELECT 1 FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE E
        WHERE CAST(VL.DNI_RESPONSABLE AS INT) = E.DNI_RESPONSABLE
            AND E.AÑO = @Año AND E.MES = @Mes AND E.ESTADO = 'ACTIVO'
    )
    OR VL.FECHA IN (
        SELECT DISTINCT FECHA FROM PORTAL_COMERCIAL.dbo.abonos_postpago_log
        WHERE YEAR(FECHA) = @Año AND MONTH(FECHA) = @Mes
    )
    OR SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) > 2
ORDER BY Dia, Motivo;

-- =============================================
-- QUERY 3: Verificar ventas del 16-21 que SÍ deberían procesarse (Alta <= 2)
-- =============================================
DECLARE @Año INT = YEAR(GETDATE());
DECLARE @Mes INT = MONTH(GETDATE());

SELECT
    DAY(VL.FECHA) AS Dia,
    VL.FECHA,
    VL.DNI_RESPONSABLE,
    SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) AS [Alta],
    SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Portabilidad],
    CASE
        WHEN EXISTS (
            SELECT 1 FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE E
            WHERE CAST(VL.DNI_RESPONSABLE AS INT) = E.DNI_RESPONSABLE
                AND E.AÑO = @Año AND E.MES = @Mes AND E.ESTADO = 'ACTIVO'
        ) THEN 'SÍ'
        ELSE 'NO'
    END AS TienePDVActivo,
    CASE
        WHEN VL.FECHA IN (
            SELECT DISTINCT FECHA FROM PORTAL_COMERCIAL.dbo.abonos_postpago_log
            WHERE YEAR(FECHA) = @Año AND MONTH(FECHA) = @Mes
        ) THEN 'SÍ'
        ELSE 'NO'
    END AS YaRegistrada
FROM PORTAL_COMERCIAL.dbo.VentasLog VL
WHERE VL.PRODUCT_NAME = 'Postpago'
    AND YEAR(VL.FECHA) = @Año
    AND MONTH(VL.FECHA) = @Mes
    AND DAY(VL.FECHA) BETWEEN 16 AND 21
GROUP BY VL.FECHA, VL.DNI_RESPONSABLE
HAVING SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) <= 2
ORDER BY Dia, VL.FECHA;

-- =============================================
-- QUERY 4: Simular exactamente lo que hace el SP para ver qué está fallando
-- =============================================
DECLARE @Año INT = YEAR(GETDATE());
DECLARE @Mes INT = MONTH(GETDATE());

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
        VL.PRODUCT_NAME = 'Postpago'
        AND E.AÑO = @Año
        AND E.MES = @Mes
        AND E.ESTADO = 'ACTIVO'
        AND YEAR(VL.FECHA) = @Año
        AND MONTH(VL.FECHA) = @Mes
        AND DAY(VL.FECHA) BETWEEN 16 AND 21
        AND VL.FECHA NOT IN (
            SELECT DISTINCT FECHA
            FROM PORTAL_COMERCIAL.dbo.abonos_postpago_log
            WHERE YEAR(FECHA) = @Año
                AND MONTH(FECHA) = @Mes
        )
    GROUP BY
        VL.FECHA,
        E.ZONAL,
        E.ACCION_1,
        VL.DNI_RESPONSABLE,
        VL.DNI_VENDEDOR,
        E.NOMBRE_RESPONSABLE
)
SELECT
    DAY(VA.FECHA) AS Dia,
    VA.FECHA,
    VA.DNI_RESPONSABLE,
    VA.DNI_VENDEDOR,
    VA.[Alta],
    VA.[Portabilidad],
    VA.[Total general],
    CASE WHEN VA.[Alta] <= 2 THEN 'SÍ procesa' ELSE 'NO procesa (Alta > 2)' END AS Resultado
FROM VentasAgrupadas VA
WHERE VA.[Alta] <= 2
ORDER BY Dia, VA.FECHA;

-- =============================================
-- QUERY 5: Simular TODO el proceso del SP hasta el INSERT (incluyendo recargador y bono)
-- =============================================
DECLARE @Año INT = YEAR(GETDATE());
DECLARE @Mes INT = MONTH(GETDATE());

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
        VL.PRODUCT_NAME = 'Postpago'
        AND E.AÑO = @Año
        AND E.MES = @Mes
        AND E.ESTADO = 'ACTIVO'
        AND YEAR(VL.FECHA) = @Año
        AND MONTH(VL.FECHA) = @Mes
        AND DAY(VL.FECHA) BETWEEN 16 AND 21
        AND VL.FECHA NOT IN (
            SELECT DISTINCT FECHA
            FROM PORTAL_COMERCIAL.dbo.abonos_postpago_log
            WHERE YEAR(FECHA) = @Año
                AND MONTH(FECHA) = @Mes
        )
    GROUP BY
        VL.FECHA,
        E.ZONAL,
        E.ACCION_1,
        VL.DNI_RESPONSABLE,
        VL.DNI_VENDEDOR,
        E.NOMBRE_RESPONSABLE
),
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
            ORDER BY BR.NUM_RECARGA ASC
        ) R
),
VentasConBono AS (
    SELECT
        VCR.*,
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
    WHERE
        VCR.[Alta] <= 2
)
SELECT
    DAY(VCB.FECHA) AS Dia,
    VCB.FECHA,
    VCB.DNI_RESPONSABLE,
    VCB.DNI_VENDEDOR,
    VCB.[Alta],
    VCB.[Portabilidad],
    VCB.[Total general],
    VCB.NUM_RECARGA,
    VCB.[BONO],
    'DEBERÍA INSERTARSE' AS Estado
FROM VentasConBono VCB
ORDER BY Dia, VCB.FECHA;

-- =============================================
-- QUERY 6: Verificar si los registros que DEBERÍAN insertarse ya están en abonos_postpago_log
-- =============================================
DECLARE @Año INT = YEAR(GETDATE());
DECLARE @Mes INT = MONTH(GETDATE());

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
        VL.PRODUCT_NAME = 'Postpago'
        AND E.AÑO = @Año
        AND E.MES = @Mes
        AND E.ESTADO = 'ACTIVO'
        AND YEAR(VL.FECHA) = @Año
        AND MONTH(VL.FECHA) = @Mes
        AND DAY(VL.FECHA) BETWEEN 16 AND 21
        AND VL.FECHA NOT IN (
            SELECT DISTINCT FECHA
            FROM PORTAL_COMERCIAL.dbo.abonos_postpago_log
            WHERE YEAR(FECHA) = @Año
                AND MONTH(FECHA) = @Mes
        )
    GROUP BY
        VL.FECHA,
        E.ZONAL,
        E.ACCION_1,
        VL.DNI_RESPONSABLE,
        VL.DNI_VENDEDOR,
        E.NOMBRE_RESPONSABLE
),
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
            ORDER BY BR.NUM_RECARGA ASC
        ) R
),
VentasConBono AS (
    SELECT
        VCR.*,
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
    WHERE
        VCR.[Alta] <= 2
)
SELECT
    DAY(VCB.FECHA) AS Dia,
    VCB.FECHA,
    VCB.DNI_RESPONSABLE,
    VCB.DNI_VENDEDOR,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM PORTAL_COMERCIAL.dbo.abonos_postpago_log APL
            WHERE APL.FECHA = VCB.FECHA
                AND APL.DNI_RESPONSABLE = VCB.DNI_RESPONSABLE
                AND APL.DNI_VENDEDOR = VCB.DNI_VENDEDOR
        ) THEN '✅ YA ESTÁ REGISTRADO'
        ELSE '❌ NO ESTÁ REGISTRADO (PROBLEMA)'
    END AS Estado
FROM VentasConBono VCB
ORDER BY Dia, VCB.FECHA;

-- =============================================
-- SENTENCIAS PARA EJECUTAR EL SP
-- =============================================

-- Opción 1: Ejecutar para todo el mes (procesa todos los días no registrados)
EXEC PORTAL_COMERCIAL.dbo.sp_Registrar_AbonosPostpago
    @Año = 2025,
    @Mes = 12,
    @DiasFiltro = NULL;

-- Opción 2: Ejecutar SOLO para los días 16-21 (forzar solo esos días)
EXEC PORTAL_COMERCIAL.dbo.sp_Registrar_AbonosPostpago
    @Año = 2025,
    @Mes = 12,
    @DiasFiltro = '16,17,18,19,20,21';

-- =============================================
-- ELIMINAR REGISTROS DEL 16 AL 21 DE DICIEMBRE 2025
-- =============================================
DELETE FROM PORTAL_COMERCIAL.dbo.abonos_postpago_log
WHERE YEAR(FECHA) = 2025
    AND MONTH(FECHA) = 12
    AND DAY(FECHA) BETWEEN 16 AND 21;

-- =============================================
-- VERIFICAR CÁLCULO DE BONO (especialmente Total = 3)
-- =============================================
SELECT
    FECHA,
    DNI_RESPONSABLE,
    DNI_VENDEDOR,
    RECARGADOR,
    Alta,
    Portabilidad,
    TOTAL,
    BONO,
    CASE
        WHEN RECARGADOR <> '-' THEN
            CASE
                WHEN TOTAL > 3 THEN 6
                ELSE TOTAL * 2
            END
        ELSE 0
    END AS BONO_ESPERADO,
    CASE
        WHEN BONO = CASE
            WHEN RECARGADOR <> '-' THEN
                CASE
                    WHEN TOTAL > 3 THEN 6
                    ELSE TOTAL * 2
                END
            ELSE 0
        END THEN '✅ CORRECTO'
        ELSE '❌ INCORRECTO'
    END AS Validacion
FROM PORTAL_COMERCIAL.dbo.abonos_postpago_log
WHERE YEAR(FECHA) = 2025
    AND MONTH(FECHA) = 12
    AND TOTAL = 3
ORDER BY FECHA;
