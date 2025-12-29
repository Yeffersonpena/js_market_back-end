# 🔄 Flujo Completo del Proceso de Pagos

## 📋 Descripción General

Este documento describe el flujo completo del sistema de procesamiento de órdenes de pago, desde la importación inicial hasta la recepción de respuestas de finanzas.

## 🔄 Diagrama del Flujo

```
┌─────────────────┐
│   Excel Pagos   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  Upload + Python Script │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  tblpago_detalle_temp    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ spInsertarPagosInicio   │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  tblpago_detalle        │
│  Estado: PENDIENTE      │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ spInsertarOrdenesPago   │
│ Agrupación DNI+Canal    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ tblpago_orden_de_pago   │
│ Estado: ENVIADO A PAGO  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Generación Excel        │
│ + Envío Correo          │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ tblpago_orden_pago      │
│ Estado: ENVIADO         │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Excel Respuesta        │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Upload + Python Script  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ tblpago_orden_de_pago   │
│ _respuesta_temp         │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ spInsertarRespuestaPago │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Actualización Estados   │
│ PAGADO/RECHAZADO        │
└─────────────────────────┘
```

## 📝 Fases Detalladas

### Fase 1: Importación de Pagos

**Objetivo**: Cargar datos desde Excel y prepararlos para procesamiento.

**Proceso**:
1. Usuario sube archivo Excel
2. Script Python (`importar_pagos.py`) lee y valida
3. Datos se cargan en `tblpago_detalle_temp`
4. Stored Procedure `spInsertarPagosInicio` enriquece datos:
   - JOIN con Odoo (datos vendedor)
   - JOIN con métodos de pago
   - JOIN con flyers (fechas período)
5. Inserta en `tblpago_detalle` con estado `PENDIENTE`
6. Registra log en `tblpago_detalle_log`

**Endpoints**:
- `POST /importaciones/upload-pagos/pagos`
- `POST /importaciones/importar-pagos/pagos`

**Ver**: [flujo-importacion-pagos.md](./flujo-importacion-pagos.md) para más detalles.

---

### Fase 2: Procesamiento de Órdenes

**Objetivo**: Agrupar pagos pendientes y crear órdenes de pago.

**Proceso**:
1. Usuario ejecuta procesamiento de órdenes
2. Stored Procedure `spInsertarOrdenesPagoPendientes`:
   - Agrupa por `dni_pago` + `canal`
   - Filtra: `estado_pago IN ('PENDIENTE', 'NO PAGADO')`
   - Filtra: `monto_pagar > 0`
   - Agrupa: `SUM(monto_pagar) >= 10` (monto mínimo)
   - Genera UUID para `id_lote`
3. Inserta en `tblpago_orden_de_pago_detalle`
4. Crea relaciones en `tblpago_orden_vs_detalle`
5. Actualiza estado a `ENVIADO A PAGO` en `tblpago_detalle`
6. Registra log con acción `ENVIADO A ORDEN PAGO`

**Endpoint**:
- `POST /orden-pago/process-order`

**Validaciones**:
- No puede procesar si existe orden pendiente (sin respuesta)
- Monto mínimo por agrupación: $10

---

### Fase 3: Generación y Envío

**Objetivo**: Generar archivos Excel y enviarlos a finanzas.

**Proceso**:
1. Generación de archivos Excel:
   - `GeneraExcelPagoService` genera archivos por canal
   - Guarda en `uploads/excel_pagos/`
   - Nombre: `pago_{fecha}_lote_{id_lote}_{canal}.xlsx`
2. Guardado en BD:
   - Inserta en `tblpago_orden_pago`
   - Genera correlativo automático
   - Estado: `ENVIADO`
3. Envío de correo (opcional):
   - Lee plantilla `templates/orden_pago.html`
   - Adjunta archivos Excel generados
   - Envía a destinatarios configurados
   - Usa `MailService` con PHPMailer

**Endpoints**:
- `POST /orden-pago/process-order` (genera archivos)
- `POST /orden-pago/send-email` (envía correo)
- `GET /orden-pago/validate-pending` (valida si hay orden pendiente)

**Separación de Procesos**:
- **Procesar**: Solo genera archivos y guarda en BD
- **Enviar**: Envía correo con archivos ya generados

---

### Fase 4: Importación de Respuestas

**Objetivo**: Procesar respuestas de finanzas y actualizar estados.

