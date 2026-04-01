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
('PASO_1', 'P01', '¿Cuánto compra en equipos por mes?', 'Revisar historial en ControlNet. Anotar ticket promedio mensual en S/. /mes.', 'decimal', 1, 0, 0, 0, 0, 1, NULL, 0, NULL),
('PASO_1', 'P02', '¿Cuánto debería comprar en accesorios Sync?', 'Calcular: ticket equipos × 10% = meta de accesorios en S/. /mes.', 'decimal', 1, 0, 0, 0, 0, 2, NULL, 0, NULL),
('PASO_1', 'P03', '¿Ya compra accesorios a JS Market hoy?', 'Revisar historial en ControlNet. ¿Cuánto? ¿Con qué frecuencia? Registrar Sí / No y, si aplica, un monto aproximado en S/.', 'opcion_unica', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
('PASO_1', 'P04', '¿Qué zona y quién la atiende?', 'Confirmar jefe zonal asignado y vendedor de ruta. Registrar la zona y el nombre del vendedor.', 'texto_corto', 1, 0, 0, 0, 0, 4, 150, NULL, NULL),
('PASO_1', 'P05', '¿Qué llevo para mostrar?', 'Preparar catálogo PDF Sync y fotos de producto. Llevar kit si disponible. Marcar qué materiales lleva.', 'opcion_multiple', 1, 0, 0, 0, 0, 5, NULL, NULL, NULL),

('PASO_2_CAPA_1', 'P06', '¿Cuál es el nombre completo del dueño del local?', 'Anotar tal como aparece en su DNI. Junto con el DNI, este dato resuelve el problema de los RUCs duplicados en la base — es el primer campo que Cecilia necesita para limpiar y unificar registros.', 'texto_corto', 1, 0, 0, 0, 0, 1, 150, NULL, NULL),
('PASO_2_CAPA_1', 'P07', '¿Cuál es su DNI?', 'Campo OBLIGATORIO — es el identificador único en el sistema. Sin DNI la ficha no puede ingresarse a la base. Si el dueño se niega, anotar el motivo en observaciones y escalar al jefe zonal.', 'numero', 1, 0, 0, 0, 0, 2, NULL, 10000000, 99999999),
('PASO_2_CAPA_1', 'P08', '¿Cuántos años lleva este local operando?', 'Indica estabilidad del canal. Un negocio con más de 5 años es un cliente más confiable y predecible que uno reciente. Si no sabe exactamente, anotar uno de los rangos: 1-3 / 3-5 / +5 años. Este dato también ayuda a calibrar el nivel de fidelidad con sus proveedores actuales.', 'opcion_unica', 1, 1, 0, 0, 0, 3, NULL, NULL, NULL),
('PASO_2_CAPA_1', 'P09', '¿Maneja otros puntos de venta además de este?', 'Identifica distribuidores o microempresas encubiertos que manejan múltiples PDVs. Si dice sí, anotar cuántos y en qué zonas — puede ser una cuenta de mayor volumen del que aparece en la base. Escalarlo a la dirección si aplica.', 'si_no', 1, 0, 0, 0, 0, 4, NULL, NULL, NULL),
('PASO_2_CAPA_1', 'P10', '¿Con qué nombre comercial se identifica este local?', 'El nombre comercial puede ser distinto al RUC registrado en la base. Este dato permite identificar el local por su nombre real en el mercado y detectar duplicados o locales mal registrados.', 'texto_corto', 1, 0, 0, 0, 0, 5, 200, NULL, NULL),
('PASO_2_CAPA_1', 'E01', 'EVIDENCIA: Foto de la fachada del local + foto del DNI del dueño (con su permiso).', NULL, 'texto_largo', 1, 0, 1, 2, 4, 6, NULL, NULL, NULL),

-- PASO 2 - CAPA 2
('PASO_2_CAPA_2', 'P11', '¿Qué productos vende principalmente?', 'Determina si el PDV es un cliente potencial de accesorios o si su foco es otro. Muchos PDVs que aparecen en la base de Telefónica no venden accesorios activamente — este filtro es clave antes de hacer cualquier oferta. Celulares / Accesorios / Recargas / Chips / SSTT / Otros.', 'opcion_multiple', 1, 0, 0, 0, 0, 1, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'P11B', '¿Vende equipos? Si no vende equipos, ¿por qué no?', 'Algunos PDVs de la base solo venden accesorios y recargas aunque estén registrados como clientes de equipos. Entender la razón de no venta ayuda a identificar si hay una oportunidad real o si es un canal que no aplica para la línea de equipos. Si responde No, anotar la razón en observaciones.', 'si_no', 1, 0, 0, 0, 0, 2, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'P12', '¿Cuánto estima que vende en accesorios por mes?', 'Da el tamaño real del negocio de accesorios — independiente de lo que compra a JS hoy. Es la base para dimensionar el potencial de la cuota del 10%. Un PDV que vende +S/2K en accesorios es un objetivo prioritario aunque hoy compre a la competencia. < S/500 / S/500-2K / S/2K-5K / +S/5K.', 'opcion_unica', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'P13', '¿Qué accesorios se venden más en su local?', 'Identifica qué líneas tienen demanda probada en este PDV específico. Permite hacer una oferta de las líneas correctas en lugar de ofrecer todo el catálogo — aumenta la probabilidad de cierre y reduce el riesgo de inventario sin rotación. Selecciona 3 más importantes: Top 3: cables, audífonos, cargadores, relojes, micas, power bank (cargador portátil), parlantes, carcasas, mouse.', 'opcion_multiple', 1, 0, 0, 0, 0, 4, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'P14', '¿A qué proveedores le compra accesorios hoy?', 'NOTA: pregunta en PLURAL. Muchos PDVs compran a varios proveedores según la categoría o el precio del momento. El objetivo es mapear quién tiene qué parte del negocio hoy — es el mapa de competencia real del jefe zonal en su zona. Texto libre (puede ser más de uno).', 'texto_largo', 1, 0, 0, 0, 0, 5, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'P15', '¿Qué marcas maneja en mostradores?', 'Lo que está en la góndola es la competencia directa de Sync hoy. Anotar marcas presentes permite a Cecilia mapear qué marcas dominan por zona y afinar la propuesta de valor. Si puede, fotografiar los precios visibles — dato de inteligencia competitiva directo. Observar y anotar. Fotografiar si posible.', 'texto_largo', 1, 0, 1, 2, 10, 6, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'P16', 'De todo lo que valora en sus proveedores, ¿qué es lo más importante para usted?', 'Prioriza el criterio principal de compra. Es la palanca de la propuesta de JS — si el PDV dice \"crédito\" y JS no tiene crédito disponible, hay una brecha importante que reportar y manejar antes de intentar el cierre. Precio / rapidez / crédito / garantía / variedad / Otros (texto libre).', 'opcion_unica', 1, 0, 0, 0, 0, 7, NULL, NULL, NULL),
('PASO_2_CAPA_2', 'E02', 'EVIDENCIA: Foto de la góndola de accesorios con marcas y precios visibles.', NULL, 'texto_largo', 1, 0, 1, 1, 3, 8, NULL, NULL, NULL),

-- PASO 2 - CAPA 3
('PASO_2_CAPA_3', 'P17', 'Tamaño del local', 'Indicador directo de capacidad de inventario. Un local grande puede absorber más stock y manejar un pedido mayor — es un factor de scoring del canal. Un local pequeño puede ser un buen canal B/C aunque compre poco hoy si tiene alta rotación. Pequeño (<20m²) / Mediano (20-50m²) / Grande (+50m²).', 'opcion_unica', 1, 0, 0, 0, 0, 1, NULL, NULL, NULL),
('PASO_2_CAPA_3', 'P19', '¿Tiene vitrina o display activo de accesorios?', 'Un local con vitrina activa de accesorios ya tiene el hábito de vender accesorios — es el cliente más fácil de activar. Si tiene vitrina desordenada, hay oportunidad de diferenciarse con organización y material POP de Sync. Sin vitrina, el trabajo es mayor. Sí, bien organizado / Sí, desordenado / No tiene.', 'opcion_unica', 1, 0, 1, 1, 10, 2, NULL, NULL, NULL),
('PASO_2_CAPA_3', 'P20', 'Nivel de organización general del local', 'Un local organizado sugiere un dueño que cuida su imagen comercial y es más receptivo a trabajar con una marca que cuida el display. Un nivel bajo puede indicar menor foco comercial o un dueño difícil de gestionar. Dato de calibración para el jefe zonal. Alto / Medio / Bajo.', 'opcion_unica', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
('PASO_2_CAPA_3', 'P21', '¿Tiene letrero o señalización visible de operador?', 'Indica la alineación comercial actual del PDV. Un PDV con letrero de competidores activos puede estar siendo trabajado. Dato crítico para el jefe zonal — si hay señalización de Claro/Entel pero no de Telefónica, hay un movimiento de base activo que reportar. Anotar qué operadores tiene señalizados (Claro / Entel / Bitel / ZTE / Samsung / Infinix / Motorola / Honor / Xiaomi / Marca propia / Otros). Espacio libre + foto.', 'opcion_multiple', 1, 1, 1, 1, 10, 4, NULL, NULL, NULL),
('PASO_2_CAPA_3', 'P22', 'Observación libre del jefe zonal — intuición sobre este canal', 'Todo lo que el jefe zonal ve y siente en la visita que no encaja en las preguntas anteriores. La intuición entrenada del jefe tiene valor estratégico real — se usa para priorizar canales y detectar oportunidades fuera del formulario. Texto libre (percepción personal).', 'texto_largo', 0, 1, 0, 0, 0, 5, NULL, NULL, NULL),
('PASO_2_CAPA_3', 'E03', 'EVIDENCIA: Foto frontal del local + foto interior mostrando organización y display de accesorios.', NULL, 'texto_largo', 1, 0, 1, 2, 4, 7, NULL, NULL, NULL),

-- PASO 3
('PASO_3', 'P23', 'Mostrando el catálogo: ¿Le parece atractivo el packaging y la presentación de los productos Sync?', 'La reacción visual es el primer filtro de receptividad. Un puntaje 4 o 5 con comentario positivo es señal clara de interés. Anotar el comentario exacto — es el tipo de feedback que el equipo de producto necesita para calibrar el siguiente embarque. Puntaje 1-5 + comentario (seleccionar del 1 al 5) + espacio libre.', 'opcion_unica', 1, 0, 0, 0, 0, 1, NULL, NULL, NULL),
('PASO_3', 'P24', '¿Qué líneas le interesaría trabajar?', 'Esta selección es el input directo para armar el primer pedido. La multi-selección permite ver si hay más de una línea de interés — un PDV que selecciona 3 líneas tiene más potencial que uno que solo marca una. No ofrecer todo el catálogo — dejar que el canal elija. Multi-selección: Parlantes / Audífonos / Cables / Baterías / Relojes / Micas / Otros (copias opción de accesorios anterior) + campo Otros con opción de texto libre.', 'opcion_multiple', 1, 0, 0, 0, 0, 2, NULL, NULL, NULL),
('PASO_3', 'P25', 'Revisando el catálogo con precios por volumen: ¿este precio le parece competitivo frente a lo que compra hoy?', 'Más útil que preguntar \"¿a qué precio comprarías?\" porque el canal ya tiene un precio de referencia (sus proveedores actuales). La respuesta revela si el precio de JS es una barrera real o no. Si dice \"No\", preguntar: ¿cuánto paga hoy por [línea]? Opciones: Sí / No / Más o menos + comentario libre.', 'opcion_unica', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
('PASO_3', 'P26', '¿Hay algo del producto o empaque que cambiaría o mejoraría?', 'Feedback de producto directo desde el canal — más valioso que cualquier estudio. Anotar textualmente. Este input va directo al equipo de producto para el próximo pedido. No filtrar ni interpretar — transcribir la respuesta del PDV tal cual. Comentario libre.', 'texto_largo', 0, 1, 0, 0, 0, 4, NULL, NULL, NULL),

-- PASO 4
('PASO_4', 'P30', 'Nivel de receptividad general', '1 Sin interés: No ve valor en accesorios de una marca nueva / 2 Escéptico: Tiene dudas sobre el precio o la calidad de Sync / 3 Neutral: Abierto pero sin convicción todavía / 4 Interesado: Haría un pedido de prueba cuando llegue el embarque / 5 Muy receptivo: Listo para comprometerse hoy — pedir número de contacto', 'opcion_unica', 1, 0, 0, 0, 0, 1, NULL, NULL, NULL),
('PASO_4', 'P31', '¿Te interesaría comprar accesorios Sync cuando llegue el embarque?', 'Pregunta directa de intención de compra. \"Tal vez\" es suficiente para seguir — no es un no. Anotar cualquier comentario sobre el porqué. Esta respuesta es el primer dato real del pipeline comercial y la base del forecast de ventas para el embarque. Opciones: Sí / No / Tal vez.', 'opcion_unica', 1, 0, 0, 0, 0, 2, NULL, NULL, NULL),
('PASO_4', 'P32', 'El pack inicial equivale al 10% de lo que facturas mensualmente en equipos. ¿Cuánto sería eso en S/. para ti? ¿En qué líneas lo armarías?', 'En lugar de preguntar una cantidad mínima (que el PDV rechaza), se ancla al 10% de su facturación en equipos — un número que ya conoce y que tiene lógica para él. Anotar las líneas que menciona: son la base del primer pedido personalizado. Monto en S/. + líneas seleccionadas.', 'texto_largo', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
('PASO_4', 'P33', 'Observaciones libres del jefe zonal — intuición sobre este canal', 'El cierre de la ficha. ¿Hay algo que cambió tu percepción del canal durante la visita? ¿Hay algo que la dirección debe saber y que no está en las preguntas? La intuición del jefe zonal entrenado en la zona tiene valor estratégico — no omitir. Texto libre.', 'texto_largo', 0, 1, 0, 0, 0, 4, NULL, NULL, NULL);

;IF EXISTS (
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
