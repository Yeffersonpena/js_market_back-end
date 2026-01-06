# Documentación: Ventas Inusuales Postpago

## Descripción General

Las **Ventas Inusuales** son registros de ventas postpago donde un vendedor realizó **más de 2 altas** en un mismo día, agrupadas por fecha, zonal, acción, DNI responsable y DNI vendedor.

Estas ventas se separan del reporte normal de cierre postpago y se exportan en una hoja separada del Excel para su revisión y control.

---

## Criterio de Separación

**Regla de negocio:**
- **VENTAS INUSUALES**: Registros donde `Alta > 2`
- **CIERRE POST** (ventas normales): Registros donde `Alta <= 2`

> **Nota**: El campo `Alta` representa la cantidad de operaciones de tipo "Alta" realizadas por un vendedor en un día específico, agrupadas por fecha, zonal, acción, DNI responsable y DNI vendedor.

---

## Query SQL para Obtener los Datos

### Query Completa

```sql
SELECT
    VL.FECHA,
    E.ZONAL AS [ZONAL JS],
    E.ACCION_1 AS [ACCION JS],
    VL.DNI_RESPONSABLE,
    VL.DNI_VENDEDOR,
    VL.PRODUCT_NAME AS [PRODUCT_NAME],
    SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) AS [Alta],
    SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Portabilidad],
    SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) +
    SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Total general]
FROM
    PORTAL_COMERCIAL.dbo.VentasLog VL
    INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE E
        ON CAST(VL.DNI_RESPONSABLE AS INT) = E.DNI_RESPONSABLE
WHERE
    VL.PRODUCT_NAME = 'Postpago'
    AND E.AÑO = ?
    AND E.MES = ?
    AND E.ESTADO = 'ACTIVO'
    AND YEAR(VL.FECHA) = ?
    AND MONTH(VL.FECHA) = ?
    AND DAY(VL.FECHA) IN (dias_str)  -- Ejemplo: (16,17,18,19,20,21)
GROUP BY
    VL.FECHA,
    E.ZONAL,
    E.ACCION_1,
    VL.DNI_RESPONSABLE,
    VL.DNI_VENDEDOR,
    VL.PRODUCT_NAME
ORDER BY
    VL.FECHA,
    E.ZONAL,
    E.ACCION_1,
    VL.DNI_RESPONSABLE,
    VL.DNI_VENDEDOR
```

### Parámetros de la Query

| Parámetro | Tipo | Descripción | Ejemplo |
|-----------|------|-------------|---------|
| `?` (1) | INT | Año para filtrar `E.AÑO` | 2025 |
| `?` (2) | INT | Mes para filtrar `E.MES` | 12 |
| `?` (3) | INT | Año para filtrar `YEAR(VL.FECHA)` | 2025 |
| `?` (4) | INT | Mes para filtrar `MONTH(VL.FECHA)` | 12 |
| `dias_str` | VARCHAR | Días concatenados para la cláusula `IN` | `"16,17,18,19,20,21"` |

> **Importante**: Los parámetros de año y mes se pasan dos veces: una para filtrar `PDV_OUT_ENTREGABLE` y otra para filtrar `VentasLog`.

---

## Tablas Utilizadas

### 1. `PORTAL_COMERCIAL.dbo.VentasLog` (alias: `VL`)

**Descripción**: Tabla principal que contiene todas las ventas realizadas.

**Columnas utilizadas**:

| Columna | Tipo | Descripción | Uso en Query |
|---------|------|-------------|--------------|
| `FECHA` | DATE | Fecha de la venta | SELECT, WHERE, GROUP BY, ORDER BY |
| `DNI_RESPONSABLE` | VARCHAR/INT | DNI del responsable del PDV | SELECT, JOIN, GROUP BY, ORDER BY |
| `DNI_VENDEDOR` | INT | DNI del vendedor que realizó la venta | SELECT, GROUP BY, ORDER BY |
| `PRODUCT_NAME` | VARCHAR | Nombre del producto | SELECT, WHERE (debe ser 'Postpago') |
| `OPERATION_NAME` | VARCHAR | Tipo de operación | WHERE (debe ser 'Alta' o 'Portabilidad') |

