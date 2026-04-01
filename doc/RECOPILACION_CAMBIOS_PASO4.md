# Cambios de modelo - Recopilación PASO_4

Fecha: 2026-03-31

Este documento resume las convenciones de almacenamiento y ajustes de modelo para PASO 4.

## P30 – Nivel de receptividad general

- **Tipo**: `opcion_unica`.
- **Opciones** (en `RC_PREGUNTA_OPCION`):
  - `1` → Sin interés: No ve valor en accesorios de una marca nueva.
  - `2` → Escéptico: Tiene dudas sobre el precio o la calidad de Sync.
  - `3` → Neutral: Abierto pero sin convicción todavía.
  - `4` → Interesado: Haría un pedido de prueba cuando llegue el embarque.
  - `5` → Muy receptivo: Listo para comprometerse hoy — pedir número de contacto.
- **Frontend**:
  - Mostrar control tipo rate o botones 1–5 con texto de ayuda visible para el encuestador.

## P31 – ¿Te interesaría comprar accesorios Sync cuando llegue el embarque?

- **Tipo**: `opcion_unica`.
- **Opciones** en `RC_PREGUNTA_OPCION`:
  - `SI` (Sí).
  - `NO` (No).
  - `TAL_VEZ` (Tal vez).
- **Comentario libre**:
  - Cualquier explicación adicional se guarda en `RC_RESPUESTA.observacion` para esta pregunta.
- **Frontend**:
  - Radio buttons Sí / No / Tal vez.
  - Textarea adicional para anotar el motivo (se envía como `observacion`).

## P32 – Pack inicial 10% de facturación en equipos (monto + líneas)

- **Tipo**: `texto_largo`.
- **Convención de almacenamiento**:
  - `RC_RESPUESTA.valor_texto` guarda un **JSON** con dos campos:
    - `monto`: número (S/. del 10% de facturación en equipos).
    - `lineas`: string con la descripción de las líneas mencionadas.
  - Ejemplo de valor:
    - `{"monto": 1500, "lineas": "Parlantes, cables, micas"}`
- **Frontend**:
  - Mostrar dos inputs para esta pregunta:
    - Input numérico para el monto en S/. (con validación de número positivo).
    - Textarea para las líneas (texto libre).
  - Al guardar:
    - Construir un objeto `{ monto, lineas }` y serializar con `JSON.stringify` en `valor_texto`.
  - Al cargar:
    - Hacer `JSON.parse(valor_texto)` (si no viene vacío) y poblar ambos campos.

## P33 – Observaciones libres del jefe zonal — intuición sobre este canal

- **Antes**: `tipo_respuesta = 'audio'`.
- **Ahora**:
  - `tipo_respuesta = 'texto_largo'`.
  - No se exige ni modela audio; la respuesta es únicamente texto libre.
- **Frontend**:
  - Mostrar un textarea grande para que el jefe zonal escriba su percepción final del canal.
  - Enviar el texto en `valor_texto` (o `observacion`, según convenga; lo importante es ser consistente).

