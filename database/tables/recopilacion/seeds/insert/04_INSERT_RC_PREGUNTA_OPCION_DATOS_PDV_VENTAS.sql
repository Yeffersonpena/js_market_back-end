-- =============================================
-- INSERT: RC_PREGUNTA_OPCION
-- Formulario: DATOS PDV VENTAS
-- Requiere:
--   - RC_FORMULARIO(codigo='DATOS_PDV_VENTAS', version=1)
--   - RC_PREGUNTA cargada para ese formulario
-- =============================================

DECLARE @FormularioCodigo VARCHAR(50) = 'DATOS_PDV_VENTAS';
DECLARE @Version INT = 1;
DECLARE @FormularioId INT;

SELECT @FormularioId = id
FROM dbo.RC_FORMULARIO
WHERE codigo = @FormularioCodigo
  AND version = @Version;

IF @FormularioId IS NULL
BEGIN
    THROW 51011, 'No existe RC_FORMULARIO DATOS_PDV_VENTAS v1.', 1;
END;

DECLARE @Opciones TABLE (
    seccion_codigo VARCHAR(50),
    pregunta_codigo VARCHAR(50),
    codigo VARCHAR(50),
    etiqueta VARCHAR(200),
    valor VARCHAR(200),
    orden INT
);

INSERT INTO @Opciones
VALUES
-- P03
('PASO_1', 'P03', 'SI', 'Sí', 'SI', 1),
('PASO_1', 'P03', 'NO', 'No', 'NO', 2),

-- P05
('PASO_1', 'P05', 'FOTOS', 'Fotos', 'FOTOS', 1),
('PASO_1', 'P05', 'KIT', 'Kit', 'KIT', 2),

-- P09
('PASO_2_CAPA_1', 'P09', 'SI', 'Sí', 'SI', 1),
('PASO_2_CAPA_1', 'P09', 'NO', 'No', 'NO', 2),

-- P11
('PASO_2_CAPA_2', 'P11', 'CELULARES', 'Celulares', 'CELULARES', 1),
('PASO_2_CAPA_2', 'P11', 'ACCESORIOS', 'Accesorios', 'ACCESORIOS', 2),
('PASO_2_CAPA_2', 'P11', 'RECARGAS', 'Recargas', 'RECARGAS', 3),
('PASO_2_CAPA_2', 'P11', 'OTROS', 'Otros', 'OTROS', 4),

-- P12
('PASO_2_CAPA_2', 'P12', 'R1', '< S/500', '<500', 1),
('PASO_2_CAPA_2', 'P12', 'R2', 'S/500-2K', '500-2000', 2),
('PASO_2_CAPA_2', 'P12', 'R3', 'S/2K-5K', '2000-5000', 3),
('PASO_2_CAPA_2', 'P12', 'R4', '+S/5K', '>5000', 4),

-- P16
('PASO_2_CAPA_2', 'P16', 'PRECIO', 'Precio', 'PRECIO', 1),
('PASO_2_CAPA_2', 'P16', 'RAPIDEZ', 'Rapidez', 'RAPIDEZ', 2),
('PASO_2_CAPA_2', 'P16', 'CREDITO', 'Crédito', 'CREDITO', 3),
('PASO_2_CAPA_2', 'P16', 'GARANTIA', 'Garantía', 'GARANTIA', 4),
('PASO_2_CAPA_2', 'P16', 'VARIEDAD', 'Variedad', 'VARIEDAD', 5),

-- P17
('PASO_2_CAPA_3', 'P17', 'PEQUENO', 'Pequeño (<20m²)', 'PEQUENO', 1),
('PASO_2_CAPA_3', 'P17', 'MEDIANO', 'Mediano (20-50m²)', 'MEDIANO', 2),
('PASO_2_CAPA_3', 'P17', 'GRANDE', 'Grande (+50m²)', 'GRANDE', 3),

-- P18
('PASO_2_CAPA_3', 'P18', 'SIN_CLIENTES', 'Sin clientes', 'SIN_CLIENTES', 1),
('PASO_2_CAPA_3', 'P18', 'UNO_A_TRES', '1-3 clientes', '1_3_CLIENTES', 2),
('PASO_2_CAPA_3', 'P18', 'MAS_DE_TRES', '+3 clientes', 'MAS_3_CLIENTES', 3),

