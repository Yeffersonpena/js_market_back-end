## sp_Stock_General - Documentación de cambios

### 1. Creación del SP sin precios

- **Fecha**: 2026-03-05
- **Procedimiento**: `sp_Stock_General`
- **Origen**: Copia basada en `sp_Stock_JS_Yali`.
- **Objetivo**: Obtener el stock unificado de JS (WOLAP) y YALI sin considerar información de precios de venta.

#### Cambios principales respecto a `sp_Stock_JS_Yali`

- Se eliminaron todas las referencias a **precio de venta**:
  - Se quitó la columna `PRECIO_VTA` de los `SELECT`.
  - Se eliminaron los `OUTER APPLY` a `[WOLAP_PRECIOS_DETALLISTA]` tanto en la parte JS como en la parte YALI.
- Se mantuvieron las columnas de **costo**:
  - `NCOSTO`
  - `COSTO` (en JS: `NCOSTO * 1.18`; en YALI: `Precio`).
- Se mantuvo la lógica de:
  - Cálculo de **edad** (`EDAD`) por rangos de días desde la fecha de compra/recepción.
  - Unión con `DCN_MAESTRO_PRODUCTO` para obtener `MARCA` y `MODELO` sin descartar registros (uso de `LEFT JOIN`).
  - Normalización de **ALMACEN** (HUÁNUCO / UCAYALI → PUCALLPA en YALI, etc.).

### 2. Uso de DCN_MAESTRO_PRODUCTO

- **Tabla**: `DISTRIBUTOR_DATAMART.dbo.DCN_MAESTRO_PRODUCTO`
- **Propósito**:
  - Proveer **MARCA** y **MODELO** normalizados por cada producto.
  - Evitar duplicados mediante un CTE con `ROW_NUMBER()` y tomando `rn = 1`.
- **Importante**:
  - El join hacia `DCN_MAESTRO_PRODUCTO` es siempre **`LEFT JOIN`**, por lo que:
    - **No se pierden registros de stock** por falta de match en el maestro.
    - En caso de no encontrar coincidencia, las columnas `MARCA` y `MODELO` quedan en `NULL`, pero la fila de stock igual se devuelve.

### 3. Consideración de almacenes en la parte JS (WOLAP_CONSULTA_SERIES)

- **Fuente**: `[192.168.3.101,1800\MSSQL_NEW].[Distribuidora].[dbo].[WOLAP_CONSULTA_SERIES]`.
- **Filtro de almacenes cuando `@almacen` es `NULL` o vacío**:

  ```sql
  AND (
      (
          @almacen IS NULL OR RTRIM(LTRIM(@almacen)) = ''
      )
      AND ( UPPER(LTRIM(RTRIM(w.ALMACEN))) IN (
          'AREQUIPA', 'AYACUCHO', 'CUSCO', 'E-COMMERCE', 'HUANCAYO', 'HUANUCO', 'HUÁNUCO',
          'ICA', 'LA MERCED', 'LIMA SUR', 'PUCALLPA', 'PUNO'
      ) OR UPPER(LTRIM(RTRIM(w.ALMACEN))) COLLATE Latin1_General_CI_AI = 'HUANUCO' )
      OR
      (
          @almacen IS NOT NULL AND RTRIM(LTRIM(@almacen)) <> ''
          AND UPPER(LTRIM(RTRIM(w.ALMACEN))) COLLATE Latin1_General_CI_AI = UPPER(LTRIM(RTRIM(@almacen))) COLLATE Latin1_General_CI_AI
      )
  )
  ```

- **Cambio clave**:
  - Se agregó explícitamente el almacén **`E-COMMERCE`** al listado de almacenes considerados por defecto, para alinear el comportamiento con la consulta utilizada en Power Query / Power BI que también incluía `E-COMMERCE` en el `IN` de almacenes.

### 4. Rangos de EDAD alineados con Power Query

- **Objetivo**: Que el día 15 y el resto de cortes coincidan con la consulta de Power Query (JS).
- **Power Query** define:
  - `[0-15 dias]`: `DATEDIFF(day, fcompra, GETDATE()) BETWEEN 0 AND 15`
  - `[15-30 dias]`: `> 15 AND <= 30`
  - `[30-70 dias]`: `> 30 AND <= 70`
  - `[70-90 dias]`: `> 70 AND <= 90`
  - `[Mas de 90 dias]`: `> 90`
- **Cambio en el SP** (parte JS y parte YALI):
  - Se reemplazó la lógica anterior (`< 15`, `<= 30`, etc.) por la misma regla que PQ:
    - `BETWEEN 0 AND 15` → `'0 - 15'`
    - `> 15 AND <= 30` → `'15 - 30'`
    - `> 30 AND <= 70` → `'30 - 70'`
    - `> 70 AND <= 90` → `'70 - 90'`
    - `ELSE` → `'> 90'`
  - Así el día 15 queda en el rango **0 - 15**, igual que en Power Query.

### 5. Columna CCOD_PROD (identificador de producto)

