# Tablas de Recopilacion de Datos de PDV

## Objetivo

Este conjunto de tablas implementa un formulario tipo encuesta, configurable y versionable, para recopilar informacion de puntos de venta (PDV) por zonal, con guardado parcial por secciones.

El modelo soporta:

- catalogo de formularios, secciones y preguntas;
- distintos tipos de respuesta (texto, numero, si/no, opciones, fecha/hora, audio);
- preguntas con evidencia (foto/audio);
- guardado por partes sin exigir completar todo en una sola sesion.

## Tablas creadas

### 1) Catalogo de formulario

- `RC_FORMULARIO`: encabezado/version del formulario.
- `RC_SECCION`: pasos o capas del formulario.
- `RC_PREGUNTA`: definicion de preguntas por seccion.
- `RC_PREGUNTA_OPCION`: opciones para preguntas cerradas.

### 2) Ejecucion por punto visitado

- `RC_VISITA_FORMULARIO`: instancia del formulario por `programacion_id` y periodo.
- `RC_VISITA_SECCION_ESTADO`: avance por seccion (pendiente, en_progreso, completa).

### 3) Respuestas y evidencias

- `RC_RESPUESTA`: respuesta base por pregunta.
- `RC_RESPUESTA_OPCION`: opciones seleccionadas en preguntas de opcion multiple.
- `RC_RESPUESTA_MEDIA`: archivos de evidencia asociados a una respuesta (foto/audio).

## Relacion con datos existentes

- `RC_VISITA_FORMULARIO.programacion_id` referencia `PDV_VISITAS_AD_PROGRAMACION.id`.
- Esto permite precargar datos del punto (zonal, nombre, direccion, etc.) y registrar la recopilacion contra la programacion real.

## Reglas de diseno aplicadas

- No se usa `GO`.
- Se usan llaves primarias, foraneas, checks y unicos para integridad.
- Se agregan indices para consultas frecuentes por:
  - formulario/seccion/orden,
  - zonal y periodo,
  - visita y pregunta,
  - respuesta y media.

## Tipos de respuesta soportados

En `RC_PREGUNTA.tipo_respuesta`:

- `texto_corto`
- `texto_largo`
- `numero`
- `decimal`
- `si_no`
- `opcion_unica`
- `opcion_multiple`
- `fecha`
- `hora`
- `audio`

## Soporte para fotos requeridas

En `RC_PREGUNTA` se definieron:

- `requiere_foto` (BIT)
- `min_fotos` (INT)
- `max_fotos` (INT)

Esto permite declarar preguntas donde la evidencia fotografica es obligatoria y controlar limites.

## Guardado parcial por secciones

El guardado parcial se soporta con:

- `RC_VISITA_FORMULARIO.estado` (`borrador`, `en_progreso`, `finalizado`)
- `RC_VISITA_SECCION_ESTADO` para avance por segmento
- `RC_RESPUESTA` para persistir respuestas parciales en cualquier momento

No es necesario completar todo el formulario para guardar.

## Orden sugerido de ejecucion en SQL Server

1. `01_RC_FORMULARIO.sql`
2. `02_RC_SECCION.sql`
3. `03_RC_PREGUNTA.sql`
4. `04_RC_PREGUNTA_OPCION.sql`
5. `05_RC_VISITA_FORMULARIO.sql`
6. `06_RC_VISITA_SECCION_ESTADO.sql`
7. `07_RC_RESPUESTA.sql`
8. `08_RC_RESPUESTA_OPCION.sql`
9. `09_RC_RESPUESTA_MEDIA.sql`

## Notas para el siguiente paso (backend)

- Exponer endpoints bajo prefijo `api/v1/recopilacion`.
- Filtrar por zonal del usuario autenticado.
- Permitir actualizar respuestas por seccion (upsert).
- Validar obligatoriedad y evidencias solo al finalizar.
