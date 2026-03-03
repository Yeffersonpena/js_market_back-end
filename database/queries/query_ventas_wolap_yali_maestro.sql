-- Ventas WOLAP + YALI unificadas con MARCA y MODELO desde DCN_MAESTRO_PRODUCTO.
-- WOLAP: match por NOM_PRODUCTO = CNOM_PROD. YALI: match por Descripcion = CNOM_PROD.
-- Ejecutar en base DISTRIBUTOR_DATAMART.

SELECT
    v.NRODOC AS num_documento,
    v.FEC_EMISION AS fecha,
    v.NOM_PRODUCTO AS nom_producto,
    p.MARCA AS marca,
    p.MODELO AS modelo,
    v.IMEI AS imei,
    v.ALMACEN AS almacen,
    v.PROD_CATEGORIA AS prod_categoria,
    v.PROD_LINEA AS prod_linea,
    'JSMS' AS empresa
FROM DISTRIBUTOR_DATAMART.dbo.DD_WOLAP_VENTA_ANALISIS_DETALLADO v
LEFT JOIN DISTRIBUTOR_DATAMART.dbo.DCN_MAESTRO_PRODUCTO p
    ON RTRIM(LTRIM(v.NOM_PRODUCTO)) = RTRIM(LTRIM(p.CNOM_PROD))

UNION ALL

SELECT
    y.Num_Documento AS num_documento,
    y.Fecha AS fecha,
    y.Descripcion AS nom_producto,
    p.MARCA AS marca,
    p.MODELO AS modelo,
    y.Imei_Icc_Sn AS imei,
    y.x_zonal AS almacen,
    'EQUIPOS' AS prod_categoria,
    'EQUIPOS' AS prod_linea,
    'YALI' AS empresa
FROM DISTRIBUTOR_DATAMART.dbo.YALI_VENTAS y
LEFT JOIN DISTRIBUTOR_DATAMART.dbo.DCN_MAESTRO_PRODUCTO p
    ON RTRIM(LTRIM(y.Descripcion)) = RTRIM(LTRIM(p.CNOM_PROD));
