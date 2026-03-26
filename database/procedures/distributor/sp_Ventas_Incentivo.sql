-- Unifica ventas de WOLAP (DD_WOLAP_VENTA_ANALISIS_DETALLADO) y YALI (YALI_VENTAS).
-- Agrupación: fecha, zonal, vendedor, línea. Sin detalle por producto. Origen WOLAP/YALI.
-- Filtros WOLAP idénticos a la query de referencia para que el monto total coincida.
-- NOM_VENDEDOR: nombre normalizado; si hay fila en vendedor_nombre_diccionario se usa nombre_canonico (un solo nombre).
CREATE PROCEDURE sp_Ventas_Incentivo
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        FEC_EMISION,
        ALMACEN,
        NOM_VENDEDOR,
        PROD_LINEA,
        precio_vta,
        Origen
    FROM (
        -- WOLAP: mismo WHERE y CROSS APPLY que la query de referencia (monto total igual)
        SELECT
            CAST(v.[FEC_EMISION] AS DATE) AS FEC_EMISION,
            UPPER(z.[ZONA]) AS ALMACEN,
            COALESCE(dict.[nombre_canonico], vn.[nom_norm]) AS NOM_VENDEDOR,
            LTRIM(RTRIM(v.[PROD_LINEA])) AS PROD_LINEA,
            CAST(SUM(v.[PRECIO_VTA]) AS DECIMAL(18,4)) AS precio_vta,
            'WOLAP' AS Origen
        FROM [DISTRIBUTOR_DATAMART].[dbo].[DD_WOLAP_VENTA_ANALISIS_DETALLADO] v
        CROSS APPLY (
            VALUES (
                CASE
                    WHEN v.COD_VENDEDOR IN (148, 225, 279, 280) THEN 'Huánuco'
                    WHEN v.COD_VENDEDOR IN (185, 277, 278) THEN 'Pucallpa'
                    WHEN v.COD_VENDEDOR IN (221, 276) THEN 'Huancayo'
                    WHEN v.COD_VENDEDOR IN (198) THEN 'Ayacucho'
                    WHEN v.COD_VENDEDOR IN (281) THEN 'Cusco'
                    WHEN LTRIM(RTRIM(v.[ALMACEN])) = 'LOG - AREQUIPA' THEN 'Arequipa'
                    WHEN LTRIM(RTRIM(v.[ALMACEN])) = 'La Merced' THEN 'Huancayo'
                    ELSE LTRIM(RTRIM(v.[ALMACEN]))
                END
            )
        ) z([ZONA])
        CROSS APPLY (
            SELECT UPPER(LTRIM(RTRIM(
                REPLACE(REPLACE(ISNULL(v.[NOM_VENDEDOR], N''), CHAR(160), N' '), CHAR(9), N' ')
            ))) AS nom_norm
        ) vn
        LEFT JOIN [DISTRIBUTOR_DATAMART].[dbo].[vendedor_nombre_diccionario] dict
            ON dict.[nombre_alias] = vn.[nom_norm]
            AND dict.[activo] = 1
        WHERE CAST(v.[FEC_EMISION] AS DATE) >= @FechaInicio
            AND CAST(v.[FEC_EMISION] AS DATE) <= @FechaFin
            AND v.[PROD_LINEA] != 'CHIPS'
            AND v.cod_cliente <> '00026087'
            AND v.REPARTO NOT LIKE 'CANAL MASIVO%'
            AND v.cdoc_ide NOT IN ('20612606405', '20615283607')
        GROUP BY
            CAST(v.[FEC_EMISION] AS DATE),
            UPPER(z.[ZONA]),
            COALESCE(dict.[nombre_canonico], vn.[nom_norm]),
            LTRIM(RTRIM(v.[PROD_LINEA]))

        UNION ALL

        -- YALI: ventas canal Yali (EQUIPOS), agrupado por fecha, zonal, vendedor
        SELECT
            CAST(y.[Fecha] AS DATE) AS FEC_EMISION,
            UPPER(LTRIM(RTRIM(y.[x_zonal]))) AS ALMACEN,
            COALESCE(dict.[nombre_canonico], vn.[nom_norm]) AS NOM_VENDEDOR,
            'EQUIPOS' AS PROD_LINEA,
            CAST(SUM(y.[X_SALDO]) AS DECIMAL(18,4)) AS precio_vta,
            'YALI' AS Origen
        FROM [DISTRIBUTOR_DATAMART].[dbo].[YALI_VENTAS] y
        CROSS APPLY (
            SELECT UPPER(LTRIM(RTRIM(
                REPLACE(REPLACE(ISNULL(y.[x_vendedor], N''), CHAR(160), N' '), CHAR(9), N' ')
            ))) AS nom_norm
        ) vn
        LEFT JOIN [DISTRIBUTOR_DATAMART].[dbo].[vendedor_nombre_diccionario] dict
            ON dict.[nombre_alias] = vn.[nom_norm]
            AND dict.[activo] = 1
        WHERE CAST(y.[Fecha] AS DATE) >= @FechaInicio
            AND CAST(y.[Fecha] AS DATE) <= @FechaFin
        GROUP BY
            CAST(y.[Fecha] AS DATE),
            UPPER(LTRIM(RTRIM(y.[x_zonal]))),
            COALESCE(dict.[nombre_canonico], vn.[nom_norm])
    ) u
    ORDER BY u.Origen, u.FEC_EMISION, u.ALMACEN, u.NOM_VENDEDOR, u.PROD_LINEA;
END
