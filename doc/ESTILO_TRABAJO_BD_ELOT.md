# Estilo de Trabajo - Base de Datos ELOT

## Propósito
Este documento describe el estilo y las convenciones utilizadas para crear tablas y stored procedures en el proyecto. Este estilo debe mantenerse en el nuevo proyecto **ELOT** para garantizar consistencia y facilitar el mantenimiento.

---

## Estructura de Directorios

Los archivos SQL se organizan en las siguientes carpetas dentro de `database/`:

```
database/
├── tables/          # Scripts de creación de tablas
├── procedures/      # Stored Procedures (SP)
├── functions/       # Funciones definidas por el usuario
└── queries/         # Consultas SQL de referencia o análisis
```

### Convención de Nombres de Archivos

- **Tablas**: Nombre en minúsculas con guiones bajos, ej: `blacklist_usuarios.sql`, `abonos_postpago_log.sql`
- **Stored Procedures**: Prefijo `sp_` seguido del nombre en PascalCase, ej: `sp_Registrar_AbonosPostpago.sql`, `sp_Procesa_Ventas_Log.sql`
- **Funciones**: Prefijo `fn_` seguido del nombre descriptivo, ej: `fn_CalcularBonoUnitario.sql`

---

## Estructura de Tablas

### Formato General

Todas las tablas deben seguir esta estructura:

```sql
-- Tabla: [Nombre descriptivo de la tabla]
-- Fuente: [Origen de los datos, si aplica]
-- Propósito: [Descripción clara del propósito de la tabla]

CREATE TABLE [ESQUEMA].dbo.[NOMBRE_TABLA] (
    -- Campos de la tabla
    -- Constraints
);

-- Índices para optimizar consultas habituales
-- [Comentario explicando el propósito del índice]
CREATE INDEX [NOMBRE_INDICE]
    ON [ESQUEMA].dbo.[NOMBRE_TABLA] ([CAMPO(s)]);
```

### Elementos Obligatorios

1. **Comentarios de Encabezado**
   - Descripción clara del propósito
   - Fuente de datos (si aplica)
   - Contexto adicional relevante

2. **Esquema y Base de Datos**
   - Usar el esquema completo: `[NOMBRE_BD].dbo.`
   - Para ELOT: `ELOT.dbo.`

3. **Collation**
   - Todos los campos de texto (`VARCHAR`, `NVARCHAR`, `CHAR`, etc.) deben usar:
   ```sql
   COLLATE Modern_Spanish_CI_AS
   ```

4. **Campos de Auditoría**
   - Incluir campos de control cuando sea relevante:
     - `FECHA_CARGA DATETIME DEFAULT GETDATE() NOT NULL`
     - `FECHA_ACTUALIZACION DATETIME NULL`
     - `USUARIO_CREACION VARCHAR(50) NULL`

5. **Primary Keys**
   - Usar `IDENTITY(1,1)` para claves autoincrementales
   - Nombrar constraints: `PK_[NombreTabla]`
   - Ejemplo:
   ```sql
   ID BIGINT IDENTITY(1,1) NOT NULL
       CONSTRAINT PK_BlacklistUsuarios PRIMARY KEY,
   ```

6. **Índices**
   - Crear índices para campos usados frecuentemente en:
     - Cláusulas `WHERE`
     - `JOIN`
     - Ordenamientos (`ORDER BY`)
   - Convención de nombres: `IX_[NombreTabla]_[Campo(s)]`
   - Incluir comentarios explicando el propósito de cada índice
   - Considerar índices compuestos para consultas que filtran por múltiples campos

### Ejemplo Completo de Tabla

