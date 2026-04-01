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
('PASO_1', 'P05', 'CATALOGO', 'Catálogo', 'CATALOGO', 1),
('PASO_1', 'P05', 'FOTOS', 'Fotos', 'FOTOS', 2),

-- P08
('PASO_2_CAPA_1', 'P08', 'R1_1_3', '1-3 años', '1_3', 1),
('PASO_2_CAPA_1', 'P08', 'R2_3_5', '3-5 años', '3_5', 2),
('PASO_2_CAPA_1', 'P08', 'R3_MAS_5', '+5 años', 'MAS_5', 3),

-- P09
('PASO_2_CAPA_1', 'P09', 'SI', 'Sí', 'SI', 1),
('PASO_2_CAPA_1', 'P09', 'NO', 'No', 'NO', 2),

-- P11
('PASO_2_CAPA_2', 'P11', 'CELULARES', 'Celulares', 'CELULARES', 1),
('PASO_2_CAPA_2', 'P11', 'ACCESORIOS', 'Accesorios', 'ACCESORIOS', 2),
('PASO_2_CAPA_2', 'P11', 'RECARGAS', 'Recargas', 'RECARGAS', 3),
('PASO_2_CAPA_2', 'P11', 'OTROS', 'Otros', 'OTROS', 4),
('PASO_2_CAPA_2', 'P11', 'CHIPS', 'Chips', 'CHIPS', 5),
('PASO_2_CAPA_2', 'P11', 'SSTT', 'SSTT', 'SSTT', 6),

-- P11B
('PASO_2_CAPA_2', 'P11B', 'SI', 'Sí', 'SI', 1),
('PASO_2_CAPA_2', 'P11B', 'NO', 'No', 'NO', 2),

-- P12
('PASO_2_CAPA_2', 'P12', 'R1', '< S/500', '<500', 1),
('PASO_2_CAPA_2', 'P12', 'R2', 'S/500-2K', '500-2000', 2),
('PASO_2_CAPA_2', 'P12', 'R3', 'S/2K-5K', '2000-5000', 3),
('PASO_2_CAPA_2', 'P12', 'R4', '+S/5K', '>5000', 4),

-- P13
('PASO_2_CAPA_2', 'P13', 'CABLES', 'Cables', 'CABLES', 1),
('PASO_2_CAPA_2', 'P13', 'AUDIFONOS', 'Audífonos', 'AUDIFONOS', 2),
('PASO_2_CAPA_2', 'P13', 'CARGADORES', 'Cargadores', 'CARGADORES', 3),
('PASO_2_CAPA_2', 'P13', 'RELOJES', 'Relojes', 'RELOJES', 4),
('PASO_2_CAPA_2', 'P13', 'MICAS', 'Micas', 'MICAS', 5),
('PASO_2_CAPA_2', 'P13', 'POWER_BANK', 'Power bank (cargador portátil)', 'POWER_BANK', 6),
('PASO_2_CAPA_2', 'P13', 'PARLANTES', 'Parlantes', 'PARLANTES', 7),
('PASO_2_CAPA_2', 'P13', 'CARCASAS', 'Carcasas', 'CARCASAS', 8),
('PASO_2_CAPA_2', 'P13', 'MOUSE', 'Mouse', 'MOUSE', 9),
('PASO_2_CAPA_2', 'P13', 'OTROS', 'Otros', 'OTROS', 10),

-- P16
('PASO_2_CAPA_2', 'P16', 'PRECIO', 'Precio', 'PRECIO', 1),
('PASO_2_CAPA_2', 'P16', 'RAPIDEZ', 'Rapidez', 'RAPIDEZ', 2),
('PASO_2_CAPA_2', 'P16', 'CREDITO', 'Crédito', 'CREDITO', 3),
('PASO_2_CAPA_2', 'P16', 'GARANTIA', 'Garantía', 'GARANTIA', 4),
('PASO_2_CAPA_2', 'P16', 'VARIEDAD', 'Variedad', 'VARIEDAD', 5),
('PASO_2_CAPA_2', 'P16', 'OTROS', 'Otros', 'OTROS', 6),

