# API - Programación de Visitas AD

## Descripción General

API REST para gestionar la programación mensual de visitas a PDVs del canal AD (Tecnología y Telecom). Permite crear, consultar, actualizar y eliminar programaciones de visitas, así como gestionar los días específicos programados para cada PDV.

**Base de Datos:** Base de datos principal (dbo)
**Autenticación:** JWT Token requerido
**Permisos:** Solo usuarios con rol ADMIN

---

## Endpoints

### Base URL
```
/api/v1/admin/pdv-visitas-ad
```

### 1. Listar Programaciones

**GET** `/programacion`

Obtiene un listado paginado de programaciones con filtros opcionales.

#### Query Parameters

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `año` | integer | No | Filtrar por año |
| `mes` | integer | No | Filtrar por mes (1-12) |
| `dni` | integer | No | Filtrar por DNI responsable |
| `zonal` | string | No | Filtrar por zonal (búsqueda parcial) |
| `vendedor` | integer | No | Filtrar por código de vendedor (COD_VVDD) |
| `page` | integer | No | Número de página (default: 1) |
| `per_page` | integer | No | Registros por página (default: 10, max: 100) |

#### Ejemplo de Request
```
GET /api/v1/admin/pdv-visitas-ad/programacion?año=2025&mes=1&zonal=AYACUCHO&page=1&per_page=10
```

#### Ejemplo de Response
```json
{
  "status": 200,
  "message": "Listado de programaciones de visitas AD",
  "data": [
    {
      "id": 1,
      "dni_responsable": 12345678,
      "año": 2025,
      "mes": 1,
      "nombre_punto": "Punto de Venta ABC",
      "zonal": "AYACUCHO",
      "cod_vvdd": 198,
      "vendedores": "Juan Pérez",
      "tipo_visita": "PRESENCIAL",
      "frecuencia": "SEMANAL",
      "status": "PROGRAMADO",
      "cantidad_dias": 5,
      "fecha_creacion": "2025-01-15T10:30:00",
      "usuario_creacion": "admin"
    }
  ],
  "pagination": {
    "current_page": 1,
    "per_page": 10,
    "total": 50,
    "last_page": 5
  }
}
```

---

### 2. Obtener Programación Específica

**GET** `/programacion/{id}`

Obtiene una programación específica con todos sus días programados.

#### Path Parameters

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `id` | integer | ID de la programación |

#### Ejemplo de Request
```
GET /api/v1/admin/pdv-visitas-ad/programacion/1
```

#### Ejemplo de Response
```json
{
  "status": 200,
  "message": "Programación obtenida",
  "data": {
    "id": 1,
    "dni_responsable": 12345678,
    "año": 2025,
    "mes": 1,
    "nombre_punto": "Punto de Venta ABC",
    "zonal": "AYACUCHO",
    "direccion": "Av. Principal 123",
    "tipo_visita": "PRESENCIAL",
    "frecuencia": "SEMANAL",
    "status": "PROGRAMADO",
    "dias": [
      {
        "id": 1,
        "programacion_id": 1,
        "dia_mes": 1,
        "fecha_completa": "2025-01-01",
        "programado": true,
        "es_extraordinario": false
      },
      {
        "id": 2,
        "programacion_id": 1,
        "dia_mes": 3,
        "fecha_completa": "2025-01-03",
        "programado": true,
        "es_extraordinario": false
      }
    ]
  }
}
```

---

### 3. Crear Programación

**POST** `/programacion`

Crea una nueva programación (solo datos del PDV, sin días). Los días se agregan posteriormente con el endpoint `storeDias`.

#### Request Body

```json
{
  "dni_responsable": 12345678,
  "año": 2025,
  "mes": 1,
  "cod_cliente": "00012345",
  "zonal": "AYACUCHO",
  "ruta": "XA01",
  "cod_vvdd": 198,
  "modulo": "ACHJSM29",
  "nombre_punto": "Punto de Venta ABC",
  "cedula_cliente": "12345678",
  "departamento": "AYACUCHO",
  "provincia": "LA MAR",
  "distrito": "SAMUGARI",
  "direccion": "Av. Principal 123",
  "conglomerado": "Centro Comercial",
  "latitud": -12.76814108,
  "longitud": -73.65564689,
  "vendedores": "Juan Pérez",
  "tipo_visita": "PRESENCIAL",
  "frecuencia": "SEMANAL",
  "status": "PROGRAMADO",
  "comentarios": "Visita programada regular"
}
```

