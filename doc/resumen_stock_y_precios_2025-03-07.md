# Resumen: Stock, Resumen Stock y Precios YALI (7 mar 2025)

Documento de contexto para continuar en otro equipo. Recoge lo hablado y los cambios hechos hoy sobre `sp_Stock_General`, `sp_Resumen_Stock`, precios YALI y consultas de validación.

---

## 1. SP Stock General (`sp_Stock_General.sql`)

### Match de series YALI con traslados
- **Origen stock:** `YALI_STOCK` (columna `IMEI` = serie).
- **Origen traslados:** `YALI_SERIES_TRASLADOS` (columnas `CSERIE`, `ALMACEN`).
- **Match:** `y.IMEI = t.CSERIE` (LEFT JOIN).
- Si hay match se usa `t.ALMACEN`; si no, `REPLACE(y.NombrePV, 'YALI-', '')`. Normalizaciones: UCAYALI → PUCALLPA, HUANUCO.

### Maestro de productos (MARCA / MODELO)
- **DCN_MAESTRO_PRODUCTO** se usa para **JS y Amazonía**.
- En la rama YALI: join por `y.Modelo` (normalizado) = `maestro.CNOM_PROD` (normalizado); de ahí salen MARCA y MODELO.

### Pendiente (mañana)
- El almacén **PICHANAQUI** debe quedar como **LA MERCED** en el resultado (mapeo tipo UCAYALI→PUCALLPA).

---

## 2. SP Resumen Stock (`sp_Resumen_Stock.sql`)

### Relación con tabla dinámica en Excel
- Si se exporta el resultado de `sp_Stock_General` a Excel y se hace tabla dinámica: **Empresa** y **nombre producto** en filas, **Edad** en columnas, **cuenta de IMEI/CSERIE** en valores → equivale al resumen del SP **solo si** en filas se usa **COALESCE(MODELO, CNOM_PROD)** (no solo CNOM_PROD), porque el SP agrupa por eso.

### Agrupación por producto
- En el SELECT final se agrupa por **EMPRESA** y **COALESCE(MODELO, CNOM_PROD)**.
- **Por qué:** MODELO viene del maestro (nombre corto); CNOM_PROD puede tener variantes (color, capacidad). Varios CNOM_PROD comparten el mismo MODELO y deben ir en una sola fila. Si no hay modelo en el maestro, MODELO es NULL y se usa CNOM_PROD.

### Columna MODELO en el resultado
- Se cambió de `COALESCE(MODELO, CNOM_PROD) AS MODELO` a **MAX(MODELO) AS MODELO**.
- Así se muestra el modelo real y **NULL** cuando el producto no tiene modelo en el maestro (regla de negocio: todos deben tener marca y modelo).
- Se usa MAX(MODELO) por las reglas de GROUP BY: lo que no está en el GROUP BY debe ir en una agregación.

### Match de precios en el SP
- **JS:** por **CCOD_PROD + ALMACEN** contra `#PreciosJS` (linked 1800, WOLAP_PRECIOS_DETALLISTA). RTRIM/LTRIM en código y tipo venta.
- **YALI (Amazonía):** dos pasos contra `#PreciosYali` (linked 1900):
  1. **Paso 1:** match por **CNOM_PROD** (nombre en stock): `precios.CNOM_PROD LIKE base.CNOM_PROD + '%'`, MAX(PRECIO).
  2. **Paso 2:** solo si quedó NULL, match por **MODELO** (maestro): `precios.CNOM_PROD LIKE base.MODELO + '%'`, MAX(PRECIO).

### Espacios en linked de precios
- En los INSERT a `#PreciosJS` y `#PreciosYali` se aplica **RTRIM(LTRIM(...))** (y REPLACE de `&quot;`) a los campos que vienen del linked.
- En el JOIN de precios JS se normalizan ambos lados: CCOD_PROD y ALMACEN / TIPO_VENTA_NORM con RTRIM/LTRIM e ISNULL.

---

## 3. Precios YALI: nombre vs modelo y problema 4GB vs 4+

### Orden acordado
- Primero match por **nombre de producto (CNOM_PROD)**.
- Si no hay precio, segundo match por **MODELO** (maestro).

### Por qué a veces no hay match
- En **YALI_STOCK** el campo **Modelo** es el **nombre completo** del producto (ej. "REDMI 15C 4GB+256GB BLACK").
- En **maestro:** CNOM_PROD = "REDMI 15C 4GB+256GB BLACK", MODELO = "REDMI 15C 4GB+256GB".
- En **precios (linked 1900):** "REDMI 15C 4**+**256GB BLACK" (escrito **4+256GB**).
- El SP usa CNOM_PROD y MODELO tal como vienen de stock/maestro; si ahí está "4**GB+**256" y en precios "4**+**256", el `LIKE` no coincide → PRECIO_VTA NULL. Para que coincida habría que normalizar esa variación (ej. 4GB+ ↔ 4+) en el match.

