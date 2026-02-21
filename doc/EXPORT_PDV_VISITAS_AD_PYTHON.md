Documento: Exportacion de visitas AD a Excel (Python)

Objetivo
- El proceso Python debe exportar la informacion ya depurada (sin duplicados)
  desde la tabla de ejecutadas. No debe recalcular la limpieza.
- Las formulas de Excel ya se replican en el SP, por lo que los campos
  calculados deben leerse directo de la tabla.

Tabla principal (fuente de exportacion)
- dbo.PDV_VISITAS_AD_EJECUTADAS
- Esta tabla es alimentada por el SP `dbo.SP_SYNC_PDV_VISITAS_AD_EJECUTADAS`
  y ya incluye deduplicacion + calculos.

Filtro recomendado
- Siempre filtrar por fecha:
  - FECHA_INI = @fecha (el mismo parametro usado en el SP)
- Si se necesita solo AD:
  - ZONAL LIKE '%MOVISTAR%'

Campos clave para el Excel
1) Identificacion y tiempos
- ID_CHECK (PK, bigint)
- FECHA_INI (date)
- HORA_INI (time)
- FECHA_FIN (date)
- HORA_FIN (time)
- DURACION (varchar(10))
- OBJETIVO_VISITA (varchar(1))

2) PDV y vendedor
- IDPDV (char(10))  -> clave de PDV en ejecucion
- CODIGO_ALTERNO (char(15))
- NOMBRE_PDV (varchar(100))
- ZONAL (varchar(40))
- RUTA (char(4))
- MODULO (char(10))
- NOMBRE_VENDEDOR (varchar(50))
- DNI_VENDEDOR (varchar(20))
- CLUSTER_PDV (varchar(1))
- TIPO_VISITA (varchar(20))        -- viene del linked query

3) Banderas (en tabla ya son BIT)
- VISITA_EFECTIVA
- MARCACION_EN_PUNTO
- EXTRA_RUTA
- POSICION_SIMULADA

4) Coordenadas de visita
- CLIENTE_LATITUD, CLIENTE_LONGITUD
- CHECKIN_LATITUD, CHEKIN_LONGITUD
- CHECKOUT_LATITUD, CHECKOUT_LONGITUD

5) Encuesta (si aplica exportar todo)
- ENCUESTA
- PREG_01 ... PREG_15
- IMG_01, IMG_02, IMG_03

6) Campos calculados (ya vienen listos)
- DIF_METROS (decimal(10,2))                       -- Haversine
- MARCACION_EN_PUNTO_FORMULADO (bit)              -- replica Excel
- TIPO_VISITA_PROGRAMACION (varchar(50))          -- desde programacion
- programacion_id (int)                           -- FK a programacion

Tabla de programacion (si se requiere enriquecer)
- dbo.PDV_VISITAS_AD_PROGRAMACION
- Join recomendado:
  - CAST(ejec.IDPDV AS INT) = CAST(prog.COD_CLIENTE AS INT)
  - YEAR(ejec.FECHA_INI) = prog.AÑO
  - MONTH(ejec.FECHA_INI) = prog.MES

Campos utiles de programacion para exportar si se necesitan
- CODIGO_CUM
- COD_CLIENTE
- ZONAL
- RUTA
- COD_VVDD
- MODULO
- NOMBRE_PUNTO
- DEPARTAMENTO, PROVINCIA, DISTRITO
- DIRECCION
- CONGLOMERADO
- LATITUD, LONGITUD
- VENDEDORES
- TIPO_VISITA (programacion)
- FRECUENCIA
- STATUS
- COMENTARIOS

Notas de consistencia
- La deduplicacion ya se aplica en el SP:
  - CU_ELIMINAR = MODULO + FECHA_INI (serial Excel) + IDPDV +
    MARCACION_EN_PUNTO_FORMULADO (SI/NO)
  - CU_VALIDAR  = MODULO + FECHA_INI (serial Excel) + IDPDV
- Por lo tanto, el exportador debe leer SOLO la tabla ejecutadas
  y no volver a filtrar duplicados en Python.

Sugerencia de consulta base (para exportar por fecha)
SELECT
    *
FROM dbo.PDV_VISITAS_AD_EJECUTADAS
WHERE FECHA_INI = @fecha;
