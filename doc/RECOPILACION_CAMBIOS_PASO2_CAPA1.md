# Cambios de modelo - Recopilación PASO_2_CAPA_1

Fecha: 2026-03-31

## Contexto

Se alineó el modelo de datos del PASO 2 - CAPA 1 del formulario `DATOS_PDV_VENTAS` con la especificación funcional actual (documento de negocio y `FORMULARIO_RECOPILACION_SPEC.md` del frontend).

Los cambios impactan solo a la capa de catálogo (tablas RC_PREGUNTA y RC_PREGUNTA_OPCION) y no modifican la estructura física de tablas.

## Pregunta P08 – Años operando

**Antes**

- Código: `P08`
- Sección: `PASO_2_CAPA_1`
- Texto: «¿Cuántos años lleva este local operando?»
- `tipo_respuesta = 'numero'`
- `valor_minimo = 0`, `valor_maximo = NULL`
- No tenía opciones en `RC_PREGUNTA_OPCION`.

**Problema**

Funcionalmente se trabaja con rangos discretos (`1-3 / 3-5 / +5 años`), pero en el modelo se permitía cualquier número. Esto dificultaba estandarizar el análisis y alinearlo con la guía de campo.

**Ahora**

- Sigue siendo la misma pregunta (mismo código `P08` y misma sección), pero:
  - `tipo_respuesta` pasa de `numero` a **`opcion_unica`**.
  - Se agregan opciones explícitas en `RC_PREGUNTA_OPCION`.

Cambios realizados en `database/tables/recopilacion/seeds/insert/03_INSERT_RC_PREGUNTA_DATOS_PDV_VENTAS.sql`:

- Registro de `P08` actualizado a:
  - `tipo_respuesta = 'opcion_unica'`
  - `valor_minimo = NULL`, `valor_maximo = NULL`
  - Texto de ayuda indicando elección de uno de los rangos fijos.

Cambios realizados en `database/tables/recopilacion/seeds/insert/04_INSERT_RC_PREGUNTA_OPCION_DATOS_PDV_VENTAS.sql`:

- Nuevas opciones para `P08`:
  - Código `R1_1_3`, etiqueta `1-3 años`, valor `1_3`, orden 1.
  - Código `R2_3_5`, etiqueta `3-5 años`, valor `3_5`, orden 2.
  - Código `R3_MAS_5`, etiqueta `+5 años`, valor `MAS_5`, orden 3.

**Implicancias para el backend**

- Los endpoints de recopilación no requieren cambios estructurales: siguen recibiendo/guardando `opcion_ids` para preguntas de `opcion_unica`.
- Cualquier lógica que interprete P08 como número libre debe actualizarse para trabajar con los códigos/valores de opción (por ejemplo, mapeando `1_3`, `3_5`, `MAS_5` a rangos numéricos si hace falta).

**Implicancias para el frontend**

- El frontend debe renderizar P08 como un **Radio Group** (opción única), no como input numérico.
- Al guardar, se enviará el `id` de la opción seleccionada en `opcion_ids`.

## Pregunta P09 – Otros puntos de venta

**Situación actual**

- Código: `P09`
- Tipo: `si_no`
- Opciones en `RC_PREGUNTA_OPCION`: `SI` / `NO`.
- La especificación indica: si responde «Sí», registrar en detalle «cuántos» y «en qué zonas».

**Decisión de modelado (por ahora)**

- Se mantiene `P09` como pregunta de **sí/no**.
- El detalle de «cuántos» y «zonas» se registrará en el campo `observacion` de `RC_RESPUESTA` para esta pregunta.
- No se agregan por ahora nuevas preguntas estructuradas (`P09A`, `P09B`); si más adelante se requiere análisis más detallado, se podrán modelar como preguntas adicionales.

**Implicancias para el frontend**

- Cuando la respuesta a P09 sea **Sí**, el frontend debería habilitar un campo de texto (observaciones) para registrar:
  - cantidad de otros PDVs,
  - descripción de las zonas.

