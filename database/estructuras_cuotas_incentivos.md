# Estructuras de Tablas y Query de Referencia

## Tabla: cuotas_incentivos_logistica

```sql
CREATE TABLE [dbo].[cuotas_incentivos_logistica] (
    id INT IDENTITY(1,1) NOT NULL,
    zonal VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
    categoria VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL,  -- EQUIPOS, ACCESORIOS
    cuota1 DECIMAL(18,2) NOT NULL,                                -- Primera cuota objetivo
    bono1 DECIMAL(18,2) NOT NULL,                                 -- Bono por alcanzar cuota1
    cuota2 DECIMAL(18,2) NOT NULL,                                -- Segunda cuota objetivo
    bono2 DECIMAL(18,2) NOT NULL,                                 -- Bono por alcanzar cuota2
    fecha_inicio DATE NOT NULL,                                    -- Fecha de inicio de vigencia
    fecha_fin DATE NOT NULL,                                       -- Fecha de fin de vigencia
    activo BIT DEFAULT 1 NOT NULL,                                 -- Indica si el registro está activo
    created_at DATETIME DEFAULT GETDATE() NOT NULL,
    updated_at DATETIME NULL,
    CONSTRAINT PK_cuotas_incentivos_logistica PRIMARY KEY (id)
);

-- Índices para optimizar consultas
CREATE INDEX IX_cuotas_incentivos_logistica_Zonal_Categoria
ON [dbo].[cuotas_incentivos_logistica] (zonal, categoria, activo);

CREATE INDEX IX_cuotas_incentivos_logistica_Fechas
ON [dbo].[cuotas_incentivos_logistica] (fecha_inicio, fecha_fin);

CREATE INDEX IX_cuotas_incentivos_logistica_Categoria_Fechas
ON [dbo].[cuotas_incentivos_logistica] (categoria, fecha_inicio, fecha_fin);
```

### Campos principales:
- **zonal**: Zona geográfica (AREQUIPA, AYACUCHO, CUSCO, HUANCAYO, HUANUCO, ICA, LIMASUR, PUCALLPA, PUNO)
- **categoria**: Tipo de producto (EQUIPOS, ACCESORIOS)
- **cuota1/bono1**: Primera meta y su bono correspondiente
- **cuota2/bono2**: Segunda meta y su bono correspondiente (mayor que cuota1)
- **fecha_inicio/fecha_fin**: Período de vigencia de las cuotas

---

## Tabla: DD_WOLAP_VENTA_ANALISIS_DETALLADO

```sql
CREATE TABLE DISTRIBUTOR_DATAMART.dbo.DD_WOLAP_VENTA_ANALISIS_DETALLADO (
	TD char(2) COLLATE Modern_Spanish_CI_AS NOT NULL,
	NRODOC char(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
	FEC_EMISION datetime NOT NULL,
	COD_CLIENTE char(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
	NOM_CLIENTE varchar(70) COLLATE Modern_Spanish_CI_AS NULL,
	DIR_CLIENTE varchar(70) COLLATE Modern_Spanish_CI_AS NULL,
	DISTRITO varchar(40) COLLATE Modern_Spanish_CI_AS NULL,
	CDOC_IDE varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
	COD_VENDEDOR char(6) COLLATE Modern_Spanish_CI_AS NOT NULL,
	NOM_VENDEDOR varchar(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
	COD_PRODUCTO char(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
	NOM_PRODUCTO varchar(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
	NOM_PLAN varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	CANTIDAD_REF int NOT NULL,
	PRECIO_VTA money NOT NULL,
	IMEI varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
	ICC varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
	NRO_ASIGNADO varchar(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
	ALMACEN varchar(35) COLLATE Modern_Spanish_CI_AS NOT NULL,
	FONO1 varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
	FONO2 varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
	COD_ALTERNO char(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
	FAX varchar(15) COLLATE Modern_Spanish_CI_AS NOT NULL,
	REPARTO varchar(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
	TIPO varchar(9) COLLATE Modern_Spanish_CI_AS NOT NULL,
	NCOSTO money NULL,
	PROVEEDOR varchar(60) COLLATE Modern_Spanish_CI_AS NULL,
	GRUPO_TECNO char(1) COLLATE Modern_Spanish_CI_AS NOT NULL,
	CTIPO_DOC varchar(2) COLLATE Modern_Spanish_CI_AS NULL,
	CNRO_DOC char(15) COLLATE Modern_Spanish_CI_AS NULL,
	FEC_COMPRA datetime NULL,
	CTIPO_DOC2 varchar(2) COLLATE Modern_Spanish_CI_AS NULL,
	CNRO_DOC2 char(15) COLLATE Modern_Spanish_CI_AS NULL,
	PROD_CATEGORIA varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
	PROD_LINEA varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
	COD_FUERZA char(4) COLLATE Modern_Spanish_CI_AS NOT NULL,
	FUERZA varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	CCOD_RUTA char(4) COLLATE Modern_Spanish_CI_AS NOT NULL,
	CCOD_MODULO char(10) COLLATE Modern_Spanish_CI_AS NOT NULL
);

CREATE NONCLUSTERED INDEX [NonClusteredIndex-20250818-214854]
ON DISTRIBUTOR_DATAMART.dbo.DD_WOLAP_VENTA_ANALISIS_DETALLADO (IMEI);
```