```sql
-- Tabla: Blacklist de Usuarios (Bloqueados por Ventas Inusuales Postpago)
-- Fuente: Excel con datos de usuarios bloqueados enviado por compañero
-- Propósito: Registrar usuarios que han sido bloqueados por malas prácticas (ventas inusuales reincidentes)

CREATE TABLE ELOT.dbo.blacklist_usuarios (
    ID BIGINT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_BlacklistUsuarios PRIMARY KEY,

    ZONAL VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    FECHA_DE_SOLICITUD DATE NOT NULL,
    DNI_RESPONSABLE INT NULL,
    USUARIO INT NOT NULL,
    TIPO_DE_DNI VARCHAR(50) COLLATE Modern_Spanish_CI_AS NULL,
    CASUISTICA VARCHAR(255) COLLATE Modern_Spanish_CI_AS NULL,
    FECHA_CARGA DATETIME DEFAULT GETDATE() NOT NULL
);

-- Índices para optimizar consultas habituales
-- Índice para filtros por usuario (DNI del usuario bloqueado)
CREATE INDEX IX_BlacklistUsuarios_Usuario
    ON ELOT.dbo.blacklist_usuarios (USUARIO);

-- Índice para filtros por DNI responsable
CREATE INDEX IX_BlacklistUsuarios_DNI_Responsable
    ON ELOT.dbo.blacklist_usuarios (DNI_RESPONSABLE);

-- Índice compuesto para consultas por usuario y fecha
CREATE INDEX IX_BlacklistUsuarios_Usuario_Fecha
    ON ELOT.dbo.blacklist_usuarios (USUARIO, FECHA_DE_SOLICITUD);
```

---

## Estructura de Stored Procedures

### Formato General

Todos los stored procedures deben seguir esta estructura:

```sql
-- =============================================
-- Autor: [Nombre o Sistema]
-- Fecha de creación: [YYYY-MM-DD]
-- Descripción: [Descripción detallada de qué hace el SP]
--              [Líneas adicionales de descripción si es necesario]
-- =============================================
CREATE PROCEDURE [ESQUEMA].dbo.[NOMBRE_SP]
    @Parametro1 TIPO_DATO,
    @Parametro2 TIPO_DATO = NULL  -- Parámetros opcionales con valor por defecto
AS
BEGIN
    SET NOCOUNT ON;

    -- Variables locales
    DECLARE @VariableLocal TIPO_DATO = ValorInicial;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Lógica del procedimiento
        -- Usar CTEs (Common Table Expressions) para consultas complejas
        -- Incluir comentarios explicativos

        COMMIT TRANSACTION;

        -- Retornar resultado o mensaje de éxito
        SELECT
            @VariableLocal AS [CampoResultado],
            'Operación completada exitosamente' AS [Mensaje];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Retornar error
        SELECT
            0 AS [CampoResultado],
            ERROR_MESSAGE() AS [Mensaje];
    END CATCH;

END;
GO
```

### Elementos Obligatorios

1. **Encabezado con Comentarios**
   - Autor
   - Fecha de creación
   - Descripción detallada del propósito y funcionamiento

2. **SET NOCOUNT ON**
   - Siempre incluir al inicio para mejorar rendimiento

3. **Manejo de Transacciones**
   - Usar `BEGIN TRANSACTION` / `COMMIT TRANSACTION`
   - Implementar `TRY/CATCH` para manejo de errores
   - Siempre hacer `ROLLBACK` en caso de error

4. **Parámetros**
   - Prefijo `@` para todos los parámetros
   - Nombres descriptivos en PascalCase
   - Especificar valores por defecto cuando sea apropiado
   - Incluir comentarios para parámetros complejos

5. **CTEs (Common Table Expressions)**
   - Usar CTEs para organizar consultas complejas
   - Nombrar CTEs de forma descriptiva
   - Separar lógica en múltiples CTEs cuando mejore la legibilidad

6. **Retorno de Resultados**
   - Retornar resultados estructurados con `SELECT`
   - Incluir mensajes informativos
   - En caso de error, retornar `ERROR_MESSAGE()`

7. **Comentarios en el Código**
   - Explicar lógica compleja
   - Documentar reglas de negocio implementadas
   - Incluir referencias a fórmulas o cálculos cuando aplique

### Ejemplo Completo de Stored Procedure

