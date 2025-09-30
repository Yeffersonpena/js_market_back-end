CREATE PROCEDURE dbo.sp_Sincronizar_Flyers
    @año INT,
    @mes INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Variables para almacenar el año y mes que realmente se usarán
    DECLARE @año_real INT = @año;
    DECLARE @mes_real INT = @mes;

    -- Verificar si existe información para el mes solicitado
    IF NOT EXISTS (
        SELECT 1 
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE 
        WHERE AÑO = @año AND MES = @mes AND ESTADO = 'ACTIVO'
    )
    BEGIN
        -- Si no existe información para el mes solicitado, buscar el último mes disponible para ese año
        SELECT TOP 1 
            @año_real = AÑO,
            @mes_real = MES
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE 
        WHERE AÑO = @año AND ESTADO = 'ACTIVO'
        ORDER BY MES DESC;

        -- Si no hay datos para ese año, buscar el último mes disponible en general
        IF @mes_real IS NULL
        BEGIN
            SELECT TOP 1 
                @año_real = AÑO,
                @mes_real = MES
            FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE 
            WHERE ESTADO = 'ACTIVO'
            ORDER BY AÑO DESC, MES DESC;
        END
    END

    -- Inserta campañas de PDV
    INSERT INTO PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS (
        año,
        mes,
        dni_responsable,
        zonal,
        foto_esquema,
        fecha_inicio,
        fecha_fin,
        tipoImg
    )
    SELECT DISTINCT
        YEAR(c.fecha_inicio) AS año,
        MONTH(c.fecha_inicio) AS mes,
        CAST(e.DNI_RESPONSABLE AS VARCHAR(50)) AS dni_responsable,
        e.ZONAL,
        c.foto_esquema,
        c.fecha_inicio,
        c.fecha_fin,
        c.tipoImg
    FROM PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS c
    INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e ON (
        c.modo = 'PDV'
        AND e.DNI_RESPONSABLE IS NOT NULL
        AND e.ESTADO = 'ACTIVO'
        AND e.AÑO = @año_real
        AND e.MES = @mes_real
        -- Validar GRUPO exacto
        AND (
            e.GRUPO = c.criterio_filtro
            OR (',' + c.criterio_filtro + ',' LIKE '%,' + e.GRUPO + ',%')
        )
        -- Validar zonales
        AND (
            (c.zonales IS NULL OR c.zonales = '' OR LTRIM(RTRIM(c.zonales)) = '')
            OR (LOWER(LTRIM(RTRIM(c.zonales))) = 'todas')
            OR (', ' + c.zonales + ', ' LIKE '%, ' + e.ZONAL + ', %')
        )
    )
    WHERE
        c.activa = 1
        AND YEAR(c.fecha_inicio) = @año
        AND MONTH(c.fecha_inicio) = @mes
        AND NOT EXISTS (
            SELECT 1
            FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS f
            WHERE f.dni_responsable = CAST(e.DNI_RESPONSABLE AS VARCHAR(50))
              AND f.foto_esquema = c.foto_esquema
        );

    -- Inserta campañas MULTIMARCA
    INSERT INTO PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS (
        año,
        mes,
        dni_responsable,
        zonal,
        foto_esquema,
        fecha_inicio,
        fecha_fin,
        tipoImg
    )
    SELECT DISTINCT
        YEAR(c.fecha_inicio) AS año,
        MONTH(c.fecha_inicio) AS mes,
        CAST(e.DNI_VENDEDOR AS VARCHAR(50)) AS dni_responsable,
        e.ZONAL,
        c.foto_esquema,
        c.fecha_inicio,
        c.fecha_fin,
        c.tipoImg
    FROM PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS c
    INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e ON (
        c.modo = 'MULTIMARCA'
        AND e.DNI_VENDEDOR IS NOT NULL
        AND e.ESTADO = 'ACTIVO'
        AND e.ACCION_1 = 'MULTIMARCA'
        AND e.AÑO = @año_real
        AND e.MES = @mes_real
        -- MULTIMARCA no valida criterio_filtro
        AND c.criterio_filtro IS NULL
        -- Validar zonales
        AND (
            (c.zonales IS NULL OR c.zonales = '' OR LTRIM(RTRIM(c.zonales)) = '')
            OR (LOWER(LTRIM(RTRIM(c.zonales))) = 'todas')
            OR (', ' + c.zonales + ', ' LIKE '%, ' + e.ZONAL + ', %')
        )
    )
    WHERE
        c.activa = 1
        AND YEAR(c.fecha_inicio) = @año
        AND MONTH(c.fecha_inicio) = @mes
        AND NOT EXISTS (
            SELECT 1
            FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS f
            WHERE f.dni_responsable = CAST(e.DNI_VENDEDOR AS VARCHAR(50))
              AND f.foto_esquema = c.foto_esquema
        );

END;