### Campos principales utilizados:
- **FEC_EMISION**: Fecha de emisión de la venta
- **ALMACEN**: Almacén/zonal de la venta
- **NOM_VENDEDOR**: Nombre del vendedor
- **NOM_PRODUCTO**: Nombre del producto
- **PROD_LINEA**: Línea de producto (EQUIPOS, ACCESORIOS)
- **PRECIO_VTA**: Precio de venta

---

## Query de Referencia

```sql
SELECT
    CAST([FEC_EMISION] AS DATE) as [FEC_EMISION],
    CASE
        WHEN LTRIM(RTRIM([ALMACEN])) = 'LOG - AREQUIPA' THEN 'Arequipa'
        WHEN LTRIM(RTRIM([ALMACEN])) = 'La Merced' THEN 'Huancayo'
        ELSE LTRIM(RTRIM([ALMACEN]))
    END as [ALMACEN],
    [NOM_VENDEDOR],
    [NOM_PRODUCTO],
    [PROD_LINEA],
    sum([PRECIO_VTA]) as precio_vta
FROM [DISTRIBUTOR_DATAMART].[dbo].[DD_WOLAP_VENTA_ANALISIS_DETALLADO]
WHERE CAST([FEC_EMISION] AS DATE) >= '2025-12-06'  -- fecha_inicio
  AND CAST([FEC_EMISION] AS DATE) <= '2025-12-13'    -- fecha_fin
  AND [PROD_LINEA] IN ('EQUIPOS', 'ACCESORIOS')
  AND LTRIM(RTRIM([ALMACEN])) <> 'E-COMMERCE'
GROUP BY
    CAST([FEC_EMISION] AS DATE),
    CASE
        WHEN LTRIM(RTRIM([ALMACEN])) = 'LOG - AREQUIPA' THEN 'Arequipa'
        WHEN LTRIM(RTRIM([ALMACEN])) = 'La Merced' THEN 'Huancayo'
        ELSE LTRIM(RTRIM([ALMACEN]))
    END,
    [NOM_VENDEDOR],
    [NOM_PRODUCTO],
    [PROD_LINEA]
```

### Notas sobre la query:
- **Mapeo de ALMACEN**:
  - `'LOG - AREQUIPA'` → `'Arequipa'`
  - `'La Merced'` → `'Huancayo'`
  - Otros almacenes se mantienen tal cual
- **Filtros aplicados**:
  - Rango de fechas (fecha_inicio y fecha_fin)
  - Solo EQUIPOS y ACCESORIOS
  - Excluye E-COMMERCE
- **Agrupación**: Por fecha, almacén, vendedor, producto y línea de producto

