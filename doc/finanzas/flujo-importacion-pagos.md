# Flujo de Importación de Pagos - Sistema Financiero

## 📋 Descripción General

Este documento describe el proceso completo de importación de pagos desde un archivo Excel hasta su registro en la base de datos como pagos pendientes. Este es el primer paso del flujo completo de procesamiento de pagos financieros.

## 🔄 Flujo del Proceso

### 1. Subida del Archivo Excel

El proceso inicia cuando un usuario sube un archivo Excel mediante la API del sistema. El archivo debe cumplir con la estructura definida y contener los datos de los bonos a pagar.

### 2. Procesamiento con Script Python

Una vez subido el archivo, se ejecuta el script `importar_pagos.py` que realiza las siguientes acciones:

#### 2.1 Validaciones Iniciales
- Verifica que el archivo existe en la ruta especificada
- Valida que el archivo tenga extensión `.xlsx`
- Verifica que el archivo no haya sido procesado previamente (consulta en `tblpago_detalle` por `nombre_archivo`)

#### 2.2 Lectura del Excel
- Lee la hoja "DETALLE" del archivo Excel
- Extrae las siguientes columnas:
  - `ZONAL`: Zona geográfica del pago
  - `DNI RESPONSABLE`: DNI del dueño del local/responsable (nuevo campo)
  - `DNI`: DNI del vendedor que recibe el pago
  - `CANAL`: Canal de pago
  - `DETALLE`: Detalle del pago (imagen/esquema)
  - `BONO TOTAL`: Monto del bono a pagar

#### 2.3 Transformación de Datos
- Convierte `BONO TOTAL` a numérico
- Elimina filas con valores nulos en `BONO TOTAL`
- Renombra las columnas a formato snake_case:
  - `ZONAL` → `zonal`
  - `DNI RESPONSABLE` → `dni_resp` (dni_responsable)
  - `DNI` → `dni_vendedor` (dni del vendedor)
  - `CANAL` → `canal`
  - `DETALLE` → `detalle`
  - `BONO TOTAL` → `bono_total`
- Convierte ambos campos DNI a numérico
- **Lógica de fallback**: Si `DNI RESPONSABLE` está vacío, se rellena automáticamente con el valor de `DNI` (vendedor)
- Valida que ambos campos tengan valores válidos antes de continuar

#### 2.4 Carga en Tabla Temporal
- Trunca la tabla temporal `tblpago_detalle_temp`
- Inserta los datos transformados en la tabla temporal
- Los datos quedan listos para ser procesados por el stored procedure

### 3. Procesamiento con Stored Procedure

El script Python ejecuta el stored procedure `spInsertarPagosInicio` que realiza el procesamiento final:

#### 3.1 Enriquecimiento de Datos

El SP realiza varios LEFT JOINs para enriquecer la información:

**a) JOIN con Odoo (`tblpagos_datos_odoo`)**
- Busca el vendedor en Odoo usando el DNI del vendedor de la tabla temporal (`temp.dni_vendedor`)
- Si encuentra coincidencia, obtiene:
  - `numero_de_documento`: DNI del vendedor (puede diferir del DNI ingresado)
  - `nombre_del_vendedor`: Nombre del titular del pago

**b) JOIN con Métodos de Pago (`tblpagos_dni_chip_recarga`)**
- Busca el método de pago preferido usando el DNI del vendedor (`temp.dni_vendedor`)
- Si no encuentra, usa "Transferencia" como método por defecto

**c) JOIN con Flyers (`PDV_OUT_FLYERS`)**
- Busca fechas de inicio y fin del período usando el campo `detalle` (foto_esquema)
- Obtiene `fecha_inicio` y `fecha_fin` del período del bono

#### 3.2 Lógica de DNI (Implementada)

**Separación de DNI Responsable y DNI Vendedor:**

El sistema ahora diferencia claramente entre dos tipos de DNI:

1. **DNI Responsable** (`dni_responsable`): 
   - Se toma directamente de `temp.dni_resp` (columna "DNI RESPONSABLE" del Excel)
   - Representa al dueño del local/responsable
   - Se almacena en `tblpago_detalle.dni_responsable`

