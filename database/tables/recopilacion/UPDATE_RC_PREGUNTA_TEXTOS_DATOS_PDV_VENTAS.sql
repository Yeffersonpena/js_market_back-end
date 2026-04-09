-- =============================================
-- UPDATE: RC_PREGUNTA — textos (texto, texto_ayuda)
-- Formulario: DATOS_PDV_VENTAS versión 1
-- Sincronizado con: seeds/insert/03_INSERT_RC_PREGUNTA_DATOS_PDV_VENTAS.sql
-- Uso: catálogo ya cargado; no re-ejecutar INSERT de preguntas.
-- Nota: texto_ayuda en BD es VARCHAR(500); si algún texto supera 500, ampliar columna antes.
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
    THROW 52001, 'No existe RC_FORMULARIO DATOS_PDV_VENTAS v1.', 1;
END;

-- PASO 1
UPDATE p
SET
    p.texto = N'¿Cuánto compra en equipos por mes?',
    p.texto_ayuda = N'Revisar historial en ControlNet. Anotar ticket promedio mensual en S/. /mes.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_1'
  AND p.codigo = N'P01';

UPDATE p
SET
    p.texto = N'¿Cuánto debería comprar en accesorios Zync?',
    p.texto_ayuda = N'Calcular: ticket equipos × 10% = meta de accesorios en S/. /mes.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_1'
  AND p.codigo = N'P02';

UPDATE p
SET
    p.texto = N'¿Ya compra accesorios a JS Market hoy?',
    p.texto_ayuda = N'Revisar historial en ControlNet. ¿Cuánto? ¿Con qué frecuencia? Registrar Sí / No y, si aplica, un monto aproximado en S/.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_1'
  AND p.codigo = N'P03';

UPDATE p
SET
    p.texto = N'¿Qué zona y quién la atiende?',
    p.texto_ayuda = N'Confirmar jefe zonal asignado y vendedor de ruta. Registrar la zona y el nombre del vendedor.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_1'
  AND p.codigo = N'P04';

UPDATE p
SET
    p.texto = N'¿Qué llevo para mostrar?',
    p.texto_ayuda = N'Preparar catálogo PDF Zync y fotos de producto. Llevar kit si disponible. Marcar qué materiales lleva.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_1'
  AND p.codigo = N'P05';

-- PASO 2 CAPA 1
UPDATE p
SET
    p.texto = N'¿Cuál es el nombre completo del dueño del local?',
    p.texto_ayuda = N'Anotar tal como aparece en su DNI. Junto con el DNI, este dato resuelve el problema de los RUCs duplicados en la base — es el primer campo que Cecilia necesita para limpiar y unificar registros.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_1'
  AND p.codigo = N'P06';

UPDATE p
SET
    p.texto = N'¿Cuál es su DNI?',
    p.texto_ayuda = N'Campo OBLIGATORIO — es el identificador único en el sistema. Sin DNI la ficha no puede ingresarse a la base. Si el dueño se niega, anotar el motivo en observaciones y escalar al jefe zonal.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_1'
  AND p.codigo = N'P07';

UPDATE p
SET
    p.texto = N'¿Cuántos años lleva este local operando?',
    p.texto_ayuda = N'Indica estabilidad del canal. Un negocio con más de 5 años es un cliente más confiable y predecible que uno reciente. Si no sabe exactamente, anotar rango. Este dato también ayuda a calibrar el nivel de fidelidad con sus proveedores actuales.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_1'
  AND p.codigo = N'P08';

UPDATE p
SET
    p.texto = N'¿Maneja otros puntos de venta además de este?',
    p.texto_ayuda = N'Identifica distribuidores o microempresas encubiertos que manejan múltiples PDVs. Si dice sí, anotar cuántos y en qué zonas — puede ser una cuenta de mayor volumen del que aparece en la base. Escalarlo a la dirección si aplica.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_1'
  AND p.codigo = N'P09';

UPDATE p
SET
    p.texto = N'¿Con qué nombre comercial se identifica este local?',
    p.texto_ayuda = N'El nombre comercial puede ser distinto al RUC registrado en la base. Este dato permite identificar el local por su nombre real en el mercado y detectar duplicados o locales mal registrados.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_1'
  AND p.codigo = N'P10';

UPDATE p
SET
    p.texto = N'EVIDENCIA: Foto de la fachada del local + foto del DNI del dueño (con su permiso).',
    p.texto_ayuda = NULL,
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_1'
  AND p.codigo = N'E01';

-- PASO 2 CAPA 2
UPDATE p
SET
    p.texto = N'¿Qué productos vende principalmente?',
    p.texto_ayuda = N'Determina si el PDV es un cliente potencial de accesorios o si su foco es otro. Muchos PDVs que aparecen en la base de Telefónica no venden accesorios activamente — este filtro es clave antes de hacer cualquier oferta.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_2'
  AND p.codigo = N'P11';

