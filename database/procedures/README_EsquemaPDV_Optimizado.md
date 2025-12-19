# Arquitectura Optimizada para sp_Esquema_PDV

## Problema Original
- `sp_Esquema_PDV` tardaba **20 minutos** en ejecutarse
- Múltiples escaneos de tablas grandes (VentasLog, PDV_OUT_FUNNEL, tbl_venta_log)
- UNION ALL complejo en EventosCombinados
- OUTER APPLY ejecutado por cada PDV para calcular bonos

## Solución: Arquitectura en 3 Tablas + 3 SPs

### Tabla Creada

1. **`PDV_OUT_ESQUEMA_RESUMEN`**: Tabla única de resultado final (denormalizada)
   - Se actualiza cuando cambian datos de ventas (diariamente)
   - Contiene: métricas de ventas + bonos + datos básicos
   - Optimización: todo se calcula en tablas temporales y se inserta directamente aquí

### Stored Procedures (2 SPs)

1. **`sp_ActualizarEsquemaPDV`** (SP de Actualización)
   - Calcula métricas, bonos y consolida resultado final
   - Se ejecuta en 3 etapas internas:
     - Etapa 1: Métricas de ventas (3-5 min)
     - Etapa 2: Bonos unitarios y de rango (2-4 min)
     - Etapa 3: Consolidación (<10 seg)
   - Optimizaciones: MERGE en lugar de UNION ALL, pre-filtra BonoEscala
   - Se llama desde `spLoadFileFunnel_New`
   - Tiempo total estimado: 5-9 minutos

2. **`sp_Esquema_PDV_Resumen`** (SP de Consulta)
   - Reemplaza a `sp_Esquema_PDV` para consultas
   - Lee directamente de `PDV_OUT_ESQUEMA_RESUMEN`
   - Tiempo estimado: <1 segundo

## Instalación

### 1. Crear la tabla
```sql
-- Ejecutar:
-- database/tables/PDV_OUT_ESQUEMA_RESUMEN.sql
```

### 2. Crear los SPs
```sql
-- Ejecutar en orden:
-- database/procedures/sp_ActualizarEsquemaPDV.sql
-- database/procedures/sp_Esquema_PDV_Resumen.sql
```

### 3. Modificar spLoadFileFunnel_New

Agregar al final del SP (después de línea 196):

```sql
-- Actualizar esquema PDV optimizado
EXEC dbo.sp_ActualizarEsquemaPDV @año, @mes;
```

## Uso

### Actualización (automática)
- Se ejecuta automáticamente cuando se cargan datos de ventas
- Tiempo total: 5-9 minutos (vs 20 minutos original)

### Consulta
```sql
-- En lugar de:
EXEC dbo.sp_Esquema_PDV @año, @mes;

-- Usar:
EXEC dbo.sp_Esquema_PDV_Resumen @año, @mes;
```

## Optimizaciones Implementadas

1. **Eliminación de UNION ALL**: Reemplazado por MERGE con tablas temporales
2. **Pre-filtrado de BonoEscala**: Se filtra una vez en tabla temporal
3. **Tablas temporales**: Todo se calcula en memoria (#MetricasCalculadas, #BonosCalculados)
4. **Una sola tabla final**: Eliminamos redundancia, todo se guarda directamente en RESUMEN
5. **Índices optimizados**: En tabla de resultados para consultas rápidas

## Rendimiento Esperado

- **Actualización completa**: 5-9 minutos (vs 20 minutos)
- **Consulta**: <1 segundo (vs 20 minutos)
- **Mejora total**: ~60-70% más rápido

## Notas Importantes

- Los cálculos son **idénticos** a `sp_Esquema_PDV` original
- Respeta la lógica de `spCalculoPayment_12`
- `sp_Esquema_PDV` original se mantiene para compatibilidad
- Las tablas se actualizan **siempre** cuando se cargan datos (no hay detección de cambios)

