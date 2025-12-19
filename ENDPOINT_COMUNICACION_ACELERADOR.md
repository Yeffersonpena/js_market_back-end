# Endpoint Comunicación Acelerador

## Endpoint
```
POST /api/v1/imagenes/campanas/{id}/comunicacion-acelerador
```

## Autenticación
- JWT Token requerido
- Permisos de administrador

## Parámetros
- **Path**: `id` (integer) - ID de la campaña
- **Body**: `archivo_comunicacion` (file) - Archivo Excel obligatorio

## Validaciones
- Campaña debe existir
- Campaña debe ser tipo "ACELERADOR"
- Archivo es obligatorio
- Solo archivos Excel (.xlsx, .xls)
- Tamaño máximo 10MB

## Respuesta Exitosa (200)
```json
{
  "success": true,
  "message": "Comunicación del acelerador actualizada exitosamente",
  "data": {
    "id": 123,
    "comunicado": true,
    "fecha_comunicacion": "2025-01-15",
    "archivo_comunicacion": "comunicacion_acelerador_123_2025-01-15_14-30-25.xlsx",
    "download_url": "https://dominio.com/api/v1/imagenes/campanas/download-secure/archivo.xlsx"
  }
}
```

## Respuestas de Error
- **400**: "Campaña no encontrada" / "Esta funcionalidad solo está disponible para campañas de tipo ACELERADOR" / "El archivo de comunicación es obligatorio"
- **404**: "Campaña no encontrada"
- **422**: Errores de validación de archivo
- **500**: Error interno del servidor

## Campos Actualizados en BD
- `comunicado`: 1
- `fecha_comunicacion`: fecha actual
- `archivo_comunicacion`: nombre único generado

## Almacenamiento
- Archivos guardados en `storage/app/private/comunicaciones/`
- Descarga directa mediante: `GET /api/v1/imagenes/campanas/download-secure/{fileName}`
- Acceso solo mediante endpoint autenticado
