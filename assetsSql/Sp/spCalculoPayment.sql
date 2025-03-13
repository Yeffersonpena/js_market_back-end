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
        SELECT COUNT(*) AS totalRecargas
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
    ),
    bonos AS (
        SELECT 
			
            SUM(CASE WHEN f.PRODUCTO_WEB = 'PORT PREPAGO M7' THEN 4.00 ELSE 0.00 END) AS bonoPortaPre,
            SUM(CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' THEN 10.00 ELSE 0.00 END) AS bonoAltaPost,
            SUM(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' THEN 35.00 ELSE 0.00 END) AS bonoPortaPostOPost,
            SUM(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' THEN 20.00 ELSE 0.00 END) AS bonoPortaPostOPre,
            SUM(CASE 
                WHEN tp.tipoPDV = 'PDV REGULAR' AND f.[RECARGAS>5] = 1 THEN 2.00 
                WHEN tp.tipoPDV = 'PDV PREMIUM' AND f.[RECARGAS>5] = 1 THEN 3.00 
                ELSE 0.00 
            END) AS bonoRecargaPre
        FROM dbo.PDV_OUT_FUNNEL f
        LEFT JOIN tipoPDV tp ON 1=1 
        WHERE f.DNI_RESPONSABLE = @dni 
          AND YEAR(f.FECHA) = @año 
          AND MONTH(f.FECHA) = @mes
    ),
	unitarioRec_ as (select top 1
            CASE 
                WHEN t.tipoPDV = 'PDV REGULAR' THEN 2.00 
                WHEN t.tipoPDV = 'PDV PREMIUM' THEN 3.00 
                ELSE 0.00 
            END  as unitarioRec from PDV_OUT_FUNNEL f LEFT JOIN tipoPDV t ON 1=1 where f.DNI_RESPONSABLE=@dni and year(f.FECHA)=@año and month(f.FECHA)=@mes)
    SELECT 
		ut.unitarioRec,
        ISNULL(dbo.fn_calcularBono(@dni, @año, @mes), 0.00) AS bonoPre,
        b.bonoRecargaPre,
        b.bonoPortaPre,
        b.bonoAltaPost,
        b.bonoPortaPostOPost,
        b.bonoPortaPostOPre,
        t.tipoPDV,
        v.totalVenta AS bonoChips,
        ISNULL(dbo.fn_calcularBono(@dni, @año, @mes), 0.00) + b.bonoRecargaPre + b.bonoPortaPre + b.bonoAltaPost + b.bonoPortaPostOPost + b.bonoPortaPostOPre  AS bonoTotalEfectivo,
        v.totalVenta + ISNULL(dbo.fn_calcularBono(@dni, @año, @mes), 0.00) + b.bonoRecargaPre + b.bonoPortaPre + b.bonoAltaPost + b.bonoPortaPostOPost + b.bonoPortaPostOPre AS bonoTotal
    FROM dbo.users u
    LEFT JOIN ventas v ON 1=1
    LEFT JOIN recargas r ON 1=1
    LEFT JOIN tipoPDV t ON 1=1
    LEFT JOIN bonos b ON 1=1
	LEFT JOIN unitarioRec_ ut ON 1=1 
    WHERE u.[user] = @dni;
END;
