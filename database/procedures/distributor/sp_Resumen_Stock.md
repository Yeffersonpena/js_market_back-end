# sp_Resumen_Stock – Documentación

## Resumen

El procedimiento obtiene el resumen de stock por EMPRESA y MODELO (rangos de antigüedad, STOCK, COSTO, PRECIO_VTA). La base de detalle viene de `sp_Stock_General`; los precios de venta se asignan en el SP por cruce con tablas de precios en linked servers.

---

## Asignación de PRECIO_VTA

### JS

- **Origen de precios:** `[192.168.3.101,1800\MSSQL_NEW].[Distribuidora].[dbo].[WOLAP_PRECIOS_DETALLISTA]` (#PreciosJS).
- **Cruce:** por **CCOD_PROD** + **ALMACEN** (TIPO_VENTA_NORM). Una fila de #Base (JS) hace match cuando su `CCOD_PROD` y `ALMACEN` coinciden con una fila de #PreciosJS. Se asigna el PRECIO (agrupado por CCOD_PROD + TIPO_VENTA_NORM con MAX(PRECIO)).

### YALI (Amazonía) – Match por prefijo usando MODELO o CNOM_PROD

- **Origen de precios:** `[192.168.3.101,1900\MSSQL_log].[Distribuidora].[dbo].[WOLAP_PRECIOS_DETALLISTA]` (#PreciosYali).
- **Cruce:** por **prefijo del nombre** (`precios.CNOM_PROD LIKE nombre_base + '%'`). Se usa **MODELO** (nombre corto del maestro) cuando existe; si no, **CNOM_PROD** (YALI_STOCK.Modelo).
- **Por qué usar MODELO:** En precios los nombres suelen ser cortos + variante (ej. "HONOR X7C 8GB+256GB VERDE"). En #Base, CNOM_PROD puede ser el nombre largo de stock (ej. "HONOR X7C ALT-LX3 RAM 8GB + ROM 256GB GREEN"). Ese nombre largo no coincide por prefijo con el de precios, y el producto quedaría con NULL. Con MODELO del maestro ("HONOR X7C 8GB+256GB") sí hace match.
- **Regla de match:**
  - Si `b.MODELO` tiene valor: `p2.CNOM_PROD LIKE b.MODELO + '%'` (COLLATE Latin1_General_CI_AI).
  - Si `b.MODELO` está vacío: `p2.CNOM_PROD LIKE b.CNOM_PROD` normalizado `+ '%'`.
  - Se asigna **MAX(p2.PRECIO)** entre las filas que cumplen.
- **Campos en #Base:** MODELO y CNOM_PROD vienen de `sp_Stock_General` (YALI: MODELO del join a DCN_MAESTRO_PRODUCTO, CNOM_PROD = YALI_STOCK.Modelo).

---

## Qué se necesita para el cruce YALI

| Elemento | Origen |
|----------|--------|
| Nombre para buscar precio | **MODELO** (prioridad) o **CNOM_PROD** en #Base (Amazonía). MODELO viene del maestro vía `sp_Stock_General`. |
| Tabla de precios | **#PreciosYali** (CNOM_PROD, PRECIO), linked server 1900. |
| Regla | Prefijo: `precios.CNOM_PROD LIKE nombre_base + '%'`, COLLATE Latin1_General_CI_AI. |

---

## Historial de cambios

- **Precio YALI con MODELO:** Se restableció el uso de **MODELO** (maestro) cuando existe para el match por prefijo con #PreciosYali. Si solo se usa CNOM_PROD (nombre largo de stock), muchos productos que sí tienen precio en el linked quedan con NULL porque el nombre en precios es corto y no empieza con el nombre largo.