**Filtros aplicados**:
- `PRODUCT_NAME = 'Postpago'` (solo ventas postpago)
- `YEAR(FECHA) = año` (filtro por año)
- `MONTH(FECHA) = mes` (filtro por mes)
- `DAY(FECHA) IN (días especificados)` (filtro por días específicos)

### 2. `PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE` (alias: `E`)

**Descripción**: Tabla que contiene información de los puntos de venta y sus entregables.

**Columnas utilizadas**:

| Columna | Tipo | Descripción | Uso en Query |
|---------|------|-------------|--------------|
| `DNI_RESPONSABLE` | INT | DNI del responsable (usado para JOIN) | JOIN, WHERE |
| `ZONAL` | VARCHAR | Zonal JS | SELECT (como `ZONAL JS`), GROUP BY |
| `ACCION_1` | VARCHAR | Acción JS | SELECT (como `ACCION JS`), GROUP BY |
| `AÑO` | INT | Año del entregable | WHERE |
| `MES` | INT | Mes del entregable | WHERE |
| `ESTADO` | VARCHAR | Estado del entregable | WHERE (debe ser 'ACTIVO') |

**Filtros aplicados**:
- `AÑO = año` (filtro por año del entregable)
- `MES = mes` (filtro por mes del entregable)
- `ESTADO = 'ACTIVO'` (solo entregables activos)

**JOIN**:
```sql
INNER JOIN ON CAST(VL.DNI_RESPONSABLE AS INT) = E.DNI_RESPONSABLE
```

> **Nota importante**: Se hace un `CAST` de `VL.DNI_RESPONSABLE` a `INT` para realizar el JOIN, ya que en `VentasLog` puede estar como VARCHAR.

---

## Agregaciones y Cálculos

### Agrupación

Los datos se agrupan por:
- `VL.FECHA` (fecha de la venta)
- `E.ZONAL` (zonal JS)
- `E.ACCION_1` (acción JS)
- `VL.DNI_RESPONSABLE` (DNI del responsable)
- `VL.DNI_VENDEDOR` (DNI del vendedor)
- `VL.PRODUCT_NAME` (nombre del producto)

### Campos Calculados

1. **Alta**: 
   ```sql
   SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) AS [Alta]
   ```
   - Cuenta cuántas operaciones de tipo "Alta" hay en el grupo

2. **Portabilidad**:
   ```sql
   SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Portabilidad]
   ```
   - Cuenta cuántas operaciones de tipo "Portabilidad" hay en el grupo

3. **Total general**:
   ```sql
   SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) +
   SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Total general]
   ```
   - Suma de Altas + Portabilidades

---

## Estructura de Datos de Salida

### Campos Retornados por la Query

| Campo SQL | Tipo | Descripción |
|-----------|------|-------------|
| `FECHA` | DATE | Fecha de la venta |
| `ZONAL JS` | VARCHAR | Zonal JS (viene de `E.ZONAL`) |
| `ACCION JS` | VARCHAR | Acción JS (viene de `E.ACCION_1`) |
| `DNI_RESPONSABLE` | INT | DNI del responsable del PDV |
| `DNI_VENDEDOR` | INT | DNI del vendedor |
| `PRODUCT_NAME` | VARCHAR | Nombre del producto (siempre 'Postpago') |
| `Alta` | INT | Cantidad de altas en el grupo |
| `Portabilidad` | INT | Cantidad de portabilidades en el grupo |
| `Total general` | INT | Total de altas + portabilidades |

### Separación de Datos

Después de obtener los datos de la query, se deben separar en dos grupos:

