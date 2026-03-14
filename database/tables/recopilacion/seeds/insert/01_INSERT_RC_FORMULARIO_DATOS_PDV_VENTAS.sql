-- =============================================
-- INSERT: RC_FORMULARIO
-- Formulario: DATOS PDV VENTAS
-- =============================================
INSERT INTO dbo.RC_FORMULARIO (
    codigo,
    nombre,
    version,
    descripcion,
    activo,
    fecha_inicio_vigencia,
    fecha_fin_vigencia,
    usuario_creacion
)
VALUES (
    'DATOS_PDV_VENTAS',
    'DATOS PDV VENTAS',
    1,
    'Formulario de recopilacion de datos comerciales en PDV',
    1,
    CAST(GETDATE() AS DATE),
    NULL,
    'SEED_INSERT'
);