**Proceso**:
1. Usuario sube archivo Excel de respuesta
2. Script Python (`importar_respuesta.py`) lee y valida
3. Datos se cargan en `tblpago_orden_de_pago_respuesta_temp`
4. Stored Procedure `spInsertarRespuestaPago`:
   - Inserta respuestas en `tblpago_orden_de_pago_respuesta`
   - Actualiza estados en `tblpago_orden_de_pago_detalle`
   - Actualiza estados en `tblpago_detalle`
   - Registra logs con acción `RESPUESTA DE PAGO`
   - Marca lote como `RESPONDIDO` en `tblpago_orden_pago`

**Endpoints**:
- `POST /importaciones/upload-pagos/respuesta`
- `POST /importaciones/importar-pagos/respuesta`

**Estados de Respuesta**:
- `PAGADO`: Pago procesado exitosamente
- `RECHAZADO`: Pago rechazado por finanzas
- `NO PAGADO`: No procesado

---

## 🔄 Estados del Sistema

### Estados de Pago (`estado_pago`)

| Estado | Descripción | Cuándo se Asigna |
|--------|-------------|------------------|
| `PENDIENTE` | Registro inicial | Al importar desde Excel |
| `ENVIADO A PAGO` | En orden de pago | Al procesar orden |
| `PAGADO` | Procesado exitosamente | Al recibir respuesta positiva |
| `RECHAZADO` | Rechazado por finanzas | Al recibir respuesta negativa |
| `NO PAGADO` | No procesado | Al recibir respuesta negativa |

### Estados de Lote (`estado` en `tblpago_orden_pago`)

| Estado | Descripción | Cuándo se Asigna |
|--------|-------------|------------------|
| `ENVIADO` | Lote enviado a finanzas | Al generar y guardar orden |
| `RESPONDIDO` | Respuesta recibida | Al procesar respuesta |

---

## 🔗 Relaciones Clave

### Claves de Enlace

- **DNI**: Conecta Odoo, chip_recarga y detalles de pago
- **Canal**: Agrupa pagos del mismo tipo
- **id_lote** (UUID): Rastrea lotes completos
- **id_orden**: Conecta órdenes con respuestas
- **id_detalle**: Conecta detalles con órdenes (N:M)

### Tablas de Relación

- `tblpago_orden_vs_detalle`: Relación N:M entre órdenes y detalles
  - `id_pago`: FK a `tblpago_orden_de_pago_detalle`
  - `id_detalle`: FK a `tblpago_detalle`

---

## 📊 Validaciones de Negocio

### Reglas de Agrupación

1. **Agrupación obligatoria**: Por `dni_pago` + `canal`
2. **Monto mínimo**: $10 por agrupación
3. **Estados válidos**: Solo `PENDIENTE` o `NO PAGADO`
4. **Monto válido**: `monto_pagar > 0`

### Prevención de Duplicados

1. **Archivos**: Verifica `nombre_archivo` antes de procesar
2. **Registros**: Valida `dni_pago` + `detalle_pago_imagen` + `monto_pagar`
3. **Órdenes pendientes**: No permite procesar nueva orden si hay una sin respuesta

---

## 🔍 Trazabilidad

### Tabla de Logs (`tblpago_detalle_log`)

Registra todos los cambios de estado:

| Campo | Descripción |
|-------|-------------|
| `id_detalle` | ID del registro afectado |
| `dni_pago` | DNI del pago |
| `estado_pago` | Estado asignado |
| `fecha_registro` | Fecha del cambio |
| `accion` | Acción realizada |
| `id_orden` | ID de orden (si aplica) |

### Acciones Registradas

- `REGISTRO INICIAL`: Al importar pagos
- `ENVIADO A ORDEN PAGO`: Al procesar orden
- `RESPUESTA DE PAGO`: Al recibir respuesta

---

## 🚨 Casos Especiales

### Orden Pendiente

Si existe una orden sin respuesta (`archivo_respuesta IS NULL`):
- No se puede procesar nueva orden
- Debe esperarse la respuesta de finanzas
- Endpoint `validate-pending` valida esto

### Pagos Múltiples Canales

Un mismo DNI puede tener pagos en diferentes canales:
- Se agrupan por separado
- Cada canal genera su propia orden
- Se envían en archivos Excel separados

### Monto Insuficiente

Pagos con monto < $10:
- No se agrupan en órdenes
- Permanecen en estado `PENDIENTE`
- Pueden procesarse cuando se acumulen más pagos

---

## 📚 Referencias

- [Flujo de Importación](./flujo-importacion-pagos.md)
- [Estructura de Base de Datos](./estructura-base-datos.md)
- [Endpoints API](./endpoints-api.md)

