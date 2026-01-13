# Tablas de Programación de Visitas PDV ELOT (Loterías)

## Descripción General

Este conjunto de tablas almacena la programación mensual de visitas a puntos de venta ELOT (Loterías). A diferencia de AD (Tecnología), ELOT utiliza un modelo de programación por **días de la semana** en lugar de fechas específicas.

**Característica Principal:** Todos los lunes del mes se visitan los mismos puntos, todos los martes los mismos puntos, etc. Es un patrón semanal recurrente.

**Base de Datos:** Estas tablas se encuentran en la base de datos **ELOT** (no en la base de datos principal).

## Estructura de Tablas

### 1. PDV_VISITAS_ELOT_PROGRAMACION
Tabla principal que almacena la programación mensual de cada PDV ELOT.

**Características:**
- Una fila por cada PDV ELOT programado en un mes específico
- Contiene todos los datos del PDV (del Excel original)
- Relación 1:N con `PDV_VISITAS_ELOT_DIAS_SEMANA`

**Clave Primaria:** `id` (auto-increment)
**Clave Única:** `(DNI, AÑO, MES)` - Evita duplicados

**Campos Principales:**
- `DNI`: Identificador del punto ELOT (equivalente a DNI_RESPONSABLE en AD)
- `AÑO`, `MES`: Período de la programación
- Datos del PDV: COD_CLIENTE, ID_ELOT, RAZON_SOCIAL, DIRECCION, coordenadas, etc.
- Metadatos: STATUS, STATUS_IMPLEMENTO, COMENTARIOS

**Diferencias con AD:**
- Usa `DNI` en lugar de `DNI_RESPONSABLE`
- Usa `RAZON_SOCIAL` en lugar de `NOMBRE_PUNTO`
- Tiene `ID_ELOT` específico para ELOT
- Tiene `STATUS_IMPLEMENTO` adicional

### 2. PDV_VISITAS_ELOT_DIAS_SEMANA
Tabla que almacena los días de la semana programados para cada PDV ELOT.

**Características:**
- Una fila por cada día de semana programado
- Permite consultas eficientes por día de semana (Lunes, Martes, etc.)
- Facilita comparación VS con visitas realizadas

**Clave Primaria:** `id` (auto-increment)
**Clave Única:** `(programacion_id, DIA_SEMANA)` - Evita duplicar el mismo día de semana

**Campos Principales:**
- `programacion_id`: FK a PDV_VISITAS_ELOT_PROGRAMACION
- `DIA_SEMANA`: Día de la semana (1=Lunes, 2=Martes, 3=Miércoles, 4=Jueves, 5=Viernes, 6=Sábado)
- `PROGRAMADO`: BIT indicando si está programado (1) o no (0)

**Diferencias con AD:**
- Usa `DIA_SEMANA` (1-6) en lugar de `DIA_MES` (1-31)
- **NO tiene** `FECHA_COMPLETA` (no hay fechas específicas)
- **NO tiene** `es_extraordinario` (el patrón es siempre semanal)

## Casos de Uso

### 1. Consulta del Calendario (Frontend)
Obtener todos los PDVs ELOT a visitar en un día específico (ej: lunes 6 de enero de 2025):

```sql
-- Obtener todos los lunes de enero 2025
SELECT
    pv.DNI,
    pv.RAZON_SOCIAL,
    pv.DIRECCION,
    pv.VENDEDOR,
    pv.ZONAL,
    pv.RUTA,
    vd.DIA_SEMANA
FROM ELOT.dbo.PDV_VISITAS_ELOT_PROGRAMACION pv
INNER JOIN ELOT.dbo.PDV_VISITAS_ELOT_DIAS_SEMANA vd ON pv.id = vd.programacion_id
WHERE pv.AÑO = 2025
  AND pv.MES = 1
  AND vd.DIA_SEMANA = 1 -- 1 = Lunes
  AND vd.PROGRAMADO = 1
  AND pv.STATUS = 'AGENTE' -- o el status que corresponda
  AND DATEPART(WEEKDAY, '2025-01-06') = 2; -- Verificar que la fecha sea lunes
```

