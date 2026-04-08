






CREATE PROCEDURE [dbo].[spView_Avances_Diarios]
    @DNI_RESPONSABLE INT = NULL,
    @Anio INT,
    @Mes INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @existeResponsable BIT;
	DECLARE @ULTIMA_FECHA varchar(30);

    IF EXISTS (
        SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE
        WHERE DNI_RESPONSABLE = @DNI_RESPONSABLE AND  AÑO= @Anio AND MES = @Mes

    )
        SET @existeResponsable = 1;
    ELSE
        SET @existeResponsable = 0;

    IF @existeResponsable = 1
        BEGIN
        select @ULTIMA_FECHA=valor from parametros where tipo=1;
        WITH Ventas AS (
            select DNI_RESPONSABLE,
            -- DNI_VENDEDOR,
            FECHA,
            sum(ALTA_PREPAGO) as ALTA_PREPAGO, sum(PORTA_PREPAGO) as PORTA_PREPAGO from dbo.tbl_ventas_prepago_new where DNI_RESPONSABLE=@DNI_RESPONSABLE
            and year(FECHA)=@Anio and month(FECHA)=@Mes
            --and NOT EXISTS ( select 1 from dbo.PDV_OUT_ENTREGABLE where año = @Anio and mes = @Mes and DNI_VENDEDOR = dbo.tbl_ventas_prepago_new.DNI_VENDEDOR )
                AND (
                NOT EXISTS (
                        SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE año = @Anio AND mes = @Mes AND DNI_VENDEDOR = dbo.tbl_ventas_prepago_new.DNI_VENDEDOR
                    )
                    OR EXISTS (
                        SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE año = @Anio AND mes = @Mes AND DNI_VENDEDOR = dbo.tbl_ventas_prepago_new.DNI_VENDEDOR AND DNI_RESPONSABLE = @DNI_RESPONSABLE
                    )
                ) --;
            GROUP BY DNI_RESPONSABLE, FECHA
        ),
        Funnel AS (
            select DNI_RESPONSABLE, FECHA, sum(ALTA_POSTPAGO) as ALTA_POSTPAGO,
            sum(PORTA_POST_O_PRE) as PORTA_POST_O_PRE, sum(PORTA_POST_O_POS) as PORTA_POST_O_POS
            from tbl_funnel_resumen_post where DNI_RESPONSABLE = @DNI_RESPONSABLE and year(FECHA) = @Anio and month(FECHA) = @Mes
            GROUP BY DNI_RESPONSABLE, FECHA
        )
        SELECT
            COALESCE(f.DNI_RESPONSABLE, v.DNI_RESPONSABLE) AS DNI_RESPONSABLE,
            COALESCE(f.FECHA, v.FECHA) AS FECHA,
            -- SUM(ISNULL(v.ALTA_PREPAGO, 0)) AS ALTA_PREPAGO,
            -- SUM(ISNULL(f.ALTA_POSTPAGO, 0)) AS ALTA_POSTPAGO,
            -- SUM(ISNULL(v.PORTA_PREPAGO, 0)) AS PORTA_PREPAGO,
            -- SUM(ISNULL(f.PORTA_POST_O_PRE, 0)) AS PORTA_POST_O_PRE,
            -- SUM(ISNULL(f.PORTA_POST_O_POS, 0)) AS PORTA_POST_O_POS,
            ISNULL(v.ALTA_PREPAGO, 0) AS ALTA_PREPAGO,
            ISNULL(f.ALTA_POSTPAGO, 0) AS ALTA_POSTPAGO,
            ISNULL(v.PORTA_PREPAGO, 0) AS PORTA_PREPAGO,
            ISNULL(f.PORTA_POST_O_PRE, 0) AS PORTA_POST_O_PRE,
            ISNULL(f.PORTA_POST_O_POS, 0) AS PORTA_POST_O_POS,
            @ULTIMA_FECHA AS MAX_FECHA
        FROM Funnel f
        FULL OUTER JOIN Ventas v
            ON f.DNI_RESPONSABLE = v.DNI_RESPONSABLE
            AND f.FECHA = v.FECHA
        WHERE
            ISNULL(f.ALTA_POSTPAGO, 0) > 0
            OR ISNULL(v.PORTA_PREPAGO, 0) > 0
            OR ISNULL(f.PORTA_POST_O_PRE, 0) > 0
            OR ISNULL(f.PORTA_POST_O_POS, 0) > 0
            OR ISNULL(v.ALTA_PREPAGO, 0) > 0
        -- GROUP BY COALESCE(f.DNI_RESPONSABLE, v.DNI_RESPONSABLE), COALESCE(f.FECHA, v.FECHA)
        ORDER BY FECHA ASC;
    END
    ELSE
        BEGIN
        select @ULTIMA_FECHA=valor from parametros where tipo=1;
        WITH Ventas AS (
            select DNI_RESPONSABLE, DNI_VENDEDOR, FECHA,ALTA_PREPAGO,PORTA_PREPAGO from dbo.tbl_ventas_prepago_MM where DNI_VENDEDOR=@DNI_RESPONSABLE
            and year(FECHA)=@Anio and month(FECHA)=@Mes
            -- select DNI_RESPONSABLE,
            -- DNI_VENDEDOR,
            -- FECHA,
            -- sum(ALTA_PREPAGO) as ALTA_PREPAGO, sum(PORTA_PREPAGO) as PORTA_PREPAGO from dbo.tbl_ventas_prepago_MM where DNI_VENDEDOR=@DNI_RESPONSABLE
            -- and year(FECHA)=@Anio and month(FECHA)=@Mes
            -- GROUP BY DNI_RESPONSABLE, FECHA
        ),
        Funnel AS (
            select DNI_RESPONSABLE, DNI_VENDEDOR, FECHA, ALTA_POSTPAGO, PORTA_POST_O_PRE, PORTA_POST_O_POS
            from tbl_funnel_resumen_post_MM where DNI_VENDEDOR=@DNI_RESPONSABLE and year(FECHA)=@Anio and month(FECHA)=@Mes
            -- select DNI_RESPONSABLE, FECHA, sum(ALTA_POSTPAGO) as ALTA_POSTPAGO,
            -- sum(PORTA_POST_O_PRE) as PORTA_POST_O_PRE, sum(PORTA_POST_O_POS) as PORTA_POST_O_POS
            -- from tbl_funnel_resumen_post_MM where DNI_VENDEDOR = @DNI_RESPONSABLE and year(FECHA) = @Anio and month(FECHA) = @Mes
            -- GROUP BY DNI_RESPONSABLE, FECHA
        )
        SELECT
            COALESCE(f.DNI_RESPONSABLE, v.DNI_RESPONSABLE) AS DNI_RESPONSABLE,
            COALESCE(f.DNI_VENDEDOR, v.DNI_VENDEDOR) AS DNI_VENDEDOR,
            COALESCE(f.FECHA, v.FECHA) AS FECHA,
            ISNULL(v.ALTA_PREPAGO, 0) AS ALTA_PREPAGO,
            ISNULL(f.ALTA_POSTPAGO, 0) AS ALTA_POSTPAGO,
            ISNULL(v.PORTA_PREPAGO, 0) AS PORTA_PREPAGO,
            ISNULL(f.PORTA_POST_O_PRE, 0) AS PORTA_POST_O_PRE,
            ISNULL(f.PORTA_POST_O_POS, 0) AS PORTA_POST_O_POS,
            @ULTIMA_FECHA AS MAX_FECHA
        FROM Funnel f
        FULL OUTER JOIN Ventas v
            ON f.DNI_VENDEDOR = v.DNI_VENDEDOR
            AND f.FECHA = v.FECHA
        WHERE
            ISNULL(f.ALTA_POSTPAGO, 0) > 0
            OR ISNULL(v.PORTA_PREPAGO, 0) > 0
            OR ISNULL(f.PORTA_POST_O_PRE, 0) > 0
            OR ISNULL(f.PORTA_POST_O_POS, 0) > 0
            OR ISNULL(v.ALTA_PREPAGO, 0) > 0
            ORDER BY FECHA asc;
    END
END