#### Campos Requeridos

- `dni_responsable` (integer)
- `año` (integer, 2020-2100)
- `mes` (integer, 1-12)

#### Campos Opcionales

Todos los demás campos son opcionales.

#### Validaciones

- Unicidad: No puede existir otra programación con el mismo `(DNI_RESPONSABLE, AÑO, MES)`
- Si ya existe → Error 409 (Conflict)

#### Ejemplo de Response
```json
{
  "status": 201,
  "message": "Programación creada exitosamente",
  "data": {
    "id": 1,
    "dni_responsable": 12345678,
    "año": 2025,
    "mes": 1,
    "nombre_punto": "Punto de Venta ABC",
    "status": "PROGRAMADO",
    "fecha_creacion": "2025-01-15T10:30:00",
    "usuario_creacion": "admin"
  }
}
```

---

### 4. Actualizar Programación

**PUT** `/programacion/{id}`

Actualiza los datos del PDV de una programación existente.

**IMPORTANTE:** No permite cambiar `DNI_RESPONSABLE`, `AÑO` ni `MES` (clave única).

#### Path Parameters

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `id` | integer | ID de la programación |

#### Request Body

Solo incluir los campos que se desean actualizar:

```json
{
  "nombre_punto": "Punto de Venta ABC - Actualizado",
  "direccion": "Av. Principal 456",
  "status": "CANCELADO",
  "comentarios": "Actualización de datos"
}
```

#### Ejemplo de Response
```json
{
  "status": 200,
  "message": "Programación actualizada",
  "data": {
    "id": 1,
    "nombre_punto": "Punto de Venta ABC - Actualizado",
    "fecha_actualizacion": "2025-01-15T11:00:00",
    "usuario_actualizacion": "admin"
  }
}
```

---

### 5. Eliminar Programación

**DELETE** `/programacion/{id}`

Elimina una programación. Los días asociados se eliminan automáticamente por CASCADE.

#### Path Parameters

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `id` | integer | ID de la programación |

#### Ejemplo de Response
```json
{
  "status": 200,
  "message": "Programación eliminada exitosamente"
}
```

---

### 6. Agregar Días a Programación

**POST** `/programacion/{id}/dias`

Agrega días programados a una programación existente.

#### Path Parameters

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `id` | integer | ID de la programación |

#### Request Body

```json
{
  "dias": [1, 3, 5, 7, 9, 11, 13, 15]
}
```

#### Validaciones

- `dias` debe ser un array con al menos 1 elemento
- Cada día debe ser un entero entre 1 y 31
- El día debe ser válido para el mes/año de la programación (ej: no día 31 en febrero)
- No se pueden duplicar días (ya programados)

#### Ejemplo de Response
```json
{
  "status": 201,
  "message": "8 día(s) creado(s) exitosamente",
  "data": [
    {
      "id": 1,
      "programacion_id": 1,
      "dia_mes": 1,
      "fecha_completa": "2025-01-01",
      "programado": true,
      "es_extraordinario": false
    },
    {
      "id": 2,
      "programacion_id": 1,
      "dia_mes": 3,
      "fecha_completa": "2025-01-03",
      "programado": true,
      "es_extraordinario": false
    }
  ],
  "warnings": null
}
```

#### Respuesta con Errores Parciales

Si algunos días no se pueden crear (duplicados o inválidos), se crean los válidos y se reportan los errores:

```json
{
  "status": 201,
  "message": "5 día(s) creado(s) exitosamente. 3 error(es): El día 1 ya está programado, El día 31 no es válido para el mes 2 del año 2025",
  "data": [...],
  "warnings": [
    "El día 1 ya está programado",
    "El día 31 no es válido para el mes 2 del año 2025"
  ]
}
```

