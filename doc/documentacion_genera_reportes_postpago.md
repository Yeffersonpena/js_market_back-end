# Documentación Técnica: excel_generator.genera_reportes_postpago

## Descripción General

El script `excel_generator.genera_reportes_postpago` es un orquestador que ejecuta un proceso completo de generación de reportes postpago en tres pasos secuenciales:

1. **Paso 0 (Opcional)**: Ejecuta el stored procedure `sp_Registrar_AbonosPostpago` para calcular y registrar bonos
2. **Paso 1**: Genera el reporte de cierre postpago (Excel con dos hojas)
3. **Paso 2**: Genera el reporte de bono recargas postpago (Excel)

---

## Flujo de Ejecución

### Función Principal: `ejecutar_reportes_postpago()`

**Ubicación**: `excel_generator/genera_reportes_postpago.py`

**Parámetros**:
- `año` (int): Año del período a procesar
- `mes` (int): Mes del período (1-12)
- `dias` (List[int]): Lista de días del mes a consultar (ej: [1, 2, 3])
- `ejecutar_sp` (bool): Si es `True`, ejecuta el SP antes de generar reportes. Si es `False`, omite el SP.

**Flujo**:
```
1. Validación de parámetros (mes y días)
2. Si ejecutar_sp = True:
   → Ejecuta sp_Registrar_AbonosPostpago
3. Genera cierre postpago (generar_cierre_postpago)
4. Calcula fechas desde los días proporcionados
5. Genera bono recargas postpago (generar_bono_recargas_postpago)
```

---

## Paso 0: Stored Procedure sp_Registrar_AbonosPostpago

### Función: `ejecutar_sp_registrar_abonos_postpago()`

**Ubicación**: `excel_generator/genera_reportes_postpago.py` (líneas 20-79)

**Propósito**: Ejecuta el stored procedure que calcula los bonos en base a las reglas del negocio y los inserta en la tabla `abonos_postpago_log`.

### Parámetros del SP

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `@Año` | INT | Año del período |
| `@Mes` | INT | Mes del período (1-12) |
| `@DiasFiltro` | VARCHAR/NULL | Lista de días separados por comas (ej: "4,5,6") o NULL para procesar todos los días no registrados del mes |

### Ejecución

**Conexión**: `PORTAL_COMERCIAL` (servidor: 192.168.3.212\jsms)

**Query de ejecución**:
```sql
-- Con filtro de días:
EXEC sp_Registrar_AbonosPostpago @Año = ?, @Mes = ?, @DiasFiltro = ?

-- Sin filtro (todos los días no registrados):
EXEC sp_Registrar_AbonosPostpago @Año = ?, @Mes = ?, @DiasFiltro = NULL
```

### Retorno del SP

El SP retorna un resultado con dos columnas:
- `RegistrosInsertados` (INT): Número de registros insertados
- `Mensaje` (VARCHAR): Mensaje descriptivo del resultado

**Validación**: Si `RegistrosInsertados = 0` y el mensaje no contiene "exitosamente", se considera un error.

### Tablas que el SP debe usar (internamente)

> **Nota**: El SP es un stored procedure en la base de datos. Aunque no podemos ver su código interno desde el script Python, el SP debe estar:
> - Leyendo datos de ventas postpago (probablemente de `VentasLog`)
> - Aplicando reglas de negocio para calcular bonos
> - Insertando/actualizando registros en `abonos_postpago_log`

**Tabla de destino**: `PORTAL_COMERCIAL.dbo.abonos_postpago_log`

---

## Paso 1: Generación de Cierre Postpago

### Función: `generar_cierre_postpago()`

**Ubicación**: `excel_generator/genera_cierre_postpago.py` (líneas 93-148)

**Propósito**: Genera un archivo Excel con dos hojas:
- **CIERRE POST**: Registros con `Alta <= 2`
- **VENTAS INUSUALES**: Registros con `Alta > 2`

**Nombre del archivo generado**: `CIERRE POSTPAGO LOG DD-MM.xlsx` (ej: `CIERRE POSTPAGO LOG 01-12.xlsx`)

### Query SQL Ejecutada

**Ubicación**: `excel_generator/repositories/ventas_postpago_repository.py` (líneas 43-80)

**Conexión**: `PORTAL_COMERCIAL` (servidor: 192.168.3.212\jsms)