### Query de simulación de precio YALI
- Query donde se declara `@nombreProducto` y se devuelve CNOM_PROD, MARCA, MODELO, PRECIO: maestro por nombre (exacto o prefijo) + precios por `precios.CNOM_PROD LIKE @nombreProducto + '%'`, MAX(PRECIO). Útil para probar un producto concreto.

---

## 4. Validación: productos sin MARCA/MODELO

- **Objetivo:** Antes de ejecutar reportes, validar que todos tengan marca y modelo.
- **Query 1:** Productos en stock (JS + Amazonía) **sin MARCA o sin MODELO**, misma base que `sp_Stock_General`, agrupados por producto con cuenta de series. Filtro **línea EQUIPOS** (JS por LINEA, YALI por Tipo = 'equipos').
- **Query 2:** Productos en **DCN_MAESTRO_PRODUCTO** con MARCA o MODELO en blanco/NULL.
- Ubicación lógica: en `database/procedures/distributor/` o en un script de validación (ej. referencia en PRODCUSTO SIN MARCA.SQL).

---

## 5. Productos YALI que no hacen match con precios

- **Objetivo:** Listar productos YALI que, con la misma lógica del SP, no obtienen precio (para revisar si es por nombre o por no estar en precios).
- **Archivo:** `database/queries/YALI_productos_sin_precio.sql`
- **Lógica:** Misma base que `sp_Stock_General` (join a traslados, mismo cálculo de ALMACEN, misma condición de línea y almacén). Mismo match que `sp_Resumen_Stock`: paso 1 por CNOM_PROD, paso 2 por MODELO. Se listan solo productos con PRECIO_VTA NULL.
- **Parámetros:** `@linea = 'EQUIPOS'`, `@almacen = NULL` (todo completo; para zonal se puede poner ej. `'PICHANAQUI'`).
- **Importante:** Con `@linea = 'EQUIPOS'` el SP **no** filtra por `y.Tipo` en la rama YALI (la condición se cumple por `LOWER(@linea) = 'equipos'`), así que entran todos los tipos (Equipos, Exclusivo, etc.). La query debe replicar eso y el filtro de almacén (join a YALI_SERIES_TRASLADOS y normalización UCAYALI/HUANUCO) para que el conjunto de productos coincida con el SP.

---

## 6. Linked server de precios YALI

- **Servidor:** `[192.168.3.101,1900\MSSQL_log]`
- **Tabla:** `[Distribuidora].[dbo].[WOLAP_PRECIOS_DETALLISTA]`
- Power Query: conexión a `192.168.3.212\jsms`, base `distributor_datamart`, con query que hace `SELECT *` desde ese linked. El SP usa la misma tabla.

---

## 7. Rendimiento de `sp_Resumen_Stock`

### Por qué era lento (~30 s vs ~2 s de `sp_Stock_General`)
- `sp_Stock_General` solo carga stock (linked 1800 + local).
- `sp_Resumen_Stock` además: (1) dos lecturas a linked (precios JS y YALI), (2) dos UPDATEs con OUTER APPLY que, **por cada fila** de #Base (por serie), escaneaban #PreciosYali con LIKE → coste del orden de N×P.

### Optimización aplicada
- **YALI:** En lugar de OUTER APPLY por cada fila de #Base:
  1. Se obtienen los **productos distintos** de Amazonía (CNOM_PROD, MODELO).
  2. Se calcula el precio **una vez por producto** (COALESCE(paso1 por CNOM_PROD, paso2 por MODELO) y se guarda en **#PreciosYaliAsignados**.
  3. Un **solo UPDATE** hace JOIN de #Base con #PreciosYaliAsignados para asignar PRECIO_VTA.
- Mismo resultado; mucho menos trabajo (solo un like por producto distinto, no por serie).

---

## 8. Archivos tocados hoy

| Archivo | Cambios |
|--------|---------|
| `database/procedures/distributor/sp_Resumen_Stock.sql` | MAX(MODELO); RTRIM/LTRIM e ISNULL en precios JS/YALI y en JOIN JS; dos pasos YALI (CNOM_PROD luego MODELO); optimización precios YALI por producto distinto (#PreciosYaliAsignados + un UPDATE). |
| `database/queries/YALI_productos_sin_precio.sql` | Creado: misma base y match que los SP, parámetros @linea y @almacen (por defecto EQUIPOS y NULL). |

---

## 9. Pendiente

- **sp_Stock_General:** Mapear almacén **PICHANAQUI** → **LA MERCED** (igual que UCAYALI→PUCALLPA) en el CASE del ALMACEN de la rama YALI.
