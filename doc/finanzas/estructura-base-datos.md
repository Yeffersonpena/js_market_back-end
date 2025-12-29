# 🗄️ Estructura de Base de Datos

## 📋 Información General

- **Base de Datos**: `PORTAL_COMERCIAL`
- **Prefijo de Tablas**: `tblpago_`
- **Motor**: SQL Server

## 📊 Diagrama de Relaciones

```
tblpago_detalle (Principal)
    ├──→ tblpago_detalle_log (Auditoría)
    ├──→ tblpago_orden_vs_detalle (N:M)
    │       └──→ tblpago_orden_de_pago_detalle
    │               └──→ tblpago_orden_de_pago_respuesta
    └──→ tblpago_orden_pago (Control de Lotes)

tblpago_detalle_temp (Temporal)
tblpago_orden_de_pago_respuesta_temp (Temporal)

tblpagos_datos_odoo (Maestra)
tblpagos_dni_chip_recarga (Maestra)
```

## 📋 Tablas Principales

### `tblpago_detalle`

Registro principal de todos los pagos.

| Campo | Tipo | Descripción |
|------|------|--------------|
| `id` | INT (PK, IDENTITY) | Identificador único |
| `zonal` | VARCHAR | Zona geográfica |
| `dni_responsable` | INT | DNI del responsable (dueño del local) |
| `dni_pago` | VARCHAR(20) | DNI de quien recibe el pago |
| `nombre_titular` | VARCHAR | Nombre del vendedor |
| `detalle_pago_imagen` | VARCHAR | Detalle del pago (foto/esquema) |
| `monto_pagar` | DECIMAL(10,2) | Monto del bono |
| `estado_pago` | VARCHAR(20) | Estado del pago |
| `metodo_pago` | VARCHAR | Método de pago preferido |
| `fecha_inicio` | DATE | Fecha inicio del período |
| `fecha_fin` | DATE | Fecha fin del período |
| `fecha_carga` | DATETIME | Fecha de carga |
| `user_carga` | VARCHAR(50) | Usuario que cargó |
| `canal` | VARCHAR(50) | Canal de pago |
| `nombre_archivo` | VARCHAR(200) | Archivo Excel origen |
| `observacion_odoo` | VARCHAR | Observación de Odoo |
| `observacion_estado` | VARCHAR | Observación del estado |

**Estados posibles**: `PENDIENTE`, `ENVIADO A PAGO`, `PAGADO`, `RECHAZADO`, `NO PAGADO`

**Índices**:
- `dni_pago`
- `estado_pago`
- `canal`
- `nombre_archivo`

---

### `tblpago_orden_de_pago_detalle`

Órdenes de pago agrupadas por DNI + Canal.

| Campo | Tipo | Descripción |
|------|------|-------------|
| `id` | INT (PK, IDENTITY) | Identificador único |
| `fecha_pago` | DATETIME | Fecha de la orden |
| `zonal` | VARCHAR | Zona geográfica |
| `dni_pago` | VARCHAR(20) | DNI de quien recibe |
| `monto_pago` | DECIMAL(10,2) | Monto total agrupado |
| `estado_pago` | VARCHAR(20) | Estado de la orden |
| `usuario_registro` | VARCHAR(50) | Usuario que procesó |
| `canal` | VARCHAR(50) | Canal de pago |
| `id_lote_pago` | UNIQUEIDENTIFIER | UUID del lote |
| `metodo_pago` | VARCHAR | Método de pago |

**Relación**: N:M con `tblpago_detalle` a través de `tblpago_orden_vs_detalle`

---

### `tblpago_orden_pago`

Control de lotes enviados a finanzas.

| Campo | Tipo | Descripción |
|------|------|-------------|
| `id_orden` | INT (PK, IDENTITY) | Identificador único |
| `id_lote` | VARCHAR(200) | UUID del lote |
| `correlativo` | VARCHAR(50) | Correlativo de orden |
| `fecha_hora_envio` | DATETIME | Fecha de envío |
| `archivo_envio` | VARCHAR(200) | Nombre archivo Excel enviado |
| `archivo_respuesta` | VARCHAR(200) | Nombre archivo respuesta |
| `estado` | VARCHAR(20) | Estado del lote |

