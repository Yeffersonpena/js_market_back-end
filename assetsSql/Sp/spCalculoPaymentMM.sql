CREATE PROCEDURE [dbo].[spCalculoPaymentMM]
    @dni int,
    @año INT,
    @mes INT
AS
BEGIN
    SET NOCOUNT ON;
    declare @RECARGA_TOTAL int, @ULTIMA_FECHA date, @bonoPorVenta DECIMAL(18,2), @bonoPre DECIMAL(18,2);
    DECLARE @VENTA_AVANCE_PREPAGO INT, @tipo varchar(30);
    DECLARE @ratio DECIMAL(5,2);
     select
    @ULTIMA_FECHA = ULTIMA_FECHA,
    @RECARGA_TOTAL =RECARGA_TOTAL
	FROM dbo.PDV_OUT_FUNNEL_RESUMEN
	WHERE DNI_RESPONSABLE = @dni and ANIO=@año and MES=@mes;
    
    -- avance de venta prepago
     SELECT @VENTA_AVANCE_PREPAGO = SUM(cantidad)
    FROM dbo.tbl_venta_log WHERE DNI_RESPONSABLE = @dni
      AND YEAR(FECHA) = @año AND MONTH(FECHA) = @mes;

    --  para obtener el pdv premiun o regular 
          SELECT TOP 1 @tipo = ACCION_2
        FROM dbo.PDV_OUT_ENTREGABLE
        WHERE AÑO = @año AND DNI_RESPONSABLE = @dni
        ORDER BY mes DESC;

--  precio unitario  pdv schema, si es premiun o regular 
    IF @VENTA_AVANCE_PREPAGO IS NULL
    BEGIN
        SET @VENTA_AVANCE_PREPAGO = 0;
    END

 IF @RECARGA_TOTAL IS NULL
    BEGIN
        SET @RECARGA_TOTAL = 0;
    END

    set @ratio = ROUND(
        (CAST(@RECARGA_TOTAL AS DECIMAL(10,2)) / NULLIF(CAST(@VENTA_AVANCE_PREPAGO AS DECIMAL(10,2)), 0) * 100), 0
    );

  -- Determinar el bono por cada venta según el tipo y la tabla
    SET @bonoPorVenta = 
        CASE 
            WHEN @tipo = 'PDV REGULAR' THEN 
                CASE 
                    WHEN @VENTA_AVANCE_PREPAGO BETWEEN 1 AND 10 THEN CASE WHEN @ratio >= 50 THEN 1.5 ELSE 0.5 END
                    WHEN @VENTA_AVANCE_PREPAGO BETWEEN 11 AND 20 THEN CASE WHEN @ratio >= 50 THEN 2.5 ELSE 1.5 END
                    WHEN @VENTA_AVANCE_PREPAGO BETWEEN 21 AND 40 THEN CASE WHEN @ratio >= 50 THEN 3.0 ELSE 2.0 END
                    WHEN @VENTA_AVANCE_PREPAGO BETWEEN 41 AND 80 THEN CASE WHEN @ratio >= 50 THEN 3.5 ELSE 2.5 END
                    WHEN @VENTA_AVANCE_PREPAGO BETWEEN 81 AND 149 THEN CASE WHEN @ratio >= 50 THEN 4.0 ELSE 3.0 END
                    ELSE 0
                END
            WHEN @tipo LIKE 'PDV PREMIUM%' THEN 
                CASE 
                    WHEN @VENTA_AVANCE_PREPAGO >= 80 AND @VENTA_AVANCE_PREPAGO < 150 THEN 2.0
                    WHEN @VENTA_AVANCE_PREPAGO BETWEEN 150 AND 250 THEN CASE WHEN @ratio >= 50 THEN 5.0 ELSE 4.0 END
                    WHEN @VENTA_AVANCE_PREPAGO >= 251 THEN CASE WHEN @ratio >= 50 THEN 6.0 ELSE 5.0 END
                    ELSE 0
                END
            ELSE 0
        END;
    -- 