1. **CIERRE POST** (ventas normales):
   - Condición: `Alta <= 2`
   - Se exportan en la hoja "CIERRE POST"

2. **VENTAS INUSUALES**:
   - Condición: `Alta > 2`
   - Se exportan en la hoja "VENTAS INUSUALES"

---

## Estructura del Excel Exportado

### Archivo Generado

**Nombre del archivo**: `CIERRE POSTPAGO LOG DD-MM.xlsx`

**Formato**: `CIERRE POSTPAGO LOG {primer_dia:02d}-{mes:02d}.xlsx`

**Ejemplos**:
- `CIERRE POSTPAGO LOG 01-12.xlsx` (días 1-5 de diciembre)
- `CIERRE POSTPAGO LOG 16-12.xlsx` (días 16-21 de diciembre)

### Hojas del Excel

El archivo Excel contiene **dos hojas**:

1. **"CIERRE POST"**: Ventas normales (Alta <= 2)
2. **"VENTAS INUSUALES"**: Ventas inusuales (Alta > 2)

### Columnas de la Hoja "VENTAS INUSUALES"

| Columna | Tipo | Descripción | Orden |
|---------|------|-------------|-------|
| `FECHA` | DATE | Fecha de la venta | 1 |
| `ZONAL JS` | VARCHAR | Zonal JS | 2 |
| `ACCION JS` | VARCHAR | Acción JS | 3 |
| `DNI_RESPONSABLE` | INT | DNI del responsable del PDV | 4 |
| `DNI_VENDEDOR` | INT | DNI del vendedor | 5 |
| `Alta` | INT | Cantidad de altas | 6 |
| `Portabilidad` | INT | Cantidad de portabilidades | 7 |
| `Total general` | INT | Total de altas + portabilidades | 8 |

> **Nota**: El campo `PRODUCT_NAME` no se exporta al Excel, ya que siempre es 'Postpago' y no aporta información adicional.

### Formato del Excel

- **Encabezados**: Primera fila en negrita
- **Bordes**: Todas las celdas con datos tienen bordes delgados
- **Ancho de columnas**: Se ajusta automáticamente según el contenido (mínimo 10, máximo 50 caracteres)
- **Ordenamiento**: Los datos se ordenan por:
  1. FECHA (ascendente)
  2. ZONAL JS (ascendente)
  3. ACCION JS (ascendente)
  4. DNI_RESPONSABLE (ascendente)
  5. DNI_VENDEDOR (ascendente)

---

## Ejemplo de Datos

### Datos de Entrada (Resultado de la Query)

| FECHA | ZONAL JS | ACCION JS | DNI_RESPONSABLE | DNI_VENDEDOR | PRODUCT_NAME | Alta | Portabilidad | Total general |
|-------|----------|-----------|-----------------|--------------|--------------|------|--------------|---------------|
| 2025-12-16 | NORTE | ACCION_1 | 12345678 | 87654321 | Postpago | 3 | 1 | 4 |
| 2025-12-16 | SUR | ACCION_2 | 11111111 | 22222222 | Postpago | 1 | 0 | 1 |
| 2025-12-17 | NORTE | ACCION_1 | 12345678 | 87654321 | Postpago | 5 | 2 | 7 |
| 2025-12-17 | CENTRO | ACCION_3 | 33333333 | 44444444 | Postpago | 2 | 1 | 3 |

### Datos Separados

**CIERRE POST** (Alta <= 2):
- Fila 2: DNI 11111111, vendedor 22222222, 1 alta
- Fila 4: DNI 33333333, vendedor 44444444, 2 altas

**VENTAS INUSUALES** (Alta > 2):
- Fila 1: DNI 12345678, vendedor 87654321, 3 altas
- Fila 3: DNI 12345678, vendedor 87654321, 5 altas

### Excel Exportado - Hoja "VENTAS INUSUALES"

