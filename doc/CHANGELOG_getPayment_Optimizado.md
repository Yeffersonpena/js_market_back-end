# CHANGELOG: Implementación de getPayment Optimizado

## Fecha: Diciembre 2025

## Cambio Implementado

### Archivo: `app/Http/Controllers/All/LogicController.php`

Se modificó el método `getPayment()` para usar automáticamente el endpoint optimizado desde **diciembre 2025 en adelante**, manteniendo el SP original para meses anteriores.

---

## Lógica de Selección (Líneas 235-242)

```php
// Lógica de selección: usar optimizado para diciembre 2025 en adelante
// Para meses anteriores (noviembre 2025 o antes), usar el SP original
$usarOptimizado = ($anio > 2025) || ($anio == 2025 && $mes >= 12);

if ($usarOptimizado) {
    // Usar el endpoint optimizado que consulta PDV_OUT_ESQUEMA_RESUMEN
    return $this->getPaymentOptimized($dni, $anio, $mes);
}

// Para meses anteriores a diciembre 2025, usar el SP original
$spPayment = DB::select("exec spCalculoPaymentAll ?,?,?,?,?", [$dni, $anio, $mes, 1, 2]);
```

### Condición de Activación:
- **Año > 2025**: Siempre usa optimizado
- **Año = 2025 Y Mes >= 12**: Usa optimizado
- **Año = 2025 Y Mes < 12**: Usa SP original
- **Año < 2025**: Usa SP original

---

## Endpoint Optimizado: `getPaymentOptimized()`

### Ubicación: Líneas 341-418

### Fuente de Datos:
- **Tabla**: `PDV_OUT_ESQUEMA_RESUMEN`
- **Modelo**: `App\Models\PDV_OUT_ESQUEMA_RESUMEN`
- **Dependencia**: Los datos deben estar pre-calculados ejecutando `sp_ActualizarEsquemaPDV`

### Mapeo de Campos:

| Campo API | Campo Tabla | Notas |
|-----------|-------------|-------|
| `bonoPre` | `BONO_UNITARIO_EQUIPO * VentaPrepagoLimitada` | Calculado |
| `bonoRecargaPre` | `bonoRecargaPre` | Directo |
| `bonoPortaPre` | `bonoPortaPre` | Directo |
| `bonoAltaPost` | `0.00` | Hardcodeado (igual que SP original cuando existe responsable) |
| `bonoPortaPostOPost` | `bonoPortaPostOPost` | Directo |
| `bonoPortaPostOPre` | `bonoPortaPostOPre` | Directo |
| `bonoChips` | `bonoChips` | Directo |
| `bonoTotalEfectivo` | `bonoTotalEfectivo` | Directo |
| `bonoTotal` | `bonoTotal` | Directo |
| `ventaTotal` | `VENTA_AVANCE_PREPAGO` | Directo |
| `faltaVenta` | `0.00` | Hardcodeado (igual que SP original línea 152) |
| `cantidadPortaPre` | `cantPrepagoPorta` | Directo |
| `precioUniPortaPre` | `4.00` | Hardcodeado |
| `cantidadAltaPost` | `cantidadAltaPost` | **⚠️ IMPORTANTE: Debe aplicar lógica existResp** |
| `precioUniAltaPost` | `0.00` | Hardcodeado (igual que SP original cuando existe responsable) |
| `cantidadPortaPostOPost` | `cantidadPortaPostOPost` | Directo |
| `precioPortaPostOPost` | `35.00` | Hardcodeado |
| `cantidadPortaPostOPre` | `cantidadPortaPostOPre` | Directo |
| `precioPortaPostOPre` | `20.00` | Hardcodeado |
| `precioUniSchema` | `BONO_UNITARIO_EQUIPO` | Directo |
| `levelUser` | `2.00` | Hardcodeado (todos PDV REGULAR) |
| `cantidadRecarga` | `TOTAL_RECARGAS` | Directo |
| `bonoDevolucionChips` | `bonoDevolucionChips` | Directo |
| `precioUniCalidadAdi` | `precioUniCalidadAdi` | Directo |
| `cantidadCalidad` | `TOTAL_VCALIDAD` | Directo |
| `bonoCalidad` | `bonoCalidad` | Directo |
| `zonal` | `ZONAL` | Directo |
| `nivel_rango` | `nivel_rango` | Directo |
| `rango_mes_anterior` | `RANGO_MES_ANTERIOR` | Directo |
| `tipo_bono` | `tipo_bono` | Directo |
| `bono_rango` | `bono_rango` | Directo |
| `ratio_min_requerido` | `ratio_min_requerido` | Directo |

