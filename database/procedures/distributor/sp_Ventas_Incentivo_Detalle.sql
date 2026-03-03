-- Ventas en detalle por producto (WOLAP + YALI). Sin agrupar; filtro por nombre de producto (LIKE).
-- Misma lógica de filtros que sp_Ventas_Incentivo.
CREATE PROCEDURE sp_Ventas_Incentivo_Detalle
    @NombreProducto NVARCHAR(255),
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
        NombreProducto,
        precio_vta,
        Origen
    FROM (
        -- WOLAP: una fila por línea de venta
        SELECT
            CAST(v.[FEC_EMISION] AS DATE) AS FEC_EMISION,
            UPPER(z.[ZONA]) AS ALMACEN,
            UPPER(LTRIM(RTRIM(v.[NOM_VENDEDOR]))) AS NOM_VENDEDOR,
            LTRIM(RTRIM(v.[PROD_LINEA])) AS PROD_LINEA,
            LTRIM(RTRIM(v.[NOM_PRODUCTO])) AS NombreProducto,
            CAST(v.[PRECIO_VTA] AS DECIMAL(18,4)) AS precio_vta,
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
        WHERE CAST(v.[FEC_EMISION] AS DATE) >= @FechaInicio
            AND CAST(v.[FEC_EMISION] AS DATE) <= @FechaFin
            AND v.[PROD_LINEA] != 'CHIPS'
            AND v.cod_cliente <> '00026087'
            AND v.REPARTO NOT LIKE 'CANAL MASIVO%'
            AND v.cdoc_ide NOT IN ('20612606405', '20615283607')
            AND v.[NOM_PRODUCTO] LIKE '%' + LTRIM(RTRIM(@NombreProducto)) + '%'

        UNION ALL

        -- YALI: una fila por línea de venta
        SELECT
            CAST(y.[Fecha] AS DATE) AS FEC_EMISION,
            UPPER(LTRIM(RTRIM(y.[x_zonal]))) AS ALMACEN,
            UPPER(LTRIM(RTRIM(y.[x_vendedor]))) AS NOM_VENDEDOR,
            'EQUIPOS' AS PROD_LINEA,
            LTRIM(RTRIM(y.[Descripcion])) AS NombreProducto,
            CAST(y.[X_SALDO] AS DECIMAL(18,4)) AS precio_vta,
            'YALI' AS Origen
        FROM [DISTRIBUTOR_DATAMART].[dbo].[YALI_VENTAS] y
        WHERE CAST(y.[Fecha] AS DATE) >= @FechaInicio
            AND CAST(y.[Fecha] AS DATE) <= @FechaFin
            AND y.[Descripcion] LIKE '%' + LTRIM(RTRIM(@NombreProducto)) + '%'
    ) u
    ORDER BY u.Origen, u.FEC_EMISION, u.ALMACEN, u.NOM_VENDEDOR, u.PROD_LINEA, u.NombreProducto;
END
