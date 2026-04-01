# Cambios de modelo - Recopilación PASO_2_CAPA_3

Fecha: 2026-03-31

Este documento resume los cambios estructurales en PASO 2 - CAPA 3 para alinearlo con el documento del jefe.

## P21 – ¿Tiene letrero o señalización visible de operador?

**Objetivo de negocio**

- Capturar de forma normalizada qué operadores/marcas tienen letreros/señalización en el PDV:
  - Claro, Entel, Bitel, ZTE, Samsung, Infinix, Motorola, Honor, Xiaomi, Marca propia, Otros.
- Mantener un espacio libre para comentarios adicionales.
- Asociar fotos como evidencia visual.

**Cambios en el modelo**

- Archivo: `database/tables/recopilacion/seeds/insert/03_INSERT_RC_PREGUNTA_DATOS_PDV_VENTAS.sql`
  - Pregunta `P21` en `PASO_2_CAPA_3`:
    - Antes: `tipo_respuesta = 'texto_largo'`.
    - Ahora: `tipo_respuesta = 'opcion_multiple'`.
    - Se mantiene:
      - `requiere_foto = 1` (usa `RC_RESPUESTA_MEDIA` para fotos).
      - `permite_no_aplica = 1`.

- Archivo: `database/tables/recopilacion/seeds/insert/04_INSERT_RC_PREGUNTA_OPCION_DATOS_PDV_VENTAS.sql`
  - Nuevas opciones para `P21`:
    - `CLARO` (etiqueta `Claro`, valor `CLARO`).
    - `ENTEL` (etiqueta `Entel`, valor `ENTEL`).
    - `BITEL` (etiqueta `Bitel`, valor `BITEL`).
    - `ZTE` (etiqueta `ZTE`, valor `ZTE`).
    - `SAMSUNG` (etiqueta `Samsung`, valor `SAMSUNG`).
    - `INFINIX` (etiqueta `Infinix`, valor `INFINIX`).
    - `MOTOROLA` (etiqueta `Motorola`, valor `MOTOROLA`).
    - `HONOR` (etiqueta `Honor`, valor `HONOR`).
    - `XIAOMI` (etiqueta `Xiaomi`, valor `XIAOMI`).
    - `MARCA_PROPIA` (etiqueta `Marca propia`, valor `MARCA_PROPIA`).
    - `OTROS` (etiqueta `Otros`, valor `OTROS`).

**Convención de respuestas**

- Selección de operadores:
  - Se guarda a través de `RC_RESPUESTA_OPCION` (una fila por opción seleccionada).
  - Es posible marcar varias opciones a la vez (`opcion_multiple`).
- Comentarios libres:
  - Se guardan en `RC_RESPUESTA.observacion` para esta misma pregunta (por ejemplo, para detallar "Otros" o matices).
- Fotos:
  - Se siguen manejando en `RC_RESPUESTA_MEDIA` asociadas a la respuesta de P21.
  - El número mínimo/máximo de fotos se controla con `min_fotos` / `max_fotos` y validaciones en el frontend/backoffice.

**Implicancias para el frontend**

- Renderizar P21 como:
  - Un `Checkbox.Group` o conjunto de checkboxes con las opciones listadas arriba.
  - Un campo de texto adicional ligado a `observacion` (para "Otros" y comentarios).
  - Un componente de subida de fotos (múltiples), usando el endpoint de media existente para esta pregunta.

**Implicancias para el backend**

- Los endpoints de recopilación (`getRespuestas`, `putRespuestas`, `postMedia`) ya soportan:
  - `opcion_ids` para preguntas de `opcion_multiple`.
  - Media asociada a respuestas.
- Solo es necesario:
  - Asegurarse de que el frontend envíe `opcion_ids` con los IDs seleccionados para P21.
  - Usar/interpretar `observacion` si se requiere análisis adicional de comentarios.

