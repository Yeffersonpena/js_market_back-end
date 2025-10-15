<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class CampanaFileManager
{
    private const COMUNICACIONES_DIRECTORY = 'comunicaciones';
    private const MAX_FILE_SIZE = 10240; // 10MB en KB
    private const ALLOWED_MIME_TYPES = ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/vnd.ms-excel'];
    private const ALLOWED_EXTENSIONS = ['xlsx', 'xls'];

    /**
     * Valida el archivo de comunicación
     */
    public function validateComunicacionFile(UploadedFile $file): array
    {
        $errors = [];

        // Validar tamaño
        if ($file->getSize() > self::MAX_FILE_SIZE * 1024) {
            $errors[] = 'El archivo excede el tamaño máximo de ' . self::MAX_FILE_SIZE . 'KB';
        }

        // Validar tipo MIME
        if (!in_array($file->getMimeType(), self::ALLOWED_MIME_TYPES)) {
            $errors[] = 'El archivo debe ser un archivo Excel (.xlsx o .xls)';
        }

        // Validar extensión
        $extension = strtolower($file->getClientOriginalExtension());
        if (!in_array($extension, self::ALLOWED_EXTENSIONS)) {
            $errors[] = 'La extensión del archivo debe ser .xlsx o .xls';
        }

        return $errors;
    }

    /**
     * Genera un nombre único para el archivo de comunicación
     */
    public function generateComunicacionFileName(int $campanaId, string $extension): string
    {
        $timestamp = Carbon::now()->format('Y-m-d_H-i-s');
        $uniqueId = substr(md5(uniqid(rand(), true)), 0, 8);
        
        return "comunicacion_acelerador_{$campanaId}_{$timestamp}_{$uniqueId}.{$extension}";
    }

    /**
     * Guarda el archivo de comunicación
     */
    public function saveComunicacionFile(UploadedFile $file, int $campanaId): array
    {
        try {
            // Validar archivo
            $validationErrors = $this->validateComunicacionFile($file);
            if (!empty($validationErrors)) {
                return [
                    'success' => false,
                    'errors' => $validationErrors
                ];
            }

            // Crear directorio si no existe
            $this->ensureDirectoryExists();

            // Generar nombre único
            $extension = strtolower($file->getClientOriginalExtension());
            $fileName = $this->generateComunicacionFileName($campanaId, $extension);

            // Guardar archivo en almacenamiento privado
            $file->storeAs(self::COMUNICACIONES_DIRECTORY, $fileName, 'local');

            // Generar URL de descarga segura
            $downloadUrl = $this->generateSecureDownloadUrl($fileName);

            Log::info('Archivo de comunicación guardado exitosamente (privado)', [
                'campana_id' => $campanaId,
                'file_name' => $fileName,
                'file_size' => $file->getSize(),
                'mime_type' => $file->getMimeType(),
                'storage' => 'private'
            ]);

            return [
                'success' => true,
                'file_name' => $fileName,
                'file_path' => self::COMUNICACIONES_DIRECTORY . '/' . $fileName,
                'download_url' => $downloadUrl,
                'file_size' => $file->getSize()
            ];

        } catch (\Exception $e) {
            Log::error('Error guardando archivo de comunicación', [
                'campana_id' => $campanaId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'errors' => ['Error interno al guardar el archivo: ' . $e->getMessage()]
            ];
        }
    }

    /**
     * Verifica si un archivo de comunicación existe
     */
    public function fileExists(string $fileName): bool
    {
        $filePath = self::COMUNICACIONES_DIRECTORY . '/' . $fileName;
        return Storage::disk('local')->exists($filePath);
    }

    /**
     * Obtiene la URL de descarga segura de un archivo
     */
    public function getFileDownloadUrl(string $fileName): string
    {
        return $this->generateSecureDownloadUrl($fileName);
    }

    /**
     * Elimina un archivo de comunicación
     */
    public function deleteComunicacionFile(string $fileName): bool
    {
        try {
            $filePath = self::COMUNICACIONES_DIRECTORY . '/' . $fileName;
            
            if (Storage::disk('local')->exists($filePath)) {
                Storage::disk('local')->delete($filePath);
                
                Log::info('Archivo de comunicación eliminado (privado)', [
                    'file_name' => $fileName,
                    'file_path' => $filePath
                ]);
                
                return true;
            }

            return false;
        } catch (\Exception $e) {
            Log::error('Error eliminando archivo de comunicación', [
                'file_name' => $fileName,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * Asegura que el directorio de comunicaciones existe
     */
    private function ensureDirectoryExists(): void
    {
        $directoryPath = self::COMUNICACIONES_DIRECTORY;
        if (!Storage::disk('local')->exists($directoryPath)) {
            Storage::disk('local')->makeDirectory($directoryPath);
        }
    }

    /**
     * Genera la URL de descarga segura del archivo
     */
    private function generateSecureDownloadUrl(string $fileName): string
    {
        $baseUrl = env('APP_DOMAIN', 'http://localhost');
        return $baseUrl . '/api/v1/imagenes/campanas/download-secure/' . $fileName;
    }

    /**
     * Obtiene información del archivo sin descargarlo
     */
    public function getFileInfo(string $fileName): ?array
    {
        $filePath = self::COMUNICACIONES_DIRECTORY . '/' . $fileName;
        
        if (!Storage::disk('local')->exists($filePath)) {
            return null;
        }

        $fileSize = Storage::disk('local')->size($filePath);
        $lastModified = Storage::disk('local')->lastModified($filePath);

        return [
            'file_name' => $fileName,
            'file_size' => $fileSize,
            'last_modified' => Carbon::createFromTimestamp($lastModified)->toDateTimeString(),
            'download_url' => $this->generateSecureDownloadUrl($fileName)
        ];
    }
}
