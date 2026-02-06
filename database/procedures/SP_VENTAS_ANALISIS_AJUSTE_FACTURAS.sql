CREATE OR ALTER PROCEDURE SP_VENTAS_ANALISIS_AJUSTE_FACTURAS
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Ajustes TABLE (
        NRODOC VARCHAR(20) PRIMARY KEY,
        Factor DECIMAL(10, 4) NOT NULL
    );

    INSERT INTO @Ajustes (NRODOC, Factor)
    VALUES
        ('FA02-0000135', 3.8),
        ('FA02-0000136', 3.8),
        ('FA02-0000137', 3.8);

    SELECT
        CAST(v.[FEC_EMISION] AS DATE) AS [FEC_EMISION],
        z.[ZONA] AS [ALMACEN],
        v.COD_VENDEDOR,
        v.[NOM_VENDEDOR],
        v.[NOM_PRODUCTO],
        v.[PROD_LINEA],
        SUM(v.[PRECIO_VTA] * ISNULL(a.Factor, 1)) AS precio_vta
    FROM
        [DD_WOLAP_VENTA_ANALISIS_DETALLADO] v
        LEFT JOIN @Ajustes a
            ON a.NRODOC = v.NRODOC
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
    WHERE
        CAST(v.[FEC_EMISION] AS DATE) >= @FechaInicio
        AND CAST(v.[FEC_EMISION] AS DATE) <= @FechaFin
        AND v.cod_cliente <> '00026087'
        AND REPARTO NOT LIKE 'CANAL MASIVO%'
        AND cdoc_ide NOT IN ('20612606405', '20615283607')
    GROUP BY
        CAST(v.[FEC_EMISION] AS DATE),
        z.[ZONA],
        v.COD_VENDEDOR,
        v.[NOM_VENDEDOR],
        v.[NOM_PRODUCTO],
        v.[PROD_LINEA]
    ORDER BY
        6,
        1,
        2;
END
