# Plan de Migración Frontend - Endpoint Payment Multimarca

## Cambio Realizado
El endpoint `/api/v1/multimarca/payment/{dni}/{anio}/{mes}` se dividió en dos endpoints separados.

## Nuevos Endpoints

### 1. Datos Base
**URL:** `/api/v1/multimarca/getResumenBase/{dni}/{anio}/{mes}`

**Respuesta:**
```json
{
  "status": 200,
  "message": "Datos base obtenidos correctamente",
  "data": {
    "dni_vendedor": "45841008",
    "ventasLog": 10,
    "cantidadCalidad": 6,
    "pagoUniCalidad": 0,
    "bonoCalidad": 0,
    "cantidadPortaPostOPre": 0,
    "precioPortaPostOPre": 25,
    "cantidadPortaPostOPost": 0,
    "precioPortaPostOPost": 35,
    "bonoPortaPostOPre": 0,
    "bonoPortaPostOPost": 0,
    "bonoTotalBase": 0
  }
}
```

### 2. Datos de Recargas por Período
**URL:** `/api/v1/multimarca/getRecargasPorPeriodo/{dni}/{anio}/{mes}`

**Respuesta:**
```json
{
  "status": 200,
  "message": "Datos de recargas por período obtenidos correctamente",
  "data": [
    {
      "dni_vendedor": "45841008",
      "periodo_evaluacion": "N0",
      "monto_recargado": 324,
      "ganancia_por_recarga": 129.6
    },
    {
      "dni_vendedor": "45841008",
      "periodo_evaluacion": "N1",
      "monto_recargado": 0,
      "ganancia_por_recarga": 0
    }
  ],
  "total_periodos": 2,
  "total_bono_recargas": 129.6
}
```

## Instrucciones para el Frontend

1. **Crear dos funciones separadas:**
   - `getResumenBase(dni, anio, mes)` - para datos base
   - `getRecargasPorPeriodo(dni, anio, mes)` - para datos de recargas

2. **Modificar la lógica de presentación:**
   - Mostrar datos base una sola vez
   - Mostrar datos de recargas en tabla/lista
   - Usar `total_bono_recargas` para el total de bonos por recargas

3. **Mantener compatibilidad:**
   - El endpoint original sigue funcionando
   - Migrar gradualmente
   - No romper funcionalidad existente

## Beneficios
- Mejor rendimiento
- Datos más organizados
- Fácil mantenimiento
- Separación de responsabilidades