```sql
-- =============================================
-- Autor: Sistema
-- Fecha de creación: 2025-01-XX
-- Descripción: Calcula y registra abonos de ventas Postpago en la tabla abonos_postpago_log
--              Solo procesa días que no estén ya registrados en la tabla
--              Si se especifica @DiasFiltro, solo procesa esos días específicos (si no están registrados)
-- =============================================
CREATE PROCEDURE ELOT.dbo.sp_Registrar_AbonosPostpago
    @Año INT,
    @Mes INT,
    @DiasFiltro VARCHAR(MAX) = NULL  -- Ejemplo: '4,5,6' o NULL para todos los días
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RegistrosInsertados INT = 0;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Calcular y insertar nuevos registros (solo días que no estén ya registrados)
        WITH VentasAgrupadas AS (
            SELECT
                VL.FECHA,
                E.ZONAL,
                E.ACCION_1,
                VL.DNI_RESPONSABLE,
                VL.DNI_VENDEDOR,
                E.NOMBRE_RESPONSABLE,
                SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) AS [Alta],
                SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Portabilidad],
                SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) +
                SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Total general]
            FROM
                ELOT.dbo.VentasLog VL
                INNER JOIN ELOT.dbo.PDV_OUT_ENTREGABLE E
                    ON CAST(VL.DNI_RESPONSABLE AS INT) = E.DNI_RESPONSABLE
            WHERE
                VL.PRODUCT_NAME = 'Postpago'
                AND E.AÑO = @Año
                AND E.MES = @Mes
                AND E.ESTADO = 'ACTIVO'
                AND YEAR(VL.FECHA) = @Año
                AND MONTH(VL.FECHA) = @Mes
                AND (@DiasFiltro IS NULL
                     OR DAY(VL.FECHA) IN (
                         SELECT CAST(LTRIM(RTRIM(value)) AS INT)
                         FROM STRING_SPLIT(@DiasFiltro, ',')
                         WHERE ISNUMERIC(LTRIM(RTRIM(value))) = 1
                     ))
                -- Excluir fechas que ya están registradas
                AND VL.FECHA NOT IN (
                    SELECT DISTINCT FECHA
                    FROM ELOT.dbo.abonos_postpago_log
                    WHERE YEAR(FECHA) = @Año
                        AND MONTH(FECHA) = @Mes
                )
            GROUP BY
                VL.FECHA,
                E.ZONAL,
                E.ACCION_1,
                VL.DNI_RESPONSABLE,
                VL.DNI_VENDEDOR,
                E.NOMBRE_RESPONSABLE
        )
        INSERT INTO ELOT.dbo.abonos_postpago_log (
            FECHA,
            ZONAL_JS,
            ACCION_JS,
            -- ... más campos
        )
        SELECT
            VA.FECHA,
            VA.ZONAL AS [ZONAL_JS],
            VA.ACCION_1 AS [ACCION_JS],
            -- ... más campos
        FROM
            VentasAgrupadas VA;

        -- Capturar el número de registros insertados antes del COMMIT
        SET @RegistrosInsertados = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Retornar resumen de registros insertados
        SELECT
            @RegistrosInsertados AS [RegistrosInsertados],
            'Registro completado exitosamente' AS [Mensaje];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Retornar error
        SELECT
            0 AS [RegistrosInsertados],
            ERROR_MESSAGE() AS [Mensaje];
    END CATCH;

END;
GO
```

---

## Convenciones de Nomenclatura

### Tablas
- **Nombres**: PascalCase o snake_case, consistente en todo el proyecto
- Ejemplos: `blacklist_usuarios`, `abonos_postpago_log`, `PDV_OUT_ENTREGABLE`

### Campos
- **Nombres**: UPPER_SNAKE_CASE o PascalCase (mantener consistencia con el proyecto)
- Ejemplos: `FECHA_CARGA`, `DNI_RESPONSABLE`, `USUARIO`

### Constraints
- **Primary Keys**: `PK_[NombreTabla]`
- **Foreign Keys**: `FK_[TablaOrigen]_[TablaDestino]`
- **Unique**: `UQ_[NombreTabla]_[Campo]`
- **Check**: `CK_[NombreTabla]_[Descripcion]`

### Índices
- **Formato**: `IX_[NombreTabla]_[Campo(s)]`
- **Compuestos**: `IX_[NombreTabla]_[Campo1]_[Campo2]`
- Ejemplos: `IX_BlacklistUsuarios_Usuario`, `IX_VentasLog_FECHA_DNI_VENDEDOR`

### Stored Procedures
- **Prefijo**: `sp_`
- **Nombre**: PascalCase descriptivo
- Ejemplos: `sp_Registrar_AbonosPostpago`, `sp_Procesa_Ventas_Log`

