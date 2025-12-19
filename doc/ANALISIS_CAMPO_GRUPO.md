# Análisis Completo: Campo GRUPO de PDV_OUT_ENTREGABLE

## Resumen Ejecutivo
El campo `GRUPO` de la tabla `PDV_OUT_ENTREGABLE` se utiliza en múltiples partes del sistema para:
- **Filtrado de campañas de flyers** (sincronización de imágenes)
- **Cálculo de incentivos diarios** (premios por grupo)
- **Visualización de información del vendedor** (como CLUSTER_PDV_REGULAR)
- **APIs de listado y gestión** (obtener lista de grupos disponibles)
- **Gestión de entregables** (crear/actualizar registros)

---

## 1. STORED PROCEDURES

### 1.1 `sp_Sincronizar_Flyers.sql`
**Ubicación**: `database/procedures/sp_Sincronizar_Flyers.sql`
**Líneas**: 113-118

**Uso**: Filtra qué responsables reciben qué flyers basándose en el GRUPO

```sql
-- Validar GRUPO exacto (soporta grupos concatenados como G1,G2,G3)
AND (
    e.GRUPO = c.criterio_filtro
    OR (',' + c.criterio_filtro + ',' LIKE '%,' + e.GRUPO + ',%')
    OR (', ' + c.criterio_filtro + ', ' LIKE '%, ' + e.GRUPO + ', %')
)
```

**Descripción**:
- Compara el `GRUPO` del entregable con el `criterio_filtro` de la campaña
- Soporta grupos concatenados (ej: "G1,G2,G3" en criterio_filtro)
- Se usa solo para modo 'PDV' (no para MULTIMARCA)

---

### 1.2 `spSeguimientoIncentivosDiarios.sql`
**Ubicación**: `database/procedures/spSeguimientoIncentivosDiarios.sql`
**Líneas**: 81, 97, 111, 126, 139, 176, 197

**Uso**: Calcula premios diarios basándose en el GRUPO del vendedor

**Puntos clave**:
- **Línea 81**: Normaliza el GRUPO a mayúsculas: `UPPER(LTRIM(RTRIM(e.GRUPO))) AS GRUPO`
- **Línea 97**: Agrupa por GRUPO: `MAX(GRUPO) AS GRUPO`
- **Línea 111**: Incluye GRUPO en la base de datos: `e.GRUPO`
- **Línea 126**: Usa GRUPO para join con reglas: `b.GRUPO`
- **Línea 139**: Filtra reglas por GRUPO: `rg.Grupo = b.GRUPO`
- **Línea 176**: Retorna GRUPO en resultado: `b.GRUPO`
- **Línea 197**: Ordena por GRUPO: `ORDER BY b.ZONAL_NORMALIZADO, b.GRUPO, b.NOMBRE_RESPONSABLE`

**Descripción**:
- Une el GRUPO del entregable con las reglas de `tbl_incentivos_diarios`
- Las reglas tienen grupos como "G1,G2" que se expanden con STRING_SPLIT
- Determina qué premios gana cada vendedor según su GRUPO y zonal

---

### 1.3 `spViewInfoVendedor.sql`
**Ubicación**: `database/procedures/spViewInfoVendedor.sql`
**Línea**: 73

**Uso**: Muestra el GRUPO como CLUSTER_PDV_REGULAR

```sql
E.GRUPO AS CLUSTER_PDV_REGULAR,
```

**Descripción**:
- El GRUPO se expone como "CLUSTER_PDV_REGULAR" en la información del vendedor
- Se usa para identificar el tipo/cluster del PDV

---

### 1.4 `spGetListGroup.sql`
**Ubicación**: `assetsSql/Sp/spGetListGroup.sql`
**Líneas**: 8-12

**Uso**: Obtiene lista de grupos únicos del último período

```sql
SELECT DISTINCT e.GRUPO
FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e
JOIN UltimoPeriodo u
  ON e.año = u.año AND e.mes = u.mes
WHERE e.GRUPO IS NOT NULL ORDER BY e.GRUPO;
```

**Descripción**:
- Retorna todos los grupos únicos del último período cargado
- Se usa en APIs para poblar dropdowns de selección de grupos

---

### 1.5 `spLoadFileEntregable_new.SQL`
**Ubicación**: `database/procedures/spLoadFileEntregable_new.SQL`
**Líneas**: 14, 24, 38

**Uso**: Inserta/actualiza el campo GRUPO al cargar archivos de entregable

**Línea 14**: Incluye GRUPO en el INSERT
```sql
[GRUPO],
```

**Línea 24**: Mapea desde tabla temporal
```sql
[GRUPOS],  -- Campo de origen: GRUPOS (plural)
```

**Línea 38**: Incluye GRUPO en historial
```sql
[GRUPO],
```

**Descripción**:
- Al cargar un archivo Excel de entregable, el campo `GRUPOS` (plural) se mapea a `GRUPO` (singular)
- Se guarda en la tabla principal y en el historial

---

## 2. VIEWS

