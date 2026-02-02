CREATE PROCEDURE dbo.sp_Sincronizar_Flyers_Rango
    @año INT,
    @mes INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Variables para almacenar el año y mes que realmente se usarán
    DECLARE @año_real INT = @año;
    DECLARE @mes_real INT = @mes;

    -- DECLARE @DniExcluidos TABLE (dni BIGINT PRIMARY KEY);
    -- INSERT INTO @DniExcluidos (dni)
    -- VALUES
    --     (76975598), (40903411), (40343492), (71717209), (25565140), (40886671), (46478931), (72114419),
    --     (48729788), (46629625), (41736883), (44353901), (4023647), (44417172), (70333245), (47298032),
    --     (47656328), (43755637), (47823344), (46742181), (70773977), (74906640), (76399606), (20094635),
    --     (46198310), (41667506), (40046438), (42617870), (47952684), (47912861), (5584062), (74237248),
    --     (72516981), (41935076), (47502387), (40232064), (48324120), (20076486), (74952947), (71700037),
    --     (1235233), (41566245), (76836205), (71253432), (28213248), (70417760), (22081506), (76924978),
    --     (73244844), (80630857), (70020447), (70321312), (46578934), (74887697), (77270717), (40918555),
    --     (48226812), (70598264), (2552982), (2299787), (46688548), (42917827), (44533790), (70676677),
    --     (42655052), (41715229), (47626697), (45096741), (10375343), (23230555), (41707231), (23269812),
    --     (74403823), (80064600), (70693149), (74453130), (41310223), (28284563), (70361263), (40783781),
    --     (44703655), (20090996), (41946854), (76809071), (45101795), (75927114), (24485040), (71847682),
    --     (43014679), (42148573), (28270870), (44347443), (43313957), (48669169), (76914400), (72461188),
    --     (42002902), (75419183), (47900109), (43154215), (22289239), (46232492), (22495900), (40040199),
    --     (61385988), (47073697), (41952334), (70236899), (75064228), (74581157), (47431084), (73696375),
    --     (73045217), (75795393), (72312079), (41541531), (46274125), (73628341), (77377178), (42355425),
    --     (44299025), (70332430), (70184938), (43106215), (40236973), (47277908), (70299445), (72551952),
    --     (77478281), (72102717), (42320227), (77387964), (48021612), (47929863), (44813265), (40072178),
    --     (45314574), (70816735), (21533960), (46116531), (63211667), (44963652), (40342896), (75548794),
    --     (71806241), (47949912), (42826764), (70927923), (61944222), (72182410), (46699437), (43402567),
    --     (43862923), (46909821), (6792548), (44289407), (40485564), (80449670), (40107722), (2286397),
    --     (43004844), (42196038), (2266940), (75909939), (72908166), (80045801), (75316114), (73819122),
    --     (41667737), (43673186), (42141102), (42601836), (70976898), (44068969), (75545872), (77172950),
    --     (44762902), (77299896), (43182358), (44879244), (70896462), (24983954), (24719071), (76028723),
    --     (41611355), (61694036), (71640189), (80454928), (76738791), (48080538), (46486769), (47211233),
    --     (41129773), (75919447), (45291605), (41608849), (74223935), (20111859), (76168950), (4323648),
    --     (40963887), (41982506), (46252730), (76412746), (4748858), (44155901), (46451107), (41042998),
    --     (43401820), (46015478), (80177768), (80446454), (1534959);

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

    -- Inserta campañas con todos = 1 (PDV sin validaciones de modo, criterio_filtro y zonales)
    -- Cuando es 'TODOS', incluye a todos los PDV sin exclusiones
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

    -- Inserta campañas de PDV (filtradas por RANGO)
    -- Excluye los PDV TOP cuando criterio_filtro != 'TOP'
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
        -- AND e.ESTADO = 'ACTIVO'
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
    )
    WHERE
        c.activa = 1
        AND YEAR(c.fecha_inicio) = @año
        AND MONTH(c.fecha_inicio) = @mes
        AND c.id <> 235
        -- AND NOT EXISTS (
        --     SELECT 1
        --     FROM @DniExcluidos d
        --     WHERE d.dni = e.DNI_RESPONSABLE
        -- )
        -- Excluir PDV TOP cuando criterio_filtro != 'TOP'
        AND UPPER(LTRIM(RTRIM(c.criterio_filtro))) != 'TOP'
        AND NOT EXISTS (
            SELECT 1
            FROM PORTAL_COMERCIAL.dbo.PDV_TOP pt
            WHERE pt.DNI_RESPONSABLE = e.DNI_RESPONSABLE
              AND pt.año = @año
              AND pt.mes = @mes
        )
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

END;

