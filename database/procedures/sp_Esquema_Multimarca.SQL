CREATE PROCEDURE dbo.sp_Esquema_Multimarca
    @Anio INT,
    @Mes INT
AS
BEGIN
   SET NOCOUNT ON;

    -- 1. DECLARACIÓN DE VARIABLES
    DECLARE @FechaInicio DATE = DATEFROMPARTS(@Anio, @Mes, 1);
    DECLARE @FechaFin DATE = EOMONTH(@FechaInicio);
    DECLARE @cantidadCalidad INT = 0;
   

    -- 2. CTEs OPTIMIZADOS
    WITH VendedoresMultimarca AS (
        SELECT DISTINCT
            DNI_VENDEDOR,
            NOMBRE_VENDEDOR,
            ZONAL
        FROM
            PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE
        WHERE
            AÑO = @Anio
            AND MES = @Mes
            AND ACCION_1 = 'MULTIMARCA'
    ),
    RecargasPivot AS (
        SELECT
            DNI_VENDEDOR,
            ISNULL([N0], 0) AS N0,
            ISNULL([N1], 0) AS N1,
            ISNULL([N2], 0) AS N2,
            ISNULL([N3], 0) AS N3,
            ISNULL([N4], 0) AS N4
        FROM (
            SELECT
                DNI_VENDEDOR,
                PERIODO_EVALUACION,
                SUM(MONTO_RECARGADO) AS MONTO_TOTAL
            FROM
                BD_PLANIFICACION.dbo.PP2025_N0
            WHERE
                SOCIO = 'JS MARKET'
                AND ACCION = 'MULTIMARCA'
                AND PERIODO_EVALUACION IN ('N0', 'N1', 'N2','N3','N4')
                AND FECHA_CARGA = (
                    SELECT MAX(FECHA_CARGA)
                    FROM BD_PLANIFICACION.dbo.PP2025_N0
                    WHERE FECHA_CARGA >= @FechaInicio AND FECHA_CARGA <= @FechaFin
                )
            GROUP BY
                DNI_VENDEDOR,
                PERIODO_EVALUACION
        ) AS src
        PIVOT (
            SUM(MONTO_TOTAL)
            FOR PERIODO_EVALUACION IN ([N0], [N1], [N2],[N3],[N4])
        ) AS pvt
    ),
    EventosAgregados AS (
        SELECT
            DNI_VENDEDOR AS DNI_EJECUTOR,
            COUNT(CASE WHEN CALIDAD_CLUSTER IN ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado') THEN 1 END) AS VENTAS_BC,
            COUNT(CASE WHEN PRODUCTO_WEB = 'PORT M4 NO DIR' AND DNI_RESPONSABLE IS NOT NULL AND PRODUCTOORIGEN = 'PREPAGO' THEN 1 END) AS PORTA_PRE,
            COUNT(CASE WHEN PRODUCTO_WEB = 'PORT M4 NO DIR' AND DNI_RESPONSABLE IS NOT NULL AND PRODUCTOORIGEN = 'POSTPAGO' THEN 1 END) AS PORTA_POS
        FROM
            PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
        WHERE
            fecha >= @FechaInicio AND fecha <= @FechaFin
        GROUP BY
            DNI_VENDEDOR
    ),
    --*******
    -- ==================================================================
    -- NUEVOS CTEs PARA REPLICAR LA LÓGICA COMPLETA DE LA FUNCIÓN
    -- ==================================================================
    -- CTE 1: Contamos las ventas de buena calidad en el mes que se está ejecutando el SP
    ConteoCalidadBC AS (
        SELECT
            DNI_VENDEDOR,
            COUNT(1) AS CantidadCalidad
        FROM 
            PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
        WHERE 
            -- Usamos las variables del SP para el conteo de calidad del mes actual
            TRY_CONVERT(DATE, fecha) BETWEEN @FechaInicio AND @FechaFin AND 
            CALIDAD_CLUSTER IN ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')
        GROUP BY
            DNI_VENDEDOR
    ),

    -- CTE 2: Calculamos el unitario POTENCIAL basado en el histórico de meses (lógica original)
    ClasificacionUnitarioPotencialBC AS (
        SELECT
            DNI_VENDEDOR,
            CASE 
                WHEN MAX(CASE WHEN TRY_CONVERT(DATE, FECHA) BETWEEN '2025-06-01' AND '2025-08-31' THEN 1 ELSE 0 END) = 1 THEN 5
                WHEN MAX(CASE WHEN TRY_CONVERT(DATE, FECHA) BETWEEN '2025-09-01' AND '2025-09-30' THEN 1 ELSE 0 END) = 1 THEN 8
                ELSE 0
            END AS UnitarioPotencial
        FROM 
            PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
        WHERE 
            TRY_CONVERT(DATE, FECHA) BETWEEN '2025-06-01' AND '2025-09-30'
        GROUP BY 
            DNI_VENDEDOR
    ),

 -- CTE 3: Unimos ambos resultados y aplicamos la regla de negocio final
    CalculoUnitarioFinalBC AS (
        SELECT
            cup.DNI_VENDEDOR,
            -- Aplicamos la regla: si el conteo de calidad es < 15, el unitario es 0. Si no, es el potencial.
            CASE
                WHEN ISNULL(cc.CantidadCalidad, 0) < 15 THEN 0
                ELSE cup.UnitarioPotencial
            END AS UnitarioBC -- El resultado final se sigue llamando UnitarioBC
        FROM
            ClasificacionUnitarioPotencialBC cup
        LEFT JOIN 
            ConteoCalidadBC cc ON cup.DNI_VENDEDOR = cc.DNI_VENDEDOR
    )
    --******
    -- 3. SELECT FINAL MEJORADO
    SELECT
        vm.ZONAL,
        vm.DNI_VENDEDOR,
        vm.NOMBRE_VENDEDOR,
        ISNULL(rp.N0, 0) AS N0,
        ISNULL(rp.N1, 0) AS N1,
        ISNULL(rp.N2, 0) AS N2,
        ISNULL(rp.N3, 0) AS N3,
        ISNULL(rp.N4, 0) AS N4,
        ISNULL(ep.VENTAS_BC, 0) AS VENTAS_BC,
        -- ==================================================================
    -- REEMPLAZO DE LA FUNCIÓN ESCALAR
        -- ==================================================================
        ISNULL(cv.UnitarioBC, 0) AS 'UnitarioBC',
        ISNULL(ep.PORTA_PRE, 0) AS PORTA_PRE,
        ISNULL(ep.PORTA_POS, 0) AS PORTA_POS
    FROM
        VendedoresMultimarca vm
    LEFT JOIN RecargasPivot rp 
        ON vm.DNI_VENDEDOR = rp.DNI_VENDEDOR
    LEFT JOIN EventosAgregados ep 
        ON vm.DNI_VENDEDOR = ep.DNI_EJECUTOR
    -- ==================================================================
    -- NUEVO JOIN AL CTE DE CLASIFICACIÓN
    -- ==================================================================
    LEFT JOIN CalculoUnitarioFinalBC cv 
        -- El CAST es importante para coincidir con la lógica de la función original
        -- si los tipos de datos de DNI son diferentes entre tablas.
        ON CAST(vm.DNI_VENDEDOR AS VARCHAR(50)) = cv.DNI_VENDEDOR
        where vm.DNI_VENDEDOR>0
    ORDER BY
        vm.ZONAL,
        vm.DNI_VENDEDOR;


END