<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\JsonResponse;
use App\Models\PDVOutImagen;
use App\Models\PDVOutCampanasFlyers;
use App\Services\CampanaComunicacionService;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;

class ImagenController extends Controller
{
    private CampanaComunicacionService $comunicacionService;

    public function __construct(CampanaComunicacionService $comunicacionService)
    {
        $this->comunicacionService = $comunicacionService;
    }
    public function getPaginatedData(Request $request)
    {
        try {
            $existeUser = PDVOutImagen::exists();
            $search = $request->input('search', '');
            $perPage = $request->input('per_page', 10);

            if ($existeUser) {
                $listUser = PDVOutImagen::where('nombre_imagen', 'LIKE', "%$search%")
                    ->orderBy('fecha_modificacion', 'desc')
                    ->paginate($perPage);
                $data = $listUser->items();
                $data = array_map(function ($item) {
                    return [
                        'id' => $item->id,
                        'nombre_imagen' => $item->nombre_imagen,
                        'fecha_modificacion' => $item->fecha_modificacion,
                        'ruta_imagen' => env('APP_DOMAIN') . '/storage/img/' . $item->nombre_imagen,
                    ];
                }, $data);
                return response()->json([
                    'data' => $data,
                    'current_page' => $listUser->currentPage(),
                    'per_page' => $listUser->perPage(),
                    'total' => $listUser->total(),
                    'last_page' => $listUser->lastPage(),
                ]);
            } else {
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "No hay usuarios"
                ], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    public function upload(Request $request): JsonResponse
    {
        $request->validate([
            'image' => 'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);
        $filename = $request->file('image')->getClientOriginalName();
        $request->file('image')->storeAs('img', $filename, 'public');

        PDVOutImagen::create([
            'nombre_imagen' => $filename,
            'fecha_modificacion' => Carbon::now(),
        ]);


        $imageUrl = env('APP_DOMAIN') . '/storage/img/' . $filename;
        return response()->json([
            'message' => 'Imagen subida exitosamente',
            'url' => $imageUrl,
        ]);
    }

    public function updateImg(Request $request)
    {
        try {
            $request->validate([
                'images' => 'required|array',
                'images.*' => 'image|mimes:jpeg,png,jpg,gif,svg|max:2048',
            ]);

            $imageUrls = [];
            foreach ($request->file('images') as $image) {
                $filename = $image->getClientOriginalName();
                $image->storeAs('img', $filename, 'public');
                $imageUrl = env('APP_DOMAIN') . '/storage/img/' . $filename;
                $imageUrls[] = $imageUrl;
            }
            return response()->json(['message' => 'Imagen subida exitosamente', 'url' => $imageUrls]);
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    public function delete($id): JsonResponse
    {
        $imagen = PDVOutImagen::find($id);
        if (!$imagen) {
            return response()->json(['message' => 'Imagen no encontrada'], 404);
        }
        $filePath = 'public/img/' . $imagen->nombre_imagen;
        if (Storage::exists($filePath)) {
            Storage::delete($filePath);
        }
        $imagen->delete();
        return response()->json(['message' => 'Imagen eliminada correctamente']);
    }

    public function update(Request $request, $id): JsonResponse
    {
        if (!$request->hasFile('image')) {
            return response()->json([
                'message' => 'No se recibió ninguna imagen en la petición',
            ], 400);
        }
        $request->validate([
            'image' => 'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);
        $imagen = PDVOutImagen::find($id);
        if (!$imagen) {
            return response()->json(['message' => 'Imagen no encontrada'], 404);
        }
        $oldFilePath = 'public/img/' . $imagen->nombre_imagen;
        if (Storage::exists($oldFilePath)) {
            Storage::delete($oldFilePath);
        }
        $filename = $request->file('image')->getClientOriginalName();
        $request->file('image')->storeAs('img', $filename, 'public');
        $imagen->update([
            'nombre_imagen' => $filename,
            'fecha_modificacion' => Carbon::now(),
        ]);
        $imageUrl = env('APP_DOMAIN') . '/storage/img/' . $filename;
        return response()->json([
            'message' => 'Imagen actualizada exitosamente',
            'url' => $imageUrl,
        ]);
    }

    public function load(Request $request)
    {
        try {
            // Validación condicional basada en el campo todos
            $todos = $request->input('todos');
            
            if ($todos === "1") {
                // Cuando todos = 1, los campos type, modo, group y zonal pueden estar vacíos
                $request->validate([
                    'image'       => 'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
                    'año'         => 'required|integer|min:2020|max:2030',
                    'mes'         => 'required|integer|min:1|max:12',
                    'dateStar'    => 'required|date_format:Y-m-d',
                    'dateEnd'     => 'required|date_format:Y-m-d|after_or_equal:dateStar',
                    'type'        => 'nullable|string',
                    'modo'        => 'nullable|string',
                    'namePicture' => 'required|string',
                    'group'       => 'nullable|integer|min:0|max:4',
                    'zonal'       => 'nullable|string|max:500',
                    'todos'       => 'required|string|in:0,1'
                ]);
            } else {
                // Cuando todos = 0, validación normal
                $request->validate([
                    'image'       => 'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
                    'año'         => 'required|integer|min:2020|max:2030',
                    'mes'         => 'required|integer|min:1|max:12',
                    'dateStar'    => 'required|date_format:Y-m-d',
                    'dateEnd'     => 'required|date_format:Y-m-d|after_or_equal:dateStar',
                    'type'        => 'required|string',
                    'modo'        => 'required|string',
                    'namePicture' => 'required|string',
                    'group'       => 'nullable|integer|min:0|max:4',
                    'zonal'       => 'nullable|string|max:500',
                    'todos'       => 'required|string|in:0,1'
                ]);
            }

            $pictureAnio     = (int) $request->input('año');
            $pictureMes      = (int) $request->input('mes');
            $pictureDateStar = $request->input('dateStar'); // 'Y-m-d'
            $pictureEnd      = $request->input('dateEnd');  // 'Y-m-d'
            $todos           = (string) $request->input('todos'); // "0" o "1"

            // Cuando todos = "1", los campos se envían vacíos desde el frontend
            if ($todos === "1") {
                $pictureType = (string) $request->input('type'); // El tipo real (ESQUEMA, ACELERADOR, INFORMACION)
                $pictureModo = "TODOS";   // Más claro que NULL
                $pictureGroup = "TODOS";  // Más claro que NULL
                $pictureZonal = "TODOS";  // Más claro que NULL
            } else {
                // Lógica normal cuando todos = "0"
                $pictureType = (string) $request->input('type');
                $pictureModo = (string) $request->input('modo');
                
                $grupoMapping = [
                    1 => "G1",
                    2 => "G2",
                    3 => "G3",
                    4 => "PDV PREMIUM"
                ];
                $grupoNumber = (int) ($request->input('group') ?? 0);
                $pictureGroup = $grupoMapping[$grupoNumber] ?? null;
                $pictureZonal = $request->input('zonal') ?: null; // Convertir string vacío a NULL
            }

            $pictureFile     = $request->file('image');
            $pictureName     = $request->input('namePicture');
            $extenPicture    = $pictureFile->getClientOriginalExtension();
            
            // Generar nombre de archivo con hash único para evitar duplicados
            $baseName = $pictureName . '_' . $pictureDateStar . '_' . $pictureEnd . '_' . $pictureType . '_' . $pictureModo . '_' . $pictureGroup;
            $uniqueHash = substr(md5(uniqid(rand(), true)), 0, 8); // Hash de 8 caracteres
            $nameFilePicture = $baseName . '_' . $uniqueHash . '.' . $extenPicture;
            
            // Intentar guardar el archivo
            try {
                $path = $request->file('image')->storeAs('img', $nameFilePicture, 'public');
                if (!$path) {
                    throw new \Exception('No se pudo guardar el archivo. Verifique permisos en: ' . storage_path('app/public/img'));
                }
            } catch (\Exception $fileEx) {
                // Intentar loggear pero no fallar si no se puede
                try {
                    Log::error('Error al guardar archivo flyer', [
                        'error' => $fileEx->getMessage(),
                        'path' => storage_path('app/public/img'),
                        'file' => $nameFilePicture
                    ]);
                } catch (\Exception $logEx) {
                    // Ignorar errores de logging
                }
                throw new \Exception('Error al guardar archivo: ' . $fileEx->getMessage());
            }

            $historyFlyer = new \App\Models\PDVOutImagen();
            $historyFlyer->nombre_imagen = $nameFilePicture;
            $historyFlyer->fecha_modificacion = \Carbon\Carbon::now();
            $historyFlyer->save();

            $fechaInicio   = \Carbon\Carbon::createFromFormat('Y-m-d', $pictureDateStar)->format('Y-m-d');
            $fechaFin      = \Carbon\Carbon::createFromFormat('Y-m-d', $pictureEnd)->format('Y-m-d');
            
            $campanaFlyer = new PDVOutCampanasFlyers();
            $campanaFlyer->nombre_campaña = $nameFilePicture;
            $campanaFlyer->foto_esquema = $nameFilePicture;
            $campanaFlyer->fecha_inicio = $fechaInicio;
            $campanaFlyer->fecha_fin = $fechaFin;
            $campanaFlyer->tipoImg = $pictureType;
            $campanaFlyer->modo = $pictureModo;
            $campanaFlyer->criterio_filtro = $pictureGroup;
            $campanaFlyer->zonales = $pictureZonal;
            $campanaFlyer->activa = 1;
            $campanaFlyer->todos = (int) $todos; // Convertir "0"/"1" a int
            $campanaFlyer->comunicado = 0;
            $campanaFlyer->archivo_comunicacion = null;
            $campanaFlyer->fecha_comunicacion = null;
            $campanaFlyer->save();

            try {
                DB::statement('exec dbo.sp_Sincronizar_Flyers ?, ?', [$pictureAnio, $pictureMes]);
                // Intentar loggear pero no fallar si no se puede
                try {
                    Log::info('SP sp_Sincronizar_Flyers ejecutado correctamente', ['año' => $pictureAnio, 'mes' => $pictureMes]);
                } catch (\Exception $logEx) {
                    // Ignorar errores de logging
                }
            } catch (\Exception $spEx) {
                // Intentar loggear pero no fallar si no se puede
                try {
                    Log::error('Error ejecutando SP sp_Sincronizar_Flyers', [
                        'año' => $pictureAnio,
                        'mes' => $pictureMes,
                        'error' => $spEx->getMessage()
                    ]);
                } catch (\Exception $logEx) {
                    // Ignorar errores de logging
                }
            }
            $registrosCount = $this->verificarRegistrosCreados($nameFilePicture);

            $imgUrl = env('APP_DOMAIN') . '/storage/img/' . $nameFilePicture;
            return response()->json([
                "status"     => Response::HTTP_OK,
                "message"    => "Imagen subida exitosamente",
                "urlPicture" => $imgUrl,
                "registrosCreados" => $registrosCount
            ], Response::HTTP_OK);
        } catch (\PDOException $pdoEx) {
            // Intentar loggear pero no fallar si no se puede
            try {
                Log::error('PDOException en load', ['message' => $pdoEx->getMessage()]);
            } catch (\Exception $logEx) {
                // Ignorar errores de logging
            }
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $pdoEx->getMessage()], Response::HTTP_BAD_REQUEST);
        } catch (\Exception $ex) {
            // Intentar loggear pero no fallar si no se puede
            try {
                Log::error('Exception en load', ['message' => $ex->getMessage()]);
            } catch (\Exception $logEx) {
                // Ignorar errores de logging
            }
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }



    public function getCampanasFlyers(Request $request, $año, $mes)
    {
        try {
            // Validar los parámetros de la ruta
            $validator = Validator::make([
                'año' => $año,
                'mes' => $mes
            ], [
                'año' => 'required|integer|min:2020|max:2030',
                'mes' => 'required|integer|min:1|max:12'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    "status" => Response::HTTP_BAD_REQUEST,
                    "message" => "Parámetros inválidos",
                    "errors" => $validator->errors()
                ], Response::HTTP_BAD_REQUEST);
            }

            $campanas = PDVOutCampanasFlyers::whereYear('fecha_inicio', $año)
                ->whereMonth('fecha_inicio', $mes)
                ->orderBy('fecha_inicio', 'desc')
                ->get();

            return response()->json([
                "status" => Response::HTTP_OK,
                "data" => $campanas,
                "total" => $campanas->count()
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    /**
     * Actualiza la comunicación del acelerador
     * Actualiza el estado de comunicación, fecha y permite subir archivo Excel
     */
    public function updateComunicacionAcelerador(Request $request, $id): JsonResponse
    {
        try {
            // Validar que la campaña existe
            $campana = PDVOutCampanasFlyers::find($id);
            if (!$campana) {
                return response()->json([
                    'success' => false,
                    'message' => 'Campaña no encontrada'
                ], 404);
            }

            // Validar que se proporcione archivo (obligatorio)
            if (!$request->hasFile('archivo_comunicacion')) {
                return response()->json([
                    'success' => false,
                    'message' => 'El archivo de comunicación es obligatorio'
                ], 400);
            }

            $request->validate([
                'archivo_comunicacion' => 'required|file|mimes:xlsx,xls|max:10240'
            ]);

            // Procesar actualización usando el servicio
            $result = $this->comunicacionService->processComunicacionUpdate(
                $campana, 
                $request->file('archivo_comunicacion')
            );

            if (!$result['success']) {
                $statusCode = isset($result['errors']) && 
                    in_array('Esta funcionalidad solo está disponible para campañas de tipo ACELERADOR', $result['errors']) 
                    ? 400 : 422;

                return response()->json([
                    'success' => false,
                    'message' => implode(', ', $result['errors'])
                ], $statusCode);
            }

            return response()->json([
                'success' => true,
                'message' => 'Comunicación del acelerador actualizada exitosamente',
                'data' => $result['data']
            ]);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Datos de validación incorrectos',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            Log::error('Error actualizando comunicación de acelerador', [
                'campana_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar la comunicación: ' . $e->getMessage()
            ], 500);
        }
    }


    /**
     * Descarga segura de archivo privado de comunicación
     */
    public function downloadSecureFile($fileName)
    {
        try {
            // Buscar la campaña que tiene este archivo
            $campana = PDVOutCampanasFlyers::where('archivo_comunicacion', $fileName)->first();
            
            if (!$campana) {
                return response()->json([
                    'success' => false,
                    'message' => 'Archivo no encontrado o no autorizado'
                ], 404);
            }

            // Verificar que el archivo existe en almacenamiento privado
            $filePath = 'comunicaciones/' . $fileName;
            
            if (!Storage::disk('local')->exists($filePath)) {
                return response()->json([
                    'success' => false,
                    'message' => 'El archivo no existe en el servidor'
                ], 404);
            }

            // Obtener información del archivo
            $fileSize = Storage::disk('local')->size($filePath);
            $fullPath = Storage::disk('local')->path($filePath);

            // Log de descarga
            Log::info('Descarga segura de archivo de comunicación', [
                'file_name' => $fileName,
                'campana_id' => $campana->id,
                'file_size' => $fileSize,
                'file_path' => $fullPath
            ]);

            // Retornar el archivo como descarga usando response()->download()
            return response()->download($fullPath, $fileName, [
                'Content-Disposition' => 'attachment; filename="' . $fileName . '"'
            ]);

        } catch (\Exception $e) {
            Log::error('Error en descarga segura de archivo', [
                'file_name' => $fileName,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Error al descargar el archivo: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Verifica cuántos registros se crearon en PDV_OUT_FLYERS para una imagen específica
     * 
     * @param string $nombreImagen Nombre de la imagen a verificar
     * @return int Número de registros encontrados
     */
    private function verificarRegistrosCreados(string $nombreImagen): int
    {
        try {
            $result = DB::select('SELECT COUNT(*) as total FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS WHERE foto_esquema = ?', [$nombreImagen]);
            $registrosCount = $result[0]->total ?? 0;

            Log::info('Verificación de registro exitosa', [
                'imagen' => $nombreImagen,
                'registros' => $registrosCount
            ]);

            return $registrosCount;
        } catch (\Exception $ex) {
            Log::error('Error verificando registro', [
                'imagen' => $nombreImagen,
                'error' => $ex->getMessage()
            ]);

            return 0;
        }
    }
}
