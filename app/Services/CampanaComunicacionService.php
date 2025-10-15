<?php

namespace App\Services;

use App\Models\PDVOutCampanasFlyers;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class CampanaComunicacionService
{
    private CampanaFileManager $fileManager;

    public function __construct(CampanaFileManager $fileManager)
    {
        $this->fileManager = $fileManager;
    }

    /**
     * Valida que la campaña sea de tipo ACELERADOR
     */
    public function validateAceleradorCampana(PDVOutCampanasFlyers $campana): array
    {
        $errors = [];

        if (strtoupper($campana->tipoImg) !== 'ACELERADOR') {
            $errors[] = 'Esta funcionalidad solo está disponible para campañas de tipo ACELERADOR';
        }

        return $errors;
    }

    /**
     * Actualiza los campos de comunicación en la base de datos
     */
    public function updateComunicacionFields(PDVOutCampanasFlyers $campana, string $fileName): bool
    {
        try {
            $campana->update([
                'comunicado' => 1,
                'fecha_comunicacion' => Carbon::now()->toDateString(),
                'archivo_comunicacion' => $fileName
            ]);

            Log::info('Campos de comunicación actualizados en BD', [
                'campana_id' => $campana->id,
                'archivo_comunicacion' => $fileName,
                'fecha_comunicacion' => $campana->fecha_comunicacion
            ]);

            return true;
        } catch (\Exception $e) {
            Log::error('Error actualizando campos de comunicación en BD', [
                'campana_id' => $campana->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return false;
        }
    }

    /**
     * Procesa la actualización completa de comunicación
     */
    public function processComunicacionUpdate(PDVOutCampanasFlyers $campana, $archivo): array
    {
        // Validar campaña
        $validationErrors = $this->validateAceleradorCampana($campana);
        if (!empty($validationErrors)) {
            return [
                'success' => false,
                'errors' => $validationErrors
            ];
        }

        // Guardar archivo
        $fileResult = $this->fileManager->saveComunicacionFile($archivo, $campana->id);
        if (!$fileResult['success']) {
            return [
                'success' => false,
                'errors' => $fileResult['errors']
            ];
        }

        // Actualizar campos en BD
        $updateSuccess = $this->updateComunicacionFields($campana, $fileResult['file_name']);
        if (!$updateSuccess) {
            // Si falla la actualización en BD, eliminar el archivo
            $this->fileManager->deleteComunicacionFile($fileResult['file_name']);
            
            return [
                'success' => false,
                'errors' => ['Error al actualizar los campos en la base de datos']
            ];
        }

        return [
            'success' => true,
            'data' => [
                'id' => $campana->id,
                'comunicado' => true,
                'fecha_comunicacion' => $campana->fecha_comunicacion,
                'archivo_comunicacion' => $campana->archivo_comunicacion,
                'download_url' => $fileResult['download_url']
            ]
        ];
    }

    /**
     * Obtiene información de descarga del archivo
     */
    public function getDownloadInfo(PDVOutCampanasFlyers $campana): array
    {
        if (!$campana->archivo_comunicacion) {
            return [
                'success' => false,
                'message' => 'No hay archivo de comunicación asociado a esta campaña'
            ];
        }

        if (!$this->fileManager->fileExists($campana->archivo_comunicacion)) {
            return [
                'success' => false,
                'message' => 'El archivo de comunicación no existe en el servidor'
            ];
        }

        $fileInfo = $this->fileManager->getFileInfo($campana->archivo_comunicacion);

        return [
            'success' => true,
            'data' => [
                'nombre_archivo' => $campana->archivo_comunicacion,
                'download_url' => $fileInfo['download_url'],
                'fecha_comunicacion' => $campana->fecha_comunicacion,
                'tamaño_archivo' => $fileInfo['file_size'],
                'fecha_modificacion' => $fileInfo['last_modified']
            ]
        ];
    }
}