-- P17
('PASO_2_CAPA_3', 'P17', 'PEQUENO', 'Pequeño (<20m²)', 'PEQUENO', 1),
('PASO_2_CAPA_3', 'P17', 'MEDIANO', 'Mediano (20-50m²)', 'MEDIANO', 2),
('PASO_2_CAPA_3', 'P17', 'GRANDE', 'Grande (+50m²)', 'GRANDE', 3),

-- P19
('PASO_2_CAPA_3', 'P19', 'SI_ORDENADO', 'Sí, bien organizado', 'SI_ORDENADO', 1),
('PASO_2_CAPA_3', 'P19', 'SI_DESORDENADO', 'Sí, desordenado', 'SI_DESORDENADO', 2),
('PASO_2_CAPA_3', 'P19', 'NO_TIENE', 'No tiene', 'NO_TIENE', 3),

-- P20
('PASO_2_CAPA_3', 'P20', 'ALTO', 'Alto', 'ALTO', 1),
('PASO_2_CAPA_3', 'P20', 'MEDIO', 'Medio', 'MEDIO', 2),
('PASO_2_CAPA_3', 'P20', 'BAJO', 'Bajo', 'BAJO', 3),

-- P21
('PASO_2_CAPA_3', 'P21', 'CLARO', 'Claro', 'CLARO', 1),
('PASO_2_CAPA_3', 'P21', 'ENTEL', 'Entel', 'ENTEL', 2),
('PASO_2_CAPA_3', 'P21', 'BITEL', 'Bitel', 'BITEL', 3),
('PASO_2_CAPA_3', 'P21', 'ZTE', 'ZTE', 'ZTE', 4),
('PASO_2_CAPA_3', 'P21', 'SAMSUNG', 'Samsung', 'SAMSUNG', 5),
('PASO_2_CAPA_3', 'P21', 'INFINIX', 'Infinix', 'INFINIX', 6),
('PASO_2_CAPA_3', 'P21', 'MOTOROLA', 'Motorola', 'MOTOROLA', 7),
('PASO_2_CAPA_3', 'P21', 'HONOR', 'Honor', 'HONOR', 8),
('PASO_2_CAPA_3', 'P21', 'XIAOMI', 'Xiaomi', 'XIAOMI', 9),
('PASO_2_CAPA_3', 'P21', 'MARCA_PROPIA', 'Marca propia', 'MARCA_PROPIA', 10),
('PASO_2_CAPA_3', 'P21', 'OTROS', 'Otros', 'OTROS', 11),

-- P23
('PASO_3', 'P23', '1', '1', '1', 1),
('PASO_3', 'P23', '2', '2', '2', 2),
('PASO_3', 'P23', '3', '3', '3', 3),
('PASO_3', 'P23', '4', '4', '4', 4),
('PASO_3', 'P23', '5', '5', '5', 5),

-- P24
('PASO_3', 'P24', 'CABLES', 'Cables', 'CABLES', 1),
('PASO_3', 'P24', 'AUDIFONOS', 'Audífonos', 'AUDIFONOS', 2),
('PASO_3', 'P24', 'CARGADORES', 'Cargadores', 'CARGADORES', 3),
('PASO_3', 'P24', 'RELOJES', 'Relojes', 'RELOJES', 4),
('PASO_3', 'P24', 'MICAS', 'Micas', 'MICAS', 5),
('PASO_3', 'P24', 'POWER_BANK', 'Power bank (cargador portátil)', 'POWER_BANK', 6),
('PASO_3', 'P24', 'PARLANTES', 'Parlantes', 'PARLANTES', 7),
('PASO_3', 'P24', 'CARCASAS', 'Carcasas', 'CARCASAS', 8),
('PASO_3', 'P24', 'MOUSE', 'Mouse', 'MOUSE', 9),
('PASO_3', 'P24', 'OTROS', 'Otros', 'OTROS', 10),

-- P25
('PASO_3', 'P25', 'SI', 'Sí', 'SI', 1),
('PASO_3', 'P25', 'NO', 'No', 'NO', 2),
('PASO_3', 'P25', 'MAS_O_MENOS', 'Más o menos', 'MAS_O_MENOS', 3),

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