---

### 7. Eliminar Día Específico

**DELETE** `/programacion/{id}/dias/{diaId}`

Elimina un día específico de una programación.

#### Path Parameters

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `id` | integer | ID de la programación |
| `diaId` | integer | ID del día a eliminar |

#### Ejemplo de Response
```json
{
  "status": 200,
  "message": "Día eliminado exitosamente"
}
```

---

### 8. Autocompletar Datos PDV

**GET** `/autocompletar/{dni}`

Obtiene datos del PDV desde `PDV_OUT_ENTREGABLE` para autocompletar el formulario.

#### Path Parameters

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `dni` | integer | DNI responsable del PDV |

#### Ejemplo de Request
```
GET /api/v1/admin/pdv-visitas-ad/autocompletar/12345678
```

#### Ejemplo de Response
```json
{
  "status": 200,
  "message": "Datos obtenidos correctamente",
  "data": {
    "cod_cliente": "00012345",
    "zonal": "AYACUCHO",
    "ruta": "XA01",
    "cod_vvdd": 198,
    "modulo": "ACHJSM29",
    "nombre_punto": "Punto de Venta ABC",
    "cedula_cliente": "12345678",
    "departamento": "AYACUCHO",
    "provincia": "LA MAR",
    "distrito": "SAMUGARI",
    "direccion": "Av. Principal 123",
    "conglomerado": "Centro Comercial",
    "latitud": -12.76814108,
    "longitud": -73.65564689,
    "vendedores": "Juan Pérez"
  }
}
```

#### Respuesta si no existe
```json
{
  "status": 404,
  "message": "No se encontraron datos para el DNI proporcionado",
  "data": null
}
```

---

## Códigos de Estado HTTP

| Código | Descripción |
|--------|-------------|
| 200 | OK - Operación exitosa |
| 201 | Created - Recurso creado exitosamente |
| 404 | Not Found - Recurso no encontrado |
| 409 | Conflict - Violación de unicidad |
| 422 | Unprocessable Entity - Error de validación |
| 500 | Internal Server Error - Error del servidor |

---

## Flujo de Uso Recomendado

### Crear Nueva Programación

1. **Autocompletar datos (opcional):**
   ```
   GET /autocompletar/{dni}
   ```

2. **Crear programación (solo datos PDV):**
   ```
   POST /programacion
   ```
   Guardar el `id` retornado.

3. **Agregar días programados:**
   ```
   POST /programacion/{id}/dias
   {
     "dias": [1, 3, 5, 7, 9, 11, 13, 15]
   }
   ```

### Actualizar Programación Existente

1. **Obtener programación actual:**
   ```
   GET /programacion/{id}
   ```

2. **Actualizar datos PDV:**
   ```
   PUT /programacion/{id}
   ```

3. **Agregar más días (si es necesario):**
   ```
   POST /programacion/{id}/dias
   ```

4. **Eliminar días específicos (si es necesario):**
   ```
   DELETE /programacion/{id}/dias/{diaId}
   ```

---

## Validaciones Importantes

### Unicidad
- No puede existir más de una programación con el mismo `(DNI_RESPONSABLE, AÑO, MES)`
- No puede existir más de un día con el mismo `(programacion_id, DIA_MES)`

### Validación de Fechas
- Los días deben ser válidos para el mes/año especificado
- Ejemplo: No se puede programar día 31 en febrero
- La función `calcularFechaCompleta()` valida automáticamente

### Campos Inmutables
- Una vez creada la programación, no se pueden cambiar:
  - `DNI_RESPONSABLE`
  - `AÑO`
  - `MES`

---

## Estructura de Datos

### Programación (PDV_VISITAS_AD_PROGRAMACION)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | integer | ID único (auto-increment) |
| dni_responsable | integer | DNI del responsable del PDV |
| año | integer | Año de la programación |
| mes | integer | Mes de la programación (1-12) |
| nombre_punto | string | Nombre del punto de venta |
| zonal | string | Zonal asignado |
| cod_vvdd | integer | Código del vendedor |
| tipo_visita | string | Tipo de visita (TELEGESTION, PRESENCIAL) |
| frecuencia | string | Frecuencia (SEMANAL, QUINCENAL, MENSUAL) |
| status | string | Estado (PROGRAMADO, CANCELADO, etc.) |

