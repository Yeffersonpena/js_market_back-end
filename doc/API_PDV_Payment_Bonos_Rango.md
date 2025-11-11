# API PDV Payment - Nuevos Campos: Bonos por Rango

## 📋 Resumen

Se han agregado **nuevos campos** al endpoint de payment para soportar el cálculo de bonos por comparación de rangos entre meses. Estos campos permiten al frontend mostrar información sobre el progreso del PDV y los bonos adicionales obtenidos por mantener o subir de rango.

## 🚀 Endpoint

### URL
```
GET /api/v1/pdv/getPayment/{dni}/{anio}/{mes}
```

### Parámetros
- `dni` (INT): DNI del responsable
- `anio` (INT): Año del período
- `mes` (INT): Mes del período

### Ejemplo de Uso
```bash
GET /api/v1/pdv/getPayment/12345678/2025/11
```

## 📊 Nuevos Campos en la Respuesta

### Estructura Completa de Respuesta

```json
{
    "status": 200,
    "message": "Hay pago para el vendedor Pdv del mes de 11",
    "data": {
        // ... campos existentes ...
        "nivel_rango": 5,
        
        // ⭐ NUEVOS CAMPOS - Bonos por Rango
        "rango_mes_anterior": 4,
        "tipo_bono": "sube",
        "bono_rango": 35.00
    }
}
```

## 🔍 Descripción Detallada de los Nuevos Campos

### 1. `rango_mes_anterior`
- **Tipo**: `INT`
- **Descripción**: Nivel de rango del mes anterior obtenido directamente del campo `RANGO` en la tabla `PDV_OUT_ENTREGABLE` para el mes actual
- **Ejemplo**: `4`
- **Valores posibles**: `0` a `8`
  - `0`: Sin rango o sin datos
  - `1`: Rango 1 (R1) - 5-9 ventas
  - `2`: Rango 2 (R2) - 10-19 ventas
  - `3`: Rango 3 (R3) - 20-29 ventas
  - `4`: Rango 4 (R4) - 30-39 ventas
  - `5`: Rango 5 (R5) - 40-49 ventas
  - `6`: Rango 6 (R6) - 50-79 ventas
  - `7`: Rango 7 (R7) - 80-99 ventas
  - `8`: Rango 8 (R8) - 100-150 ventas
- **Nota**: El rango del mes anterior viene directamente de `PDV_OUT_ENTREGABLE.RANGO` (ej: "RANGO 1" → 1, "RANGO 2" → 2). Si no existe registro, será `0`.

### 2. `tipo_bono`
- **Tipo**: `STRING | NULL`
- **Descripción**: Tipo de bono obtenido por comparación de rangos
- **Valores posibles**:
  - `"sube"`: El PDV subió de rango comparado con el mes anterior
  - `"mantiene"`: El PDV mantuvo el mismo rango del mes anterior
  - `null`: No aplica bono (bajó de rango o es el primer mes con datos)

### 3. `bono_rango`
- **Tipo**: `FLOAT`
- **Descripción**: Monto del bono obtenido por mantener o subir de rango (en soles)
- **Ejemplo**: `35.00`
- **Valores posibles**: `0.00` o mayor
- **Nota**: Solo tiene valor cuando `tipo_bono` no es `null`

## 💡 Lógica de Negocio

### Cómo se Determina el Tipo de Bono

1. **Sube de Rango** (`tipo_bono = "sube"`):
   - Cuando `nivel_rango` > `rango_mes_anterior`
   - Ejemplo: Mes anterior R4, mes actual R5 → `"sube"`

2. **Mantiene Rango** (`tipo_bono = "mantiene"`):
   - Cuando `nivel_rango` = `rango_mes_anterior` y ambos son > 0
   - Ejemplo: Mes anterior R5, mes actual R5 → `"mantiene"`

3. **No Aplica** (`tipo_bono = null`):
   - Cuando `nivel_rango` < `rango_mes_anterior` (bajó de rango)
   - Cuando es el primer mes con datos (`rango_mes_anterior = 0`)

### Escalas de Rango

**Importante**: El rango del mes anterior se obtiene directamente del campo `RANGO` en la tabla `PDV_OUT_ENTREGABLE` para el mes actual. Por ejemplo:
- Si consultas noviembre 2025 (`AÑO = 2025, MES = 11`), el campo `RANGO` contiene el rango del mes anterior (octubre)
- El rango actual se calcula en base a las ventas del mes actual

### Montos de Bonos (Noviembre 2025)

#### Bonos "Mantiene Rango"
| Rango | Monto (S/) |
|-------|------------|
| R3    | 15.00      |
| R4    | 20.00      |
| R5    | 25.00      |
| R6    | 30.00      |
| R7    | 35.00      |
| R8    | 40.00      |

#### Bonos "Sube de Rango"
| Rango Alcanzado | Monto (S/) |
|-----------------|------------|
| R2              | 20.00      |
| R3              | 25.00      |
| R4              | 30.00      |
| R5              | 35.00      |
| R6              | 40.00      |
| R7              | 45.00      |

**Nota**: Los montos pueden cambiar mes a mes. Se consultan dinámicamente desde la tabla `BonoRango`.

## 📊 Casos de Uso

### Caso 1: PDV Sube de Rango
```json
{
    "nivel_rango": 5,
    "rango_mes_anterior": 4,
    "tipo_bono": "sube",
    "bono_rango": 35.00
}
```
**Interpretación**: 
- Mes anterior: R4 (desde `PDV_OUT_ENTREGABLE.RANGO`)
- Mes actual: R5 (subió)
- Bono obtenido: S/ 35.00

### Caso 2: PDV Mantiene Rango
```json
{
    "nivel_rango": 6,
    "rango_mes_anterior": 6,
    "tipo_bono": "mantiene",
    "bono_rango": 30.00
}
```
**Interpretación**: 
- Mes anterior: R6 (desde `PDV_OUT_ENTREGABLE.RANGO`)
- Mes actual: R6 (mantuvo)
- Bono obtenido: S/ 30.00

### Caso 3: PDV Baja de Rango
```json
{
    "nivel_rango": 3,
    "rango_mes_anterior": 6,
    "tipo_bono": null,
    "bono_rango": 0.00
}
```
**Interpretación**: 
- Mes anterior: R6 (desde `PDV_OUT_ENTREGABLE.RANGO`)
- Mes actual: R3 (bajó)
- No obtiene bono

### Caso 4: Primer Mes con Datos o Sin Rango Anterior
```json
{
    "nivel_rango": 4,
    "rango_mes_anterior": 0,
    "tipo_bono": null,
    "bono_rango": 0.00
}
```
**Interpretación**: 
- No hay rango del mes anterior en `PDV_OUT_ENTREGABLE` (`rango_mes_anterior = 0`)
- No obtiene bono por comparación

## 🎯 Integración con `bonoTotal`

**Importante**: El `bono_rango` ya está incluido en los totales:
- `bonoTotalEfectivo`: Incluye `bono_rango`
- `bonoTotal`: Incluye `bono_rango` + `bonoDevolucionChips`

**No es necesario sumar manualmente** el `bono_rango` a los totales, ya viene calculado.

---

**Versión**: 1.0  
**Fecha**: Noviembre 2025  
**Estado**: Listo para Implementación  
**Compatibilidad**: Noviembre 2025 en adelante

