# Recopilacion - API de puntos registrados

## Objetivo

Agregar un endpoint para listar los PDV que ya tienen visita creada en el periodo, con el fin de habilitar en frontend un módulo de "encuestados registrados" con acción de edición.

Esto permite que el usuario vendedor (perfil 6) vuelva a abrir formularios ya iniciados, ya que esos puntos no aparecen en la lista de pendientes.

## Endpoint

- Metodo: `GET`
- Ruta: `/api/v1/recopilacion/puntos-registrados`
- Middleware: `jwt.apiRest.jsMarket`, `jwt.user.recopilacion`
- Controlador: `RecopilacionController@puntosRegistrados`

## Parametros de consulta

- `anio` (opcional, int): default `now()->year`
- `mes` (opcional, int): default `now()->month`
- `formulario_codigo` (opcional, string): default `DATOS_PDV_VENTAS`
- `page` (opcional, int): default `1`
- `per_page` (opcional, int): default `15`, minimo `5`, maximo `100`
- `search` (opcional, string): busca por `nro_documento` o `nombre_pdv`

## Reglas de acceso por perfil

- Perfil 6 (ejecutor): solo PDV asignados a su `dni_ejecutor` en `RC_PDV_ASIGNACION_VISITA` y con `fecha_visita_tentativa` no nula.
- Perfil 7 (zonal): filtra por `RC_CLIENTE_PDV.zonal = zonal del token`.
- Perfil 8 (maestro): sin filtro por zonal ni asignacion.

## Criterio de "registrado"

Un PDV se considera registrado si existe fila en `RC_VISITA_FORMULARIO` para:

- `cliente_id = RC_CLIENTE_PDV.id`
- `formulario_id` del formulario activo resuelto por `formulario_codigo`
- `anio` y `mes` solicitados

## Campos de salida por item

- `cliente_id`
- `nro_documento`
- `nombre_pdv`
- `zonal`
- `vendedor`
- `promedio_equipo`
- `total_s_venta_accesorio`
- `vende_accesorios`
- `visita_id`
- `estado_visita`
- `porcentaje_avance`
- `fecha_ultima_edicion`

## Estructura de respuesta

```json
{
  "status": 200,
  "data": [
    {
      "cliente_id": 123,
      "nro_documento": "12345678",
      "nombre_pdv": "PDV EJEMPLO",
      "zonal": "LIMA CENTRO",
      "vendedor": "NOMBRE VENDEDOR",
      "promedio_equipo": 1500.0,
      "total_s_venta_accesorio": 250.0,
      "vende_accesorios": 1,
      "visita_id": 456,
      "estado_visita": "borrador",
      "porcentaje_avance": 45,
      "fecha_ultima_edicion": "2026-04-15T14:30:00.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 1,
    "last_page": 1
  }
}
```

## Diferencia funcional frente a pendientes

- `puntos-pendientes`: lista PDV sin visita en el periodo.
- `puntos-registrados`: lista PDV con visita en el periodo.

Con ambos endpoints se cubre el flujo completo:

1. Pendientes para iniciar captura.
2. Registrados para reingresar/editar visitas ya creadas.

