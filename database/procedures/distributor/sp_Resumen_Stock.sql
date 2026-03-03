-- Resumen de stock por EMPRESA y MODELO: cuenta por rango de antigüedad (EDAD) y total STOCK.
-- Obtiene el detalle desde sp_Stock_JS_Yali y agrupa en formato: EMPRESA, MODELO, < 15, 15 - 30, 30 - 70, 70 - 90, > 90, STOCK.
CREATE PROCEDURE sp_Resumen_Stock
    @linea VARCHAR(50) = NULL,
    @almacen VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #Base (
        TIPO VARCHAR(50),
        CSERIE VARCHAR(50),
        PROVEEDOR VARCHAR(200),
        FCOMPRA DATE,
        DIAS INT,
        EDAD VARCHAR(20),
        NCOSTO DECIMAL(18,4),
        COSTO DECIMAL(18,4),
        CNOM_PROD VARCHAR(200),
        MARCA VARCHAR(100),
        MODELO VARCHAR(200),
        LINEA VARCHAR(50),
        SUBLINEA VARCHAR(50),
        ALMACEN VARCHAR(100),
        EMPRESA VARCHAR(50),
        PRECIO_VTA DECIMAL(18,4)
    );

    INSERT INTO #Base
    EXEC sp_Stock_JS_Yali @linea;

    SELECT
        EMPRESA,
        COALESCE(MODELO, CNOM_PROD) AS MODELO,
        SUM(CASE WHEN EDAD = '< 15' THEN 1 ELSE 0 END) AS [< 15],
        SUM(CASE WHEN EDAD = '15 - 30' THEN 1 ELSE 0 END) AS [15 - 30],
        SUM(CASE WHEN EDAD = '30 - 70' THEN 1 ELSE 0 END) AS [30 - 70],
        SUM(CASE WHEN EDAD = '70 - 90' THEN 1 ELSE 0 END) AS [70 - 90],
        SUM(CASE WHEN EDAD = '> 90' THEN 1 ELSE 0 END) AS [> 90],
        COUNT(*) AS STOCK,
        AVG(COSTO) AS COSTO,
        MAX(PRECIO_VTA) AS PRECIO_VTA
    FROM #Base
    WHERE (@almacen IS NULL OR RTRIM(LTRIM(@almacen)) = '' OR UPPER(RTRIM(LTRIM(ALMACEN))) = UPPER(RTRIM(LTRIM(@almacen))))
    GROUP BY EMPRESA, COALESCE(MODELO, CNOM_PROD)
    ORDER BY EMPRESA, COALESCE(MODELO, CNOM_PROD);
END