**Query completa**:
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
    AND DAY(VL.FECHA) IN (dias_str)  -- días dinámicos: ej: (1,2,3)
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

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| `?` (1) | `año` | Año para filtrar `E.AÑO` |
| `?` (2) | `mes` | Mes para filtrar `E.MES` |
| `?` (3) | `año` | Año para filtrar `YEAR(VL.FECHA)` |
| `?` (4) | `mes` | Mes para filtrar `MONTH(VL.FECHA)` |
| `dias_str` | `"1,2,3"` | Días concatenados para la cláusula `IN` |

### Tablas Utilizadas

#### 1. `PORTAL_COMERCIAL.dbo.VentasLog` (alias: `VL`)

**Columnas utilizadas**:
- `FECHA` (DATE): Fecha de la venta
- `DNI_RESPONSABLE` (VARCHAR/INT): DNI del responsable del PDV
- `DNI_VENDEDOR` (INT): DNI del vendedor
- `PRODUCT_NAME` (VARCHAR): Nombre del producto (debe ser 'Postpago')
- `OPERATION_NAME` (VARCHAR): Tipo de operación ('Alta' o 'Portabilidad')

**Filtros aplicados**:
- `PRODUCT_NAME = 'Postpago'`
- `YEAR(FECHA) = año`
- `MONTH(FECHA) = mes`
- `DAY(FECHA) IN (días especificados)`

#### 2. `PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE` (alias: `E`)

**Columnas utilizadas**:
- `DNI_RESPONSABLE` (INT): DNI del responsable (usado para JOIN)
- `ZONAL` (VARCHAR): Zonal JS (mapeado a `ZONAL JS`)
- `ACCION_1` (VARCHAR): Acción JS (mapeado a `ACCION JS`)
- `AÑO` (INT): Año del entregable
- `MES` (INT): Mes del entregable
- `ESTADO` (VARCHAR): Estado del entregable (debe ser 'ACTIVO')

**Filtros aplicados**:
- `AÑO = año`
- `MES = mes`
- `ESTADO = 'ACTIVO'`

**JOIN**: 
```sql
INNER JOIN ON CAST(VL.DNI_RESPONSABLE AS INT) = E.DNI_RESPONSABLE
```
> **Nota**: Se hace un CAST de `VL.DNI_RESPONSABLE` a INT para el JOIN.

### Agregaciones

La query agrupa por:
- `VL.FECHA`
- `E.ZONAL`
- `E.ACCION_1`
- `VL.DNI_RESPONSABLE`
- `VL.DNI_VENDEDOR`
- `VL.PRODUCT_NAME`

Y calcula:
- **Alta**: Conteo de registros donde `OPERATION_NAME = 'Alta'`
- **Portabilidad**: Conteo de registros donde `OPERATION_NAME = 'Portabilidad'`
- **Total general**: Suma de Alta + Portabilidad

### Estructura de Datos de Salida

**Modelo**: `VentasPostpago` (`excel_generator/domain/ventas_postpago.py`)

| Campo Python | Alias SQL | Tipo | Descripción |
|--------------|-----------|------|-------------|
| `fecha` | `FECHA` | date | Fecha de la venta |
| `zonal_js` | `ZONAL JS` | str | Zonal JS |
| `accion_js` | `ACCION JS` | str | Acción JS |
| `dni_responsable` | `DNI_RESPONSABLE` | int | DNI del responsable |
| `dni_vendedor` | `DNI_VENDEDOR` | int | DNI del vendedor |
| `product_name` | `PRODUCT_NAME` | str | Nombre del producto |
| `alta` | `Alta` | int | Cantidad de altas |
| `portabilidad` | `Portabilidad` | int | Cantidad de portabilidades |
| `total_general` | `Total general` | int | Total de altas + portabilidades |

### Separación de Datos

Los datos se separan en dos grupos para las hojas del Excel:
- **CIERRE POST**: `item.alta <= 2`
- **VENTAS INUSUALES**: `item.alta > 2`

---

## Paso 2: Generación de Bono Recargas Postpago

### Función: `generar_bono_recargas_postpago()`

**Ubicación**: `excel_generator/bono_recargas_postpago.py` (líneas 36-81)

**Propósito**: Genera un archivo Excel con los datos de abonos postpago desde la tabla `abonos_postpago_log`.

**Nombre del archivo generado**: `ABONOS_POSTPAGO_DD-DD MES.xlsx` (ej: `ABONOS_POSTPAGO_01-03 DICIEMBRE.xlsx`)

### Cálculo de Fechas