**Estados**: `ENVIADO`, `RESPONDIDO`

---

### `tblpago_orden_vs_detalle`

Relación N:M entre órdenes y detalles.

| Campo | Tipo | Descripción |
|------|------|-------------|
| `id_pago` | INT (FK) | FK a `tblpago_orden_de_pago_detalle.id` |
| `id_detalle` | INT (FK) | FK a `tblpago_detalle.id` |

**Clave Primaria Compuesta**: `(id_pago, id_detalle)`

---

### `tblpago_orden_de_pago_respuesta`

Respuestas de finanzas para cada orden.

| Campo | Tipo | Descripción |
|------|------|-------------|
| `id` | INT (PK, IDENTITY) | Identificador único |
| `fecha_pago` | DATETIME | Fecha del pago |
| `zonal` | VARCHAR | Zona geográfica |
| `dni_pago` | VARCHAR(20) | DNI de quien recibe |
| `monto_pago` | DECIMAL(10,2) | Monto procesado |
| `usuario_registro_respuesta` | VARCHAR(50) | Usuario que procesó respuesta |
| `estado_respuesta` | VARCHAR(20) | Estado de la respuesta |
| `canal` | VARCHAR(50) | Canal de pago |
| `metodo_pago` | VARCHAR | Método de pago |
| `id_orden` | INT (FK) | FK a `tblpago_orden_de_pago_detalle.id` |
| `observacion_odoo` | VARCHAR | Observación de Odoo |
| `observacion_estado` | VARCHAR | Observación del estado |

**Estados**: `PAGADO`, `RECHAZADO`, `NO PAGADO`

---

### `tblpago_detalle_log`

Auditoría completa de cambios de estado.

| Campo | Tipo | Descripción |
|------|------|-------------|
| `id` | INT (PK, IDENTITY) | Identificador único |
| `id_detalle` | INT (FK) | FK a `tblpago_detalle.id` |
| `dni_pago` | VARCHAR(20) | DNI del pago |
| `estado_pago` | VARCHAR(20) | Estado asignado |
| `fecha_registro` | DATETIME | Fecha del cambio |
| `accion` | VARCHAR(50) | Acción realizada |
| `id_orden` | INT (FK, NULL) | FK a `tblpago_orden_de_pago_detalle.id` (opcional) |

**Acciones registradas**:
- `REGISTRO INICIAL`
- `ENVIADO A ORDEN PAGO`
- `RESPUESTA DE PAGO`

---

## 📋 Tablas Temporales

### `tblpago_detalle_temp`

Datos iniciales del Excel antes de procesamiento.

| Campo | Tipo | Descripción |
|------|------|-------------|
| `id` | INT (PK, IDENTITY) | Identificador único |
| `zonal` | VARCHAR | Zona geográfica |
| `dni_resp` | INT | DNI responsable |
| `nombre_titular` | VARCHAR | No se usa actualmente |
| `canal` | VARCHAR | Canal de pago |
| `detalle` | VARCHAR | Detalle del pago |
| `bono_total` | DECIMAL(10,2) | Monto del bono |
| `dni_vendedor` | INT | Campo existente pero NO UTILIZADO |

**Uso**: Se trunca antes de cada importación.

---

### `tblpago_orden_de_pago_respuesta_temp`

Respuestas temporales antes de procesamiento.

| Campo | Tipo | Descripción |
|------|------|-------------|
| `id` | INT (PK, IDENTITY) | Identificador único |
| `fecha_pago` | DATETIME | Fecha del pago |
| `zonal` | VARCHAR | Zona geográfica |
| `dni_pago` | VARCHAR(20) | DNI de quien recibe |
| `monto_pago` | DECIMAL(10,2) | Monto procesado |
| `usuario_registro_respuesta` | VARCHAR(50) | Usuario que procesó |
| `estado_respuesta` | VARCHAR(20) | Estado de la respuesta |
| `canal` | VARCHAR(50) | Canal de pago |
| `metodo_pago` | VARCHAR | Método de pago |
| `id_orden` | INT | ID de la orden |
| `observacion_odoo` | VARCHAR | Observación de Odoo |
| `observacion_estado` | VARCHAR | Observación del estado |