**Nota:** En SQL Server, `DATEPART(WEEKDAY, fecha)` devuelve:
- 1 = Domingo
- 2 = Lunes
- 3 = Martes
- ...
- 7 = Sábado

### 2. Exportar Excel Diario
Para exportar los PDVs a visitar un día específico:

```sql
-- Ejemplo: Exportar todos los lunes de enero 2025
SELECT
    pv.DNI,
    pv.COD_CLIENTE,
    pv.ID_ELOT,
    pv.ZONAL,
    pv.DISTRITO,
    pv.PROVINCIA,
    pv.DEPARTAMENTO,
    pv.RAZON_SOCIAL,
    pv.DIRECCION,
    pv.LATITUD,
    pv.LONGITUD,
    pv.TELEFONO,
    pv.COD_VVDD,
    pv.MODULO,
    pv.NEW_MODULO,
    pv.RUTA,
    pv.VENDEDOR,
    CASE vd.DIA_SEMANA
        WHEN 1 THEN 'LUNES'
        WHEN 2 THEN 'MARTES'
        WHEN 3 THEN 'MIÉRCOLES'
        WHEN 4 THEN 'JUEVES'
        WHEN 5 THEN 'VIERNES'
        WHEN 6 THEN 'SÁBADO'
    END AS DIA_SEMANA_NOMBRE
FROM ELOT.dbo.PDV_VISITAS_ELOT_PROGRAMACION pv
INNER JOIN ELOT.dbo.PDV_VISITAS_ELOT_DIAS_SEMANA vd ON pv.id = vd.programacion_id
WHERE pv.AÑO = 2025
  AND pv.MES = 1
  AND vd.DIA_SEMANA = 1 -- Lunes
  AND vd.PROGRAMADO = 1
ORDER BY pv.ZONAL, pv.VENDEDOR, pv.RAZON_SOCIAL;
```

### 3. Comparación VS (Programado vs Realizado)
Comparar qué se programó vs qué se visitó realmente:

```sql
-- Comparar programado vs realizado para un día específico
SELECT
    pv.DNI,
    pv.RAZON_SOCIAL,
    vd.DIA_SEMANA,
    CASE vd.DIA_SEMANA
        WHEN 1 THEN 'LUNES'
        WHEN 2 THEN 'MARTES'
        WHEN 3 THEN 'MIÉRCOLES'
        WHEN 4 THEN 'JUEVES'
        WHEN 5 THEN 'VIERNES'
        WHEN 6 THEN 'SÁBADO'
    END AS DIA_SEMANA_NOMBRE,
    vr.FECHA AS FECHA_REALIZADA,
    CASE
        WHEN vr.FECHA IS NOT NULL THEN 'REALIZADO'
        ELSE 'PENDIENTE'
    END AS ESTADO
FROM ELOT.dbo.PDV_VISITAS_ELOT_PROGRAMACION pv
INNER JOIN ELOT.dbo.PDV_VISITAS_ELOT_DIAS_SEMANA vd ON pv.id = vd.programacion_id
LEFT JOIN VISITAS_REALIZADAS vr
    ON pv.DNI = vr.DNI
    AND DATEPART(WEEKDAY, vr.FECHA) = vd.DIA_SEMANA + 1 -- Ajuste para SQL Server
    AND YEAR(vr.FECHA) = pv.AÑO
    AND MONTH(vr.FECHA) = pv.MES
WHERE pv.AÑO = 2025
  AND pv.MES = 1
  AND vd.DIA_SEMANA = 1 -- Lunes
  AND vd.PROGRAMADO = 1;
```

### 4. Obtener Todos los Días Programados de un PDV
Ver qué días de la semana se visita un PDV específico:

```sql
SELECT
    pv.RAZON_SOCIAL,
    CASE vd.DIA_SEMANA
        WHEN 1 THEN 'LUNES'
        WHEN 2 THEN 'MARTES'
        WHEN 3 THEN 'MIÉRCOLES'
        WHEN 4 THEN 'JUEVES'
        WHEN 5 THEN 'VIERNES'
        WHEN 6 THEN 'SÁBADO'
    END AS DIA_SEMANA_NOMBRE,
    vd.PROGRAMADO
FROM ELOT.dbo.PDV_VISITAS_ELOT_PROGRAMACION pv
INNER JOIN ELOT.dbo.PDV_VISITAS_ELOT_DIAS_SEMANA vd ON pv.id = vd.programacion_id
WHERE pv.DNI = @dni
  AND pv.AÑO = @año
  AND pv.MES = @mes
  AND vd.PROGRAMADO = 1
ORDER BY vd.DIA_SEMANA;
```

## Índices

### PDV_VISITAS_ELOT_PROGRAMACION
- `IX_PDV_VISITAS_ELOT_PROG_DNI_AÑO_MES`: Búsquedas por PDV y período
- `IX_PDV_VISITAS_ELOT_PROG_VENDEDOR`: Filtros por vendedor
- `IX_PDV_VISITAS_ELOT_PROG_ZONAL`: Filtros por zonal
- `IX_PDV_VISITAS_ELOT_PROG_STATUS`: Filtros por estado

### PDV_VISITAS_ELOT_DIAS_SEMANA
- `IX_PDV_VISITAS_ELOT_DIAS_SEMANA`: **CRÍTICO** - Consultas del calendario por día de semana
- `IX_PDV_VISITAS_ELOT_DIAS_PROGRAMACION`: Consultas por programación específica
- `IX_PDV_VISITAS_ELOT_DIAS_PROGRAMADO`: Índice filtrado para días programados activos

## Proceso de Importación desde Excel

1. **Python lee Excel** y transforma estructura:
   - Para cada fila del Excel (PDV ELOT)
   - Insertar en `ELOT.dbo.PDV_VISITAS_ELOT_PROGRAMACION` (obtener el `id` generado)
   - Leer columnas de días: LUNES, MARTES, MIÉRCOLES, JUEVES, VIERNES, SÁBADO
   - Para cada día con valor = 1:
     - Mapear: LUNES=1, MARTES=2, MIÉRCOLES=3, JUEVES=4, VIERNES=5, SÁBADO=6
     - Insertar en `ELOT.dbo.PDV_VISITAS_ELOT_DIAS_SEMANA` con `DIA_SEMANA` correspondiente

2. **Stored Procedure procesa** (futuro: `spLoadFileProgramacionVisitasELOT`):
   - Validar datos
   - Eliminar programación existente del mismo AÑO/MES
   - Insertar nuevos registros

## Mapeo de Días de la Semana

| Columna Excel | DIA_SEMANA | Valor |
|---------------|------------|-------|
| LUNES | 1 | Lunes |
| MARTES | 2 | Martes |
| MIÉRCOLES | 3 | Miércoles |
| JUEVES | 4 | Jueves |
| VIERNES | 5 | Viernes |
| SÁBADO | 6 | Sábado |

**Nota:** No se programa domingo (día 7).

## Diferencias Clave con AD

| Aspecto | AD (Tecnología) | ELOT (Loterías) |
|---------|-----------------|-----------------|
| Tipo de programación | Por fechas específicas | Por días de la semana |
| Tabla de días | `PDV_VISITAS_AD_DIAS` | `PDV_VISITAS_ELOT_DIAS_SEMANA` |
| Base de datos | Base de datos principal (dbo) | Base de datos ELOT |
| Campo de día | `DIA_MES` (1-31) | `DIA_SEMANA` (1-6) |
| Fecha completa | `FECHA_COMPLETA` (DATE) | No aplica |
| Identificador | `DNI_RESPONSABLE` | `DNI` |
| Nombre del punto | `NOMBRE_PUNTO` | `RAZON_SOCIAL` |
| Consulta calendario | Por fecha específica | Por día de semana + verificar fecha |