### 2.1 `VI_AVANCES_INFO_VENDEDOR.sql`
**Ubicación**: `assetsSql/View/VI_AVANCES_INFO_VENDEDOR.sql`
**Línea**: 54

**Uso**: Expone GRUPO como CLUSTER_PDV_REGULAR

```sql
E.GRUPO AS 'CLUSTER_PDV_REGULAR',
```

**Descripción**:
- Vista que muestra información del vendedor incluyendo su GRUPO como cluster

---

## 3. CONTROLADORES PHP (Laravel)

### 3.1 `ImagenController.php`
**Ubicación**: `app/Http/Controllers/Admin/ImagenController.php`
**Líneas**: 210-217

**Uso**: Mapea número de grupo a valor de GRUPO al crear campañas

```php
$grupoMapping = [
    1 => "G1",
    2 => "G2",
    3 => "G3",
    4 => "PDV PREMIUM"
];
$grupoNumber = (int) ($request->input('group') ?? 0);
$pictureGroup = $grupoMapping[$grupoNumber] ?? null;
```

**Descripción**:
- Convierte un número (1-4) del frontend al valor de GRUPO correspondiente
- Se guarda en `criterio_filtro` de `PDV_OUT_CAMPAÑAS_FLYERS`
- Este criterio_filtro se compara con `GRUPO` en `sp_Sincronizar_Flyers`

---

### 3.2 `AdminController.php`
**Ubicación**: `app/Http/Controllers/Admin/AdminController.php`
**Líneas**: 18-19

**Uso**: API para obtener lista de grupos disponibles

```php
SELECT DISTINCT e.GRUPO FROM dbo.PDV_OUT_ENTREGABLE e
JOIN UltimoPeriodo u ON e.año = u.año AND e.mes = u.mes
WHERE e.GRUPO IS NOT NULL ORDER BY e.GRUPO;
```

**Descripción**:
- Endpoint que retorna todos los grupos únicos del último período
- Usado por el frontend para poblar selectores de grupos

---

### 3.3 `ConfigController.php`
**Ubicación**: `app/Http/Controllers/Admin/Config/ConfigController.php`
**Líneas**: 18-19

**Uso**: Misma funcionalidad que AdminController - lista de grupos

```php
SELECT DISTINCT e.GRUPO FROM dbo.PDV_OUT_ENTREGABLE e
JOIN UltimoPeriodo u ON e.año = u.año AND e.mes = u.mes
WHERE e.GRUPO IS NOT NULL ORDER BY e.GRUPO;
```

---

### 3.4 `GestorEntregableController.php`
**Ubicación**: `app/Http/Controllers/Admin/GestorEntregableController.php`
**Líneas**: 61, 147

**Uso**: Crear y actualizar el campo GRUPO de entregables

**Línea 61** (Crear):
```php
$createEntregable->GRUPO = $request->grupo;
```

**Línea 147** (Actualizar):
```php
$updateEntregable->GRUPO = $request->grupo;
```

**Descripción**:
- Permite crear/editar entregables desde la interfaz admin
- El campo GRUPO se puede establecer manualmente

---

## 4. TABLAS RELACIONADAS

### 4.1 `tbl_incentivos_diarios`
**Ubicación**: `database/tables/tbl_incentivos_diarios.sql`
**Campo**: `grupos` (VARCHAR(50))

**Uso**: Define reglas de premios por grupos

**Ejemplos de valores**:
- `'G1,G2'` - Para grupos G1 y G2
- `'G3,G4'` - Para grupos G3 y G4
- `'G1,G2,G3,G4'` - Para todos los grupos

**Descripción**:
- Esta tabla define qué premios se otorgan según el GRUPO del vendedor
- Se usa en `spSeguimientoIncentivosDiarios` para calcular premios diarios
- Los grupos pueden ser concatenados con comas

---

### 4.2 `PDV_OUT_CAMPAÑAS_FLYERS`
**Ubicación**: `database/tables/PDV_OUT_CAMPAÑAS_FLYERS.sql`
**Campo**: `criterio_filtro` (VARCHAR(500))

**Uso**: Almacena el criterio de filtro que se compara con GRUPO

**Descripción**:
- Cuando se crea una campaña de flyers, el `criterio_filtro` puede contener valores como "G1", "G2", "G1,G2", etc.
- Este valor se compara con `PDV_OUT_ENTREGABLE.GRUPO` en `sp_Sincronizar_Flyers`
- Determina qué responsables reciben qué imágenes

---

## 5. ÍNDICES

### 5.1 Índice compuesto en PDV_OUT_ENTREGABLE
**Ubicación**: `database/tables/PDV_OUT_ENTREGABLE.sql`
**Línea**: 60

```sql
CREATE NONCLUSTERED INDEX IX_ENTREGABLE_DNI_ACCION
ON PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE
(DNI_VENDEDOR ASC, DNI_RESPONSABLE ASC, ACCION_2 ASC, GRUPO ASC)
```

**Descripción**:
- Índice que incluye GRUPO para optimizar búsquedas
- Usado en queries que filtran por DNI y GRUPO