**Uso**: Se trunca antes de cada importación de respuesta.

---

## 📋 Tablas Maestras

### `tblpagos_datos_odoo`

Datos de vendedores desde Odoo.

| Campo | Tipo | Descripción |
|------|------|-------------|
| `numero_de_documento` | VARCHAR | DNI del vendedor (PK) |
| `nombre_del_vendedor` | VARCHAR | Nombre completo |
| `zonal` | VARCHAR | Zona geográfica |
| `tipo_plan` | VARCHAR | Tipo de plan |
| `datos_bancarios` | VARCHAR | Información bancaria |

**Uso**: Enriquecimiento de datos en importación.

---

### `tblpagos_dni_chip_recarga`

Métodos de pago preferidos por DNI.

| Campo | Tipo | Descripción |
|------|------|-------------|
| `dni` | INT (PK) | DNI del vendedor |
| `zonal` | VARCHAR | Zona geográfica |
| `metodo_pago` | VARCHAR | Método preferido |
| `numero_recarga` | VARCHAR | Número de recarga (si aplica) |

**Métodos comunes**: `Transferencia`, `Chip`, `Recarga`

---

## 🔗 Relaciones Clave

### Flujo de Datos

```
tblpago_detalle_temp
    ↓ (spInsertarPagosInicio)
tblpago_detalle
    ↓ (spInsertarOrdenesPagoPendientes)
tblpago_orden_de_pago_detalle ←→ tblpago_orden_vs_detalle ←→ tblpago_detalle
    ↓
tblpago_orden_pago
    ↓ (spInsertarRespuestaPago)
tblpago_orden_de_pago_respuesta_temp
    ↓
tblpago_orden_de_pago_respuesta
    ↓ (UPDATE)
tblpago_detalle (actualización de estados)
```

### Claves Foráneas

- `tblpago_orden_vs_detalle.id_pago` → `tblpago_orden_de_pago_detalle.id`
- `tblpago_orden_vs_detalle.id_detalle` → `tblpago_detalle.id`
- `tblpago_orden_de_pago_respuesta.id_orden` → `tblpago_orden_de_pago_detalle.id`
- `tblpago_detalle_log.id_detalle` → `tblpago_detalle.id`
- `tblpago_detalle_log.id_orden` → `tblpago_orden_de_pago_detalle.id` (opcional)

---

## 📊 Índices Recomendados

### `tblpago_detalle`
- `dni_pago`
- `estado_pago`
- `canal`
- `nombre_archivo`
- `(dni_pago, canal, estado_pago)` (compuesto)

### `tblpago_orden_de_pago_detalle`
- `id_lote_pago`
- `dni_pago`
- `canal`
- `estado_pago`

### `tblpago_orden_pago`
- `id_lote`
- `estado`
- `archivo_respuesta` (para validar pendientes)

---

## 🔍 Consultas Comunes

### Obtener pagos pendientes por lote

```sql
SELECT d.*
FROM tblpago_detalle d
INNER JOIN tblpago_orden_vs_detalle ovd ON d.id = ovd.id_detalle
INNER JOIN tblpago_orden_de_pago_detalle od ON ovd.id_pago = od.id
WHERE od.id_lote_pago = @id_lote
```

### Obtener resumen por canal

```sql
SELECT canal, SUM(monto_pago) as total
FROM tblpago_orden_de_pago_detalle
WHERE id_lote_pago = @id_lote
GROUP BY canal
```

### Verificar orden pendiente

```sql
SELECT TOP 1 id_lote
FROM tblpago_orden_pago
WHERE archivo_respuesta IS NULL
ORDER BY id_orden DESC
```

---

## 📚 Referencias

- [Flujo Completo](./flujo-completo-pagos.md)
- [Stored Procedures](../sql/store_procedures/)
- [Scripts de Tablas](../sql/tables/)