-- P19
('PASO_2_CAPA_3', 'P19', 'SI_ORDENADO', 'Sí, bien organizado', 'SI_ORDENADO', 1),
('PASO_2_CAPA_3', 'P19', 'SI_DESORDENADO', 'Sí, desordenado', 'SI_DESORDENADO', 2),
('PASO_2_CAPA_3', 'P19', 'NO_TIENE', 'No tiene', 'NO_TIENE', 3),

-- P20
('PASO_2_CAPA_3', 'P20', 'ALTO', 'Alto', 'ALTO', 1),
('PASO_2_CAPA_3', 'P20', 'MEDIO', 'Medio', 'MEDIO', 2),
('PASO_2_CAPA_3', 'P20', 'BAJO', 'Bajo', 'BAJO', 3),

-- P23
('PASO_3', 'P23', 'N1', '1', '1', 1),
('PASO_3', 'P23', 'N2', '2', '2', 2),
('PASO_3', 'P23', 'N3', '3', '3', 3),
('PASO_3', 'P23', 'N4', '4', '4', 4),
('PASO_3', 'P23', 'N5', '5', '5', 5),

-- P24
('PASO_3', 'P24', 'PARLANTES', 'Parlantes', 'PARLANTES', 1),
('PASO_3', 'P24', 'AUDIFONOS', 'Audífonos', 'AUDIFONOS', 2),
('PASO_3', 'P24', 'CABLES', 'Cables', 'CABLES', 3),
('PASO_3', 'P24', 'BATERIAS', 'Baterías', 'BATERIAS', 4),
('PASO_3', 'P24', 'RELOJES', 'Relojes', 'RELOJES', 5),

-- P27
('PASO_3', 'P27', 'SI', 'Sí', 'SI', 1),
('PASO_3', 'P27', 'NO', 'No', 'NO', 2),

-- P28
('PASO_3', 'P28', 'MUCHO', 'Mucho', 'MUCHO', 1),
('PASO_3', 'P28', 'ALGO', 'Algo', 'ALGO', 2),
('PASO_3', 'P28', 'POCO', 'Poco', 'POCO', 3),
('PASO_3', 'P28', 'NADA', 'Nada', 'NADA', 4),

-- P29
('PASO_3', 'P29', 'MUY', 'Muy', 'MUY', 1),
('PASO_3', 'P29', 'MODERADO', 'Moderado', 'MODERADO', 2),
('PASO_3', 'P29', 'POCO', 'Poco', 'POCO', 3),

-- P30
('PASO_4', 'P30', 'NIVEL_1', '1 Sin interés', '1', 1),
('PASO_4', 'P30', 'NIVEL_2', '2 Escéptico', '2', 2),
('PASO_4', 'P30', 'NIVEL_3', '3 Neutral', '3', 3),
('PASO_4', 'P30', 'NIVEL_4', '4 Interesado', '4', 4),
('PASO_4', 'P30', 'NIVEL_5', '5 Muy receptivo', '5', 5),

-- P31
('PASO_4', 'P31', 'SI', 'Sí', 'SI', 1),
('PASO_4', 'P31', 'NO', 'No', 'NO', 2),
('PASO_4', 'P31', 'TAL_VEZ', 'Tal vez', 'TAL_VEZ', 3);

IF EXISTS (
    SELECT 1
    FROM @Opciones o
    LEFT JOIN dbo.RC_SECCION s
        ON s.formulario_id = @FormularioId
       AND s.codigo = o.seccion_codigo
    LEFT JOIN dbo.RC_PREGUNTA q
        ON q.seccion_id = s.id
       AND q.codigo = o.pregunta_codigo
    WHERE q.id IS NULL
)
BEGIN
    THROW 51012, 'Faltan preguntas requeridas para insertar RC_PREGUNTA_OPCION.', 1;
END;

INSERT INTO dbo.RC_PREGUNTA_OPCION (
    pregunta_id,
    codigo,
    etiqueta,
    valor,
    orden,
    activo,
    usuario_creacion
)
SELECT
    q.id AS pregunta_id,
    o.codigo,
    o.etiqueta,
    o.valor,
    o.orden,
    1 AS activo,
    'SEED_INSERT' AS usuario_creacion
FROM @Opciones o
INNER JOIN dbo.RC_SECCION s
    ON s.formulario_id = @FormularioId
   AND s.codigo = o.seccion_codigo
INNER JOIN dbo.RC_PREGUNTA q
    ON q.seccion_id = s.id
   AND q.codigo = o.pregunta_codigo;