---

### 5.2 Índice con INCLUDE
**Ubicación**: `database/tables/PDV_OUT_ENTREGABLE.sql`
**Línea**: 57

```sql
CREATE NONCLUSTERED INDEX IDX_PDV_OUT_ENTREGABLE
ON PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE (DNI_RESPONSABLE ASC)
INCLUDE (ACCION_1, ACCION_2, CELULAR_VENDEDOR, CUOTA_PREPAGO, GRUPO, ...)
```

**Descripción**:
- GRUPO está incluido en el índice para evitar lookups adicionales
- Optimiza queries que filtran por DNI_RESPONSABLE y necesitan GRUPO

---

## 6. VALORES POSIBLES DE GRUPO

Según el análisis del código, los valores comunes son:
- `"G1"` - Grupo 1
- `"G2"` - Grupo 2
- `"G3"` - Grupo 3
- `"G4"` - Grupo 4
- `"PDV PREMIUM"` - PDV Premium
- `NULL` - Sin grupo asignado

**Nota**: Los valores pueden estar concatenados en `criterio_filtro` de campañas (ej: "G1,G2,G3")

---

## 7. FLUJOS PRINCIPALES

### 7.1 Flujo de Sincronización de Flyers
1. Se crea una campaña en `PDV_OUT_CAMPAÑAS_FLYERS` con `criterio_filtro = "G1"` (por ejemplo)
2. Se ejecuta `sp_Sincronizar_Flyers(@año, @mes)`
3. El SP compara `PDV_OUT_ENTREGABLE.GRUPO = "G1"` con `criterio_filtro = "G1"`
4. Si coinciden, se inserta un registro en `PDV_OUT_FLYERS` para ese responsable

### 7.2 Flujo de Incentivos Diarios
1. Se ejecuta `spSeguimientoIncentivosDiarios(@Fecha, @ZonalFiltro)`
2. Se obtiene el `GRUPO` de cada vendedor desde `PDV_OUT_ENTREGABLE`
3. Se expanden las reglas de `tbl_incentivos_diarios` (que tienen grupos como "G1,G2")
4. Se hace JOIN entre el GRUPO del vendedor y las reglas
5. Se calculan los premios según las reglas cumplidas

### 7.3 Flujo de Carga de Entregable
1. Se carga un archivo Excel con la columna `GRUPOS` (plural)
2. Se ejecuta `spLoadFileEntregable_new(@año, @mes)`
3. El campo `GRUPOS` se mapea a `GRUPO` (singular) en la tabla
4. Se guarda en `PDV_OUT_ENTREGABLE` y en `tbl_history_entregable`

---

## 8. CONSIDERACIONES IMPORTANTES

### 8.1 Comparación con RANGO
- **GRUPO**: Se usa para filtrado de flyers e incentivos (valores: G1, G2, G3, G4, PDV PREMIUM)
- **RANGO**: Se usa para bonos por rango (valores: RANGO 1, RANGO 2, ..., RANGO 8)
- **Son campos diferentes** con propósitos diferentes

### 8.2 Normalización
- En `spSeguimientoIncentivosDiarios` se normaliza a mayúsculas: `UPPER(LTRIM(RTRIM(e.GRUPO)))`
- Se recomienda mantener consistencia en los valores almacenados

### 8.3 Soporte de Múltiples Grupos
- `criterio_filtro` puede contener múltiples grupos: "G1,G2,G3"
- La comparación en `sp_Sincronizar_Flyers` soporta esto con LIKE
- `tbl_incentivos_diarios` también usa grupos concatenados

---

## 9. ARCHIVOS MODIFICADOS RECIENTEMENTE

Los siguientes archivos fueron modificados/creados recientemente y usan GRUPO:
- `INSERT_Flyers_Rangos_Emergencia.sql` - Insert de emergencia (usa RANGO, no GRUPO)
- `INSERT_Campanas_Flyers_Rangos.sql` - Insert de campañas (usa criterio_filtro con RANGO)

**Nota**: Los archivos de emergencia usan **RANGO** en lugar de **GRUPO**, lo cual es un cambio de lógica.

---

## 10. RECOMENDACIONES

1. **Mantener consistencia**: Asegurar que los valores de GRUPO sean consistentes (mayúsculas, sin espacios extra)
2. **Documentar valores**: Documentar qué valores de GRUPO son válidos
3. **Validación**: Agregar validación al crear/actualizar entregables para asegurar valores válidos
4. **Migración RANGO vs GRUPO**: Si se va a migrar de GRUPO a RANGO, actualizar todos los stored procedures y vistas mencionados

---

## CONCLUSIÓN

El campo `GRUPO` es **crítico** en el sistema y se usa en:
- ✅ 5+ stored procedures
- ✅ 1 vista
- ✅ 4+ controladores PHP
- ✅ 2 tablas relacionadas
- ✅ 2 índices de base de datos

Cualquier cambio en este campo requiere actualizar múltiples componentes del sistema.

