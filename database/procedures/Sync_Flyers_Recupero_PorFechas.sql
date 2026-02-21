-- Sincroniza únicamente flyers RECUPERO para las fechas indicadas.
-- Modificar @fecha_inicio y @fecha_fin y ejecutar.

DECLARE @fecha_inicio DATE = '2026-02-10';
DECLARE @fecha_fin   DATE = '2026-02-12';

DECLARE @año_real INT = YEAR(@fecha_inicio);
DECLARE @mes_real INT = MONTH(@fecha_inicio);

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
    AND c.fecha_inicio = @fecha_inicio
    AND c.fecha_fin = @fecha_fin
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