- **Objetivo**: Exponer el código de producto para poder agrupar en Excel igual que en las Power Query (JS agrupa por `ccod_prod`, Amazonía por `codigo`).
- **Cambios**:
  - **Parte JS**: Se agregó `RTRIM(LTRIM(CAST(w.CCOD_PROD AS VARCHAR(50)))) AS CCOD_PROD` (origen: `WOLAP_CONSULTA_SERIES.CCOD_PROD`).
  - **Parte YALI (Amazonía)**: Se agregó `CAST(y.Codigo AS VARCHAR(50)) AS CCOD_PROD` (origen: `YALI_STOCK.Codigo`).
- Ambas ramas del `UNION` devuelven la columna **CCOD_PROD** en el mismo orden, para poder agrupar por almacén + código de producto de forma alineada con las consultas de Power Query.

### 6. Alineamiento con la consulta de Power Query (JS)

- La consulta de Power Query usa como fuente `WOLAP_CONSULTA_SERIES` y filtra almacenes con una lista que incluye `E-COMMERCE`.
- `sp_Stock_General` ahora:
  - Usa la misma fuente de datos para JS.
  - Considera el mismo conjunto de almacenes por defecto (incluyendo `E-COMMERCE`).
  - Devuelve **CCOD_PROD** para agrupar por producto junto con ALMACEN; el detalle sigue siendo por serie (CSERIE).

### 7. Fecha usada en Amazonía (YALI): FechaFactura = Power Query

- **Referencia**: Consultas en `database/queries/STOCK_PQ.SQL` (Power Query JS y Amazonía).
- **Power Query Amazonía** calcula los rangos de días con **fechafactura**:  
  `DATEDIFF(day, fechafactura, GETDATE())` para 0-15, 15-30, 30-70, 70-90, >90.
- **Cambio aplicado** (solo parte YALI del SP):
  - Antes se usaba **FechaRecibido** para la columna `FCOMPRA`, `DIAS` y el `CASE` de `EDAD`.
  - Ahora se usa **FechaFactura** en los tres sitios, para que los rangos de antigüedad coincidan con la Power Query de Amazonía.
- **Tabla**: `DISTRIBUTOR_DATAMART.dbo.YALI_STOCK` — columnas `FechaFactura` y `FechaRecibido` (esta última ya no se usa en el SP para cálculo de edad).
- **Resumen**: En la parte YALI, `FCOMPRA`, `DIAS` y `EDAD` se calculan con `y.FechaFactura`. En la parte JS no se modificó nada (sigue usando `w.FCOMPRA` = fcompra, como la PQ JS).

#### Cómo revertir a FechaRecibido (solo si se necesita)

Si en algún momento se debe volver a medir la antigüedad por **fecha de recepción** en Amazonía:

1. Abrir `sp_Stock_General.sql` y localizar el bloque del segundo `SELECT` (parte YALI, tras `UNION ALL`).
2. En ese bloque, reemplazar **todas** las apariciones de `y.FechaFactura` por `y.FechaRecibido` en:
   - `CAST(y.FechaFactura AS DATE) AS FCOMPRA`
   - `DATEDIFF(day, y.FechaFactura, GETDATE()) AS DIAS`
   - Las cuatro líneas del `CASE` de `EDAD` (cada `DATEDIFF(day, y.FechaFactura, GETDATE())`).
3. Opcional: eliminar o ajustar el comentario que dice "FCOMPRA/DIAS/EDAD usan FechaFactura (igual que Power Query Amazonía...)".

Con eso el SP vuelve a usar **FechaRecibido** para la parte YALI; la documentación de este apartado 7 sigue siendo válida como historial del cambio.

### 8. Costo en Amazonía (YALI): CosteTotal = Power Query

- **Referencia**: Power Query Amazonía en `database/queries/STOCK_PQ.SQL` usa `AVG(costetotal)` por almacén + código.
- **Cambio aplicado** (solo parte YALI del SP):
  - Antes: `y.Precio AS NCOSTO`, `y.Precio AS COSTO`.
  - Ahora: `COALESCE(y.CosteTotal, y.Precio) AS NCOSTO`, `COALESCE(y.CosteTotal, y.Precio) AS COSTO`.
- Así los promedios de costo por almacén/código en Excel se alinean con la Power Query; si `CosteTotal` es NULL se usa `Precio` como respaldo.

#### Cómo revertir a solo Precio

En el segundo `SELECT` (parte YALI), reemplazar:
- `COALESCE(y.CosteTotal, y.Precio) AS NCOSTO` → `y.Precio AS NCOSTO`
- `COALESCE(y.CosteTotal, y.Precio) AS COSTO` → `y.Precio AS COSTO`

### 9. Almacén en Amazonía (nombre): sin cambio

- **Power Query Amazonía** usa `nombrepv AS ALMACEN` (valor crudo, ej. "YALI-LIMA").
- **SP**: se mantiene **ALMACEN normalizado** (quita prefijo "YALI-", UCAYALI→PUCALLPA, etc.). No se añade columna ALMACEN_PQ; la diferencia de nombre es manejo interno y se acepta como está.