**Función**: `calcular_fechas_desde_dias()` (`excel_generator/genera_reportes_postpago.py`, líneas 82-106)

**Lógica**:
- Ordena la lista de días proporcionados
- `fecha_inicio` = fecha del día menor
- `fecha_fin` = fecha del día mayor

**Ejemplo**: Si `año=2025`, `mes=12`, `dias=[3,1,5]`:
- `fecha_inicio` = `2025-12-01`
- `fecha_fin` = `2025-12-05`

### Query SQL Ejecutada

**Ubicación**: `excel_generator/repositories/bono_recargas_postpago_repository.py` (líneas 29-50)

**Conexión**: `PORTAL_COMERCIAL` (servidor: 192.168.3.212\jsms)

**Query completa**:
```sql
SELECT
    FECHA,
    ZONAL_JS,
    ACCION_JS,
    CANAL,
    DNI_RESPONSABLE,
    NOMBRE_PDV,
    DNI_VENDEDOR,
    NOMBRE_VVDD,
    RECARGADOR,
    Alta,
    Portabilidad,
    TOTAL,
    BONO,
    ESTADO_ABONO,
    OBS
FROM
    PORTAL_COMERCIAL.dbo.abonos_postpago_log
WHERE
    fecha BETWEEN ? AND ?
```

### Parámetros de la Query

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| `?` (1) | `fecha_inicio` | Fecha de inicio del rango (DATE) |
| `?` (2) | `fecha_fin` | Fecha de fin del rango (DATE) |

### Tabla Utilizada

#### `PORTAL_COMERCIAL.dbo.abonos_postpago_log`

**Descripción**: Tabla que contiene los registros de abonos postpago calculados por el SP `sp_Registrar_AbonosPostpago`.

**Columnas utilizadas**:

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `FECHA` | DATE | Fecha del abono |
| `ZONAL_JS` | VARCHAR | Zonal JS |
| `ACCION_JS` | VARCHAR | Acción JS |
| `CANAL` | VARCHAR | Canal |
| `DNI_RESPONSABLE` | INT | DNI del responsable |
| `NOMBRE_PDV` | VARCHAR | Nombre del punto de venta |
| `DNI_VENDEDOR` | INT | DNI del vendedor |
| `NOMBRE_VVDD` | VARCHAR | Nombre del vendedor |
| `RECARGADOR` | VARCHAR | Recargador |
| `Alta` | INT | Cantidad de altas |
| `Portabilidad` | INT | Cantidad de portabilidades |
| `TOTAL` | INT | Total general |
| `BONO` | FLOAT | Monto del bono calculado |
| `ESTADO_ABONO` | VARCHAR | Estado del abono |
| `OBS` | VARCHAR | Observaciones |

**Filtros aplicados**:
- `fecha BETWEEN fecha_inicio AND fecha_fin`

> **Importante**: Esta tabla es **populada por el SP** `sp_Registrar_AbonosPostpago`. Si el SP no se ejecuta antes, esta tabla puede estar vacía o desactualizada para el período consultado.

### Estructura de Datos de Salida

**Modelo**: `BonoRecargasPostpago` (`excel_generator/domain/bono_recargas_postpago.py`)

| Campo Python | Alias SQL/Excel | Tipo | Descripción |
|--------------|-----------------|------|-------------|
| `fecha` | `FECHA` | date | Fecha del abono |
| `zonal_js` | `ZONAL JS` | str | Zonal JS |
| `accion_js` | `ACCION JS` | str | Acción JS |
| `canal` | `CANAL` | str | Canal |
| `dni_responsable` | `DNI_RESPONSABLE` | int | DNI del responsable |
| `nombre_pdv` | `NOMBRE PDV` | str | Nombre del PDV |
| `dni_vendedor` | `DNI QUE VENDIÓ` | int | DNI del vendedor |
| `nombre_vvdd` | `NOMBRE VVDD` | str | Nombre del vendedor |
| `recargador` | `RECARGADOR` | str | Recargador |
| `alta` | `Alta` | int | Cantidad de altas |
| `portabilidad` | `Portabilidad` | int | Cantidad de portabilidades |
| `total_general` | `Total general` | int | Total general |
| `bono` | ` BONO ` | float (opcional) | Monto del bono |
| `estado_abono` | ` ESTADO ABONO ` | str | Estado del abono |
| `obs` | `OBS` | str (opcional) | Observaciones |

---

## Resumen de Dependencias de Base de Datos