| FECHA | ZONAL JS | ACCION JS | DNI_RESPONSABLE | DNI_VENDEDOR | Alta | Portabilidad | Total general |
|-------|----------|-----------|-----------------|--------------|------|--------------|---------------|
| 2025-12-16 | NORTE | ACCION_1 | 12345678 | 87654321 | 3 | 1 | 4 |
| 2025-12-17 | NORTE | ACCION_1 | 12345678 | 87654321 | 5 | 2 | 7 |

---

## Consideraciones para Implementación en Backend PHP

### 1. Conexión a Base de Datos

**Base de datos**: `PORTAL_COMERCIAL`
**Servidor**: `192.168.3.212\jsms`
**Usuario**: `SA`
**Driver**: ODBC Driver 17 for SQL Server (o equivalente para PHP)

### 2. Validación de Parámetros

Antes de ejecutar la query, validar:
- Año: debe ser un entero válido
- Mes: debe estar entre 1 y 12
- Días: deben ser enteros válidos entre 1 y 31, y válidos para el mes especificado (considerar años bisiestos)

### 3. Construcción de la Cláusula IN

Los días deben concatenarse de forma segura para evitar SQL injection:

```php
// Ejemplo en PHP
$dias_validos = array_filter($dias, function($dia) {
    return is_int($dia) && $dia >= 1 && $dia <= 31;
});

$dias_str = implode(',', array_map('intval', $dias_validos));
// Resultado: "16,17,18,19,20,21"
```

### 4. Separación de Datos

Después de obtener los resultados de la query:

```php
// Pseudocódigo
$ventas_inusuales = [];
$cierre_post = [];

foreach ($resultados as $registro) {
    if ($registro['Alta'] > 2) {
        $ventas_inusuales[] = $registro;
    } else {
        $cierre_post[] = $registro;
    }
}
```

### 5. Generación del Excel

- Usar una librería de PHP para generar Excel (PhpSpreadsheet, PHPExcel, etc.)
- Crear dos hojas: "CIERRE POST" y "VENTAS INUSUALES"
- Aplicar formato: encabezados en negrita, bordes en todas las celdas
- Ajustar ancho de columnas automáticamente

### 6. Nombre del Archivo

```php
// Pseudocódigo
$primer_dia = min($dias); // Primer día de la lista
$nombre_archivo = sprintf("CIERRE POSTPAGO LOG %02d-%02d.xlsx", $primer_dia, $mes);
```

---

## Resumen de Dependencias

### Tablas Requeridas

| Tabla | Esquema | Uso |
|-------|---------|-----|
| `VentasLog` | `dbo` | Lectura: Obtiene ventas postpago |
| `PDV_OUT_ENTREGABLE` | `dbo` | Lectura: Obtiene información de zonal y acción JS |

### Campos Clave

- **Filtro principal**: `VL.PRODUCT_NAME = 'Postpago'`
- **Criterio de separación**: `Alta > 2` (para ventas inusuales)
- **JOIN**: `CAST(VL.DNI_RESPONSABLE AS INT) = E.DNI_RESPONSABLE`

---

## Notas Importantes

1. **No requiere ejecución de SP**: Las ventas inusuales se obtienen directamente de `VentasLog`, no dependen de ningún stored procedure.

2. **Agrupación**: Los datos se agrupan por fecha, zonal, acción, DNI responsable y DNI vendedor. Un mismo vendedor puede aparecer múltiples veces si tiene ventas en diferentes fechas o zonas.

3. **Criterio de separación**: El criterio `Alta > 2` se aplica **después** de la agregación, no antes. Es decir, se cuentan todas las altas del grupo y luego se separa.

4. **Ordenamiento**: Los datos se ordenan por fecha, zonal, acción, DNI responsable y DNI vendedor para facilitar la revisión.

5. **Campos exportados**: El campo `PRODUCT_NAME` no se exporta al Excel ya que siempre es 'Postpago'.

