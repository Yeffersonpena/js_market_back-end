CREATE PROCEDURE dbo.sp_Sincronizar_Flyers_Rango
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
        -- Si no existe información para el mes solicitado, buscar el período más reciente anterior
        -- Busca el año y mes máximo que sea anterior cronológicamente al período solicitado
        SELECT TOP 1
            @año_real = AÑO,
            @mes_real = MES
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE
        WHERE ESTADO = 'ACTIVO'
          AND (
              AÑO < @año
              OR (AÑO = @año AND MES < @mes)
          )
        ORDER BY AÑO DESC, MES DESC;
    END

    -- TODOS = TODOS: incluye a TODOS los PDV sin ninguna exclusión (incluye TOP, todos los rangos, todas las zonales)
    -- Sin validaciones de modo, criterio_filtro ni zonales
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
        e.DNI_RESPONSABLE IS NOT NULL
        -- AND e.ESTADO = 'ACTIVO'
        AND e.AÑO = @año_real
        AND e.MES = @mes_real
    )
    WHERE
        c.activa = 1
        AND c.modo = 'TODOS'
        AND YEAR(c.fecha_inicio) = @año
        AND MONTH(c.fecha_inicio) = @mes
        AND c.id <> 235
        -- AND NOT EXISTS (
        --     SELECT 1
        --     FROM @DniExcluidos d
        --     WHERE d.dni = e.DNI_RESPONSABLE
        -- )
        AND NOT EXISTS (
            SELECT 1
            FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS f
            WHERE f.dni_responsable = CAST(e.DNI_RESPONSABLE AS VARCHAR(50))
              AND f.foto_esquema = c.foto_esquema
              AND f.fecha_inicio = c.fecha_inicio
              AND f.fecha_fin = c.fecha_fin
        );

    -- Inserta campañas de PDV (filtradas por RANGO). Solo criterios distintos de TOP y de RECUPERO.
    -- Regla: DNI en PDV_TOP o en PDV_RECUPERO (para las fechas de la campaña) no reciben incentivos por rango; solo TOP, RECUPERO o TODOS.
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
        AND e.AÑO = @año_real
        AND e.MES = @mes_real
        -- Validar RANGO exacto (soporta rangos concatenados como RANGO 1,RANGO 2,RANGO 3)
        AND (
            e.RANGO = c.criterio_filtro
            OR (',' + c.criterio_filtro + ',' LIKE '%,' + e.RANGO + ',%')
            OR (', ' + c.criterio_filtro + ', ' LIKE '%, ' + e.RANGO + ', %')
        )
        -- Validar zonales
        AND (
            (c.zonales IS NULL OR c.zonales = '' OR LTRIM(RTRIM(c.zonales)) = '')
            OR (LOWER(LTRIM(RTRIM(c.zonales))) = 'todas')
            OR (', ' + c.zonales + ', ' LIKE '%, ' + e.ZONAL + ', %')
        )
        -- Exclusión: DNI en TOP en el periodo de la campaña no entra (solo reciben TOP o TODOS)
        AND NOT EXISTS (
            SELECT 1
            FROM PORTAL_COMERCIAL.dbo.PDV_TOP pt
            WHERE pt.DNI_RESPONSABLE = e.DNI_RESPONSABLE
              AND pt.año = YEAR(c.fecha_inicio)
              AND pt.mes = MONTH(c.fecha_inicio)
        )
        -- Exclusión: DNI en RECUPERO para las mismas fechas de campaña no entra (solo reciben RECUPERO o TODOS)
        AND NOT EXISTS (
            SELECT 1
            FROM PORTAL_COMERCIAL.dbo.PDV_RECUPERO pr
            WHERE pr.DNI_RESPONSABLE = e.DNI_RESPONSABLE
              AND pr.fecha_inicio = c.fecha_inicio
              AND pr.fecha_fin = c.fecha_fin
        )
    )
    WHERE
        c.activa = 1
        AND UPPER(LTRIM(RTRIM(ISNULL(c.criterio_filtro, '')))) != 'TOP'
        AND UPPER(LTRIM(RTRIM(ISNULL(c.criterio_filtro, '')))) != 'RECUPERO'
        AND YEAR(c.fecha_inicio) = @año
        AND MONTH(c.fecha_inicio) = @mes
        AND c.id <> 235
        AND NOT EXISTS (
            SELECT 1
            FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS f
            WHERE f.dni_responsable = CAST(e.DNI_RESPONSABLE AS VARCHAR(50))
              AND f.foto_esquema = c.foto_esquema
              AND f.fecha_inicio = c.fecha_inicio
              AND f.fecha_fin = c.fecha_fin
        );

    -- Inserta campañas de PDV TOP (solo cuando criterio_filtro = 'TOP')
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
        CAST(pt.DNI_RESPONSABLE AS VARCHAR(50)) AS dni_responsable,
        e.ZONAL,
        c.foto_esquema,
        c.fecha_inicio,
        c.fecha_fin,
        c.tipoImg
    FROM PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS c
    INNER JOIN PORTAL_COMERCIAL.dbo.PDV_TOP pt ON (
        pt.año = @año
        AND pt.mes = @mes
    )
    LEFT JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e ON (
        e.DNI_RESPONSABLE = pt.DNI_RESPONSABLE
        AND e.AÑO = @año
        AND e.MES = @mes
    )
    WHERE
        c.activa = 1
        AND c.modo = 'PDV'
        AND UPPER(LTRIM(RTRIM(c.criterio_filtro))) = 'TOP'
        AND YEAR(c.fecha_inicio) = @año
        AND MONTH(c.fecha_inicio) = @mes
        AND c.id <> 235
        -- AND NOT EXISTS (
        --     SELECT 1
        --     FROM @DniExcluidos d
        --     WHERE d.dni = pt.DNI_RESPONSABLE
        -- )
        -- Validar zonales
        AND (
            (c.zonales IS NULL OR c.zonales = '' OR LTRIM(RTRIM(c.zonales)) = '')
            OR (LOWER(LTRIM(RTRIM(c.zonales))) = 'todas')
            OR e.ZONAL IS NULL
            OR (', ' + c.zonales + ', ' LIKE '%, ' + e.ZONAL + ', %')
        )
        AND NOT EXISTS (
            SELECT 1
            FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS f
            WHERE f.dni_responsable = CAST(pt.DNI_RESPONSABLE AS VARCHAR(50))
              AND f.foto_esquema = c.foto_esquema
              AND f.fecha_inicio = c.fecha_inicio
              AND f.fecha_fin = c.fecha_fin
        );

    -- Inserta campañas de PDV RECUPERO (solo cuando criterio_filtro = 'RECUPERO')
    -- Solo los DNI que están en PDV_RECUPERO para las mismas fecha_inicio/fecha_fin de la campaña
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
        CAST(pr.DNI_RESPONSABLE AS VARCHAR(50)) AS dni_responsable,
        e.ZONAL,
        c.foto_esquema,
        c.fecha_inicio,
        c.fecha_fin,
        c.tipoImg
    FROM PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS c
    INNER JOIN PORTAL_COMERCIAL.dbo.PDV_RECUPERO pr ON (
        pr.fecha_inicio = c.fecha_inicio
        AND pr.fecha_fin = c.fecha_fin
    )
    LEFT JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e ON (
        e.DNI_RESPONSABLE = pr.DNI_RESPONSABLE
        AND e.AÑO = @año_real
        AND e.MES = @mes_real
    )
    WHERE
        c.activa = 1
        AND c.modo = 'PDV'
        AND UPPER(LTRIM(RTRIM(ISNULL(c.criterio_filtro, '')))) = 'RECUPERO'
        AND YEAR(c.fecha_inicio) = @año
        AND MONTH(c.fecha_inicio) = @mes
        AND c.id <> 235
        AND (
            (c.zonales IS NULL OR c.zonales = '' OR LTRIM(RTRIM(c.zonales)) = '')
            OR (LOWER(LTRIM(RTRIM(c.zonales))) = 'todas')
            OR e.ZONAL IS NULL
            OR (', ' + c.zonales + ', ' LIKE '%, ' + e.ZONAL + ', %')
        )
        AND NOT EXISTS (
            SELECT 1
            FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS f
            WHERE f.dni_responsable = CAST(pr.DNI_RESPONSABLE AS VARCHAR(50))
              AND f.foto_esquema = c.foto_esquema
              AND f.fecha_inicio = c.fecha_inicio
              AND f.fecha_fin = c.fecha_fin
        );

END;

