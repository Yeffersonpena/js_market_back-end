# Documentación: PDV_VISITAS_AD_EJECUTADAS

## Descripción General

Tabla que almacena las visitas ejecutadas a PDVs AD (Tecnología y Telecom). Los datos se sincronizan desde el linked query:
```
[192.168.3.101,1800\MSSQL_NEW].[DISTRIB_MOVIL2].[dbo].[WOLAP_OPERACIONES_MOVILES_FINAL]
```

Incluye datos de la visita y datos de encuesta en una sola tabla.

## Relaciones

- **PDV_VISITAS_AD_PROGRAMACION**: Relación opcional mediante `programacion_id` (FK). Permite vincular visitas ejecutadas con programación previa. Si la visita no estaba programada, `programacion_id` será NULL.

## Estructura de Datos

### Identificadores
- **ID_CHECK**: BIGINT, PK. Identificador único del linked query.

### Fechas y Horas
- **FECHA_INI, HORA_INI, FECHA_FIN, HORA_FIN**: Fechas y horas de inicio y fin de la visita.
- **DURACION**: VARCHAR(10). Duración de la visita (ej: "00:25 min.").

**Nota**: En el origen, las fechas son CHAR(10) y CHAR(20). Se convierten a DATE/TIME en el Stored Procedure de sincronización.

### Datos del PDV
- **IDPDV**: CHAR(10). Identificador del PDV.
- **CODIGO_ALTERNO**: CHAR(15). Código alternativo que relaciona con `CODIGO_CUM` de `PDV_VISITAS_AD_PROGRAMACION`.
- **NOMBRE_PDV**: VARCHAR(100). Nombre del punto de venta.
- **ZONAL**: VARCHAR(40). Zonal del PDV.
- **RUTA**: CHAR(4). Ruta asignada.
- **MODULO**: CHAR(10). Módulo asignado.
- **CLUSTER_PDV**: VARCHAR(1). Cluster del PDV.
- **OBJETIVO_VISITA**: VARCHAR(1). Objetivo de la visita.
- **TIPO_VISITA**: VARCHAR(20). Tipo de visita.

### Datos del Vendedor
- **NOMBRE_VENDEDOR**: VARCHAR(50). Nombre completo del vendedor.
- **DNI_VENDEDOR**: VARCHAR(20). DNI del vendedor.

**Nota**: En el origen, `DNI_VENDEDOR` es VARCHAR(1) pero parece ser un error. Se usa VARCHAR(20) para permitir DNI completo.

### Flags de la Visita
- **VISITA_EFECTIVA**: BIT. Indica si la visita fue efectiva (1=SI, 0=NO).
- **MARCACION_EN_PUNTO**: BIT. Indica si hubo marcación en el punto (1=SI, 0=NO).
- **EXTRA_RUTA**: BIT. Indica si fue extra ruta (1=SI, 0=NO).
- **POSICION_SIMULADA**: BIT. Indica si la posición fue simulada (1=SI, 0=NO).

**Nota**: En el origen, estos campos son VARCHAR(2) con valores 'SI'/'NO'. Se convierten a BIT (1/0) en el Stored Procedure de sincronización para consultas más eficientes.

### Coordenadas Geográficas

#### Coordenadas del Cliente (ubicación registrada del PDV)
- **CLIENTE_LATITUD**: DECIMAL(10,7)
- **CLIENTE_LONGITUD**: DECIMAL(11,7)

#### Coordenadas de Check-in (ubicación al iniciar la visita)
- **CHECKIN_LATITUD**: DECIMAL(10,7)
- **CHEKIN_LONGITUD**: DECIMAL(11,7)

**Nota**: `CHEKIN_LONGITUD` mantiene el typo del origen (falta la C de CHECKIN).

#### Coordenadas de Check-out (ubicación al finalizar la visita)
- **CHECKOUT_LATITUD**: DECIMAL(10,7), nullable
- **CHECKOUT_LONGITUD**: DECIMAL(11,7), nullable