## Consultas del Calendario - Consideraciones

Para obtener los PDVs a visitar en una fecha específica (ej: 6 de enero de 2025), necesitas:

1. Determinar qué día de la semana es esa fecha
2. Buscar todos los PDVs programados para ese día de semana
3. Filtrar por AÑO y MES

**Ejemplo completo:**
```sql
DECLARE @fecha DATE = '2025-01-06'; -- Lunes 6 de enero
DECLARE @dia_semana INT = DATEPART(WEEKDAY, @fecha) - 1; -- Ajuste: SQL Server empieza en domingo=1

-- Si @dia_semana = 0, entonces es domingo (no se programa)
-- Si @dia_semana = 1, entonces es lunes
-- etc.

SELECT
    pv.*,
    CASE @dia_semana
        WHEN 1 THEN 'LUNES'
        WHEN 2 THEN 'MARTES'
        WHEN 3 THEN 'MIÉRCOLES'
        WHEN 4 THEN 'JUEVES'
        WHEN 5 THEN 'VIERNES'
        WHEN 6 THEN 'SÁBADO'
    END AS DIA_SEMANA_NOMBRE
FROM ELOT.dbo.PDV_VISITAS_ELOT_PROGRAMACION pv
INNER JOIN ELOT.dbo.PDV_VISITAS_ELOT_DIAS_SEMANA vd ON pv.id = vd.programacion_id
WHERE pv.AÑO = YEAR(@fecha)
  AND pv.MES = MONTH(@fecha)
  AND vd.DIA_SEMANA = @dia_semana
  AND vd.PROGRAMADO = 1
  AND pv.STATUS IN ('AGENTE', 'PROGRAMADO'); -- Ajustar según necesidad
```

## Notas Importantes

1. **Patrón Semanal Recurrente**: Todos los lunes del mes se visitan los mismos puntos, todos los martes los mismos, etc.
2. **No hay fechas específicas**: A diferencia de AD, no se programa "el día 15", sino "todos los lunes"
3. **Domingo no se programa**: Solo se programan días 1-6 (Lunes a Sábado)
4. **Historial**: Cada mes es un registro independiente, manteniendo historial completo
5. **Modificaciones**: Se pueden modificar días programados actualizando `PDV_VISITAS_ELOT_DIAS_SEMANA`
6. **Status**: Los valores comunes son: 'AGENTE', 'BOTICA', 'POR IMPLEMENTAR', 'IMPLEMENTADO', 'DE BAJA', 'TAMBO'

## Volumen Estimado

- Similar a AD: ~2,000 PDVs ELOT por mes
- ~2-3 días de semana promedio por PDV
- Total: ~4,000-6,000 filas en `PDV_VISITAS_ELOT_DIAS_SEMANA` por mes
- Performance: Excelente con índices adecuados

## Relación con Otros Sistemas

- **Independiente de AD**: No hay relación directa entre tablas AD y ELOT
- **Base de Datos Separada**: Las tablas ELOT están en la base de datos **ELOT**, mientras que AD está en la base de datos principal
- **Visitas Realizadas**: Se relaciona por `DNI` y fecha (verificar día de semana)
- **Exportación**: Formato diferente (días de semana vs fechas específicas)

## Nota sobre Base de Datos

**IMPORTANTE:** Todas las tablas ELOT se encuentran en la base de datos **ELOT**, no en la base de datos principal. Al hacer consultas, siempre usar el prefijo `ELOT.dbo.`:

- `ELOT.dbo.PDV_VISITAS_ELOT_PROGRAMACION`
- `ELOT.dbo.PDV_VISITAS_ELOT_DIAS_SEMANA`