### Base de Datos
- **Nombre**: `PORTAL_COMERCIAL`
- **Servidor**: `192.168.3.212\jsms`
- **Usuario**: `SA`
- **Driver**: `ODBC Driver 17 for SQL Server`

### Tablas Utilizadas

| Tabla | Esquema | Uso |
|-------|---------|-----|
| `VentasLog` | `dbo` | Lectura: Obtiene ventas postpago agrupadas |
| `PDV_OUT_ENTREGABLE` | `dbo` | Lectura: Obtiene información de zonal y acción JS |
| `abonos_postpago_log` | `dbo` | Lectura/Escritura: Populada por el SP, leída para el reporte de bonos |

### Stored Procedures Utilizados

| Stored Procedure | Parámetros | Retorno | Uso |
|------------------|------------|---------|-----|
| `sp_Registrar_AbonosPostpago` | `@Año`, `@Mes`, `@DiasFiltro` | `RegistrosInsertados`, `Mensaje` | Calcula y registra bonos en `abonos_postpago_log` |

---

## Consideraciones para Cambios en el Backend

### 1. Dependencia del SP

El **Paso 2** (Bono Recargas Postpago) depende directamente de que el **Paso 0** (SP) se haya ejecutado previamente. Si el SP no se ejecuta, la tabla `abonos_postpago_log` puede no tener datos para el período consultado.

**Recomendación**: Si se modifica el backend para cambiar el flujo, asegurarse de que:
- El SP se ejecute antes de consultar `abonos_postpago_log`, o
- Se implemente una lógica alternativa para calcular los bonos si el SP no se ejecuta.

### 2. Estructura de la Tabla `abonos_postpago_log`

Esta tabla debe mantener la estructura de columnas documentada arriba. Si se modifica:
- Actualizar el modelo `BonoRecargasPostpago`
- Actualizar la query en `BonoRecargasPostpagoRepository`
- Actualizar el servicio de exportación si cambian los nombres de columnas del Excel

### 3. JOIN entre `VentasLog` y `PDV_OUT_ENTREGABLE`

El JOIN actual usa:
```sql
CAST(VL.DNI_RESPONSABLE AS INT) = E.DNI_RESPONSABLE
```

**Consideración**: Si `DNI_RESPONSABLE` en `VentasLog` cambia de tipo o formato, este JOIN puede fallar.

### 4. Filtros de Fecha

Ambas queries usan filtros de fecha:
- **Cierre Postpago**: Filtra por año, mes y días específicos usando `YEAR()`, `MONTH()`, `DAY()`
- **Bono Recargas**: Filtra por rango de fechas usando `BETWEEN`

**Consideración**: Si se cambia la estructura de fechas o se migra a otro sistema de fechas, actualizar ambos filtros.

### 5. Agregaciones en Cierre Postpago

La query de cierre postpago agrupa y suma operaciones. Si se cambia la lógica de negocio:
- Actualizar las condiciones `CASE WHEN` en la query
- Verificar que los campos `OPERATION_NAME` sigan siendo 'Alta' y 'Portabilidad'

### 6. Separación de Datos (Alta > 2)

El script separa los datos en dos hojas basándose en `Alta > 2`. Si esta regla cambia:
- Actualizar la lógica en `VentasPostpagoExportService._separar_datos()`

---

## Archivos de Salida Generados

### 1. Cierre Postpago
- **Ruta**: `output/CIERRE POSTPAGO LOG DD-MM.xlsx`
- **Hojas**: 
  - `CIERRE POST`
  - `VENTAS INUSUALES`

### 2. Bono Recargas Postpago
- **Ruta**: `output/ABONOS_POSTPAGO_DD-DD MES.xlsx`
- **Hoja**: `VENTAS POSTPAGO`
- **Plantilla**: Usa una plantilla Excel (debe existir en `templates/`)

---

## Ejemplo de Uso

```bash
# Ejecutar con SP (comportamiento por defecto)
python -m excel_generator.genera_reportes_postpago --año 2025 --mes 12 --dias 1,2,3

# Ejecutar sin SP (solo genera reportes)
python -m excel_generator.genera_reportes_postpago --año 2025 --mes 12 --dias 1,2,3 --sin-sp
```

---

## Notas Finales

- El script valida que los días proporcionados sean válidos para el mes especificado (considera años bisiestos)
- Todos los logs se escriben en la consola con formato estructurado
- Los errores se capturan y se relanzan con mensajes descriptivos
- La conexión a la base de datos se establece mediante `get_portal_comercial_connection()` en cada operación

