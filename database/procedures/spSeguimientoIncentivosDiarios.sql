CREATE PROCEDURE dbo.spSeguimientoIncentivosDiarios
(
    @Fecha DATE,
    @ZonalFiltro VARCHAR(20),
    @SoloGanadores BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ZonalFiltroNorm VARCHAR(20) = UPPER(LTRIM(RTRIM(@ZonalFiltro)));

    IF (@ZonalFiltroNorm NOT IN ('HUANUCO', 'HUANCAYO'))
    BEGIN
        RAISERROR('El parámetro @ZonalFiltro solo admite HUANUCO o HUANCAYO.', 16, 1);
        RETURN;
    END;

    ---------------------------------------------------------------
    -- 1. Reglas: expandir grupos (G1,G2) para facilitar el join
    ---------------------------------------------------------------
    ;WITH Reglas AS (
        SELECT
            r.*,
            LTRIM(RTRIM(value)) AS Grupo
        FROM PORTAL_COMERCIAL.dbo.tbl_incentivos_diarios r
        CROSS APPLY STRING_SPLIT(REPLACE(r.grupos, ' ', ''), ',')
        WHERE r.activo = 1
    ),
    ---------------------------------------------------------------
    -- 2. Ventas del día por vendedor (ALTAS / PORTA / POSTPAGO)
    ---------------------------------------------------------------
    Ventas AS (
        SELECT
            TRY_CONVERT(INT, v.DNI_RESPONSABLE) AS DNI_RESPONSABLE,
            v.ZONAL AS ZONAL_ORIGEN,
            SUM(CASE WHEN v.OPERATION_NAME = 'Alta' AND v.PRODUCT_NAME = 'Prepago' THEN 1 ELSE 0 END) AS ALTAS_PRE,
            SUM(CASE WHEN v.OPERATION_NAME = 'Portabilidad' AND v.PRODUCT_NAME = 'Prepago' THEN 1 ELSE 0 END) AS PORTA_PRE,
            SUM(CASE WHEN v.PRODUCT_NAME = 'Postpago' THEN 1 ELSE 0 END) AS POSTPAGO
        FROM PORTAL_COMERCIAL.dbo.VentasLog v
        WHERE v.FECHA = @Fecha
          AND v.OPERATION_NAME IN ('Alta', 'Portabilidad')
          AND v.PRODUCT_NAME IN ('Prepago', 'Postpago')
          AND (
                (@ZonalFiltroNorm = 'HUANUCO' AND UPPER(LTRIM(RTRIM(v.ZONAL))) = 'HUANUCO')
                OR (@ZonalFiltroNorm = 'HUANCAYO' AND UPPER(LTRIM(RTRIM(v.ZONAL))) = 'HUANCAYO')
              )
          AND TRY_CONVERT(INT, v.DNI_RESPONSABLE) IS NOT NULL
          AND TRY_CONVERT(INT, v.DNI_RESPONSABLE) <> 0
        GROUP BY TRY_CONVERT(INT, v.DNI_RESPONSABLE), v.ZONAL
    ),
    ---------------------------------------------------------------
    -- 3. Recargas del día por vendedor
    ---------------------------------------------------------------
    Recargas AS (
        SELECT
            f.DNI_RESPONSABLE,
            COUNT(1) AS RECARGAS
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL f
        WHERE f.FECHA = @Fecha
          AND f.RECARGA_SI_NO = 1
          AND f.[RECARGAS>5] = 1
          AND f.PRODUCTO_WEB IN ('PREPAGO M7', 'PORT PREPAGO M7')
          AND (
                (@ZonalFiltroNorm = 'HUANUCO' AND UPPER(LTRIM(RTRIM(f.ZONAL))) = 'HUANUCO')
                OR (@ZonalFiltroNorm = 'HUANCAYO' AND UPPER(LTRIM(RTRIM(f.ZONAL))) = 'HUANCAYO')
              )
        GROUP BY f.DNI_RESPONSABLE
    ),
    ---------------------------------------------------------------
    -- 4. Base de vendedores activos del entregable (normaliza DNI)
    ---------------------------------------------------------------
    EntregableBase AS (
        SELECT
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(e.DNI_RESPONSABLE)), '')) AS DNI_NORMALIZADO,
            e.ZONAL AS ZONAL_ORIGEN,
            CASE
                WHEN UPPER(LTRIM(RTRIM(e.ZONAL))) IN ('H. CENTRO', 'H. SELVA') THEN 'HUANCAYO'
                ELSE 'HUANUCO'
            END AS ZONAL_NORMALIZADO,
            UPPER(LTRIM(RTRIM(e.GRUPO))) AS GRUPO,
            e.NOMBRE_RESPONSABLE
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e
        WHERE e.ESTADO = 'ACTIVO'
          AND e.AÑO = YEAR(@Fecha)
          AND e.MES = MONTH(@Fecha)
          AND (
                (@ZonalFiltroNorm = 'HUANUCO' AND UPPER(LTRIM(RTRIM(e.ZONAL))) = 'HUANUCO')
                OR (@ZonalFiltroNorm = 'HUANCAYO' AND UPPER(LTRIM(RTRIM(e.ZONAL))) IN ('H. CENTRO', 'H. SELVA'))
              )
    ),
    Entregable AS (
        SELECT
            DNI_NORMALIZADO,
            MAX(ZONAL_ORIGEN) AS ZONAL_ORIGEN,
            MAX(ZONAL_NORMALIZADO) AS ZONAL_NORMALIZADO,
            MAX(GRUPO) AS GRUPO,
            MAX(NOMBRE_RESPONSABLE) AS NOMBRE_RESPONSABLE
        FROM EntregableBase
        WHERE DNI_NORMALIZADO IS NOT NULL AND DNI_NORMALIZADO <> 0
        GROUP BY DNI_NORMALIZADO
    ),
    Base AS (
        SELECT
            e.DNI_NORMALIZADO AS DNI_RESPONSABLE,
            ISNULL(v.ALTAS_PRE, 0) AS ALTAS_PRE,
            ISNULL(v.PORTA_PRE, 0) AS PORTA_PRE,
            ISNULL(v.POSTPAGO, 0) AS POSTPAGO,
            ISNULL(r.RECARGAS, 0) AS RECARGAS,
            e.ZONAL_NORMALIZADO,
            e.GRUPO,
            e.NOMBRE_RESPONSABLE,
            e.ZONAL_ORIGEN
        FROM Entregable e
        LEFT JOIN Ventas v ON v.DNI_RESPONSABLE = e.DNI_NORMALIZADO
        LEFT JOIN Recargas r ON r.DNI_RESPONSABLE = e.DNI_NORMALIZADO
    ),
    ---------------------------------------------------------------
    -- 5. Reglas cumplidas por vendedor
    ---------------------------------------------------------------
    ReglasCumplidas AS (
        SELECT
            b.DNI_RESPONSABLE,
            b.NOMBRE_RESPONSABLE,
            b.ZONAL_NORMALIZADO,
            b.GRUPO,
            b.ALTAS_PRE,
            b.PORTA_PRE,
            b.POSTPAGO,
            b.RECARGAS,
            rg.id AS REGLA_ID,
            rg.premio,
            rg.es_exclusivo,
            rg.prioridad,
            rg.descripcion_detalle
        FROM Base b
        INNER JOIN Reglas rg
            ON rg.zonal = b.ZONAL_NORMALIZADO
           AND rg.Grupo = b.GRUPO
        WHERE (rg.requisito_altas_pre IS NULL OR b.ALTAS_PRE >= rg.requisito_altas_pre)
          AND (rg.requisito_porta_pre IS NULL OR b.PORTA_PRE >= rg.requisito_porta_pre)
          AND (rg.requisito_postpago IS NULL OR b.POSTPAGO >= rg.requisito_postpago)
          AND (rg.requisito_recargas IS NULL OR b.RECARGAS >= rg.requisito_recargas)
    ),
    Exclusivos AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY DNI_RESPONSABLE ORDER BY prioridad DESC, REGLA_ID) AS rn
        FROM ReglasCumplidas
        WHERE es_exclusivo = 1
    ),
    NoExclusivos AS (
        SELECT *
        FROM ReglasCumplidas
        WHERE es_exclusivo = 0
    ),
    NoExclusivosAgg AS (
        SELECT
            ne1.DNI_RESPONSABLE,
            STUFF((
                SELECT ' + ' + ne2.premio
                FROM NoExclusivos ne2
                WHERE ne2.DNI_RESPONSABLE = ne1.DNI_RESPONSABLE
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)'), 1, 3, '') AS PremiosAdicionales
        FROM NoExclusivos ne1
        GROUP BY ne1.DNI_RESPONSABLE
    )
    ---------------------------------------------------------------
    -- 6. Resultado final
    ---------------------------------------------------------------
    SELECT
        @Fecha AS Fecha,
        b.DNI_RESPONSABLE,
        b.NOMBRE_RESPONSABLE,
        b.ZONAL_ORIGEN AS ZONAL,
        b.GRUPO,
        b.ALTAS_PRE,
        b.PORTA_PRE,
        b.POSTPAGO,
        b.RECARGAS,
        CASE
            WHEN ex.premio IS NOT NULL THEN ex.premio
            WHEN ne.PremiosAdicionales IS NOT NULL THEN NULL
            ELSE 'NO GANA MERCH'
        END AS PremioPrincipal,
        CASE
            WHEN ex.descripcion_detalle IS NOT NULL THEN ex.descripcion_detalle
            WHEN ne.PremiosAdicionales IS NOT NULL THEN NULL
            ELSE 'NO GANA MERCH'
        END AS DetallePremioPrincipal,
        ne.PremiosAdicionales
    FROM Base b
    LEFT JOIN Exclusivos ex ON ex.DNI_RESPONSABLE = b.DNI_RESPONSABLE AND ex.rn = 1
    LEFT JOIN NoExclusivosAgg ne ON ne.DNI_RESPONSABLE = b.DNI_RESPONSABLE
WHERE (@SoloGanadores = 0)
   OR (@SoloGanadores = 1 AND (ex.premio IS NOT NULL OR ne.PremiosAdicionales IS NOT NULL))
ORDER BY b.ZONAL_NORMALIZADO, b.GRUPO, b.NOMBRE_RESPONSABLE;
END;

