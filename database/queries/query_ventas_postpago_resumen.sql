-- Query para mostrar ventas de Postpago con formato similar a Excel
-- Relaciona VentasLog con PDV_OUT_ENTREGABLE por DNI_RESPONSABLE
-- Muestra resumen por FECHA, ZONAL, ACCION, DNI_RESPONSABLE, DNI_VENDEDOR
-- Con columnas separadas para Alta y Portabilidad

SELECT
    VL.FECHA,
    E.ZONAL AS [ZONAL JS],
    E.ACCION_1 AS [ACCION JS],
    VL.DNI_RESPONSABLE,
    VL.DNI_VENDEDOR,
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
    VL.DNI_VENDEDOR
ORDER BY
    VL.FECHA,
    E.ZONAL,
    E.ACCION_1,
    VL.DNI_RESPONSABLE,
    VL.DNI_VENDEDOR;