UPDATE p
SET
    p.texto = N'¿Vende equipos? Si no vende equipos, ¿por qué no?',
    p.texto_ayuda = N'NUEVA PREGUNTA. Algunos PDVs de la base solo venden accesorios y recargas aunque estén registrados como clientes de equipos. Entender la razón de no venta ayuda a identificar si hay una oportunidad real o si es un canal que no aplica para la línea de equipos.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_2'
  AND p.codigo = N'P11B';

UPDATE p
SET
    p.texto = N'¿Cuánto estima que vende en accesorios por mes?',
    p.texto_ayuda = N'Da el tamaño real del negocio de accesorios — independiente de lo que compra a JS hoy. Es la base para dimensionar el potencial de la cuota del 10%. Un PDV que vende +S/2K en accesorios es un objetivo prioritario aunque hoy compre a la competencia.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_2'
  AND p.codigo = N'P12';

UPDATE p
SET
    p.texto = N'¿Qué accesorios se venden más en su local?',
    p.texto_ayuda = N'Identifica qué líneas tienen demanda probada en este PDV específico. Permite hacer una oferta de las líneas correctas en lugar de ofrecer todo el catálogo — aumenta la probabilidad de cierre y reduce el riesgo de inventario sin rotación.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_2'
  AND p.codigo = N'P13';

UPDATE p
SET
    p.texto = N'¿A qué proveedores le compra accesorios hoy?',
    p.texto_ayuda = N'NOTA: pregunta en PLURAL. Muchos PDVs compran a varios proveedores según la categoría o el precio del momento. El objetivo es mapear quién tiene qué parte del negocio hoy — es el mapa de competencia real del jefe zonal en su zona.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_2'
  AND p.codigo = N'P14';

UPDATE p
SET
    p.texto = N'¿Qué valora de cada uno de esos proveedores?',
    p.texto_ayuda = N'NUEVA PREGUNTA. Revela los criterios reales de compra del canal y qué hace que trabaje con varios proveedores simultáneamente. La opción ''Otros'' captura criterios que no anticipamos. Este input es la palanca de negociación de JS frente a cada competidor identificado.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_2'
  AND p.codigo = N'P14B';

UPDATE p
SET
    p.texto = N'¿Qué marcas maneja en mostradores?',
    p.texto_ayuda = N'Lo que está en la góndola es la competencia directa de Zync hoy. Anotar marcas presentes permite a Cecilia mapear qué marcas dominan por zona y afinar la propuesta de valor. Si puede, fotografiar los precios visibles — dato de inteligencia competitiva directo.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_2'
  AND p.codigo = N'P15';

UPDATE p
SET
    p.texto = N'De todo lo que valora en sus proveedores, ¿qué es lo más importante para usted?',
    p.texto_ayuda = N'Prioriza el criterio principal de compra. Es la palanca de la propuesta de JS — si el PDV dice ''crédito'' y JS no tiene crédito disponible, hay una brecha importante que reportar y manejar antes de intentar el cierre.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_2'
  AND p.codigo = N'P16';

UPDATE p
SET
    p.texto = N'EVIDENCIA: Foto de la góndola de accesorios con marcas y precios visibles.',
    p.texto_ayuda = NULL,
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_2'
  AND p.codigo = N'E02';

-- PASO 2 CAPA 3
UPDATE p
SET
    p.texto = N'Tamaño del local',
    p.texto_ayuda = N'Indicador directo de capacidad de inventario. Un local grande puede absorber más stock y manejar un pedido mayor — es un factor de scoring del canal. Un local pequeño puede ser un buen canal B/C aunque compre poco hoy si tiene alta rotación.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_3'
  AND p.codigo = N'P17';

UPDATE p
SET
    p.texto = N'¿Tiene vitrina o display activo de accesorios?',
    p.texto_ayuda = N'Un local con vitrina activa de accesorios ya tiene el hábito de vender accesorios — es el cliente más fácil de activar. Si tiene vitrina desordenada, hay oportunidad de diferenciarse con organización y POP material de Zync. Sin vitrina, el trabajo es mayor.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_3'
  AND p.codigo = N'P19';

UPDATE p
SET
    p.texto = N'Nivel de organización general del local',
    p.texto_ayuda = N'Un local organizado sugiere un dueño que cuida su imagen comercial y es más receptivo a trabajar con una marca que cuida el display. Nivel bajo puede indicar menor foco comercial o un dueño difícil de gestionar. Dato de calibración para el jefe zonal.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_3'
  AND p.codigo = N'P20';

UPDATE p
SET
    p.texto = N'¿Tiene letrero o señalización visible de operador?',
    p.texto_ayuda = N'Indica la alineación comercial actual del PDV. Un PDV con letrero de competidores activos puede estar siendo trabajado. Dato crítico para el jefe zonal — si hay señalización de Claro/Entel pero no de Telefónica, hay un movimiento de base activo que reportar.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_3'
  AND p.codigo = N'P21';