2. **DNI Pago** (`dni_pago`):
   - Se calcula usando el DNI del vendedor: `ISNULL(odoo.numero_de_documento, CAST(temp.dni_vendedor AS VARCHAR))`
   - El JOIN con Odoo se realiza usando `temp.dni_vendedor` (columna "DNI" del Excel)
   - Si encuentra el DNI en Odoo, usa el `numero_de_documento` de Odoo
   - Si no encuentra, usa el `dni_vendedor` del Excel como fallback
   - Representa al vendedor que recibirá el pago
   - Se almacena en `tblpago_detalle.dni_pago`

**Ventajas de la Implementación:**
- Separación clara entre responsable y vendedor
- Permite casos donde responsable ≠ vendedor
- Mantiene compatibilidad con la estructura de BD existente
- Utiliza el campo `dni_vendedor` que ya existía en la tabla temporal

#### 3.3 Inserción en Tabla Principal

El SP inserta los registros en `tblpago_detalle` con los siguientes campos:

- `zonal`: Zona geográfica
- `dni_responsable`: DNI del responsable (dueño del local) - `temp.dni_resp` (columna "DNI RESPONSABLE")
- `dni_pago`: DNI de quien recibe el pago - calculado desde Odoo usando `temp.dni_vendedor` o `temp.dni_vendedor` como fallback
- `nombre_titular`: Nombre del vendedor desde Odoo o vacío
- `detalle_pago_imagen`: Detalle del pago
- `monto_pagar`: Monto del bono
- `estado_pago`: Siempre "PENDIENTE" en este punto
- `metodo_pago`: Método de pago desde chip_recarga o "Transferencia"
- `fecha_inicio` / `fecha_fin`: Fechas del período desde flyers
- `fecha_carga`: Fecha actual
- `user_carga`: Usuario que ejecutó la importación
- `canal`: Canal de pago
- `nombre_archivo`: Nombre del archivo Excel procesado

#### 3.4 Validación de Duplicados

Antes de insertar, el SP verifica que no exista un registro duplicado usando:
- `dni_pago`
- `detalle_pago_imagen`
- `monto_pagar`

#### 3.5 Registro de Auditoría

Para cada registro insertado, se crea un log en `tblpago_detalle_log` con:
- `id_detalle`: ID del registro insertado
- `dni_pago`: DNI del pago
- `estado_pago`: "PENDIENTE"
- `fecha_registro`: Fecha actual
- `accion`: "REGISTRO INICIAL"

### 4. Estado Final

Al finalizar el proceso:
- Todos los registros quedan con estado `PENDIENTE`
- Los datos están listos para ser procesados en una orden de pago (siguiente paso del flujo)
- Se mantiene trazabilidad completa mediante logs

## 📊 Estructura de Tablas

### Tabla Temporal: `tblpago_detalle_temp`

```sql
- id (PK, IDENTITY)
- zonal (varchar)
- dni_resp (int) - DNI responsable
- nombre_titular (varchar) - No se usa actualmente
- canal (varchar)
- detalle (varchar)
- bono_total (decimal)
- dni_vendedor (int) - Campo existente pero NO UTILIZADO actualmente
```

### Tabla Principal: `tblpago_detalle`

```sql
- id (PK, IDENTITY)
- zonal (varchar)
- dni_responsable (int) - DNI del dueño del local
- dni_pago (varchar) - DNI de quien recibe el pago
- nombre_titular (varchar) - Nombre del vendedor
- detalle_pago_imagen (varchar)
- monto_pagar (decimal)
- estado_pago (varchar) - "PENDIENTE" inicialmente
- metodo_pago (varchar)
- fecha_inicio (date)
- fecha_fin (date)
- fecha_carga (datetime)
- user_carga (varchar)
- canal (varchar)
- nombre_archivo (varchar)
```

## ✅ Solución Implementada: Separación de DNI Responsable y DNI Vendedor

### Cambios Realizados

Se ha implementado la separación entre DNI responsable y DNI vendedor para permitir un mejor control y trazabilidad de los pagos.