### Día Programado (PDV_VISITAS_AD_DIAS)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | integer | ID único (auto-increment) |
| programacion_id | integer | FK a programación |
| dia_mes | integer | Día del mes (1-31) |
| fecha_completa | date | Fecha completa (YYYY-MM-DD) |
| programado | boolean | Si está programado (1) o no (0) |
| es_extraordinario | boolean | Si es fuera de frecuencia normal |

---

## Notas Técnicas

1. **Transacciones:** El endpoint `storeDias` usa transacciones para garantizar atomicidad
2. **CASCADE:** Al eliminar una programación, los días se eliminan automáticamente
3. **Auditoría:** Todos los registros incluyen `FECHA_CREACION`, `USUARIO_CREACION`, `FECHA_ACTUALIZACION`, `USUARIO_ACTUALIZACION`
4. **Timezone:** Las fechas se manejan en timezone 'America/Lima'
5. **Transformación:** Los datos se transforman de mayúsculas (BD) a snake_case (API)

---

## Archivos Relacionados

- **Modelos:**
  - `app/Models/PDV_VISITAS_AD_PROGRAMACION.php`
  - `app/Models/PDV_VISITAS_AD_DIAS.php`
  - `app/Models/PDV_ENTREGABLE.php`

- **Controlador:**
  - `app/Http/Controllers/Admin/PDVVisitasADController.php`

- **Rutas:**
  - `routes/web.php` (dentro del bloque admin)

- **Tablas SQL:**
  - `database/tables/PDV_VISITAS_AD_PROGRAMACION.sql`
  - `database/tables/PDV_VISITAS_AD_DIAS.sql`

---

## Ejemplos de Uso Completo

### Ejemplo 1: Crear Programación Completa

```bash
# 1. Autocompletar datos
curl -X GET "http://api.example.com/api/v1/admin/pdv-visitas-ad/autocompletar/12345678" \
  -H "Authorization: Bearer {token}"

# 2. Crear programación
curl -X POST "http://api.example.com/api/v1/admin/pdv-visitas-ad/programacion" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "dni_responsable": 12345678,
    "año": 2025,
    "mes": 1,
    "nombre_punto": "Punto de Venta ABC",
    "zonal": "AYACUCHO"
  }'

# 3. Agregar días (usando el id retornado en paso 2)
curl -X POST "http://api.example.com/api/v1/admin/pdv-visitas-ad/programacion/1/dias" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "dias": [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31]
  }'
```

### Ejemplo 2: Listar y Filtrar

```bash
# Listar todas las programaciones de enero 2025
curl -X GET "http://api.example.com/api/v1/admin/pdv-visitas-ad/programacion?año=2025&mes=1" \
  -H "Authorization: Bearer {token}"

# Filtrar por zonal y vendedor
curl -X GET "http://api.example.com/api/v1/admin/pdv-visitas-ad/programacion?zonal=AYACUCHO&vendedor=198" \
  -H "Authorization: Bearer {token}"
```

---

## Errores Comunes

### Error 409: Conflict
**Causa:** Intento de crear una programación que ya existe para el mismo PDV, año y mes.

**Solución:** Verificar si ya existe una programación o actualizar la existente.

### Error 422: Validation Error
**Causa:** Datos inválidos en el request.

**Solución:** Revisar el campo `errors` en la respuesta para ver qué validaciones fallaron.

### Error 404: Not Found
**Causa:** Recurso no encontrado (programación, día, o PDV en autocompletar).

**Solución:** Verificar que el ID o DNI sea correcto.

---

## Changelog

### v1.0.0 (2025-01-15)
- Implementación inicial
- CRUD completo de programaciones
- Gestión de días programados
- Autocompletado desde PDV_OUT_ENTREGABLE
- Paginación y filtros en listado

