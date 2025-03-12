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
         SELECT TOP 1 ACCION_2 AS tipoPDV, MES
         FROM dbo.PDV_OUT_ENTREGABLE
         WHERE AÑO = @año 
           AND DNI_RESPONSABLE = @dni 
         ORDER BY mes DESC
    ),
    bonoPreCalc AS (
        SELECT 
            CASE 
                WHEN (SELECT tipoPDV FROM tipoPDV) = 'PDV REGULAR' THEN 
                    CASE 
                        WHEN v.totalVenta BETWEEN 1 AND 10 THEN
                            CASE 
                                WHEN CAST(r.TotalRecargas AS FLOAT) / v.totalVenta >= 0.5 THEN v.totalVenta * 1.5
                                ELSE v.totalVenta * 0.5
                            END
                        WHEN v.totalVenta BETWEEN 11 AND 20 THEN
                            CASE 
                                WHEN CAST(r.TotalRecargas AS FLOAT) / v.totalVenta >= 0.5 THEN v.totalVenta * 2.5
                                ELSE v.totalVenta * 1.5
                            END
                        WHEN v.totalVenta BETWEEN 21 AND 40 THEN
                            CASE 
                                WHEN CAST(r.TotalRecargas AS FLOAT) / v.totalVenta >= 0.5 THEN v.totalVenta * 3
                                ELSE v.totalVenta * 2
                            END
                        WHEN v.totalVenta BETWEEN 41 AND 80 THEN
                            CASE 
                                WHEN CAST(r.TotalRecargas AS FLOAT) / v.totalVenta >= 0.5 THEN v.totalVenta * 3.5
                                ELSE v.totalVenta * 2.5
                            END
                        WHEN v.totalVenta >= 81 THEN
                            CASE 
                                WHEN CAST(r.TotalRecargas AS FLOAT) / v.totalVenta >= 0.5 THEN v.totalVenta * 4
                                ELSE v.totalVenta * 3
                            END
                    END
                WHEN (SELECT tipoPDV FROM tipoPDV) = 'PDV PREMIUM' THEN 
                    CASE
                        WHEN v.totalVenta BETWEEN 150 AND 250 THEN
                            CASE 
                                WHEN CAST(r.TotalRecargas AS FLOAT) / v.totalVenta >= 0.5 THEN v.totalVenta * 5.0
                                ELSE v.totalVenta * 4.0
                            END
                        WHEN v.totalVenta >= 251 THEN
                            CASE 
                                WHEN CAST(r.TotalRecargas AS FLOAT) / v.totalVenta >= 0.5 THEN v.totalVenta * 6.0
                                ELSE v.totalVenta * 5.0
                            END
                    END
            END AS bonoPre
        FROM ventas v, recargas r
    )
    SELECT 
        f.DNI_RESPONSABLE, 
        f.DNI_VENDEDOR,
        f.FECHA,
        f.PRODUCTO_WEB,
        f.PRODUCTOORIGEN,
        f.TIPO_PREPAGO,
        f.FECHA_PRIMERA_RECARGA,
        f.MONTO_ACUMULADO_RECARGAS,
        f.PRODUCTO,
        f.RECARGA_SI_NO,
        f.MONTO_PRIMERA_RECARGA,
        f.[RECARGAS>5],
        f.ACCION,
        f.ACCION_INTERNA,
        f.VENTAS_REPETIDAS,
        f.TRIPLICADO_SI_NO,
        f.MONTO_ACUMULADO_RECARGAS AS unitarioRec,
        (SELECT bonoPre FROM bonoPreCalc) AS bonoPre,
        SUM(
            CASE 
                WHEN tp.tipoPDV = 'PDV REGULAR' AND f.[RECARGAS>5] = 1 THEN 2.00 
                WHEN tp.tipoPDV = 'PDV PREMIUM' AND f.[RECARGAS>5] = 1 THEN 3.00 
                ELSE 0.00 
            END
        ) AS bonoRecargaPre,
        CASE WHEN f.PRODUCTO_WEB = 'PORT PREPAGO M7' THEN 4.00 ELSE 0.00 END AS bonoPortaPre,
        CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' THEN 10.00 ELSE 0.00 END AS bonoAltaPost,
        CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' THEN 35.00 ELSE 0.00 END AS bonoPortaPostOPost,
        CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' THEN 20.00 ELSE 0.00 END AS bonoPortaPostOPre,
        tp.tipoPDV  
    FROM dbo.PDV_OUT_FUNNEL f
    LEFT JOIN tipoPDV tp ON 1=1 
    WHERE f.DNI_RESPONSABLE = @dni 
      AND YEAR(f.FECHA) = @año 
      AND MONTH(f.FECHA) = @mes
    GROUP BY 
        f.DNI_RESPONSABLE, 
        f.DNI_VENDEDOR,
        f.FECHA,
        f.PRODUCTO_WEB,
        f.PRODUCTOORIGEN,
        f.TIPO_PREPAGO,
        f.FECHA_PRIMERA_RECARGA,
        f.MONTO_ACUMULADO_RECARGAS,
        f.PRODUCTO,
        f.RECARGA_SI_NO,
        f.MONTO_PRIMERA_RECARGA,
        f.[RECARGAS>5],
        f.ACCION,
        f.ACCION_INTERNA,
        f.VENTAS_REPETIDAS,
        f.TRIPLICADO_SI_NO,
        tp.tipoPDV;
END;