**Nota**: En el origen, las coordenadas son NUMERIC(28,14) con coma (`,`) como separador decimal. Se convierten a DECIMAL(10,7)/(11,7) con punto (`.`) en el Stored Procedure. La precisión DECIMAL(10,7) es suficiente para coordenadas geográficas (aproximadamente 1.1 cm de precisión).

### Datos de Encuesta

Todas las columnas de encuesta son NULL si no hay encuesta asociada.

- **ENCUESTA**: VARCHAR(50). Tipo de encuesta (ej: "Encuesta PV").

#### Preguntas (PREG_01 a PREG_15)
- **PREG_01** a **PREG_15**: VARCHAR(100). Respuestas a las 15 preguntas de la encuesta. Muchas pueden ser NULL.

#### Imágenes
- **IMG_01, IMG_02, IMG_03**: VARCHAR(80). Rutas/URLs de las imágenes asociadas a la encuesta. Pueden ser NULL.

## Campos de Control

- **programacion_id**: INT, nullable, FK a `PDV_VISITAS_AD_PROGRAMACION.id`. Permite vincular visitas ejecutadas con programación previa. NULL si la visita no estaba programada.
- **FECHA_SINCRONIZACION**: DATETIME, default GETDATE(). Fecha/hora de sincronización desde el linked query. Útil para tracking y evitar duplicados en sincronizaciones incrementales.
- **USUARIO_SINCRONIZACION**: VARCHAR(100), default 'SISTEMA'. Usuario o proceso que sincronizó los datos.

## Índices

### IX_PDV_VISITAS_AD_EJEC_IDPDV
- Columnas: `IDPDV`, `FECHA_INI`
- Propósito: Búsqueda rápida por PDV y fecha.

### IX_PDV_VISITAS_AD_EJEC_CODIGO_ALTERNO
- Columnas: `CODIGO_ALTERNO`
- Propósito: Búsqueda por código alterno (relación con CODIGO_CUM).

### IX_PDV_VISITAS_AD_EJEC_FECHA_INI
- Columnas: `FECHA_INI`
- Include: `ID_CHECK`, `IDPDV`, `CODIGO_ALTERNO`, `NOMBRE_PDV`, `ZONAL`, `DNI_VENDEDOR`, `VISITA_EFECTIVA`
- Propósito: Consultas por día/mes con datos frecuentemente solicitados.

### IX_PDV_VISITAS_AD_EJEC_DNI_VENDEDOR
- Columnas: `DNI_VENDEDOR`, `FECHA_INI`
- Include: `ID_CHECK`, `IDPDV`, `NOMBRE_PDV`, `ZONAL`, `VISITA_EFECTIVA`
- Propósito: Búsqueda por vendedor y fecha.

### IX_PDV_VISITAS_AD_EJEC_ZONAL
- Columnas: `ZONAL`, `FECHA_INI`
- Include: `ID_CHECK`, `IDPDV`, `NOMBRE_PDV`, `DNI_VENDEDOR`, `VISITA_EFECTIVA`
- Propósito: Búsqueda por zonal y fecha.

### IX_PDV_VISITAS_AD_EJEC_PROGRAMACION_ID
- Columnas: `programacion_id`
- Filter: `WHERE programacion_id IS NOT NULL`
- Propósito: Búsqueda por programación relacionada.

## Foreign Keys

### FK_PDV_VISITAS_AD_EJEC_PROGRAMACION
- Tabla: `PDV_VISITAS_AD_PROGRAMACION`
- Columna: `id`
- Acciones:
  - ON DELETE SET NULL
  - ON UPDATE CASCADE

## Stored Procedure de Sincronización

### Conversiones Necesarias

#### 1. Fechas
```sql
-- Convertir CHAR(10) a DATE
CAST(REPLACE(@fecha_char, '/', '-') AS DATE)

-- Convertir CHAR(20) a TIME
CAST(@hora_char AS TIME)
```

#### 2. Flags (SI/NO → BIT)
```sql
-- Convertir VARCHAR(2) 'SI'/'NO' a BIT
CASE WHEN @flag = 'SI' THEN 1 ELSE 0 END
```

