-- Ventas YALI con MARCA y MODELO desde DCN_MAESTRO_PRODUCTO.
-- Match por Descripcion (YALI_VENTAS) = CNOM_PROD (DCN_MAESTRO_PRODUCTO).
-- Ejecutar en base DISTRIBUTOR_DATAMART.

SELECT
    v.Num_Documento AS num_documento,
    v.Fecha AS fecha,
    v.Descripcion AS descripcion,
    p.MARCA AS marca,
    p.MODELO AS modelo,
    v.Imei_Icc_Sn AS imei_icc_sn,
    v.x_zonal AS xzonal,
    'EQUIPOS',
    'EQUIPOS',
    'YALI'
FROM DISTRIBUTOR_DATAMART.dbo.YALI_VENTAS v
LEFT JOIN DISTRIBUTOR_DATAMART.dbo.DCN_MAESTRO_PRODUCTO p
    ON RTRIM(LTRIM(v.Descripcion)) = RTRIM(LTRIM(p.CNOM_PROD));
