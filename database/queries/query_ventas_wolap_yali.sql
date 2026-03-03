-- Ventas WOLAP + YALI (EQUIPOS). Ejecutar en base distributor_datamart.
-- Ajustar fechas en DATEFROMPARTS si es necesario.

SELECT *
FROM [dbo].[DD_WOLAP_VENTA_ANALISIS_DETALLADO]
WHERE FEC_EMISION BETWEEN DATEFROMPARTS(2026, 2, 1) AND DATEFROMPARTS(2026, 2, 28)
  AND PROD_LINEA <> 'CHIPS'

UNION ALL

SELECT
    CASE WHEN SUBSTRING(a.Num_Documento, 1, 2) = 'BV' THEN 'BV'
         WHEN SUBSTRING(a.Num_Documento, 1, 2) = 'FV' THEN 'FT' END AS TD,
    a.Num_Documento,
    FORMAT(a.Fecha, 'dd/MM/yyyy'),
    NULL,
    a.NombreCliente,
    NULL,
    NULL,
    a.Nif_Cliente_Prov,
    NULL AS cod_vendedor,
    a.x_vendedor,
    a.Codigo,
    a.Descripcion,
    NULL,
    a.Cantidad,
    a.PVP_Total,
    a.Imei_Icc_Sn,
    NULL AS icc,
    NULL,
    a.x_zonal,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    b.coste_total,
    a.NombreProveedor,
    NULL,
    NULL,
    b.num_documento,
    b.fecha_aux,
    NULL,
    b.num_documento,
    'EQUIPOS                       ',
    'EQUIPOS                       ',
    NULL,
    a.punto_venta,
    NULL,
    NULL
FROM [dbo].[YALI_VENTAS] AS a
LEFT JOIN [dbo].[YALI_COMPRAS] AS b ON a.Imei_Icc_Sn = b.imei_icc_sn
WHERE a.Fecha BETWEEN DATEFROMPARTS(2026, 2, 1) AND DATEFROMPARTS(2026, 2, 28);