#### 3. Coordenadas
```sql
-- Convertir NUMERIC(28,14) con coma a DECIMAL(10,7) con punto
CAST(REPLACE(@coordenada, ',', '.') AS DECIMAL(10,7))
```

#### 4. Manejo de Campos NOT NULL Vacíos
Algunos campos en el origen son NOT NULL pero pueden estar vacíos. En estos casos, usar NULL en lugar de strings vacíos:
```sql
NULLIF(LTRIM(RTRIM(@campo)), '')
```

### Estrategia de Sincronización

Se recomienda usar **MERGE** para manejar INSERT/UPDATE en una sola operación:

```sql
MERGE PDV_VISITAS_AD_EJECUTADAS AS destino
USING (
    SELECT
        ID_CHECK,
        -- Conversiones aquí
        ...
    FROM [192.168.3.101,1800\MSSQL_NEW].[DISTRIB_MOVIL2].[dbo].[WOLAP_OPERACIONES_MOVILES_FINAL]
    WHERE FECHA_INI >= DATEADD(DAY, -1, GETDATE()) -- Ajustar según necesidad
) AS origen
ON destino.ID_CHECK = origen.ID_CHECK
WHEN MATCHED THEN UPDATE ...
WHEN NOT MATCHED THEN INSERT ...
```

### Opciones de Sincronización

1. **Full Refresh**: DELETE + INSERT completo (más simple, más lento).
2. **Incremental por Fecha**: Solo sincronizar últimos N días (recomendado).
3. **Incremental por ID_CHECK**: Solo nuevos registros (requiere tracking).

## Casos de Uso

### Consultas Frecuentes

1. **Visitas de un día específico**:
```sql
SELECT * FROM PDV_VISITAS_AD_EJECUTADAS
WHERE FECHA_INI = '2025-01-15'
```

2. **Visitas efectivas por vendedor**:
```sql
SELECT * FROM PDV_VISITAS_AD_EJECUTADAS
WHERE DNI_VENDEDOR = '12345678'
  AND VISITA_EFECTIVA = 1
  AND FECHA_INI >= DATEADD(MONTH, -1, GETDATE())
```

3. **Visitas con encuesta**:
```sql
SELECT * FROM PDV_VISITAS_AD_EJECUTADAS
WHERE ENCUESTA IS NOT NULL
```

4. **Visitas relacionadas con programación**:
```sql
SELECT v.*, p.COD_CLIENTE, p.NOMBRE_PUNTO
FROM PDV_VISITAS_AD_EJECUTADAS v
INNER JOIN PDV_VISITAS_AD_PROGRAMACION p ON v.programacion_id = p.id
WHERE v.FECHA_INI = '2025-01-15'
```

## Notas Importantes

1. **ID_CHECK**: Es BIGINT del linked query, se usa como Primary Key.
2. **Coordenadas**: La precisión DECIMAL(10,7) es suficiente para coordenadas geográficas (aproximadamente 1.1 cm de precisión).
3. **CHEKIN_LONGITUD**: Mantiene el typo del origen (falta la C de CHECKIN). Si se corrige en el origen, actualizar también aquí.
4. **DNI_VENDEDOR**: En origen es VARCHAR(1) pero parece error. Se usa VARCHAR(20) para permitir DNI completo.
5. **Datos de encuesta**: Todas las columnas son NULL si no hay encuesta.
6. **programacion_id**: Opcional, permite vincular visitas ejecutadas con programación previa.
7. **FECHA_SINCRONIZACION**: Útil para tracking y evitar duplicados en sincronizaciones incrementales.

## Mantenimiento

- **Sincronización**: Ejecutar el Stored Procedure periódicamente (recomendado cada hora o según necesidad).
- **Limpieza**: Considerar archivar o eliminar registros antiguos si es necesario.
- **Monitoreo**: Revisar `FECHA_SINCRONIZACION` para detectar problemas de sincronización.

