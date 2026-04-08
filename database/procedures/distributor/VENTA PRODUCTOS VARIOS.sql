SET NOCOUNT ON;

DECLARE @d1 DATE = '2026-04-01';
DECLARE @d2 DATE = '2026-04-05';

IF OBJECT_ID('tempdb..#VentasIncentivo') IS NULL
BEGIN
    CREATE TABLE #VentasIncentivo (
        FEC_EMISION    DATE,
        ALMACEN        NVARCHAR(100),
        NOM_VENDEDOR   NVARCHAR(255),
        PROD_LINEA     NVARCHAR(50),
        NombreProducto NVARCHAR(255),
        precio_vta     DECIMAL(18,4),
        Origen         NVARCHAR(20)
    );
END
ELSE
BEGIN
    DELETE FROM #VentasIncentivo;
END;

INSERT INTO #VentasIncentivo
EXEC sp_Ventas_Incentivo_Detalle N'SAMSUNG GALAXY A07 128GB', @d1, @d2;

INSERT INTO #VentasIncentivo
EXEC sp_Ventas_Incentivo_Detalle N'SAMSUNG  A07 RAM 4GB + ROM 128GB', @d1, @d2;

INSERT INTO #VentasIncentivo
EXEC sp_Ventas_Incentivo_Detalle N'SAMSUNG GALAXY A17 5G 128GB', @d1, @d2;

INSERT INTO #VentasIncentivo
EXEC sp_Ventas_Incentivo_Detalle N'SAMSUNG GALAXY A16 128GB', @d1, @d2;

INSERT INTO #VentasIncentivo
EXEC sp_Ventas_Incentivo_Detalle N'SAMSUNG A16 4GB RAM + 128 GB ROM', @d1, @d2;

INSERT INTO #VentasIncentivo
EXEC sp_Ventas_Incentivo_Detalle N'REDMI 15C 25078RA3EL RAM 4GB + ROM 128GB', @d1, @d2;

INSERT INTO #VentasIncentivo
EXEC sp_Ventas_Incentivo_Detalle N'REDMI 15C 4+128GB', @d1, @d2;

SELECT *
FROM #VentasIncentivo
ORDER BY Origen, FEC_EMISION, ALMACEN, NOM_VENDEDOR, PROD_LINEA, NombreProducto;