**Estructura del Excel (Actualizada):**
- `ZONAL`: Zona geográfica
- `DNI RESPONSABLE`: DNI del dueño del local (nuevo campo requerido)
- `DNI`: DNI del vendedor que recibe el pago
- `CANAL`: Canal de pago
- `DETALLE`: Detalle del pago
- `BONO TOTAL`: Monto del bono

### Implementación Técnica

#### 1. Script Python (`importar_pagos.py`) - ✅ Actualizado
- Agregada columna `'DNI RESPONSABLE'` a `columnas_esperadas`
- Mapeo implementado:
  - `'DNI RESPONSABLE'` → `'dni_resp'` (dni_responsable)
  - `'DNI'` → `'dni_vendedor'` (dni del vendedor)

#### 2. Stored Procedure (`spInsertarPagosInicio.sql`) - ✅ Actualizado
- `dni_responsable`: Usa `temp.dni_resp` (sin cambios)
- JOIN con Odoo: Cambiado para usar `temp.dni_vendedor` en lugar de `temp.dni_resp`
- `dni_pago`: Calculado como `ISNULL(odoo.numero_de_documento, CAST(temp.dni_vendedor AS VARCHAR))`
- JOIN con chip_recarga: Cambiado para usar `temp.dni_vendedor`
- Validación de duplicados: Actualizada para usar el nuevo cálculo de `dni_pago`

### Casos de Uso Soportados

1. **Responsable = Vendedor:**
   - `DNI RESPONSABLE`: 12345678
   - `DNI`: 12345678
   - Ambos campos tienen el mismo valor

2. **Responsable ≠ Vendedor:**
   - `DNI RESPONSABLE`: 12345678 (dueño del local)
   - `DNI`: 87654321 (vendedor que recibe el pago)
   - Permite identificar quién es el responsable y quién recibe el pago

### Ventajas de la Implementación

- ✅ Separación clara de responsabilidades
- ✅ Utiliza el campo `dni_vendedor` que ya existía en la tabla temporal
- ✅ Permite casos donde responsable ≠ vendedor
- ✅ Mantiene compatibilidad con la estructura de BD existente
- ✅ Mejora la trazabilidad y capacidad de reportes

### Consideraciones Importantes

⚠️ **Migración de Datos:**
- Los archivos Excel deben incluir la columna "DNI RESPONSABLE"
- **Flexibilidad**: Si `DNI RESPONSABLE` está vacío, el sistema automáticamente usa el valor de `DNI` (vendedor) como responsable
- Si responsable = vendedor, se puede dejar `DNI RESPONSABLE` vacío y el sistema lo completará automáticamente
- El campo `DNI` (vendedor) es obligatorio y siempre debe tener valor
- Si ambos campos están vacíos, el sistema mostrará un error y detendrá el proceso

## 📝 Notas Técnicas

### Validaciones Importantes

1. **Prevención de Duplicados:**
   - El sistema verifica que el archivo no haya sido procesado previamente
   - El SP valida duplicados por `dni_pago`, `detalle_pago_imagen` y `monto_pagar`

2. **Manejo de Errores:**
   - Si el archivo ya fue procesado, el script termina con código de salida 1
   - Si hay errores durante la carga, se hace rollback de la transacción

3. **Compatibilidad con Odoo:**
   - El JOIN con Odoo usa `TRY_CAST` para manejar conversiones de tipo seguras
   - Si no hay match en Odoo, se usa el DNI ingresado como fallback

### Flujo de Datos

```
Excel
  ↓
importar_pagos.py (transformación)
  ↓
tblpago_detalle_temp (temporal)
  ↓
spInsertarPagosInicio (enriquecimiento + validación)
  ↓
tblpago_detalle (tabla principal - estado: PENDIENTE)
  ↓
tblpago_detalle_log (auditoría)
```

## 🚀 Próximos Pasos

Después de la importación, los registros con estado `PENDIENTE` pueden ser:
1. Agrupados por DNI + Canal
2. Procesados en órdenes de pago
3. Enviados a finanzas
4. Actualizados con respuestas de finanzas

Este proceso se documenta en otros archivos del sistema.

