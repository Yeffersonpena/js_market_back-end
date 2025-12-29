# Changelog: Validación de Fecha Máxima Común

## Fecha: 2025-01-XX
## SP: `sp_ActualizarEsquemaPDV`

---

## 📋 Resumen del Problema

**Problema identificado:**
- Las tablas `VentasLog` y `PDV_OUT_FUNNEL` pueden tener datos hasta fechas diferentes.
- Ejemplo: VentasLog tiene datos hasta el día 28, pero Funnel solo hasta el día 26.
- Esto causaba que los **ratios se calcularan incorrectamente**:
  - `ratio = (TOTAL_RECARGAS / VENTA_AVANCE_PREPAGO) * 100`
  - Si recargas se calculan hasta día 26 pero ventas hasta día 28, el ratio queda subestimado.

**Impacto:**
- Ratios incorrectos → Bonos incorrectos
- Métricas inconsistentes entre fuentes de datos

---

## ✅ Solución Implementada

### 1. Validación Estricta de Fecha Máxima Común

**Ubicación:** Líneas 41-86 del SP

**Lógica:**
1. Se obtiene la fecha máxima de `VentasLog` para el período (solo Prepago).
2. Se obtiene la fecha máxima de `PDV_OUT_FUNNEL` para el período.
3. **Validación estricta:** Si alguna fuente no tiene datos, el SP termina con error.
4. **Fecha máxima común:** Se usa la **fecha mínima** entre ambas máximas.
   - Ejemplo: VentasLog máximo = 28, Funnel máximo = 26 → usar 26

**Código agregado:**
```sql
DECLARE @maxFechaVentasLog DATE;
DECLARE @maxFechaFunnel DATE;
DECLARE @fechaMaximaComun DATE;

-- Obtener fechas máximas
SELECT @maxFechaVentasLog = MAX(FECHA) FROM VentasLog WHERE ...
SELECT @maxFechaFunnel = MAX(fecha) FROM PDV_OUT_FUNNEL WHERE ...

-- Validar que ambas tengan datos (REQUISITO ESTRICTO)
IF @maxFechaVentasLog IS NULL OR @maxFechaFunnel IS NULL
BEGIN
    RAISERROR('Error: Una o ambas fuentes no tienen datos...', 16, 1, ...);
    RETURN;
END;

-- Usar la fecha mínima (fecha máxima común)
SET @fechaMaximaComun = CASE
    WHEN @maxFechaVentasLog < @maxFechaFunnel THEN @maxFechaVentasLog
    ELSE @maxFechaFunnel
END;
```

---

## 🔧 Cambios en Consultas

### Consultas de VentasLog (5 modificadas)

Todas las consultas de `VentasLog` ahora incluyen: `AND FECHA <= @fechaMaximaComun`

| Línea | Consulta | Métrica | Cambio |
|-------|----------|---------|--------|
| 109-110 | `PRE_PORTA` | Pre-portabilidades | ✅ Agregado filtro |
| 183-184 | `DIAS_VENTAS_RESPONSABLE` | Días con ventas | ✅ Agregado filtro |
| 199-200 | `VENTA_AVANCE_PREPAGO` | Ventas totales | ✅ Agregado filtro (usado en ratio) |
| 207-208 | `VENTA_PREPAGO_CALIDAD` | Ventas de calidad | ✅ Agregado filtro (usado en ratioCalidad) |
| 191 | `VENTAS_MES_ANTERIOR` | Mes anterior | ⚠️ No modificado (es del mes anterior) |

### Consultas de PDV_OUT_FUNNEL (5 modificadas)

Todas las consultas de `PDV_OUT_FUNNEL` ahora incluyen: `AND f.fecha <= @fechaMaximaComun`

