-- =============================================
-- INSERT: RC_PREGUNTA
-- Formulario: DATOS PDV VENTAS
-- Requiere:
--   - RC_FORMULARIO(codigo='DATOS_PDV_VENTAS', version=1)
--   - RC_SECCION cargada para ese formulario
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
    THROW 51001, 'No existe RC_FORMULARIO DATOS_PDV_VENTAS v1.', 1;
END;

DECLARE @Preguntas TABLE (
    seccion_codigo VARCHAR(50),
    codigo VARCHAR(50),
    texto VARCHAR(1000),
    texto_ayuda VARCHAR(500),
    tipo_respuesta VARCHAR(30),
    obligatoria BIT,
    permite_no_aplica BIT,
    requiere_foto BIT,
    min_fotos INT,
    max_fotos INT,
    orden INT,
    max_longitud INT NULL,
    valor_minimo DECIMAL(18,4) NULL,
    valor_maximo DECIMAL(18,4) NULL
);

INSERT INTO @Preguntas
VALUES
-- PASO 1
('PASO_1', 'P01', '¿Cuánto compra en EQ por mes?', 'Revisar Excel del canal. Anotar ticket promedio mensual.', 'decimal', 1, 0, 0, 0, 0, 1, NULL, 0, NULL),
('PASO_1', 'P02', '¿Cuánto debería comprar en AXX?', 'Calcular: ticket x 10% = meta de AXX en S/.', 'decimal', 1, 0, 0, 0, 0, 2, NULL, 0, NULL),
('PASO_1', 'P03', '¿Ya compra AXX a JS hoy?', 'Revisar historial en Controlnet. ¿Cuánto? ¿Con qué frecuencia?', 'opcion_unica', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
('PASO_1', 'P04', '¿Qué zona y quién atiende?', 'Confirmar jefe zonal asignado y vendedor de ruta.', 'texto_corto', 1, 0, 0, 0, 0, 4, 150, NULL, NULL),
('PASO_1', 'P05', '¿Qué llevo para mostrar?', 'Preparar fotos de producto JS (caja, display). Llevar kit de muestra si disponible.', 'opcion_multiple', 1, 0, 0, 0, 0, 5, NULL, NULL, NULL),

-- PASO 2 - CAPA 1
('PASO_2_CAPA_1', 'P06', '¿Cuál es el nombre completo del dueño del local?', 'Anotar tal como aparece en su DNI.', 'texto_corto', 1, 0, 0, 0, 0, 1, 150, NULL, NULL),
('PASO_2_CAPA_1', 'P07', '¿Cuál es su DNI?', 'Este campo es OBLIGATORIO — es el ID unificador en el sistema.', 'numero', 1, 0, 0, 0, 0, 2, NULL, 10000000, 99999999),
('PASO_2_CAPA_1', 'P08', '¿Cuántos años lleva este local operando?', 'Si no sabe exactamente, anotar rango: 1-3 / 3-5 / +5 años.', 'numero', 1, 1, 0, 0, 0, 3, NULL, 0, NULL),
('PASO_2_CAPA_1', 'P09', '¿Maneja otros puntos de venta además de este?', 'Si sí: ¿cuántos? ¿en qué zonas? Esto identifica distribuidores encubiertos.', 'si_no', 1, 0, 0, 0, 0, 4, NULL, NULL, NULL),
('PASO_2_CAPA_1', 'P10', '¿Con qué nombre comercial se identifica este local?', 'Puede ser diferente al RUC registrado en la base.', 'texto_corto', 1, 0, 0, 0, 0, 5, 200, NULL, NULL),
('PASO_2_CAPA_1', 'E01', 'EVIDENCIA: Foto de la fachada del local + foto del DNI del dueño (con su permiso).', NULL, 'texto_largo', 1, 0, 1, 2, 4, 6, NULL, NULL, NULL),

-- PASO 2 - CAPA 2
('PASO_2_CAPA_2', 'P11', '¿Qué productos vende principalmente?', 'Marcar: celulares / accesorios / recargas / otros', 'opcion_multiple', 1, 0, 0, 0, 0, 1, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'P12', '¿Cuánto estima que vende en accesorios por mes?', 'Pedir rango: < S/500 / S/500-2K / S/2K-5K / +S/5K', 'opcion_unica', 1, 0, 0, 0, 0, 2, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'P13', '¿Qué accesorios se venden más en su local?', 'Top 3 productos: cables, audífonos, cargadores, etc.', 'texto_largo', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'P14', '¿A quién le compra accesorios hoy?', 'Anotar nombre de proveedor o distribuidor. ¿Cuántos proveedores tiene?', 'texto_largo', 1, 0, 0, 0, 0, 4, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'P15', '¿Qué marcas maneja en góndola?', 'Observar y anotar. Si puede, fotografiar los precios visibles.', 'texto_largo', 1, 0, 0, 0, 0, 5, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'P16', '¿Qué valora más de su proveedor actual?', 'Precio / rapidez / crédito / garantía / variedad', 'opcion_multiple', 1, 0, 0, 0, 0, 6, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'E02', 'EVIDENCIA: Foto de la góndola de accesorios con marcas y precios visibles.', NULL, 'texto_largo', 1, 0, 1, 1, 3, 7, NULL, NULL, NULL),

-- PASO 2 - CAPA 3
('PASO_2_CAPA_3', 'P17', 'Tamaño del local', 'Pequeño (<20m²) / Mediano (20-50m²) / Grande (+50m²). Indicador directo de capacidad de inventario.', 'opcion_unica', 1, 0, 0, 0, 0, 1, NULL, NULL, NULL),
('PASO_2_CAPA_3', 'P18', 'Tráfico visible al momento de la visita', 'Sin clientes / 1-3 clientes / +3 clientes. Anota hora de visita para contexto.', 'opcion_unica', 1, 0, 0, 0, 0, 2, NULL, NULL, NULL),
('PASO_2_CAPA_3', 'P19', '¿Tiene vitrina o display activo de accesorios?', 'Sí, bien organizado / Sí, desordenado / No tiene. Este dato predice receptividad al kit de muestra.', 'opcion_unica', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
('PASO_2_CAPA_3', 'P20', 'Nivel de organización general del local', 'Alto / Medio / Bajo. Un local organizado sugiere un dueño que cuida su imagen — más abierto a trabajar con marca.', 'opcion_unica', 1, 0, 0, 0, 0, 4, NULL, NULL, NULL),
('PASO_2_CAPA_3', 'P21', '¿Tiene letrero o señalización visible de operador?', 'Anotar qué operadores tiene señalizados (Claro, Entel, Bitel). Indica alineación comercial actual.', 'texto_largo', 1, 1, 0, 0, 0, 5, NULL, NULL, NULL),
('PASO_2_CAPA_3', 'P22', 'Observación libre del jefe zonal', 'Cualquier dato relevante que no encaje en las preguntas anteriores. Intuición sobre el potencial del canal.', 'texto_largo', 0, 1, 0, 0, 0, 6, NULL, NULL, NULL),
('PASO_2_CAPA_3', 'E03', 'EVIDENCIA: Foto frontal del local + foto interior mostrando organización y display de accesorios.', NULL, 'texto_largo', 1, 0, 1, 2, 4, 7, NULL, NULL, NULL),

-- PASO 3
('PASO_3', 'P23', 'Mostrar fotos de producto JS (caja + display). ¿Le parece atractivo el packaging?', '1-5 + comentario', 'opcion_unica', 1, 0, 0, 0, 0, 1, NULL, NULL, NULL),
('PASO_3', 'P24', '¿Qué línea le interesaría probar primero?', 'Parlantes / Audífonos / Cables / Baterías / Relojes', 'opcion_multiple', 1, 0, 0, 0, 0, 2, NULL, NULL, NULL),
('PASO_3', 'P25', '¿A qué precio estarían dispuestos a comprar en cada línea?', 'Rango por categoría', 'texto_largo', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
('PASO_3', 'P26', '¿Hay algo del producto o empaque que cambiaría?', 'Comentario libre', 'texto_largo', 0, 1, 0, 0, 0, 4, NULL, NULL, NULL),
('PASO_3', 'P27', '¿Ha tenido problemas con garantías de su proveedor actual?', 'Sí / No + experiencia', 'si_no', 1, 0, 0, 0, 0, 5, NULL, NULL, NULL),
('PASO_3', 'P28', '¿Una garantía de 12 meses cambiaría su decisión de comprarle a JS?', 'Mucho / Algo / Poco / Nada', 'opcion_unica', 1, 0, 0, 0, 0, 6, NULL, NULL, NULL),
('PASO_3', 'P29', '¿Qué tan importante es la garantía para su cliente final?', 'Muy / Moderado / Poco', 'opcion_unica', 1, 0, 0, 0, 0, 7, NULL, NULL, NULL),
('PASO_3', 'E04', 'EVIDENCIA: Foto de la reacción del canal al ver el producto. Audio con comentarios espontáneos del dueño.', NULL, 'audio', 1, 0, 1, 1, 3, 8, NULL, NULL, NULL),

-- PASO 4
('PASO_4', 'P30', 'Nivel de receptividad general', '1 Sin interés: No ve valor en AXX de marca nueva / 2 Escéptico: Dudas sobre precio o calidad / 3 Neutral: Abierto pero sin convicción / 4 Interesado: Haría un pedido de prueba / 5 Muy receptivo: Listo para comprometerse hoy', 'opcion_unica', 1, 0, 0, 0, 0, 1, NULL, NULL, NULL),
('PASO_4', 'P31', '¿Estaría dispuesto a recibir un pedido de prueba cuando llegue el embarque?', 'Sí / No / Tal vez', 'opcion_unica', 1, 0, 0, 0, 0, 2, NULL, NULL, NULL),
('PASO_4', 'P32', '¿Qué cantidad mínima necesitaría para probar? ¿En qué línea?', 'Número + categoría', 'texto_largo', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
('PASO_4', 'P33', '¿Hay alguna condición que necesitaría para arrancar? (crédito, precio, volumen)', 'Comentario libre', 'texto_largo', 0, 1, 0, 0, 0, 4, NULL, NULL, NULL),
('PASO_4', 'P34', 'Observaciones libres del jefe zonal — intuición sobre este canal', 'Audio o texto libre', 'audio', 0, 1, 0, 0, 0, 5, NULL, NULL, NULL);

IF EXISTS (
    SELECT 1
    FROM @Preguntas p
    LEFT JOIN dbo.RC_SECCION s
        ON s.formulario_id = @FormularioId
       AND s.codigo = p.seccion_codigo
    WHERE s.id IS NULL
)
BEGIN
    THROW 51002, 'Faltan secciones requeridas para insertar RC_PREGUNTA.', 1;
END;

INSERT INTO dbo.RC_PREGUNTA (
    seccion_id,
    codigo,
    texto,
    texto_ayuda,
    tipo_respuesta,
    obligatoria,
    permite_no_aplica,
    requiere_foto,
    min_fotos,
    max_fotos,
    orden,
    activo,
    max_longitud,
    valor_minimo,
    valor_maximo,
    usuario_creacion
)
SELECT
    s.id AS seccion_id,
    p.codigo,
    p.texto,
    p.texto_ayuda,
    p.tipo_respuesta,
    p.obligatoria,
    p.permite_no_aplica,
    p.requiere_foto,
    p.min_fotos,
    p.max_fotos,
    p.orden,
    1 AS activo,
    p.max_longitud,
    p.valor_minimo,
    p.valor_maximo,
    'SEED_INSERT' AS usuario_creacion
FROM @Preguntas p
INNER JOIN dbo.RC_SECCION s
    ON s.formulario_id = @FormularioId
   AND s.codigo = p.seccion_codigo;
