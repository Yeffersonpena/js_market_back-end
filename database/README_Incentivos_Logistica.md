# Incentivos Logistica - Documentacion de implementacion

Este documento resume lo implementado para sistematizar el seguimiento y cierre de incentivos de logistica en `DISTRIBUTOR_DATAMART`.

## 1) Objetivo funcional

- Centralizar la configuracion de incentivos por periodo.
- Definir cuotas y bonos por zonal/categoria.
- Unificar nombres de vendedores entre JS y YALI.
- Calcular avance por zonal.
- Cerrar el incentivo registrando ganadores en base de datos.

## 2) Modelo de datos implementado

### Tabla cabecera
- Archivo: `database/tables/distributor/incentivo_cabecera.sql`
- Tabla: `DISTRIBUTOR_DATAMART.dbo.incentivo_cabecera`
- Uso: maestro del incentivo (nombre, tipo, fecha inicio/fin, reglas, estado).

Campos clave:
- `id`
- `nombre_incentivo`
- `tipo_incentivo` (`BONO_EFECTIVO`, `SORTEO`, `MIXTO`)
- `fecha_inicio`, `fecha_fin`
- `estado` (`BORRADOR`, `ACTIVO`, `CERRADO`, `LIQUIDADO`)
- `activo`

### Tabla detalle de cuotas
- Archivo: `database/tables/distributor/incentivo_cuotas_detalle.sql`
- Tabla: `DISTRIBUTOR_DATAMART.dbo.incentivo_cuotas_detalle`
- Uso: cuotas/bonos por `zonal` y `categoria`.

Campos clave:
- `incentivo_id`
- `zonal`
- `categoria` (`EQUIPOS`, `ACCESORIOS`, `TODAS`)
- `cuota1`, `bono1`, `cuota2`, `bono2`
- `activo`

### Tabla de ganadores
- Archivo: `database/tables/distributor/incentivo_ganadores.sql`
- Tabla: `DISTRIBUTOR_DATAMART.dbo.incentivo_ganadores`
- Uso: resultado oficial del cierre para pago/finanzas.

Campos clave:
- `incentivo_id`, `zonal`, `categoria`, `vendedor`
- `venta_monto`, `venta_total_zonal`, `participacion_pct`
- `cuota_alcanzada`, `bono_zonal`, `bono_asignado`
- `estado_pago` (`PENDIENTE`, `ENVIADO_FINANZAS`, `PAGADO`, `OBSERVADO`)

## 3) Carga de incentivo inicial (marzo 2026)

- Archivo: `database/tables/distributor/incentivo_insert_20260323_20260327_facturacion_total.sql`
- Crea una cabecera de incentivo del `2026-03-23` al `2026-03-27`.
- Inserta cuotas por zonal con `categoria = 'TODAS'` (facturacion total).

## 4) Migracion del modelo anterior

Se dejo de usar la tabla historica `cuotas_incentivos_logistica` para la operacion actual.

- El resumen ahora se basa en:
  - `incentivo_cabecera`
  - `incentivo_cuotas_detalle`

## 5) Estandarizacion de nombres de vendedores

### Diccionario de nombres
- Archivo: `database/tables/distributor/vendedor_nombre_diccionario.sql`
- Tabla: `DISTRIBUTOR_DATAMART.dbo.vendedor_nombre_diccionario`
- Uso: mapear `nombre_alias` -> `nombre_canonico`.

Campos:
- `nombre_alias`
- `nombre_canonico`
- `origen` (texto libre: `JS`, `YALI`, `PROGRAMACION`, etc.)
- `activo`

Nota:
- Se removio la restriccion CHECK de `origen` para permitir nuevos origenes libres.

### Ajuste por truncamiento (SQL 8152)
- Archivo: `database/tables/distributor/vendedor_nombre_diccionario_fix8152.sql`
- Uso: alargar columnas si la tabla ya existia con tamanos menores.

## 6) Stored procedures actualizados

### Resumen por zonal
- Archivo: `database/procedures/sp_CuotasIncentivosLogistica_Resumen.sql`

Cambio clave:
- Ahora requiere `@incentivo_id`.
- Lee cuotas desde `DISTRIBUTOR_DATAMART.dbo.incentivo_cuotas_detalle` (ya no desde tabla antigua).
- Mantiene logica de ventas JS + YALI.
- Soporta `@categoria = 'EQUIPOS' | 'ACCESORIOS' | 'TODAS'`.

### Ventas incentivo (resumen)
- Archivo: `database/procedures/distributor/sp_Ventas_Incentivo.sql`

Cambio clave:
- Unifica `NOM_VENDEDOR` usando diccionario (`nombre_canonico`) con fallback a nombre normalizado.
- Normaliza strings (UPPER/TRIM + limpieza de espacios especiales).

### Ventas incentivo detalle
- Archivo: `database/procedures/distributor/sp_Ventas_Incentivo_Detalle.sql`

Cambio clave:
- Aplica la misma normalizacion/unificacion de vendedor que el SP resumen.

## 7) Cierre de incentivo y registro de ganadores

### Nuevo SP de cierre
- Archivo: `database/procedures/distributor/sp_Incentivo_Cerrar_Ganadores.sql`

Funcion:
- Cierra incentivo por `@incentivo_id`.
- Calcula ventas del periodo (`fecha_inicio/fecha_fin` de cabecera).
- Evalua cuota alcanzada y bono zonal.
- Reparte bono proporcional por vendedor.
- Inserta en `incentivo_ganadores`.
- Permite reproceso y cierre de estado en cabecera.

Parametros:
- `@incentivo_id INT`
- `@categoria VARCHAR(20) = NULL`
- `@reprocesar BIT = 0`
- `@cerrar_incentivo BIT = 0`

Regla de redondeo vigente:
- `bono_asignado` se redondea a **1 decimal**.

## 8) Flujo operativo recomendado

### Seguimiento diario
1. Consultar avance por zonal:
   - `sp_CuotasIncentivosLogistica_Resumen`
2. Consultar detalle vendedores:
   - `sp_Ventas_Incentivo`
   - `sp_Ventas_Incentivo_Detalle` (si se requiere detalle por producto)

### Cierre del incentivo
1. Ejecutar `sp_Incentivo_Cerrar_Ganadores`.
2. Revisar resumen devuelto por el SP.
3. Validar resultados en `incentivo_ganadores`.
4. (Opcional) dejar incentivo en estado `CERRADO`.

## 9) Consultas de ejemplo

### Resumen por zonal (facturacion total)
```sql
EXEC sp_CuotasIncentivosLogistica_Resumen
    @incentivo_id = 1,
    @fecha_inicio = '2026-03-23',
    @fecha_fin = '2026-03-27',
    @categoria = 'TODAS';
```

### Cierre y registro de ganadores
```sql
EXEC sp_Incentivo_Cerrar_Ganadores
    @incentivo_id = 1,
    @categoria = 'TODAS',
    @reprocesar = 1,
    @cerrar_incentivo = 1;
```

## 10) Estado actual

Implementacion base completa para:
- configuracion de incentivo,
- cuotas por zonal/categoria,
- estandarizacion de nombres,
- seguimiento por ventas,
- cierre con registro de ganadores.

Pendiente solo segun operacion:
- cargar historial completo de incentivos de marzo 2026 (y meses siguientes),
- ejecutar cierres y gestion de pago (`estado_pago`) segun flujo financiero.

