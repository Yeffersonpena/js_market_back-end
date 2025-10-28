# API Endpoint - Descarga de Archivos de Campañas

## 📋 Descripción

Endpoint seguro para descargar archivos de comunicación de campañas almacenados en el servidor.

## 🚀 Endpoint

### URL
```
GET /api/v1/imagenes/campanas/download-secure/{fileName}
```

### Parámetros
- `fileName` (STRING): Nombre del archivo a descargar

### Ejemplo de Uso
```bash
GET /api/v1/imagenes/campanas/download-secure/comunicacion_campana_123.pdf
```

## 🔒 Seguridad

### Validaciones Implementadas
- ✅ **Verificación de existencia**: Valida que el archivo esté asociado a una campaña
- ✅ **Autorización**: Solo archivos de campañas registradas pueden descargarse
- ✅ **Verificación física**: Confirma que el archivo existe en el servidor
- ✅ **Logging**: Registra todas las descargas para auditoría

### Flujo de Seguridad
1. Busca la campaña asociada al archivo
2. Verifica que el archivo existe físicamente
3. Registra la descarga en logs
4. Retorna el archivo como descarga

## 📊 Respuestas

### Éxito (200)
- **Tipo**: Archivo binario
- **Headers**: `Content-Disposition: attachment`
- **Descripción**: Descarga directa del archivo

### Error 404 - Archivo No Encontrado
```json
{
    "success": false,
    "message": "Archivo no encontrado o no autorizado"
}
```

### Error 404 - Archivo No Existe en Servidor
```json
{
    "success": false,
    "message": "El archivo no existe en el servidor"
}
```

### Error 500 - Error Interno
```json
{
    "success": false,
    "message": "Error interno del servidor"
}
```

## 🗂️ Ubicación de Archivos

### Directorio de Almacenamiento
- **Ruta**: `storage/app/comunicaciones/`
- **Tipo**: Almacenamiento privado (no accesible públicamente)
- **Permisos**: Solo a través del endpoint seguro

### Estructura de Archivos
```
storage/app/comunicaciones/
├── comunicacion_campana_123.pdf
├── comunicacion_campana_456.docx
└── comunicacion_campana_789.jpg
```

## 🔧 Implementación Técnica

### Función Principal
- **Controlador**: `ImagenController@downloadSecureFile`
- **Modelo**: `PDVOutCampanasFlyers`
- **Storage**: Laravel Storage (disk: local)

### Validaciones
```php
// 1. Verificar campaña asociada
$campana = PDVOutCampanasFlyers::where('archivo_comunicacion', $fileName)->first();

// 2. Verificar existencia física
$filePath = 'comunicaciones/' . $fileName;
Storage::disk('local')->exists($filePath);

// 3. Retornar descarga
return response()->download($fullPath, $fileName);
```

## 📝 Logs de Auditoría

### Información Registrada
- Nombre del archivo descargado
- ID de la campaña asociada
- Tamaño del archivo
- Ruta completa del archivo
- Timestamp de la descarga

### Ejemplo de Log
```json
{
    "level": "info",
    "message": "Descarga segura de archivo de comunicación",
    "context": {
        "file_name": "comunicacion_campana_123.pdf",
        "campana_id": 123,
        "file_size": 1024000,
        "file_path": "/path/to/storage/comunicaciones/comunicacion_campana_123.pdf"
    }
}
```

## ⚠️ Consideraciones Importantes

### Limitaciones
- Solo archivos asociados a campañas registradas
- Archivos almacenados en directorio privado
- Sin autenticación adicional (depende de la URL)

### Tipos de Archivo Soportados
- PDF, DOC, DOCX, XLS, XLSX
- JPG, PNG, GIF
- Otros tipos según configuración del servidor

### Performance
- Descarga directa desde almacenamiento local
- Sin procesamiento adicional
- Respuesta inmediata para archivos existentes

---

**Versión**: 1.0  
**Fecha**: Diciembre 2024  
**Estado**: Activo
