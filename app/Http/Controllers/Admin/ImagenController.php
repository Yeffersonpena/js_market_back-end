<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\JsonResponse;
use App\Models\PDVOutImagen;
use App\Models\PDVOutCampanasFlyers;
use App\Services\CampanaComunicacionService;
use App\Services\CargaMasivaService;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;

class ImagenController extends Controller
{
    private CampanaComunicacionService $comunicacionService;
    private CargaMasivaService $cargaMasivaService;

    public function __construct(
        CampanaComunicacionService $comunicacionService,
        CargaMasivaService $cargaMasivaService
    )
    {
        $this->comunicacionService = $comunicacionService;
        $this->cargaMasivaService = $cargaMasivaService;
    }

    public function cargaMasiva(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'archivos' => ['required', 'array', 'min:1', 'max:10'],
            'archivos.*' => ['required', 'file', 'mimes:pdf', 'max:10240'],
            'tipoImg' => ['required', 'in:Cartas,Contratos'],
            'multi_tienda' => ['required', 'in:SI,NO'],
        ], [
            'archivos.max' => 'Cada lote puede contener como máximo 10 archivos.',
            'archivos.*.max' => 'Cada PDF puede pesar como máximo 10 MB.',
            'archivos.*.mimes' => 'Todos los archivos deben ser PDF.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => $validator->errors()->first(),
                'errors' => $validator->errors(),
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $resultados = $this->cargaMasivaService->procesarArchivos(
            $request->file('archivos', []),
            (string) $request->input('tipoImg'),
            (string) $request->input('multi_tienda')
        );

        return response()->json([
            'status' => Response::HTTP_OK,
            'message' => 'Lote procesado.',
            'resultados' => $resultados,
        ]);
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
                // Cuando todos = 1, los campos type, modo, rango y zonal pueden estar vacíos
                $request->validate([
                    'image'       => 'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
                    'año'         => 'required|integer|min:2020|max:2030',
                    'mes'         => 'required|integer|min:1|max:12',
                    'dateStar'    => 'required|date_format:Y-m-d',
                    'dateEnd'     => 'required|date_format:Y-m-d|after_or_equal:dateStar',
                    'type'        => 'nullable|string',
                    'modo'        => 'nullable|string',
                    'namePicture' => 'required|string',
                    'rango'       => 'nullable', // Puede ser integer, array o string
                    'zonal'       => 'nullable|string|max:500',
                    'todos'       => 'required|string|in:0,1',
                    'hora_inicio' => 'nullable|date_format:H:i',
                    'hora_fin'    => 'nullable|date_format:H:i'
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
                    'rango'       => 'nullable', // Puede ser integer, array o string
                    'zonal'       => 'nullable|string|max:500',
                    'todos'       => 'required|string|in:0,1',
                    'hora_inicio' => 'nullable|date_format:H:i',
                    'hora_fin'    => 'nullable|date_format:H:i'
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
                $pictureRango = "TODOS";  // Más claro que NULL
                $pictureZonal = "TODOS";  // Más claro que NULL
            } else {
                $pictureType = (string) $request->input('type');
                $pictureModo = (string) $request->input('modo');

                // Siempre derivar pictureRango de rango (rango[] llega bien); criterio_filtro solo como override por si el servidor no lo recibe (encoding/multipart)
                $rangoInput = $request->input('rango');
                $rangosString = [];

                if ($rangoInput !== null && $rangoInput !== '') {
                    $rangosArray = [];
                    if (is_array($rangoInput)) {
                        $rangosArray = $rangoInput;
                    } elseif (is_string($rangoInput)) {
                        $rangoTrimmed = strtoupper(trim($rangoInput));
                        if ($rangoTrimmed === 'TOP') {
                            $rangosString[] = 'TOP';
                        } elseif ($rangoTrimmed === 'RECUPERO') {
                            $rangosString[] = 'RECUPERO';
                        } else {
                            $rangosArray = array_filter(array_map('trim', explode(',', $rangoInput)));
                        }
                    } elseif (is_numeric($rangoInput)) {
                        $rangosArray = [(int) $rangoInput];
                    }

                    foreach ($rangosArray as $rangoItem) {
                        if (is_string($rangoItem)) {
                            $itemTrimmed = strtoupper(trim($rangoItem));
                            if ($itemTrimmed === 'TOP') {
                                $rangosString[] = 'TOP';
                            } elseif ($itemTrimmed === 'RECUPERO') {
                                $rangosString[] = 'RECUPERO';
                            }
                        } elseif (is_numeric($rangoItem)) {
                            $rangoNum = (int) $rangoItem;
                            if ($rangoNum >= 1) {
                                $rangosString[] = 'RANGO ' . $rangoNum;
                            }
                        } elseif (is_string($rangoItem) && is_numeric(trim($rangoItem))) {
                            $rangoNum = (int) trim($rangoItem);
                            if ($rangoNum >= 1) {
                                $rangosString[] = 'RANGO ' . $rangoNum;
                            }
                        }
                    }
                }

                $pictureRango = !empty($rangosString) ? implode(',', $rangosString) : null;

                $criterioFiltroInput = $request->input('criterio_filtro');
                if ($criterioFiltroInput !== null && trim((string) $criterioFiltroInput) !== '') {
                    $pictureRango = trim((string) $criterioFiltroInput);
                }

                $pictureZonal = $request->input('zonal') ?: null;
            }

            $pictureFile     = $request->file('image');
            $pictureName     = $request->input('namePicture');
            $extenPicture    = $pictureFile->getClientOriginalExtension();

            // Generar nombre de archivo con hash único para evitar duplicados
            $baseName = $pictureName . '_' . $pictureDateStar . '_' . $pictureEnd . '_' . $pictureType . '_' . $pictureModo . '_' . $pictureRango;
            $uniqueHash = substr(md5(uniqid(rand(), true)), 0, 8); // Hash de 8 caracteres
            $nameFilePicture = $baseName . '_' . $uniqueHash . '.' . $extenPicture;

            // Guardar el archivo
            $path = $request->file('image')->storeAs('img', $nameFilePicture, 'public');
            if (!$path) {
                throw new \Exception('No se pudo guardar el archivo. Verifique permisos en: ' . storage_path('app/public/img'));
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
            $campanaFlyer->criterio_filtro = $pictureRango;
            $campanaFlyer->zonales = $pictureZonal;
            $campanaFlyer->activa = 1;
            $campanaFlyer->todos = (int) $todos; // Convertir "0"/"1" a int
            $campanaFlyer->comunicado = 0;
            $campanaFlyer->archivo_comunicacion = null;
            $campanaFlyer->fecha_comunicacion = null;
            $campanaFlyer->hora_inicio = $request->input('hora_inicio') ?: null;
            $campanaFlyer->hora_fin = $request->input('hora_fin') ?: null;
            $campanaFlyer->save();

            try {
                DB::statement('exec dbo.sp_Sincronizar_Flyers_Rango ?, ?', [$pictureAnio, $pictureMes]);
            } catch (\Exception $spEx) {
                // Error al ejecutar SP - se registra en el catch general si es necesario
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
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $pdoEx->getMessage()], Response::HTTP_BAD_REQUEST);
        } catch (\Exception $ex) {
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

            $campanas = PDVOutCampanasFlyers::query()
                ->whereYear('fecha_inicio', $año)
                ->whereMonth('fecha_inicio', $mes)
                ->orderBy('fecha_inicio', 'desc')
                ->get();

            // Formatear criterio_filtro para mostrar "R1,R2" en lugar de "RANGO 1,RANGO 2"
            $campanasFormateadas = $campanas->map(function ($campana) {
                if ($campana->criterio_filtro && $campana->criterio_filtro !== 'TODOS') {
                    $campana->criterio_filtro = preg_replace('/RANGO\s+(\d+)/i', 'R$1', $campana->criterio_filtro);
                }
                return $campana;
            });

            return response()->json([
                "status" => Response::HTTP_OK,
                "data" => $campanasFormateadas,
                "total" => $campanasFormateadas->count()
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    public function getCartasContratos(Request $request, $año)
    {
        try {
            $validator = Validator::make(array_merge($request->all(), [
                'año' => $año,
            ]), [
                'año' => 'required|integer|min:2020|max:2030',
                'page' => 'sometimes|integer|min:1',
                'per_page' => 'sometimes|integer|in:10,20',
                'search' => 'sometimes|nullable|string|max:100',
                'tipo' => 'sometimes|nullable|in:Todos,Cartas,Contratos',
                'multi_tienda' => 'sometimes|nullable|in:Todos,SI,NO',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => Response::HTTP_BAD_REQUEST,
                    'message' => 'Filtros de paginación inválidos',
                    'errors' => $validator->errors(),
                ], Response::HTTP_BAD_REQUEST);
            }

            $perPage = (int) $request->input('per_page', 10);
            $search = trim((string) $request->input('search', ''));
            $tipo = $request->input('tipo', 'Todos');
            $multiTienda = $request->input('multi_tienda', 'Todos');

            $query = PDVOutCampanasFlyers::query()
                ->whereYear('fecha_inicio', $año)
                ->whereIn('tipoImg', ['Cartas', 'Contratos']);

            if ($tipo !== 'Todos') {
                $query->where('tipoImg', $tipo);
            }

            if ($multiTienda === 'SI') {
                $query->where('zonales', 'SI');
            } elseif ($multiTienda === 'NO') {
                $query->where(function ($multiQuery) {
                    $multiQuery->whereNull('zonales')
                        ->orWhere('zonales', '<>', 'SI');
                });
            }

            if ($search !== '') {
                $query->where(function ($searchQuery) use ($search) {
                    $searchQuery->where('criterio_filtro', 'like', "%{$search}%")
                        ->orWhere('nombre_campaña', 'like', "%{$search}%")
                        ->orWhere('foto_esquema', 'like', "%{$search}%")
                        ->orWhere('tipoImg', 'like', "%{$search}%");
                });
            }

            $columns = [
                'id',
                'nombre_campaña',
                'foto_esquema',
                'fecha_inicio',
                'fecha_fin',
                'tipoImg',
                'criterio_filtro',
                'zonales',
            ];

            $documentos = $query
                ->orderBy('fecha_inicio', 'desc')
                ->orderBy('id', 'desc')
                ->paginate($perPage, $columns);

            return response()->json([
                'status' => Response::HTTP_OK,
                'data' => $documentos->items(),
                'total' => $documentos->total(),
                'current_page' => $documentos->currentPage(),
                'per_page' => $documentos->perPage(),
                'last_page' => $documentos->lastPage(),
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            return response()->json([
                'status' => Response::HTTP_BAD_REQUEST,
                'message' => $ex->getMessage(),
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
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar la comunicación: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Sube un Excel de comunicación a múltiples aceleradores
     * Los aceleradores deben tener: mismas fechas, mismo modo, y ser tipo ACELERADOR
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function updateComunicacionAceleradorMultiple(Request $request): JsonResponse
    {
        try {
            // Validar request
            $request->validate([
                'archivo_comunicacion' => 'required|file|mimes:xlsx,xls|max:10240',
                'ids' => 'required|string' // JSON string con array de IDs
            ]);

            // Decodificar IDs
            $idsJson = $request->input('ids');
            $ids = json_decode($idsJson, true);

            if (!is_array($ids) || empty($ids)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Debe proporcionar al menos un ID de acelerador'
                ], 400);
            }

            // Validar que los IDs sean números
            $ids = array_filter(array_map('intval', $ids));
            if (empty($ids)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Los IDs proporcionados no son válidos'
                ], 400);
            }

            // Obtener todos los flyers
            $flyers = PDVOutCampanasFlyers::whereIn('id', $ids)->get();

            if ($flyers->count() !== count($ids)) {
                $idsEncontrados = $flyers->pluck('id')->toArray();
                $idsNoEncontrados = array_diff($ids, $idsEncontrados);

                return response()->json([
                    'success' => false,
                    'message' => 'Algunos flyers no fueron encontrados',
                    'ids_no_encontrados' => array_values($idsNoEncontrados)
                ], 404);
            }

            // Validar que forman un grupo válido (mismas fechas, mismo modo, tipo ACELERADOR)
            // Pasar la colección directamente (el servicio maneja tanto objetos como arrays)
            $validationErrors = $this->comunicacionService->validateGrupoAceleradores($flyers->all());
            if (!empty($validationErrors)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Los aceleradores seleccionados no pueden combinarse',
                    'errors' => $validationErrors
                ], 400);
            }

            // Procesar el archivo usando el primer flyer como referencia
            $primerFlyer = $flyers->first();
            $result = $this->comunicacionService->processComunicacionUpdate(
                $primerFlyer,
                $request->file('archivo_comunicacion')
            );

            if (!$result['success']) {
                return response()->json([
                    'success' => false,
                    'message' => implode(', ', $result['errors']),
                    'errors' => $result['errors']
                ], 400);
            }

            // Obtener el archivo y fecha de comunicación del primer flyer actualizado
            $primerFlyer->refresh();
            $archivoComunicacion = $primerFlyer->archivo_comunicacion;
            $fechaComunicacion = $primerFlyer->fecha_comunicacion;

            // Actualizar todos los flyers del grupo con el mismo archivo
            // Pasar la colección directamente (el servicio maneja tanto objetos como arrays)
            $actualizacionExitosa = $this->comunicacionService->updateComunicacionMultiple(
                $flyers->all(),
                $archivoComunicacion,
                $fechaComunicacion
            );

            if (!$actualizacionExitosa) {
                // Si falla, eliminar el archivo usando el servicio
                $this->comunicacionService->deleteComunicacionFile($archivoComunicacion);

                return response()->json([
                    'success' => false,
                    'message' => 'Error al actualizar los flyers del grupo'
                ], 500);
            }

            return response()->json([
                'success' => true,
                'message' => "Comunicación actualizada exitosamente. Se actualizaron " .
                    $flyers->count() . " flyer(s).",
                'data' => [
                    'flyers_actualizados' => $flyers->count(),
                    'archivo_comunicacion' => $archivoComunicacion,
                    'fecha_comunicacion' => $fechaComunicacion,
                    'ids_procesados' => $ids,
                    'download_url' => $result['data']['download_url']
                ]
            ], 200);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Datos de validación incorrectos',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $ex) {
            Log::error('Error en updateComunicacionAceleradorMultiple', [
                'error' => $ex->getMessage(),
                'trace' => $ex->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Error al procesar la solicitud: ' . $ex->getMessage()
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


            // Retornar el archivo como descarga usando response()->download()
            return response()->download($fullPath, $fileName, [
                'Content-Disposition' => 'attachment; filename="' . $fileName . '"'
            ]);
        } catch (\Exception $e) {
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
            return $result[0]->total ?? 0;
        } catch (\Exception $ex) {
            return 0;
        }
    }

    /**
     * Elimina un flyer y todas sus asignaciones usando el stored procedure
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function eliminarFlyer(Request $request): JsonResponse
    {
        try {
            $request->validate([
                'nombreImagen' => 'required|string|max:200'
            ]);

            $nombreImagen = $request->input('nombreImagen');

            // Verificar que el flyer existe antes de eliminar
            $existeCampana = PDVOutCampanasFlyers::where('foto_esquema', $nombreImagen)->exists();

            if (!$existeCampana) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "No se encontró el flyer con el nombre especificado"
                ], Response::HTTP_NOT_FOUND);
            }

            // Ejecutar el stored procedure
            $result = DB::select('EXEC dbo.sp_Eliminar_Flyer ?', [$nombreImagen]);

            if (!empty($result)) {
                $resultado = $result[0];
                $asignacionesEliminadas = $resultado->Asignaciones_Eliminadas ?? 0;
                $campanaEliminada = $resultado->Campaña_Eliminada ?? 0;
                $estado = $resultado->Estado ?? '';

                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => $estado,
                    "data" => [
                        "flyer_eliminado" => $nombreImagen,
                        "asignaciones_eliminadas" => $asignacionesEliminadas,
                        "campana_eliminada" => $campanaEliminada
                    ]
                ], Response::HTTP_OK);
            } else {
                return response()->json([
                    "status" => Response::HTTP_BAD_REQUEST,
                    "message" => "No se pudo eliminar el flyer"
                ], Response::HTTP_BAD_REQUEST);
            }
        } catch (\PDOException $pdoEx) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => "Error en la base de datos: " . $pdoEx->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        }
    }
}