| Línea | Consulta | Métrica | Cambio |
|-------|----------|---------|--------|
| 120-121 | `TOTAL_RECARGAS` | Recargas | ✅ Agregado filtro (usado en ratio) |
| 133-134 | `TOTAL_VCALIDAD` | Ventas de calidad | ✅ Agregado filtro (usado en ratioCalidad) |
| 147-148 | `PORTAPRE` | Portabilidades prepago | ✅ Agregado filtro |
| 160-161 | `PORTAPOS` | Portabilidades postpago | ✅ Agregado filtro |
| 254-255 | `cantidadAltaPost`, `cantidadPortaPostOPost`, `cantidadPortaPostOPre` | Altas y portabilidades postpago | ✅ Agregado filtro |

---

## 📊 Impacto en Cálculos

### Ratios Corregidos

**Antes:**
- `ratio = (TOTAL_RECARGAS hasta día 26) / (VENTA_AVANCE_PREPAGO hasta día 28) * 100` ❌ Incorrecto

**Ahora:**
- `ratio = (TOTAL_RECARGAS hasta día 26) / (VENTA_AVANCE_PREPAGO hasta día 26) * 100` ✅ Correcto

**Mismo principio aplica a:**
- `ratioCalidad = (TOTAL_VCALIDAD / VENTA_PREPAGO_CALIDAD) * 100`

### Bonos Afectados

Los siguientes bonos ahora se calculan con métricas consistentes:
- `BONO_UNITARIO_EQUIPO` (depende de `ratio >= ratio_min`)
- `bonoCalidad` (depende de `ratioCalidad`)
- `bonoTotalEfectivo` y `bonoTotal` (suma de todos los bonos)

---

## ⚠️ Comportamiento del SP

### Validación Estricta

**Si una fuente no tiene datos:**
- El SP termina con error usando `RAISERROR`
- Mensaje de error incluye qué fuente falta y el período
- **No hay fallback** - es un requisito estricto

**Ejemplo de error:**
```
Error: Una o ambas fuentes (VentasLog/Funnel) no tienen datos para el período 12/2025.
VentasLog máximo: NULL, Funnel máximo: 2025-12-26
```

### Fecha Máxima Común

**Ejemplo práctico:**
- Hoy es 28 de diciembre 2025
- VentasLog tiene datos hasta: 2025-12-28
- Funnel tiene datos hasta: 2025-12-26
- **Resultado:** Todas las consultas usan fecha límite = 2025-12-26

---

## 📝 Notas Técnicas

1. **`VENTAS_MES_ANTERIOR`** no se modifica porque es del mes anterior, no del mes actual.

2. **`VENTA_PREPAGO_CALIDAD`** mantiene su lógica de `@maxDateCalidad` además del nuevo filtro:
   ```sql
   AND FECHA <= @fechaMaximaComun  -- Nuevo
   AND FECHA <= @maxDateCalidad    -- Existente (lógica de calidad)
   ```

3. **`TOTAL_VCALIDAD`** también mantiene ambas validaciones:
   ```sql
   AND f.fecha <= @fechaMaximaComun  -- Nuevo
   AND f.fecha <= @maxDateCalidad    -- Existente
   ```

---

## ✅ Beneficios

1. ✅ **Consistencia:** Todos los cálculos usan el mismo período de fechas
2. ✅ **Precisión:** Ratios calculados correctamente
3. ✅ **Validación:** Error claro si falta alguna fuente de datos
4. ✅ **Trazabilidad:** Comentarios claros en cada consulta modificada

---

## 🔍 Cómo Verificar

Para verificar que funciona correctamente:

1. **Ejecutar el SP** con un período que tenga datos en ambas fuentes
2. **Verificar que no hay error** si ambas fuentes tienen datos
3. **Verificar que hay error** si una fuente no tiene datos
4. **Comparar ratios** antes y después del cambio (deben ser más precisos)

---

## 📌 Archivos Modificados

- `database/procedures/sp_ActualizarEsquemaPDV.sql`
  - Líneas 41-86: Validación de fecha máxima común
  - Líneas 109-110, 120-121, 133-134, 147-148, 160-161: Filtros en MERGE
  - Líneas 183-184, 199-200, 207-208: Filtros en LEFT JOIN
  - Líneas 254-255: Filtro en consulta de postpago

---

**Fin del Changelog**