---

## ⚠️ Lógica Pendiente: `cantidadAltaPost` (Línea 377)

### Estado Actual:
```php
"cantidadAltaPost" => (float) $paymentData->cantidadAltaPost,
```

### Debería Ser:
```php
// Verificar si existe responsable en PDV_OUT_ENTREGABLE (misma lógica que spCalculoPayment_12)
$existResp = PDV_ENTREGABLE::where('DNI_RESPONSABLE', $dni)
    ->where('AÑO', $anio)
    ->where('MES', $mes)
    ->exists();

"cantidadAltaPost" => $existResp ? 0.00 : (float) $paymentData->cantidadAltaPost,
```

### Referencia SP Original:
- **Archivo**: `database/procedures/spCalculoPayment_12.sql`
- **Línea 146**: `IIF(@existResp = 1, 0, c.cantidadAltaPost) AS cantidadAltaPost`

### Impacto:
- Si `existResp = true` → `cantidadAltaPost` debe ser `0`
- Si `existResp = false` → `cantidadAltaPost` = valor de la tabla
- **Nota**: Este campo no afecta los totales (`bonoTotalEfectivo`, `bonoTotal`), pero debe coincidir con el SP original para consistencia

---

## Endpoint Original: `getPayment()` (SP)

### Cuando se Usa:
- Años < 2025
- Año = 2025, Mes < 12 (enero a noviembre)

### Fuente de Datos:
- **Stored Procedure**: `spCalculoPaymentAll`
- **SP Interno**: `spCalculoPayment_12`
- **Cálculo**: En tiempo real desde tablas base

---

## Endpoints Disponibles

### 1. Endpoint Principal (Recomendado):
```
GET /api/v1/pdv/getPayment/{dni}/{anio}/{mes}
```
- **Comportamiento**: Selecciona automáticamente optimizado u original según fecha
- **Frontend**: No requiere cambios

### 2. Endpoint Optimizado (Solo Pruebas):
```
GET /api/v1/pdv/getPaymentOptimized/{dni}/{anio}/{mes}
```
- **Comportamiento**: Siempre usa tabla optimizada
- **Uso**: Solo para pruebas y validación

---

## Dependencias

### Para que el Optimizado Funcione:

1. **Tabla `PDV_OUT_ESQUEMA_RESUMEN` debe estar poblada**:
   ```sql
   EXEC sp_ActualizarEsquemaPDV @año, @mes
   ```

2. **Función `fn_CalcularBonoUnitario_PDV` debe estar actualizada**:
   - Archivo: `database/functions/fn_CalcularBonoUnitario_PDV.sql`
   - Cambio: PDV REGULAR siempre usa `zonal_pattern = 'TODAS'`

3. **Tabla `BonoEscala` debe tener datos para el período**:
   - Verificar que existan registros con `fecha_inicio` y `fecha_fin` que cubran el mes consultado

---

## Troubleshooting en Producción

### Problema 1: Endpoint optimizado devuelve datos vacíos o incorrectos

**Causa**: Tabla `PDV_OUT_ESQUEMA_RESUMEN` no está actualizada

**Solución**:
```sql
-- Ejecutar SP de actualización
EXEC sp_ActualizarEsquemaPDV 2025, 12;
```