--  calcular el bono bonoPre 
SET @bonoPre = 
        CASE 
            WHEN @tipo = 'PDV REGULAR' THEN 
                CASE 
                    WHEN @VENTA_AVANCE_PREPAGO BETWEEN 1 AND 10 THEN CASE WHEN @ratio >= 50 THEN @VENTA_AVANCE_PREPAGO * 1.5 ELSE @VENTA_AVANCE_PREPAGO * 0.5 END
                    WHEN @VENTA_AVANCE_PREPAGO BETWEEN 11 AND 20 THEN CASE WHEN @ratio >= 50 THEN @VENTA_AVANCE_PREPAGO * 2.5 ELSE @VENTA_AVANCE_PREPAGO * 1.5 END
                    WHEN @VENTA_AVANCE_PREPAGO BETWEEN 21 AND 40 THEN CASE WHEN @ratio >= 50 THEN @VENTA_AVANCE_PREPAGO * 3.0 ELSE @VENTA_AVANCE_PREPAGO * 2.0 END
                    WHEN @VENTA_AVANCE_PREPAGO BETWEEN 41 AND 80 THEN CASE WHEN @ratio >= 50 THEN @VENTA_AVANCE_PREPAGO * 3.5 ELSE @VENTA_AVANCE_PREPAGO * 2.5 END
                    WHEN @VENTA_AVANCE_PREPAGO >= 81 THEN CASE WHEN @ratio >= 50 THEN @VENTA_AVANCE_PREPAGO * 4.0 ELSE @VENTA_AVANCE_PREPAGO * 3.0 END
                    ELSE 0
                END
            WHEN @tipo like 'PDV PREMIUM%' THEN 
                CASE 
                    WHEN @VENTA_AVANCE_PREPAGO BETWEEN 80 AND 149 THEN @VENTA_AVANCE_PREPAGO * 2.0
                    WHEN @VENTA_AVANCE_PREPAGO BETWEEN 150 AND 250 THEN CASE WHEN @ratio >= 50 THEN @VENTA_AVANCE_PREPAGO * 5.0 ELSE @VENTA_AVANCE_PREPAGO * 4.0 END
                    WHEN @VENTA_AVANCE_PREPAGO >= 251 THEN CASE WHEN @ratio >= 50 THEN @VENTA_AVANCE_PREPAGO * 6.0 ELSE @VENTA_AVANCE_PREPAGO * 5.0 END
                    ELSE 0
                END
            ELSE 0
        END;

    WITH 
    tipoPDV AS (
        SELECT TOP 1 ACCION_2 AS tipoPDV
        FROM dbo.PDV_OUT_ENTREGABLE
        WHERE AÑO = @año 
          AND DNI_RESPONSABLE = @dni 
        ORDER BY mes DESC
    ),
    bonos AS (
        SELECT distinct 
            f.DNI_RESPONSABLE,
			--
			 isnull((SELECT sum(CASE 
                WHEN OPERATION_NAME = 'Portabilidad' AND PRODUCT_NAME = 'Prepago' 
                THEN cantidad ELSE 0.00 END) 
            FROM dbo.tbl_venta_log WHERE dni_responsable = f.DNI_RESPONSABLE 
            AND YEAR(fecha) = @año AND MONTH(fecha) = @mes),0)  AS cantidadPortaPre,
			isnull((SELECT max(CASE 
                WHEN OPERATION_NAME = 'Portabilidad' AND PRODUCT_NAME = 'Prepago' 
                THEN 4.00 ELSE 0.00 END) 
            FROM dbo.tbl_venta_log WHERE dni_responsable = f.DNI_RESPONSABLE 
            AND YEAR(fecha) = @año AND MONTH(fecha) = @mes),0)  AS precioUniPortaPre,
isnull(SUM(CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes THEN 1.00 ELSE 0.00 END),0) AS cantidadAltaPost,
isnull(max(CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes THEN 10.00 ELSE 0.00 END),0) AS precioUniAltaPost,
isnull(SUM(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes THEN 1.00 ELSE 0.00 END),0) AS cantidadPortaPostOPost,
isnull(max(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes THEN 35.00 ELSE 0.00 END),0) AS precioPortaPostOPost,
isnull(SUM(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes THEN 1.00 ELSE 0.00 END),0) AS cantidadPortaPostOPre,
isnull(max(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes THEN 20.00 ELSE 0.00 END),0) AS precioPortaPostOPre,

			--
            isnull((SELECT SUM(CASE 
                WHEN OPERATION_NAME = 'Portabilidad' AND PRODUCT_NAME = 'Prepago' 
                THEN 4.00 * cantidad 
                ELSE 0.00 
            END) 
            FROM dbo.tbl_venta_log 
            WHERE dni_responsable = f.DNI_RESPONSABLE 
              AND YEAR(fecha) = @año 
              AND MONTH(fecha) = @mes),0)  AS bonoPortaPre,

			isnull(SUM(CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes THEN 10.00 ELSE 0.00 END),0) AS bonoAltaPost,
            isnull(SUM(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes THEN 35.00 ELSE 0.00 END),0) AS bonoPortaPostOPost,
            isnull(SUM(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes THEN 20.00 ELSE 0.00 END),0) AS bonoPortaPostOPre,

            isnull(SUM(CASE 
                WHEN tp.tipoPDV = 'PDV REGULAR' AND f.[RECARGAS>5] = 1 AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes THEN 2.00 
                WHEN tp.tipoPDV like 'PDV PREMIUM%' AND f.[RECARGAS>5] = 1 AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes THEN 3.00 
                ELSE 0.00 
            END),0) AS bonoRecargaPre
        FROM dbo.PDV_OUT_FUNNEL f
        LEFT JOIN tipoPDV tp ON 1=1 
        WHERE f.DNI_RESPONSABLE = @dni 
          AND YEAR(f.FECHA) = @año 
          AND MONTH(f.FECHA) = @mes
        GROUP BY f.DNI_RESPONSABLE
    ),
    unitarioRec_ AS (
        SELECT TOP 1
            CASE 
                WHEN t.tipoPDV = 'PDV REGULAR' THEN 2.00 
                WHEN t.tipoPDV like 'PDV PREMIUM%' THEN 3.00 
                ELSE 0.00 
            END AS levelUser
        FROM PDV_OUT_FUNNEL f 
        LEFT JOIN tipoPDV t ON 1=1 
        WHERE f.DNI_RESPONSABLE = @dni 
          AND YEAR(f.FECHA) = @año 
          AND MONTH(f.FECHA) = @mes
    )
    SELECT 
		b.cantidadPortaPre,
		b.precioUniPortaPre,
		b.cantidadAltaPost,
        b.precioUniAltaPost,
        b.cantidadPortaPostOPost,
        b.precioPortaPostOPost,
        b.cantidadPortaPostOPre,
        b.precioPortaPostOPre,
		-- dbo.fn_categoriaTable(@dni,@año,@mes) as faltaVenta,
        0 as faltaVenta,
        @bonoPorVenta as precioUniSchema,
        ut.levelUser,
        @RECARGA_TOTAL as cantidadRecarga,
        -- ISNULL(dbo.fn_calcularBono(@dni, @año, @mes), 0.00)  AS bonoPre,
        @bonoPre AS bonoPre,
        b.bonoRecargaPre,
        b.bonoPortaPre,
		b.bonoAltaPost,
        b.bonoPortaPostOPost,
        b.bonoPortaPostOPre,
        t.tipoPDV,
        @VENTA_AVANCE_PREPAGO AS bonoChips,
        ISNULL(dbo.fn_calcularBono(@dni, @año, @mes), 0.00) + b.bonoRecargaPre + b.bonoPortaPre +b.bonoAltaPost + b.bonoPortaPostOPost + b.bonoPortaPostOPre AS bonoTotalEfectivo,
        @VENTA_AVANCE_PREPAGO + ISNULL(dbo.fn_calcularBono(@dni, @año, @mes), 0.00) + b.bonoRecargaPre + b.bonoPortaPre + b.bonoAltaPost + b.bonoPortaPostOPost + b.bonoPortaPostOPre AS bonoTotal
    FROM dbo.users u
    LEFT JOIN tipoPDV t ON 1=1
    LEFT JOIN bonos b ON u.[user] = b.DNI_RESPONSABLE
    LEFT JOIN unitarioRec_ ut ON 1=1 
    WHERE u.[user] = CAST(@dni AS varchar);
END;
GO