### Funciones
- **Prefijo**: `fn_`
- **Nombre**: PascalCase descriptivo
- Ejemplos: `fn_CalcularBonoUnitario`, `fn_ObtenerNivelRango`

### Variables y Parámetros
- **Prefijo**: `@` (obligatorio en SQL Server)
- **Nombres**: PascalCase
- Ejemplos: `@Año`, `@Mes`, `@RegistrosInsertados`

---

## Buenas Prácticas

### Rendimiento

1. **Índices**
   - Crear índices en campos usados frecuentemente en `WHERE` y `JOIN`
   - Considerar índices compuestos para consultas que filtran por múltiples campos
   - Revisar y optimizar índices periódicamente

2. **Consultas**
   - Usar `SET NOCOUNT ON` en stored procedures
   - Evitar `SELECT *` en producción
   - Usar `EXISTS` en lugar de `IN` cuando sea posible para mejor rendimiento

3. **Transacciones**
   - Mantener transacciones lo más cortas posible
   - No incluir operaciones que no requieren transacción dentro de `BEGIN TRANSACTION`

### Mantenibilidad

1. **Comentarios**
   - Documentar lógica compleja
   - Explicar reglas de negocio implementadas
   - Incluir referencias a fórmulas o cálculos

2. **Organización**
   - Usar CTEs para consultas complejas en lugar de subconsultas anidadas
   - Separar lógica en múltiples CTEs cuando mejore la legibilidad
   - Mantener procedimientos enfocados en una tarea específica

3. **Consistencia**
   - Mantener el mismo estilo de formato en todo el proyecto
   - Usar las mismas convenciones de nombres
   - Seguir la estructura establecida para tablas y SPs

### Seguridad

1. **Validación**
   - Validar parámetros de entrada en stored procedures
   - Usar tipos de datos apropiados para prevenir inyección SQL
   - Implementar manejo de errores adecuado

2. **Permisos**
   - Documentar permisos requeridos para ejecutar stored procedures
   - Usar el principio de menor privilegio

---

## Checklist para Crear una Nueva Tabla

- [ ] Archivo creado en `database/tables/` con nombre descriptivo
- [ ] Comentarios de encabezado con propósito y fuente
- [ ] Esquema completo: `ELOT.dbo.[NOMBRE_TABLA]`
- [ ] Todos los campos de texto con `COLLATE Modern_Spanish_CI_AS`
- [ ] Primary Key definida con constraint nombrado
- [ ] Campos de auditoría incluidos si aplica (`FECHA_CARGA`, etc.)
- [ ] Índices creados para campos usados frecuentemente
- [ ] Comentarios en cada índice explicando su propósito
- [ ] Nombres de constraints e índices siguen las convenciones

---

## Checklist para Crear un Nuevo Stored Procedure

- [ ] Archivo creado en `database/procedures/` con prefijo `sp_`
- [ ] Encabezado completo con autor, fecha y descripción
- [ ] `SET NOCOUNT ON` incluido
- [ ] Parámetros con nombres descriptivos y tipos apropiados
- [ ] Transacciones implementadas con `TRY/CATCH`
- [ ] `ROLLBACK` en caso de error
- [ ] Resultados estructurados retornados
- [ ] Comentarios explicando lógica compleja
- [ ] CTEs usados para consultas complejas
- [ ] Nombres de variables y parámetros siguen las convenciones

---

## Notas para el Proyecto ELOT

- **Base de datos**: `ELOT`
- **Esquema**: `ELOT.dbo.`
- **Mantener**: Todas las convenciones y estilos descritos en este documento
- **Referencia**: Este proyecto (js_market_back-end) como ejemplo de implementación

---

## Ejemplos de Referencia

Para ver ejemplos completos de implementación, consultar:

- **Tablas**:
  - `database/tables/blacklist_usuarios.sql`
  - `database/tables/abonos_postpago_log.sql`
  - `database/tables/VentasLog.sql`

- **Stored Procedures**:
  - `database/procedures/sp_Registrar_AbonosPostpago.sql`
  - `database/procedures/sp_Procesa_Ventas_Log.sql`
  - `database/procedures/sp_Esquema_PDV.sql`

---

**Última actualización**: 2025-01-XX
**Proyecto de referencia**: js_market_back-end
**Proyecto destino**: ELOT