UPDATE p
SET
    p.texto = N'Observación libre del jefe zonal — intuición sobre este canal',
    p.texto_ayuda = N'Todo lo que el jefe zonal ve y siente en la visita que no encaja en las preguntas anteriores. La intuición entrenada del jefe tiene valor estratégico real — Cecilia y la dirección necesitan este input para priorizar canales y detectar oportunidades fuera del formulario.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_3'
  AND p.codigo = N'P22';

UPDATE p
SET
    p.texto = N'EVIDENCIA: Foto frontal del local + foto interior mostrando organización y display de accesorios.',
    p.texto_ayuda = NULL,
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_2_CAPA_3'
  AND p.codigo = N'E03';

-- PASO 3
UPDATE p
SET
    p.texto = N'Mostrando el catálogo: ¿Le parece atractivo el packaging y la presentación de los productos Zync?',
    p.texto_ayuda = N'La reacción visual es el primer filtro de receptividad. Un puntaje 4 o 5 con comentario positivo es señal clara de interés. Anotar el comentario exacto — es el tipo de feedback que el equipo de producto necesita para calibrar el siguiente embarque.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_3'
  AND p.codigo = N'P23';

UPDATE p
SET
    p.texto = N'¿Qué líneas le interesaría trabajar?',
    p.texto_ayuda = N'Esta selección es el input directo para armar el primer pedido. La multi-selección permite ver si hay más de una línea de interés — un PDV que selecciona 3 líneas tiene más potencial que uno que solo marca una. No ofrecer todo el catálogo — dejar que el canal elija.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_3'
  AND p.codigo = N'P24';

UPDATE p
SET
    p.texto = N'Revisando el catálogo con precios por volumen: ¿este precio le parece competitivo frente a lo que compra hoy?',
    p.texto_ayuda = N'Más útil que preguntar ''¿a qué precio comprarías?'' porque el canal ya tiene un precio de referencia (sus proveedores actuales). La respuesta revela si el precio de JS es una barrera real o no. Si dice ''no'', preguntar: ¿cuánto paga hoy por [línea]?',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_3'
  AND p.codigo = N'P25';

UPDATE p
SET
    p.texto = N'¿Hay algo del producto o empaque que cambiaría o mejoraría?',
    p.texto_ayuda = N'Feedback de producto directo desde el canal — más valioso que cualquier estudio. Anotar textualmente. Este input va directo al equipo de producto para el próximo pedido. No filtrar ni interpretar — transcribir la respuesta del PDV tal cual.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_3'
  AND p.codigo = N'P26';

-- PASO 4
UPDATE p
SET
    p.texto = N'Nivel de receptividad general',
    p.texto_ayuda = N'1 Sin interés: No ve valor en accesorios de una marca nueva / 2 Escéptico: Tiene dudas sobre el precio o la calidad de Zync / 3 Neutral: Abierto pero sin convicción todavía / 4 Interesado: Haría un pedido de prueba cuando llegue el embarque / 5 Muy receptivo: Listo para comprometerse hoy — pedir número de contacto',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_4'
  AND p.codigo = N'P30';

UPDATE p
SET
    p.texto = N'¿Te interesaría comprar accesorios Zync cuando llegue el embarque?',
    p.texto_ayuda = N'Pregunta directa de intención de compra. ''Tal vez'' es suficiente para seguir — no es un no. Anotar cualquier comentario sobre el porqué. Esta respuesta es el primer dato real del pipeline comercial y la base del forecast de ventas para el embarque.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_4'
  AND p.codigo = N'P31';

UPDATE p
SET
    p.texto = N'Viendo nuestra nueva oferta comercial ¿Cuánto le interesaría comprar en el mes de mayo? ¿En qué líneas de producto armaría esta compra?',
    p.texto_ayuda = NULL,
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_4'
  AND p.codigo = N'P32';

UPDATE p
SET
    p.texto = N'Observaciones libres del jefe zonal — intuición sobre este canal',
    p.texto_ayuda = N'El cierre de la ficha. ¿Hay algo que cambió tu percepción del canal durante la visita? ¿Hay algo que la dirección debe saber y que no está en las preguntas? La intuición del jefe zonal entrenado en la zona tiene valor estratégico — no omitir.',
    p.fecha_actualizacion = GETDATE(),
    p.usuario_actualizacion = N'UPDATE_TEXTOS_DATOS_PDV_VENTAS'
FROM dbo.RC_PREGUNTA p
INNER JOIN dbo.RC_SECCION s ON s.id = p.seccion_id
WHERE s.formulario_id = @FormularioId
  AND s.codigo = N'PASO_4'
  AND p.codigo = N'P33';

-- Si falta P14B en PASO_2_CAPA_2, insertarla y ajustar orden según 03_INSERT_RC_PREGUNTA_DATOS_PDV_VENTAS.sql (script aparte).
