-- Incentivo vigente: facturación total (categoría TODAS), 23 al 27 de marzo de 2026
-- Base de datos: DISTRIBUTOR_DATAMART
-- Zonales: nombres alineados con ventas/cuotas (HUANUCO sin tilde, LIMA SUR como LIMASUR)

DECLARE @IncentivoId INT;

INSERT INTO [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cabecera] (
    nombre_incentivo,
    tipo_incentivo,
    fecha_inicio,
    fecha_fin,
    descripcion,
    detalle_premios,
    consideraciones,
    estado,
    activo
)
VALUES (
    N'Incentivo facturación total 23-27 mar 2026',
    'BONO_EFECTIVO',
    '2026-03-23',
    '2026-03-27',
    N'Bonos por zonal según cumplimiento de Cuota 1 y Cuota 2 sobre facturación total (todas las líneas).',
    NULL,
    N'Cuotas y bonos por zonal según tabla de incentivo. Categoría de medición: TODAS (facturación total).',
    'ACTIVO',
    1
);

SET @IncentivoId = SCOPE_IDENTITY();

INSERT INTO [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cuotas_detalle] (
    incentivo_id,
    zonal,
    categoria,
    cuota1,
    bono1,
    cuota2,
    bono2,
    activo
)
VALUES
    (@IncentivoId, 'AREQUIPA',   'TODAS', 28000.00,  98.00, 40000.00, 100.00, 1),
    (@IncentivoId, 'AYACUCHO',   'TODAS', 51000.00, 179.00, 61000.00, 300.00, 1),
    (@IncentivoId, 'CUSCO',      'TODAS', 70000.00, 245.00, 80000.00, 400.00, 1),
    (@IncentivoId, 'HUANCAYO',   'TODAS', 86000.00, 301.00, 96000.00, 500.00, 1),
    (@IncentivoId, 'HUANUCO',    'TODAS', 46000.00, 161.00, 56000.00, 300.00, 1),
    (@IncentivoId, 'ICA',        'TODAS', 70000.00, 245.00, 80000.00, 400.00, 1),
    (@IncentivoId, 'LIMASUR',    'TODAS', 63000.00, 221.00, 73000.00, 350.00, 1),
    (@IncentivoId, 'PUCALLPA',   'TODAS', 40000.00, 140.00, 50000.00, 180.00, 1),
    (@IncentivoId, 'PUNO',       'TODAS', 28000.00,  98.00, 38000.00, 150.00, 1);
