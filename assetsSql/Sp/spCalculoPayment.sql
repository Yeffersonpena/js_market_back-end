CREATE PROCEDURE spCalculoPayment
    @dni VARCHAR(10),
    @año INT,
    @mes INT
AS
BEGIN
    SET NOCOUNT ON;

    WITH ventas AS (
        SELECT COUNT(*) AS totalVenta
        FROM dbo.PDV_OUT_FUNNEL
        WHERE DNI_RESPONSABLE = @dni
          AND YEAR(fecha) = @año
          AND MONTH(fecha) = @mes
    ),
    recargas AS (
        SELECT COUNT(*) AS TotalRecargas
        FROM dbo.PDV_OUT_FUNNEL
        WHERE DNI_RESPONSABLE = @dni
          AND YEAR(fecha) = @año
          AND MONTH(fecha) = @mes
          AND [RECARGAS>5] = 1
    ),
    tipoPDV AS (
         SELECT TOP 1 ACCION_2 AS tipoPDV
         FROM dbo.PDV_OUT_ENTREGABLE
         WHERE AÑO = @año 
           AND DNI_RESPONSABLE = @dni 
         ORDER BY mes DESC
    )
    
    SELECT
        f.DNI_RESPONSABLE, 
        f.PRODUCTO_WEB,
        f.PRODUCTOORIGEN,
         SUM( CASE 
            WHEN tp.tipoPDV = 'PDV REGULAR' AND f.[RECARGAS>5] = 1 THEN 2.00 
            WHEN tp.tipoPDV = 'PDV PREMIUM' AND f.[RECARGAS>5] = 1 THEN 3.00 
            ELSE 0.00 
        END ) AS unitarioRec,
		 isnull(dbo.fn_calcularBono(@dni, @mes, @año),0.00) AS bonoPre,
        SUM(
            CASE 
                WHEN tp.tipoPDV = 'PDV REGULAR' AND f.[RECARGAS>5] = 1 THEN 2.00 
                WHEN tp.tipoPDV = 'PDV PREMIUM' AND f.[RECARGAS>5] = 1 THEN 3.00 
                ELSE 0.00 
            END
        ) AS bonoRecargaPre,
        sum(CASE WHEN f.PRODUCTO_WEB = 'PORT PREPAGO M7' THEN 4.00 ELSE 0.00 END) AS bonoPortaPre,
        sum(CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' THEN 10.00 ELSE 0.00 END) AS bonoAltaPost,
        sum(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' THEN 35.00 ELSE 0.00 END) AS bonoPortaPostOPost,
        sum(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' THEN 20.00 ELSE 0.00 END) AS bonoPortaPostOPre,
        tp.tipoPDV,
         v.totalVenta AS bonoChips, 
        isnull(dbo.fn_calcularBono(@dni, @mes, @año),0.00)
        + SUM(CASE WHEN f.PRODUCTO_WEB = 'PORT PREPAGO M7' THEN 4.00 ELSE 0.00 END)
        + SUM(CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' THEN 10.00 ELSE 0.00 END)
        + SUM(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' THEN 35.00 ELSE 0.00 END)
        + SUM(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' THEN 20.00 ELSE 0.00 END)
        + SUM(
            CASE 
                WHEN tp.tipoPDV = 'PDV REGULAR' AND f.[RECARGAS>5] = 1 THEN 2.00 
                WHEN tp.tipoPDV = 'PDV PREMIUM' AND f.[RECARGAS>5] = 1 THEN 3.00 
                ELSE 0.00 
            END
        ) AS bonoTotalEfectivo,  
        v.totalVenta + isnull(dbo.fn_calcularBono(@dni, @mes, @año),0.00)
        + SUM(CASE WHEN f.PRODUCTO_WEB = 'PORT PREPAGO M7' THEN 4.00 ELSE 0.00 END)
        + SUM(CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' THEN 10.00 ELSE 0.00 END)
        + SUM(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' THEN 35.00 ELSE 0.00 END)
        + SUM(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' THEN 20.00 ELSE 0.00 END)
        + SUM(
            CASE 
                WHEN tp.tipoPDV = 'PDV REGULAR' AND f.[RECARGAS>5] = 1 THEN 2.00 
                WHEN tp.tipoPDV = 'PDV PREMIUM' AND f.[RECARGAS>5] = 1 THEN 3.00 
                ELSE 0.00 
            END
        )  AS bonoTotal
    FROM dbo.PDV_OUT_FUNNEL f
    LEFT JOIN tipoPDV tp ON 1=1 
    CROSS JOIN ventas v 
    WHERE f.DNI_RESPONSABLE = @dni 
      AND YEAR(f.FECHA) = @año 
      AND MONTH(f.FECHA) = @mes
    GROUP BY 
        f.DNI_RESPONSABLE, 
        f.PRODUCTO_WEB,
        f.PRODUCTOORIGEN,
        tp.tipoPDV,
        v.totalVenta;
END;
GO
