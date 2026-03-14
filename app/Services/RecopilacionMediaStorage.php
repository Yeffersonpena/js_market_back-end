<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class RecopilacionMediaStorage
{
    public const DISK = 'recopilacion';

    /** Tamaño máximo por archivo: 10 MB */
    public const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024;

    /** MIME permitidos para fotos */
    public const ALLOWED_MIME_PHOTO = [
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/gif',
    ];

    /**
     * Guarda una foto en recopilacion/{visita_id}/{pregunta_id}/{uuid}.{ext}
     * Retorna array con ruta_archivo (relativa al disco), nombre_archivo, mime_type, tamano_bytes.
     */
    public function savePhoto(UploadedFile $file, int $visitaId, int $preguntaId): array
    {
        $ext = strtolower($file->getClientOriginalExtension() ?: 'jpg');
        if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp', 'gif'], true)) {
            $ext = 'jpg';
        }
        $nombre = Str::uuid()->toString() . '.' . $ext;
        $dir = "visita_{$visitaId}/pregunta_{$preguntaId}";
        $path = $dir . '/' . $nombre;

        $file->storeAs($dir, $nombre, self::DISK);

        return [
            'ruta_archivo' => $path,
            'nombre_archivo' => $file->getClientOriginalName(),
            'mime_type' => $file->getMimeType(),
            'tamano_bytes' => $file->getSize(),
        ];
    }

    /**
     * Elimina un archivo por su ruta (relativa al disco recopilacion).
     */
    public function deleteByPath(string $ruta): bool
    {
        if ($ruta === '' || preg_match('/\.\./', $ruta)) {
            return false;
        }
        return Storage::disk(self::DISK)->delete($ruta);
    }

    /**
     * Valida archivo para foto: tipo y tamaño.
     * Retorna array de mensajes de error; vacío si es válido.
     */
    public function validatePhoto(UploadedFile $file): array
    {
        $errors = [];
        if ($file->getSize() > self::MAX_FILE_SIZE_BYTES) {
            $errors[] = 'El archivo no debe superar 10 MB';
        }
        if (!in_array($file->getMimeType(), self::ALLOWED_MIME_PHOTO, true)) {
            $errors[] = 'Solo se permiten imágenes (JPEG, PNG, WebP, GIF)';
        }
        return $errors;
    }
}
