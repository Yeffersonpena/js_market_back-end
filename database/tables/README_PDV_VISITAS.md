# Tablas de Programación de Visitas PDV AD (Tecnología y Telecom)

## Descripción General

Este conjunto de tablas almacena la programación mensual de visitas a puntos de venta (PDV) del canal **AD (Tecnología y Telecom)**. El diseño utiliza un modelo normalizado con dos tablas principales que permiten consultas eficientes por fecha y comparación con visitas realizadas.

**Nota:** Para el canal ELOT (Loterías), ver `README_PDV_VISITAS_ELOT.md`

## Estructura de Tablas

### 1. PDV_VISITAS_AD_PROGRAMACION
Tabla principal que almacena la programación mensual de cada PDV AD.

**Características:**
- Una fila por cada PDV programado en un mes específico
- Contiene todos los datos del PDV (del Excel original)
- Relación 1:N con `PDV_VISITAS_AD_DIAS`

**Clave Primaria:** `id` (auto-increment)
**Clave Única:** `(DNI_RESPONSABLE, AÑO, MES)` - Evita duplicados

**Campos Principales:**
- `DNI_RESPONSABLE`: Identificador del PDV (relacionado con PDV_OUT_ENTREGABLE)
- `AÑO`, `MES`: Período de la programación
- Datos del PDV: COD_CLIENTE, NOMBRE_PUNTO, DIRECCION, coordenadas, etc.
- Metadatos: TIPO_VISITA, FRECUENCIA, STATUS, COMENTARIOS

### 2. PDV_VISITAS_AD_DIAS
Tabla que almacena los días específicos programados para cada PDV AD.

**Características:**
- Una fila por cada día programado
- Permite consultas eficientes por fecha (calendario)
- Facilita comparación VS con visitas realizadas

**Clave Primaria:** `id` (auto-increment)
**Clave Única:** `(programacion_id, DIA_MES)` - Evita duplicar el mismo día

**Campos Principales:**
- `programacion_id`: FK a PDV_VISITAS_AD_PROGRAMACION
- `DIA_MES`: Día del mes (1-31)
- `FECHA_COMPLETA`: Fecha completa (DATE) - debe calcularse en el proceso de registro usando AÑO, MES y DIA_MES
- `PROGRAMADO`: BIT indicando si está programado (1) o no (0)
- `es_extraordinario`: BIT para casos fuera de la frecuencia normal

## Casos de Uso

### 1. Consulta del Calendario (Frontend)
Obtener todos los PDVs a visitar en una fecha específica:

```sql
SELECT
    pv.DNI_RESPONSABLE,
    pv.NOMBRE_PUNTO,
    pv.DIRECCION,
    pv.VENDEDORES,
    pv.TIPO_VISITA,
    pv.ZONAL
FROM PDV_VISITAS_AD_PROGRAMACION pv
INNER JOIN PDV_VISITAS_AD_DIAS vd ON pv.id = vd.programacion_id
WHERE vd.FECHA_COMPLETA = '2025-01-15'
  AND vd.PROGRAMADO = 1
  AND pv.STATUS = 'PROGRAMADO';
```

### 2. Exportar Excel Diario
Misma consulta que calendario, formateada para Excel.

### 3. Comparación VS (Programado vs Realizado)
Comparar qué se programó vs qué se visitó realmente:

```sql
SELECT
    pv.DNI_RESPONSABLE,
    pv.NOMBRE_PUNTO,
    vd.FECHA_COMPLETA AS FECHA_PROGRAMADA,
    vr.FECHA AS FECHA_REALIZADA,
    CASE
        WHEN vr.FECHA IS NOT NULL THEN 'REALIZADO'
        ELSE 'PENDIENTE'
    END AS ESTADO
FROM PDV_VISITAS_AD_PROGRAMACION pv
INNER JOIN PDV_VISITAS_AD_DIAS vd ON pv.id = vd.programacion_id
LEFT JOIN VISITAS_REALIZADAS vr
    ON pv.DNI_RESPONSABLE = vr.DNI_RESPONSABLE
    AND vd.FECHA_COMPLETA = vr.FECHA
WHERE vd.FECHA_COMPLETA = @fecha
  AND vd.PROGRAMADO = 1;
```

### 4. Exportar Reporte Mensual (Formato Excel)
Usar PIVOT para convertir filas a columnas:

```sql
-- Ver stored procedure: sp_ExportarProgramacionVisitas_Excel
```

## Índices

### PDV_VISITAS_AD_PROGRAMACION
- `IX_PDV_VISITAS_AD_PROG_DNI_AÑO_MES`: Búsquedas por PDV y período
- `IX_PDV_VISITAS_AD_PROG_VENDEDOR`: Filtros por vendedor
- `IX_PDV_VISITAS_AD_PROG_ZONAL`: Filtros por zonal
- `IX_PDV_VISITAS_AD_PROG_STATUS`: Filtros por estado

### PDV_VISITAS_AD_DIAS
- `IX_PDV_VISITAS_AD_DIAS_FECHA`: **CRÍTICO** - Consultas del calendario
- `IX_PDV_VISITAS_AD_DIAS_PROGRAMACION`: Consultas por programación específica
- `IX_PDV_VISITAS_AD_DIAS_PROGRAMADO`: Índice filtrado para días programados activos

## Proceso de Importación desde Excel

1. **Python lee Excel** y transforma estructura:
   - Para cada fila del Excel (PDV)
   - Insertar en `PDV_VISITAS_AD_PROGRAMACION` (obtener el `id` generado)
   - Leer 31 columnas de días
   - Para cada día con valor = 1:
     - Calcular `FECHA_COMPLETA = DATEFROMPARTS(AÑO, MES, DIA_MES)`
     - Insertar en `PDV_VISITAS_AD_DIAS` con `FECHA_COMPLETA` calculada

2. **Stored Procedure procesa** (futuro: `spLoadFileProgramacionVisitasAD`):
   - Validar datos
   - Eliminar programación existente del mismo AÑO/MES
   - Insertar nuevos registros
   - Sincronizar con PDV_OUT_ENTREGABLE

## Relación con PDV_OUT_ENTREGABLE

- `DNI_RESPONSABLE` es la clave de relación
- La programación determina qué PDVs están activos en Entregable
- Proceso de sincronización: PDVs en programación → activos en Entregable

## Notas Importantes

1. **FECHA_COMPLETA**: Debe calcularse en el proceso de registro (Python) usando `DATEFROMPARTS(AÑO, MES, DIA_MES)` antes de insertar en `PDV_VISITAS_AD_DIAS`
2. **Historial**: Cada mes es un registro independiente, manteniendo historial completo
3. **Modificaciones**: Se pueden modificar días programados actualizando `PDV_VISITAS_AD_DIAS`
4. **Casos Extraordinarios**: Campo `es_extraordinario` permite marcar visitas fuera de la frecuencia normal

## Volumen Estimado

- ~2,000 PDVs AD por mes
- ~4 visitas promedio por PDV
- Total: ~8,000 filas en `PDV_VISITAS_AD_DIAS` por mes
- Performance: Excelente con índices adecuados

## Relación con ELOT

- **AD y ELOT son sistemas separados** con tablas independientes
- AD: `PDV_VISITAS_AD_PROGRAMACION` y `PDV_VISITAS_AD_DIAS`
- ELOT: `PDV_VISITAS_ELOT_PROGRAMACION` y `PDV_VISITAS_ELOT_DIAS_SEMANA`
- Ver `README_PDV_VISITAS_ELOT.md` para más información sobre ELOT

