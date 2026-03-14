-- =============================================
-- INSERT: RC_SECCION
-- Formulario: DATOS PDV VENTAS
-- Requiere que exista RC_FORMULARIO(codigo='DATOS_PDV_VENTAS', version=1)
-- =============================================
DECLARE @FormularioId INT;

SELECT @FormularioId = id
FROM dbo.RC_FORMULARIO
WHERE codigo = 'DATOS_PDV_VENTAS'
  AND version = 1;

IF @FormularioId IS NULL
BEGIN
    THROW 51000, 'No existe el formulario DATOS_PDV_VENTAS v1 en RC_FORMULARIO.', 1;
END;

INSERT INTO dbo.RC_SECCION (
    formulario_id,
    codigo,
    titulo,
    descripcion,
    orden,
    activo,
    usuario_creacion
)
VALUES
(@FormularioId, 'PASO_1', 'Antes de la visita - Preparate', 'Preparacion previa del punto de venta', 1, 1, 'SEED_INSERT'),
(@FormularioId, 'PASO_2_CAPA_1', 'Paso 2 - Capa 1 - Identidad del canal', 'Perfil base del canal', 2, 1, 'SEED_INSERT'),
(@FormularioId, 'PASO_2_CAPA_2', 'Paso 2 - Capa 2 - Posicion competitiva', 'Categoria, volumen y proveedor actual', 3, 1, 'SEED_INSERT'),
(@FormularioId, 'PASO_2_CAPA_3', 'Paso 2 - Capa 3 - Potencial y fit', 'Observacion visual del punto', 4, 1, 'SEED_INSERT'),
(@FormularioId, 'PASO_3', 'Paso 3 - Validacion de marca, producto y garantia', 'Interes por producto y garantia extendida', 5, 1, 'SEED_INSERT'),
(@FormularioId, 'PASO_4', 'Paso 4 - Cierre y compromiso', 'Temperatura comercial y siguientes pasos', 6, 1, 'SEED_INSERT');
