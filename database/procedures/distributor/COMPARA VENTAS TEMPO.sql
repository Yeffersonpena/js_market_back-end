DECLARE @MarzoIni date = '2026-03-01';
DECLARE @MarzoFin date = '2026-03-31';

;WITH Y AS (
    SELECT
        v.*,
        CONVERT(date, v.Fecha) AS FechaDia,
        REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(v.Descripcion, N''))), N' ', N''), CHAR(9), N''), CHAR(160), N'') AS DescCompacta
    FROM DISTRIBUTOR_DATAMART.dbo.YALI_VENTAS v
    WHERE CONVERT(date, v.Fecha) BETWEEN @MarzoIni AND @MarzoFin
),
T AS (
    SELECT
        t.*,
        CONVERT(date, t.Fecha) AS FechaDia,
        REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(t.Descripcion, N''))), N' ', N''), CHAR(9), N''), CHAR(160), N'') AS DescCompacta
    FROM DISTRIBUTOR_DATAMART.dbo.YALI_VENTAS_TEMPO t
    WHERE CONVERT(date, t.Fecha) BETWEEN @MarzoIni AND @MarzoFin
)
SELECT
    -- Llave custom (útil para revisar duplicados)
    CONCAT(
        CONVERT(varchar(10), y.FechaDia, 23), N'|',
        ISNULL(y.Punto_Venta, N''), N'|',
        ISNULL(y.Imei_Icc_Sn, N''), N'|',
        ISNULL(y.Num_Documento, N''), N'|',
        y.DescCompacta
    ) AS LlaveJoin,

    -- YALI_VENTAS (líneas ~8-33 del script)
    y.Fecha,
    y.Fecha_Aux,
    y.Tipo_Mov,
    y.Con_Devolucion,
    y.Punto_Venta,
    y.SFID,
    y.Tipo,
    y.Codigo,
    y.EAN,
    y.Familia,
    y.Categoria,
    y.Imei_Icc_Sn,
    y.Descripcion,
    y.InfoAdicional,
    y.Operacion,
    y.Num_Documento,
    y.NombreCliente,
    y.Nif_Cliente_Prov,
    y.Segmento,
    y.NombreProveedor,
    y.NifProveedor,
    y.Autor,
    y.Comercial,
    y.Cantidad,
    y.PVP_Total,
    y.Coste_Total,

    -- TEMPO (mismos importes al costado)
    t.PVP_Total  AS PVP_Total_TEMPO,
    t.Coste_Total AS Coste_Total_TEMPO,

    -- Diferencias (NULL si no hubo match en TEMPO)
    CASE WHEN t.Num_Documento IS NULL THEN NULL ELSE y.PVP_Total  - t.PVP_Total  END AS Diff_PVP_Total,
    CASE WHEN t.Num_Documento IS NULL THEN NULL ELSE y.Coste_Total - t.Coste_Total END AS Diff_Coste_Total

FROM Y y
LEFT JOIN T t
    ON y.FechaDia = t.FechaDia
   AND ISNULL(y.Punto_Venta, N'') = ISNULL(t.Punto_Venta, N'')
   AND ISNULL(y.Imei_Icc_Sn, N'') = ISNULL(t.Imei_Icc_Sn, N'')
   AND ISNULL(y.Num_Documento, N'') = ISNULL(t.Num_Documento, N'')
   AND y.DescCompacta = t.DescCompacta
ORDER BY y.Fecha, y.Num_Documento, y.Imei_Icc_Sn;
