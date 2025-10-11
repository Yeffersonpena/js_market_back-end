# Documentación de Stored Procedures - PDV Regular

## Descripción General

Este documento describe los stored procedures utilizados para el cálculo de esquemas de bonificación para PDV (Puntos de Venta) Regular. Los procedimientos calculan métricas de ventas, recargas, portabilidades y bonos unitarios por responsable y vendedor.

---

## 1. sp_Esquema_PDV_Regular

### Propósito
Calcula el esquema de bonificación para PDV Regular que tienen vendedores asociados. Los vendedores se obtienen de la tabla especial `tbl_pdv_regular_vvdd` (casos especiales).

### Parámetros
- `@año` (int): Año del período a calcular
- `@mes` (int): Mes del período a calcular

### Fuente de Datos
- **Lista maestra**: `PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE`
- **Vendedores**: `tbl_pdv_regular_vvdd` (INNER JOIN)
- **Filtros**: `ACCION_1 = 'PDV REGULAR'` (sin validar ACCION_2)
- **Vendedores**: Solo 1 vendedor por responsable

### Columnas Devueltas

| Columna | Tipo | Descripción |
|---------|------|-------------|
| DNI_RESPONSABLE | int | DNI del responsable del PDV |
| NOMBRE_RESPONSABLE | varchar | Nombre del responsable del PDV |
| VVDD1 | int | DNI del vendedor asociado |
| NOMBRE_VENDEDOR | varchar | Nombre del vendedor asociado |
| ZONAL | varchar | Zona geográfica del PDV |
| VENTAS_RESPONSABLE | int | Número de ventas realizadas por el responsable |
| VENTAS_VVDD1 | int | Número de ventas realizadas por el vendedor |
| RECARGAS_RESPONSABLE | int | Número de recargas realizadas por el responsable |
| RECARGAS_VVDD1 | int | Número de recargas realizadas por el vendedor |
| VCALIDAD_RESPONSABLE | int | Ventas de calidad realizadas por el responsable |
| VCALIDAD_VVDD1 | int | Ventas de calidad realizadas por el vendedor |
| PRE_PORTA_RESPONSABLE | int | Portabilidades prepago realizadas por el responsable |
| PRE_PORTA_VVDD1 | int | Portabilidades prepago realizadas por el vendedor |
| PORTAPRE_RESPONSABLE | int | Portabilidades de prepago a prepago realizadas por el responsable |
| PORTAPRE_VVDD1 | int | Portabilidades de prepago a prepago realizadas por el vendedor |
| PORTAPOS_RESPONSABLE | int | Portabilidades de postpago realizadas por el responsable |
| PORTAPOS_VVDD1 | int | Portabilidades de postpago realizadas por el vendedor |
| DIAS_VENTAS_RESPONSABLE | int | Días únicos de ventas del equipo completo |
| TOTAL_VENTAS | int | Total de ventas del equipo |
| TOTAL_RECARGAS | int | Total de recargas del equipo |
| TOTAL_VCALIDAD | int | Total de ventas de calidad del equipo |
| RATIO_EQUIPO | decimal(10,2) | Porcentaje de recargas sobre ventas del equipo |
| BONO_UNITARIO_EQUIPO | decimal | Bono unitario calculado para el equipo |

---

## 2. sp_Esquema_PDV_Regular_Sin_HC

### Propósito
Calcula el esquema de bonificación para PDV Regular que NO tienen vendedores asociados. Solo muestra métricas del responsable.

### Parámetros
- `@año` (int): Año del período a calcular
- `@mes` (int): Mes del período a calcular

### Fuente de Datos
- **Lista maestra**: `PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE`
- **Exclusión**: `tbl_pdv_regular_vvdd` (LEFT JOIN con IS NULL)
- **Filtros**: `ACCION_1 = 'PDV REGULAR'` AND `v.dni_responsable IS NULL`
- **Vendedores**: Ninguno (solo responsable)

### Columnas Devueltas

| Columna | Tipo | Descripción |
|---------|------|-------------|
| DNI_RESPONSABLE | int | DNI del responsable del PDV |
| NOMBRE_RESPONSABLE | varchar | Nombre del responsable del PDV |
| ZONAL | varchar | Zona geográfica del PDV |
| VENTAS_RESPONSABLE | int | Número de ventas realizadas por el responsable |
| RECARGAS_RESPONSABLE | int | Número de recargas realizadas por el responsable |
| VCALIDAD_RESPONSABLE | int | Ventas de calidad realizadas por el responsable |
| PRE_PORTA_RESPONSABLE | int | Portabilidades prepago realizadas por el responsable |
| PORTAPRE_RESPONSABLE | int | Portabilidades de prepago a prepago realizadas por el responsable |
| PORTAPOS_RESPONSABLE | int | Portabilidades de postpago realizadas por el responsable |
| DIAS_VENTAS_RESPONSABLE | int | Días únicos de ventas del responsable |
| TOTAL_VENTAS | int | Total de ventas del responsable |
| TOTAL_RECARGAS | int | Total de recargas del responsable |
| TOTAL_VCALIDAD | int | Total de ventas de calidad del responsable |
| RATIO_EQUIPO | decimal(10,2) | Porcentaje de recargas sobre ventas del responsable |
| BONO_UNITARIO_EQUIPO | decimal | Bono unitario calculado para el responsable |

---

## Diferencias Clave Entre Stored Procedures

### sp_Esquema_PDV_Regular vs sp_Esquema_PDV_Regular_Sin_HC
- **Vendedores**: Regular tiene vendedores, Sin_HC no tiene
- **Columnas**: Regular incluye columnas de vendedor, Sin_HC solo responsable
- **Lógica**: Regular separa métricas por actor, Sin_HC solo responsable

---

## Uso en Python

### Ejemplo de llamada básica:
```python
# Para PDV Regular con vendedores
cursor.execute("EXEC sp_Esquema_PDV_Regular @año = ?, @mes = ?", (2025, 9))

# Para PDV Regular sin vendedores
cursor.execute("EXEC sp_Esquema_PDV_Regular_Sin_HC @año = ?, @mes = ?", (2025, 9))
```

### Estructura de DataFrame esperada:
- **Regular**: 20 columnas (solo VVDD1)
- **Regular_Sin_HC**: 15 columnas (solo responsable)

---

## Notas Importantes

1. **Función de Bono**: Todos los SP usan `dbo.fn_CalcularBonoUnitario()` con el tipo correspondiente
2. **Ordenamiento**: Resultados ordenados por ZONAL, DNI_RESPONSABLE
3. **Métricas**: Todos calculan ventas, recargas, portabilidades y ventas de calidad
4. **Días de Ventas**: Se calculan días únicos de ventas por responsable
5. **Ratio**: Porcentaje de recargas sobre ventas (evita división por cero)
