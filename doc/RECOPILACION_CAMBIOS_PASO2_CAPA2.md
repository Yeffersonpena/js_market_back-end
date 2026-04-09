# Cambios de modelo - Recopilación PASO_2_CAPA_2

Fecha: 2026-03-31

Este documento resume solo los cambios estructurales aplicados para alinear el PASO 2 - CAPA 2 con el documento de negocio del jefe.

## 1) P11 – ¿Qué productos vende principalmente?

- **Tipo**: `opcion_multiple`.
- **Cambio**: se completó la lista de opciones para que coincida con:
  - Celulares / Accesorios / Recargas / Chips / SSTT / Otros.
- **Detalle en seeds**:
  - Archivo: `04_INSERT_RC_PREGUNTA_OPCION_DATOS_PDV_VENTAS.sql`.
  - Se agregaron las opciones:
    - `CHIPS` (etiqueta `Chips`, valor `CHIPS`).
    - `SSTT` (etiqueta `SSTT`, valor `SSTT`).

Frontend: debe permitir marcar múltiples categorías (checkbox/checkbox group).

## 2) P11B – ¿Vende equipos? Si no vende equipos, ¿por qué no?

- **Tipo**: `si_no` (Sí/No).
- **Implementación de "razón libre"**:
  - La respuesta Sí/No se guarda como booleano (a través de `tipo_respuesta = 'si_no'` + opciones en `RC_PREGUNTA_OPCION`).
  - La razón cuando la respuesta es **No** se guarda en `RC_RESPUESTA.observacion` para esta misma pregunta.
- **Detalle en seeds**:
  - Archivo: `03_INSERT_RC_PREGUNTA_DATOS_PDV_VENTAS.sql`:
    - Nueva pregunta en `PASO_2_CAPA_2` con código `P11B`, `tipo_respuesta = 'si_no'` y texto completo del spec.
  - Archivo: `04_INSERT_RC_PREGUNTA_OPCION_DATOS_PDV_VENTAS.sql`:
    - Opciones para `P11B`:
      - `SI` (Sí).
      - `NO` (No).

Frontend:
- Renderizar como pregunta de Sí/No.
- Si el usuario marca **No**, mostrar un campo de texto ligado a `observacion` (enviar en el body de `putRespuestas`).

## 3) P13 – ¿Qué accesorios se venden más en su local?

- **Antes**: `tipo_respuesta = 'texto_largo'` (texto libre).
- **Ahora**:
  - `tipo_respuesta = 'opcion_multiple'`.
  - Catálogo de opciones en `RC_PREGUNTA_OPCION`:
    - CABLES
    - AUDIFONOS
    - CARGADORES
    - RELOJES
    - MICAS
    - POWER_BANK (Power bank / cargador portátil)
    - PARLANTES
    - CARCASAS
    - MOUSE
    - OTROS
- **Regla de negocio**: el spec indica "Selecciona 3 más importantes (Top 3)".
  - Esta restricción se implementará en el **frontend** (máx. 3 seleccionados), no en BD.

Frontend:
- Renderizar P13 como `Checkbox.Group` (opción múltiple) con esas etiquetas.
- Limitar a máximo 3 seleccionadas y mostrar mensaje si intenta marcar más.

## 4) P16 – De todo lo que valora en sus proveedores, ¿qué es lo más importante para usted?

- **Antes**: `tipo_respuesta = 'opcion_multiple'`.
- **Ahora**:
  - `tipo_respuesta = 'opcion_unica'` (una sola opción, porque es "lo más importante").
  - Opciones en `RC_PREGUNTA_OPCION`:
    - PRECIO
    - RAPIDEZ
    - CREDITO
    - GARANTIA
    - VARIEDAD
    - OTROS
  - Si se selecciona "OTROS", el detalle se captura en `RC_RESPUESTA.observacion`.

Frontend:
- Renderizar P16 como Radio Group (una sola opción).
- Si el usuario selecciona "Otros", habilitar un campo de texto vinculado a `observacion`.

## 5) P14 – ¿A qué proveedores le compra accesorios hoy? (lista de hasta 5 proveedores)

- **Tipo**: `texto_largo`.
- **Convención de almacenamiento**:
  - `RC_RESPUESTA.valor_texto` es **un solo texto** con exactamente **5 posiciones** unidas por un separador fijo (comodín): el carácter **`|`** (pipe).
  - Ejemplo: `Distribuidor A|Mayorista B|||` (proveedor 1, 2, 3 vacíos 4 y 5).
  - No se crean columnas ni tablas adicionales; toda la lista vive en `valor_texto`.

Frontend:
- Mostrar **5 inputs** de texto independientes (Proveedor 1 … Proveedor 5).
- Al guardar: unir los cinco textos con `|` (los `|` que el usuario escriba dentro de un nombre se sustituyen por espacio al persistir).
- Al cargar: partir con `split('|')` y rellenar los 5 campos (compatibilidad con respuestas antiguas en JSON o texto libre según implementación del cliente).

Backend / reportes:
- Para tabular: en PHP `explode('|', $valor_texto)` y tomar los primeros 5 elementos (rellenar vacíos si hay menos), o en Excel “Texto en columnas” con separador `|`.
- Datos históricos en JSON (`["a","b"]` o `{ "principal", "secundarios" }`) pueden seguir existiendo; el frontend actual los migra al leer hacia los 5 slots.

## 6) P15 – ¿Qué marcas maneja en mostradores? (orden ~12 en el cuestionario; código BD `P15`)

Texto de negocio: *«¿Qué marcas maneja en mostradores?»* — lo que está en la góndola es la competencia directa de Sync; anotar marcas y, si puede, fotografiar precios visibles.

- **Tipo**: `texto_largo`, con `requiere_foto = 1`, **`min_fotos = 2`**, `max_fotos = 10` (ya en seeds `03_INSERT_RC_PREGUNTA_DATOS_PDV_VENTAS.sql`).
- **Convención de almacenamiento para marcas** (alineada con **P14**):
  - **No** es texto libre: son **10 campos fijos** de marca.
  - `RC_RESPUESTA.valor_texto` = **un solo string** con **10 posiciones** separadas por **`|`** (pipe), p. ej. `Samsung|Xiaomi|||||||` (marcas 1–3 informadas, resto vacío).
  - Legado: si existía JSON array o una sola línea, el frontend puede migrar al leer hacia los 10 slots.

Frontend:
- **10 inputs** independientes (Marca 1 … Marca 10).
- Guardar / cargar con `split` / `join` por `|` (sustituir `|` dentro del nombre por espacio al persistir, igual que P14).
- **Fotos**: subida vía `RC_RESPUESTA_MEDIA` (`uploadMedia`); la UI debe exigir **mínimo 2 fotos** antes de avanzar de sección (validación en cliente coherente con `min_fotos` en BD).

Backend:
- Sin tablas nuevas; fotos en `RC_RESPUESTA_MEDIA`.
- Para tabular marcas: `explode('|', $valor_texto)` y tomar hasta 10 elementos.

