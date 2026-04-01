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
  - `RC_RESPUESTA.valor_texto` guarda un **JSON array** con hasta 5 proveedores, por ejemplo:
    - `["Proveedor 1", "Proveedor 2", "Proveedor 3"]`
  - No se crean columnas ni tablas adicionales; toda la lista vive en `valor_texto`.

Frontend:
- Mostrar 5 inputs de texto independientes para esta pregunta.
- Al cargar:
  - Si `valor_texto` tiene contenido, hacer `JSON.parse(valor_texto)` y asignar cada elemento a un input.
- Al guardar:
  - Tomar los valores no vacíos de los 5 inputs → armar un array de strings.
  - Serializar con `JSON.stringify(array)` y enviarlo en `valor_texto` de la respuesta de P14.

Backend:
- Cuando se necesite consumir esta información como lista:
  - Usar `json_decode($respuesta->valor_texto, true)` en PHP para obtener `array<string>`.

## 6) P15 – ¿Qué marcas maneja en mostradores? (lista de hasta 10 marcas + fotos)

- **Tipo**: `texto_largo`, con `requiere_foto = 1` y soporte de media en `RC_RESPUESTA_MEDIA`.
- **Convención de almacenamiento para marcas**:
  - Igual que proveedores, `RC_RESPUESTA.valor_texto` guardará un **JSON array** con hasta 10 marcas, por ejemplo:
    - `["Marca 1", "Marca 2", "Marca 3"]`

Frontend:
- Mostrar 10 inputs de texto independientes para esta pregunta.
- Al cargar:
  - Parsear `valor_texto` como JSON para rellenar los 10 inputs.
- Al guardar:
  - Recoger hasta 10 valores no vacíos → array de strings → `JSON.stringify` → `valor_texto`.
- Para fotos:
  - Mantener la lógica actual de subida de media (`uploadMedia`), pero controlando al menos 2 fotos:
    - Validar en UI que se hayan subido ≥ 2 imágenes antes de dar por completa la sección.

Backend:
- No requiere nuevas tablas; se sigue usando `RC_RESPUESTA_MEDIA` para las fotos.
- Si en algún proceso se analiza la lista de marcas, se parsea `valor_texto` como JSON igual que en P14.