**Verificación**:
```sql
SELECT COUNT(*)
FROM PDV_OUT_ESQUEMA_RESUMEN
WHERE AÑO = 2025 AND MES = 12;
```

---

### Problema 2: Valores diferentes entre original y optimizado

**Causa 1**: Datos desactualizados en `PDV_OUT_ESQUEMA_RESUMEN`
- **Solución**: Re-ejecutar `sp_ActualizarEsquemaPDV`

**Causa 2**: Función `fn_CalcularBonoUnitario_PDV` no actualizada
- **Solución**: Re-compilar la función con el cambio de `zonalPattern`

**Causa 3**: `cantidadAltaPost` no aplica lógica `existResp`
- **Solución**: Implementar verificación de `PDV_ENTREGABLE` (ver sección "Lógica Pendiente")

---

### Problema 3: Revertir a SP original temporalmente

**Opción 1**: Comentar la lógica de selección (Líneas 235-242):
```php
// $usarOptimizado = ($anio > 2025) || ($anio == 2025 && $mes >= 12);
// if ($usarOptimizado) {
//     return $this->getPaymentOptimized($dni, $anio, $mes);
// }
$usarOptimizado = false; // Forzar uso de SP original
```

**Opción 2**: Cambiar la condición:
```php
$usarOptimizado = false; // Desactivar optimizado temporalmente
```

---

## Validación Post-Deploy

### Checklist:
- [ ] Verificar que `sp_ActualizarEsquemaPDV` se ejecuta correctamente
- [ ] Verificar que `PDV_OUT_ESQUEMA_RESUMEN` tiene datos para diciembre 2025
- [ ] Comparar resultados con script `compare_payments.py` para DNIs de prueba
- [ ] Verificar que `fn_CalcularBonoUnitario_PDV` está actualizada
- [ ] Probar con DNIs de LIMA SUR (eran los que fallaban antes)

### DNIs de Prueba Validados:
- ✅ 10475165 (LIMA SUR)
- ✅ 43313973 (LIMA SUR) - Corregido después de actualizar función
- ✅ 47724499 (LIMA SUR) - Corregido después de actualizar función
- ✅ 43997154 (LIMA SUR) - Corregido después de actualizar función
- ✅ 71633212 (LIMA SUR) - Solo diferencia en `cantidadAltaPost` (no afecta totales)

---

## Notas Importantes

1. **El frontend NO requiere cambios**: Sigue usando `/api/v1/pdv/getPayment/{dni}/{anio}/{mes}`

2. **Meses anteriores NO se afectan**: La lógica solo aplica para diciembre 2025 en adelante

3. **El endpoint optimizado es público**: Disponible en `/api/v1/pdv/getPaymentOptimized/{dni}/{anio}/{mes}` para pruebas

4. **Dependencia crítica**: `sp_ActualizarEsquemaPDV` debe ejecutarse regularmente para mantener datos actualizados

---

## Archivos Relacionados

- `app/Http/Controllers/All/LogicController.php` - Lógica de selección y mapeo
- `app/Models/PDV_OUT_ESQUEMA_RESUMEN.php` - Modelo Eloquent
- `database/procedures/sp_ActualizarEsquemaPDV.sql` - SP que calcula datos optimizados
- `database/functions/fn_CalcularBonoUnitario_PDV.sql` - Función corregida para zonalPattern
- `database/procedures/spCalculoPayment_12.sql` - SP original (referencia)
- `compare_payments.py` - Script de validación

---

## Historial de Cambios

### Diciembre 2025
- ✅ Implementada lógica de selección automática en `getPayment()`
- ✅ Creado método `getPaymentOptimized()` que consulta `PDV_OUT_ESQUEMA_RESUMEN`
- ✅ Corregida función `fn_CalcularBonoUnitario_PDV` para PDV REGULAR siempre use 'TODAS'
- ⚠️ Pendiente: Implementar verificación `existResp` para `cantidadAltaPost` en `getPaymentOptimized()`

