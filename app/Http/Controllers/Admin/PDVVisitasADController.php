<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PDV_ENTREGABLE;
use App\Models\PDV_VISITAS_AD_DIAS;
use App\Models\PDV_VISITAS_AD_PROGRAMACION;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;
use Tymon\JWTAuth\Facades\JWTAuth;

class PDVVisitasADController extends Controller
{
    /**
     * Transforma los campos del modelo de mayúsculas a snake_case en minúsculas
     */
    private function transformProgramacionData($row)
    {
        if (!$row) {
            return null;
        }

        try {
            return [
                'id' => $row->id,
                'dni_responsable' => $row->DNI_RESPONSABLE,
                'año' => $row->AÑO,
                'mes' => $row->MES,
                'cod_cliente' => $row->COD_CLIENTE,
                'zonal' => $row->ZONAL,
                'ruta' => $row->RUTA,
                'cod_vvdd' => $row->COD_VVDD,
                'modulo' => $row->MODULO,
                'nombre_punto' => $row->NOMBRE_PUNTO,
                'cedula_cliente' => $row->CEDULA_CLIENTE,
                'departamento' => $row->DEPARTAMENTO,
                'provincia' => $row->PROVINCIA,
                'distrito' => $row->DISTRITO,
                'direccion' => $row->DIRECCION,
                'conglomerado' => $row->CONGLOMERADO,
                'latitud' => $row->LATITUD ? (float) $row->LATITUD : null,
                'longitud' => $row->LONGITUD ? (float) $row->LONGITUD : null,
                'vendedores' => $row->VENDEDORES,
                'tipo_visita' => $row->TIPO_VISITA,
                'frecuencia' => $row->FRECUENCIA,
                'status' => $row->STATUS,
                'comentarios' => $row->COMENTARIOS,
                'fecha_creacion' => $row->FECHA_CREACION ? Carbon::parse($row->FECHA_CREACION)->setTimezone('America/Lima')->format('Y-m-d\TH:i:s') : null,
                'usuario_creacion' => $row->USUARIO_CREACION,
                'fecha_actualizacion' => $row->FECHA_ACTUALIZACION ? Carbon::parse($row->FECHA_ACTUALIZACION)->setTimezone('America/Lima')->format('Y-m-d\TH:i:s') : null,
                'usuario_actualizacion' => $row->USUARIO_ACTUALIZACION,
            ];
        } catch (\Exception $e) {
            Log::error('Error transformando datos de programación: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Transforma los campos de días a snake_case
     */
    private function transformDiaData($row)
    {
        if (!$row) {
            return null;
        }

        try {
            return [
                'id' => $row->id,
                'programacion_id' => $row->programacion_id,
                'dia_mes' => $row->DIA_MES,
                'fecha_completa' => $row->FECHA_COMPLETA ? Carbon::parse($row->FECHA_COMPLETA)->format('Y-m-d') : null,
                'programado' => (bool) $row->PROGRAMADO,
                'es_extraordinario' => (bool) $row->es_extraordinario,
                'fecha_creacion' => $row->FECHA_CREACION ? Carbon::parse($row->FECHA_CREACION)->setTimezone('America/Lima')->format('Y-m-d\TH:i:s') : null,
                'usuario_creacion' => $row->USUARIO_CREACION,
            ];
        } catch (\Exception $e) {
            Log::error('Error transformando datos de día: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Calcula la fecha completa a partir de año, mes y día
     */
    private function calcularFechaCompleta($año, $mes, $diaMes)
    {
        try {
            // Validar que la fecha sea válida
            if (!checkdate($mes, $diaMes, $año)) {
                return null;
            }
            return Carbon::create($año, $mes, $diaMes)->format('Y-m-d');
        } catch (\Exception $e) {
            return null;
        }
    }

    /**
     * Obtener usuario autenticado del token JWT
     */
    private function getUsuarioAutenticado()
    {
        try {
            $datosToken = JWTAuth::parseToken()->authenticate();
            return $datosToken->user ?? 'SISTEMA';
        } catch (\Exception $e) {
            return 'SISTEMA';
        }
    }

    /**
     * Listado con paginación y filtros
     */
    public function index(Request $request)
    {
        try {
            $query = PDV_VISITAS_AD_PROGRAMACION::query();

            // Filtros
            if ($request->filled('año')) {
                $query->where('AÑO', (int) $request->input('año'));
            }

            if ($request->filled('mes')) {
                $query->where('MES', (int) $request->input('mes'));
            }

            if ($request->filled('dni')) {
                $query->where('DNI_RESPONSABLE', (int) $request->input('dni'));
            }

            if ($request->filled('zonal')) {
                $query->where('ZONAL', 'LIKE', '%' . $request->input('zonal') . '%');
            }

            if ($request->filled('vendedor')) {
                $query->where('COD_VVDD', (int) $request->input('vendedor'));
            }

            // Paginación
            $perPage = (int) $request->input('per_page', 10);
            $perPage = $perPage > 0 ? min($perPage, 100) : 10;

            $page = (int) $request->input('page', 1);
            $page = $page > 0 ? $page : 1;

            // Ordenar y paginar
            $rows = $query->orderBy('AÑO', 'desc')
                ->orderBy('MES', 'desc')
                ->orderBy('DNI_RESPONSABLE', 'asc')
                ->paginate($perPage, ['*'], 'page', $page);

            // Transformar datos y agregar count de días
            $transformedData = [];
            foreach ($rows->items() as $item) {
                $transformed = $this->transformProgramacionData($item);
                if ($transformed) {
                    // Agregar cantidad de días programados
                    $transformed['cantidad_dias'] = $item->dias()->where('PROGRAMADO', 1)->count();
                    $transformedData[] = $transformed;
                }
            }

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Listado de programaciones de visitas AD",
                "data" => $transformedData,
                "pagination" => [
                    "current_page" => $rows->currentPage(),
                    "per_page" => $rows->perPage(),
                    "total" => $rows->total(),
                    "last_page" => $rows->lastPage(),
                ],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en index PDVVisitasAD: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al obtener datos: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Obtener programación específica con días
     */
    public function show($id)
    {
        try {
            $programacion = PDV_VISITAS_AD_PROGRAMACION::with('dias')->find($id);

            if (!$programacion) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "Programación no encontrada",
                    "data" => null,
                ], Response::HTTP_NOT_FOUND);
            }

            $programacionData = $this->transformProgramacionData($programacion);
            $diasData = [];

            foreach ($programacion->dias as $dia) {
                $diaTransformed = $this->transformDiaData($dia);
                if ($diaTransformed) {
                    $diasData[] = $diaTransformed;
                }
            }

            $programacionData['dias'] = $diasData;

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Programación obtenida",
                "data" => $programacionData,
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en show PDVVisitasAD: ' . $ex->getMessage());
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage(),
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    /**
     * Crear programación (solo datos PDV, sin días)
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'dni_responsable' => 'required|integer',
                'año' => 'required|integer|min:2020|max:2100',
                'mes' => 'required|integer|min:1|max:12',
                'cod_cliente' => 'nullable|string|max:50',
                'zonal' => 'nullable|string|max:70',
                'ruta' => 'nullable|string|max:50',
                'cod_vvdd' => 'nullable|integer',
                'modulo' => 'nullable|string|max:50',
                'nombre_punto' => 'nullable|string|max:255',
                'cedula_cliente' => 'nullable|string|max:70',
                'departamento' => 'nullable|string|max:100',
                'provincia' => 'nullable|string|max:100',
                'distrito' => 'nullable|string|max:100',
                'direccion' => 'nullable|string|max:500',
                'conglomerado' => 'nullable|string|max:255',
                'latitud' => 'nullable|numeric',
                'longitud' => 'nullable|numeric',
                'vendedores' => 'nullable|string|max:255',
                'tipo_visita' => 'nullable|string|max:50',
                'frecuencia' => 'nullable|string|max:50',
                'status' => 'nullable|string|max:50',
                'comentarios' => 'nullable|string',
            ]);

            // Verificar unicidad (DNI_RESPONSABLE, AÑO, MES)
            $existe = PDV_VISITAS_AD_PROGRAMACION::where('DNI_RESPONSABLE', $validated['dni_responsable'])
                ->where('AÑO', $validated['año'])
                ->where('MES', $validated['mes'])
                ->exists();

            if ($existe) {
                return response()->json([
                    "status" => Response::HTTP_CONFLICT,
                    "message" => "Ya existe una programación para este PDV en el período seleccionado",
                ], Response::HTTP_CONFLICT);
            }

            $programacion = new PDV_VISITAS_AD_PROGRAMACION();
            $programacion->DNI_RESPONSABLE = (int) $validated['dni_responsable'];
            $programacion->AÑO = (int) $validated['año'];
            $programacion->MES = (int) $validated['mes'];
            $programacion->COD_CLIENTE = $validated['cod_cliente'] ?? null;
            $programacion->ZONAL = $validated['zonal'] ?? null;
            $programacion->RUTA = $validated['ruta'] ?? null;
            $programacion->COD_VVDD = isset($validated['cod_vvdd']) ? (int) $validated['cod_vvdd'] : null;
            $programacion->MODULO = $validated['modulo'] ?? null;
            $programacion->NOMBRE_PUNTO = $validated['nombre_punto'] ?? null;
            $programacion->CEDULA_CLIENTE = $validated['cedula_cliente'] ?? null;
            $programacion->DEPARTAMENTO = $validated['departamento'] ?? null;
            $programacion->PROVINCIA = $validated['provincia'] ?? null;
            $programacion->DISTRITO = $validated['distrito'] ?? null;
            $programacion->DIRECCION = $validated['direccion'] ?? null;
            $programacion->CONGLOMERADO = $validated['conglomerado'] ?? null;
            $programacion->LATITUD = isset($validated['latitud']) ? (float) $validated['latitud'] : null;
            $programacion->LONGITUD = isset($validated['longitud']) ? (float) $validated['longitud'] : null;
            $programacion->VENDEDORES = $validated['vendedores'] ?? null;
            $programacion->TIPO_VISITA = $validated['tipo_visita'] ?? null;
            $programacion->FRECUENCIA = $validated['frecuencia'] ?? null;
            $programacion->STATUS = $validated['status'] ?? 'PROGRAMADO';
            $programacion->COMENTARIOS = $validated['comentarios'] ?? null;
            $programacion->FECHA_CREACION = Carbon::now('America/Lima');
            $programacion->USUARIO_CREACION = $this->getUsuarioAutenticado();

            $programacion->save();
            $programacion->refresh();

            return response()->json([
                "status" => Response::HTTP_CREATED,
                "message" => "Programación creada exitosamente",
                "data" => $this->transformProgramacionData($programacion),
            ], Response::HTTP_CREATED);
        } catch (\Illuminate\Validation\ValidationException $ex) {
            return response()->json([
                "status" => Response::HTTP_UNPROCESSABLE_ENTITY,
                "message" => "Error de validación",
                "errors" => $ex->errors(),
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        } catch (\Exception $ex) {
            Log::error('Error en store PDVVisitasAD: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al crear programación: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Actualizar datos PDV (no permite cambiar DNI_RESPONSABLE, AÑO, MES)
     */
    public function update(Request $request, $id)
    {
        try {
            $programacion = PDV_VISITAS_AD_PROGRAMACION::find($id);

            if (!$programacion) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "Programación no encontrada",
                    "data" => null,
                ], Response::HTTP_NOT_FOUND);
            }

            $validated = $request->validate([
                'cod_cliente' => 'sometimes|nullable|string|max:50',
                'zonal' => 'sometimes|nullable|string|max:70',
                'ruta' => 'sometimes|nullable|string|max:50',
                'cod_vvdd' => 'sometimes|nullable|integer',
                'modulo' => 'sometimes|nullable|string|max:50',
                'nombre_punto' => 'sometimes|nullable|string|max:255',
                'cedula_cliente' => 'sometimes|nullable|string|max:70',
                'departamento' => 'sometimes|nullable|string|max:100',
                'provincia' => 'sometimes|nullable|string|max:100',
                'distrito' => 'sometimes|nullable|string|max:100',
                'direccion' => 'sometimes|nullable|string|max:500',
                'conglomerado' => 'sometimes|nullable|string|max:255',
                'latitud' => 'sometimes|nullable|numeric',
                'longitud' => 'sometimes|nullable|numeric',
                'vendedores' => 'sometimes|nullable|string|max:255',
                'tipo_visita' => 'sometimes|nullable|string|max:50',
                'frecuencia' => 'sometimes|nullable|string|max:50',
                'status' => 'sometimes|nullable|string|max:50',
                'comentarios' => 'sometimes|nullable|string',
            ]);

            // Actualizar solo campos presentes
            if (array_key_exists('cod_cliente', $validated)) {
                $programacion->COD_CLIENTE = $validated['cod_cliente'];
            }
            if (array_key_exists('zonal', $validated)) {
                $programacion->ZONAL = $validated['zonal'];
            }
            if (array_key_exists('ruta', $validated)) {
                $programacion->RUTA = $validated['ruta'];
            }
            if (array_key_exists('cod_vvdd', $validated)) {
                $programacion->COD_VVDD = $validated['cod_vvdd'] ? (int) $validated['cod_vvdd'] : null;
            }
            if (array_key_exists('modulo', $validated)) {
                $programacion->MODULO = $validated['modulo'];
            }
            if (array_key_exists('nombre_punto', $validated)) {
                $programacion->NOMBRE_PUNTO = $validated['nombre_punto'];
            }
            if (array_key_exists('cedula_cliente', $validated)) {
                $programacion->CEDULA_CLIENTE = $validated['cedula_cliente'];
            }
            if (array_key_exists('departamento', $validated)) {
                $programacion->DEPARTAMENTO = $validated['departamento'];
            }
            if (array_key_exists('provincia', $validated)) {
                $programacion->PROVINCIA = $validated['provincia'];
            }
            if (array_key_exists('distrito', $validated)) {
                $programacion->DISTRITO = $validated['distrito'];
            }
            if (array_key_exists('direccion', $validated)) {
                $programacion->DIRECCION = $validated['direccion'];
            }
            if (array_key_exists('conglomerado', $validated)) {
                $programacion->CONGLOMERADO = $validated['conglomerado'];
            }
            if (array_key_exists('latitud', $validated)) {
                $programacion->LATITUD = $validated['latitud'] ? (float) $validated['latitud'] : null;
            }
            if (array_key_exists('longitud', $validated)) {
                $programacion->LONGITUD = $validated['longitud'] ? (float) $validated['longitud'] : null;
            }
            if (array_key_exists('vendedores', $validated)) {
                $programacion->VENDEDORES = $validated['vendedores'];
            }
            if (array_key_exists('tipo_visita', $validated)) {
                $programacion->TIPO_VISITA = $validated['tipo_visita'];
            }
            if (array_key_exists('frecuencia', $validated)) {
                $programacion->FRECUENCIA = $validated['frecuencia'];
            }
            if (array_key_exists('status', $validated)) {
                $programacion->STATUS = $validated['status'];
            }
            if (array_key_exists('comentarios', $validated)) {
                $programacion->COMENTARIOS = $validated['comentarios'];
            }

            $programacion->FECHA_ACTUALIZACION = Carbon::now('America/Lima');
            $programacion->USUARIO_ACTUALIZACION = $this->getUsuarioAutenticado();

            $programacion->save();
            $programacion->refresh();

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Programación actualizada",
                "data" => $this->transformProgramacionData($programacion),
            ], Response::HTTP_OK);
        } catch (\Illuminate\Validation\ValidationException $ex) {
            return response()->json([
                "status" => Response::HTTP_UNPROCESSABLE_ENTITY,
                "message" => "Error de validación",
                "errors" => $ex->errors(),
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        } catch (\Exception $ex) {
            Log::error('Error en update PDVVisitasAD: ' . $ex->getMessage());
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage(),
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    /**
     * Eliminar programación (CASCADE eliminará días automáticamente)
     */
    public function destroy($id)
    {
        try {
            $programacion = PDV_VISITAS_AD_PROGRAMACION::find($id);

            if (!$programacion) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "Programación no encontrada",
                ], Response::HTTP_NOT_FOUND);
            }

            $programacion->delete();

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Programación eliminada exitosamente",
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en destroy PDVVisitasAD: ' . $ex->getMessage());
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage(),
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    /**
     * Agregar días a una programación existente
     */
    public function storeDias(Request $request, $id)
    {
        try {
            $programacion = PDV_VISITAS_AD_PROGRAMACION::find($id);

            if (!$programacion) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "Programación no encontrada",
                ], Response::HTTP_NOT_FOUND);
            }

            $validated = $request->validate([
                'dias' => 'required|array|min:1',
                'dias.*' => 'integer|min:1|max:31',
            ]);

            $año = $programacion->AÑO;
            $mes = $programacion->MES;
            $diasCreados = [];
            $errores = [];

            DB::beginTransaction();

            try {
                foreach ($validated['dias'] as $diaMes) {
                    // Verificar que el día sea válido para el mes
                    $fechaCompleta = $this->calcularFechaCompleta($año, $mes, $diaMes);

                    if (!$fechaCompleta) {
                        $errores[] = "El día $diaMes no es válido para el mes $mes del año $año";
                        continue;
                    }

                    // Verificar que no exista ya
                    $existe = PDV_VISITAS_AD_DIAS::where('programacion_id', $id)
                        ->where('DIA_MES', $diaMes)
                        ->exists();

                    if ($existe) {
                        $errores[] = "El día $diaMes ya está programado";
                        continue;
                    }

                    // Crear día
                    $dia = new PDV_VISITAS_AD_DIAS();
                    $dia->programacion_id = $id;
                    $dia->DIA_MES = $diaMes;
                    $dia->FECHA_COMPLETA = $fechaCompleta;
                    $dia->PROGRAMADO = 1;
                    $dia->es_extraordinario = 0;
                    $dia->FECHA_CREACION = Carbon::now('America/Lima');
                    $dia->USUARIO_CREACION = $this->getUsuarioAutenticado();
                    $dia->save();

                    $diasCreados[] = $this->transformDiaData($dia);
                }

                if (count($errores) > 0 && count($diasCreados) == 0) {
                    DB::rollBack();
                    return response()->json([
                        "status" => Response::HTTP_BAD_REQUEST,
                        "message" => "No se pudo crear ningún día",
                        "errors" => $errores,
                    ], Response::HTTP_BAD_REQUEST);
                }

                DB::commit();

                $mensaje = count($diasCreados) . " día(s) creado(s) exitosamente";
                if (count($errores) > 0) {
                    $mensaje .= ". " . count($errores) . " error(es): " . implode(', ', $errores);
                }

                return response()->json([
                    "status" => Response::HTTP_CREATED,
                    "message" => $mensaje,
                    "data" => $diasCreados,
                    "warnings" => count($errores) > 0 ? $errores : null,
                ], Response::HTTP_CREATED);
            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }
        } catch (\Illuminate\Validation\ValidationException $ex) {
            return response()->json([
                "status" => Response::HTTP_UNPROCESSABLE_ENTITY,
                "message" => "Error de validación",
                "errors" => $ex->errors(),
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        } catch (\Exception $ex) {
            Log::error('Error en storeDias PDVVisitasAD: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al crear días: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Eliminar día específico
     */
    public function destroyDia($id, $diaId)
    {
        try {
            $programacion = PDV_VISITAS_AD_PROGRAMACION::find($id);

            if (!$programacion) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "Programación no encontrada",
                ], Response::HTTP_NOT_FOUND);
            }

            $dia = PDV_VISITAS_AD_DIAS::where('id', $diaId)
                ->where('programacion_id', $id)
                ->first();

            if (!$dia) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "Día no encontrado o no pertenece a esta programación",
                ], Response::HTTP_NOT_FOUND);
            }

            $dia->delete();

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Día eliminado exitosamente",
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en destroyDia PDVVisitasAD: ' . $ex->getMessage());
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage(),
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    /**
     * Autocompletar datos del PDV desde PDV_OUT_ENTREGABLE
     */
    public function autocompletar($dni)
    {
        try {
            $dniInt = (int) $dni;

            // Obtener el registro más reciente del PDV
            $result = PDV_ENTREGABLE::where('DNI_RESPONSABLE', $dniInt)
                ->orderBy('AÑO', 'desc')
                ->orderBy('MES', 'desc')
                ->first();

            if (!$result) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "No se encontraron datos para el DNI proporcionado",
                    "data" => null,
                ], Response::HTTP_NOT_FOUND);
            }

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Datos obtenidos correctamente",
                "data" => [
                    "cod_cliente" => $result->COD_CLIENTE ?? null,
                    "zonal" => $result->ZONAL ?? null,
                    "ruta" => $result->RUTA ?? null,
                    "cod_vvdd" => $result->COD_VVDD ?? null,
                    "modulo" => $result->MODULO ?? null,
                    "nombre_punto" => $result->NOMBRE_PUNTO ?? null,
                    "cedula_cliente" => $result->CEDULA_CLIENTE ?? null,
                    "departamento" => $result->DEPARTAMENTO ?? null,
                    "provincia" => $result->PROVINCIA ?? null,
                    "distrito" => $result->DISTRITO ?? null,
                    "direccion" => $result->DIRECCION ?? null,
                    "conglomerado" => $result->CONGLOMERADO ?? null,
                    "latitud" => $result->LATITUD ? (float) $result->LATITUD : null,
                    "longitud" => $result->LONGITUD ? (float) $result->LONGITUD : null,
                    "vendedores" => $result->NOMBRE_VENDEDOR ?? null,
                ],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en autocompletar PDVVisitasAD: ' . $ex->getMessage());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al obtener datos: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Dashboard: Resumen de visitas de un día específico
     * Retorna estadísticas y resumen agrupado por zonal
     */
    public function dashboardDia($fecha)
    {
        try {
            // Validar formato de fecha
            try {
                $fechaCarbon = Carbon::parse($fecha);
            } catch (\Exception $e) {
                return response()->json([
                    "status" => Response::HTTP_BAD_REQUEST,
                    "message" => "Formato de fecha inválido. Use formato YYYY-MM-DD",
                ], Response::HTTP_BAD_REQUEST);
            }

            $fechaFormateada = $fechaCarbon->format('Y-m-d');

            // Obtener todos los PDVs programados para esta fecha
            $pdvsDelDia = PDV_VISITAS_AD_DIAS::where('FECHA_COMPLETA', $fechaFormateada)
                ->where('PROGRAMADO', 1)
                ->with('programacion')
                ->get();

            if ($pdvsDelDia->isEmpty()) {
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "No hay visitas programadas para esta fecha",
                    "data" => [
                        "fecha" => $fechaFormateada,
                        "resumen" => [
                            "total_pdvs" => 0,
                            "total_zonales" => 0,
                            "total_vendedores" => 0,
                        ],
                        "resumen_por_zonal" => [],
                    ],
                ], Response::HTTP_OK);
            }

            // Agrupar por zonal y vendedor
            $agrupadoPorZonal = [];
            $zonalesUnicos = [];
            $vendedoresUnicos = [];

            foreach ($pdvsDelDia as $dia) {
                $programacion = $dia->programacion;
                if (!$programacion) {
                    continue;
                }

                $zonal = $programacion->ZONAL ?? 'SIN ZONAL';
                $codVvdd = $programacion->COD_VVDD ?? null;
                $vendedor = $programacion->VENDEDORES ?? 'SIN VENDEDOR';

                // Inicializar zonal si no existe
                if (!isset($agrupadoPorZonal[$zonal])) {
                    $agrupadoPorZonal[$zonal] = [
                        'zonal' => $zonal,
                        'cantidad' => 0,
                        'vendedores' => [],
                    ];
                    $zonalesUnicos[$zonal] = true;
                }

                // Inicializar vendedor dentro del zonal si no existe
                $keyVendedor = $codVvdd ? (string) $codVvdd : $vendedor;
                if (!isset($agrupadoPorZonal[$zonal]['vendedores'][$keyVendedor])) {
                    $agrupadoPorZonal[$zonal]['vendedores'][$keyVendedor] = [
                        'vendedor' => $vendedor,
                        'cod_vvdd' => $codVvdd,
                        'cantidad' => 0,
                    ];
                    $vendedoresUnicos[$keyVendedor] = true;
                }

                // Incrementar contadores
                $agrupadoPorZonal[$zonal]['cantidad']++;
                $agrupadoPorZonal[$zonal]['vendedores'][$keyVendedor]['cantidad']++;
            }

            // Formatear resumen por zonal
            $resumenPorZonal = [];
            foreach ($agrupadoPorZonal as $zonal => $datos) {
                $vendedoresArray = array_values($datos['vendedores']);
                $resumenPorZonal[] = [
                    'zonal' => $zonal,
                    'cantidad' => $datos['cantidad'],
                    'vendedores' => count($vendedoresArray),
                    'detalle_vendedores' => $vendedoresArray,
                ];
            }

            // Ordenar por cantidad descendente
            usort($resumenPorZonal, function ($a, $b) {
                return $b['cantidad'] - $a['cantidad'];
            });

            // Calcular totales
            $totalPDVs = $pdvsDelDia->count();
            $totalZonales = count($zonalesUnicos);
            $totalVendedores = count($vendedoresUnicos);

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Resumen del día obtenido correctamente",
                "data" => [
                    "fecha" => $fechaFormateada,
                    "resumen" => [
                        "total_pdvs" => $totalPDVs,
                        "total_zonales" => $totalZonales,
                        "total_vendedores" => $totalVendedores,
                    ],
                    "resumen_por_zonal" => $resumenPorZonal,
                ],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en dashboardDia PDVVisitasAD: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al obtener resumen del día: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Detalle completo de PDVs a visitar en un día específico
     * Para mostrar en modal o tabla detallada
     */
    public function detalleDia(Request $request, $fecha)
    {
        try {
            // Validar formato de fecha
            try {
                $fechaCarbon = Carbon::parse($fecha);
            } catch (\Exception $e) {
                return response()->json([
                    "status" => Response::HTTP_BAD_REQUEST,
                    "message" => "Formato de fecha inválido. Use formato YYYY-MM-DD",
                ], Response::HTTP_BAD_REQUEST);
            }

            $fechaFormateada = $fechaCarbon->format('Y-m-d');

            // Filtros opcionales
            $zonal = $request->input('zonal');
            $vendedor = $request->input('vendedor'); // COD_VVDD
            $search = $request->input('search'); // Búsqueda general

            // Query base: PDVs del día
            $query = PDV_VISITAS_AD_DIAS::where('FECHA_COMPLETA', $fechaFormateada)
                ->where('PROGRAMADO', 1)
                ->with('programacion');

            // Aplicar filtros si existen
            if ($zonal) {
                $query->whereHas('programacion', function ($q) use ($zonal) {
                    $q->where('ZONAL', 'LIKE', '%' . $zonal . '%');
                });
            }

            if ($vendedor) {
                $query->whereHas('programacion', function ($q) use ($vendedor) {
                    $q->where('COD_VVDD', (int) $vendedor);
                });
            }

            if ($search) {
                $query->whereHas('programacion', function ($q) use ($search) {
                    $q->where('NOMBRE_PUNTO', 'LIKE', '%' . $search . '%')
                        ->orWhere('COD_CLIENTE', 'LIKE', '%' . $search . '%')
                        ->orWhere('DIRECCION', 'LIKE', '%' . $search . '%')
                        ->orWhereRaw('CAST(DNI_RESPONSABLE AS VARCHAR) LIKE ?', ["%$search%"]);
                });
            }

            // Paginación
            $perPage = (int) $request->input('per_page', 50);
            $perPage = $perPage > 0 ? min($perPage, 200) : 50;

            $page = (int) $request->input('page', 1);
            $page = $page > 0 ? $page : 1;

            // Ordenar y paginar
            $rows = $query->orderBy('id', 'asc')
                ->paginate($perPage, ['*'], 'page', $page);

            // Transformar datos
            $transformedData = [];
            foreach ($rows->items() as $dia) {
                $programacion = $dia->programacion;
                if (!$programacion) {
                    continue;
                }

                $transformedData[] = [
                    'id' => $dia->id,
                    'programacion_id' => $programacion->id,
                    'dni_responsable' => $programacion->DNI_RESPONSABLE,
                    'cod_cliente' => $programacion->COD_CLIENTE,
                    'nombre_punto' => $programacion->NOMBRE_PUNTO,
                    'zonal' => $programacion->ZONAL,
                    'ruta' => $programacion->RUTA,
                    'cod_vvdd' => $programacion->COD_VVDD,
                    'vendedor' => $programacion->VENDEDORES,
                    'modulo' => $programacion->MODULO,
                    'cedula_cliente' => $programacion->CEDULA_CLIENTE,
                    'departamento' => $programacion->DEPARTAMENTO,
                    'provincia' => $programacion->PROVINCIA,
                    'distrito' => $programacion->DISTRITO,
                    'direccion' => $programacion->DIRECCION,
                    'conglomerado' => $programacion->CONGLOMERADO,
                    'latitud' => $programacion->LATITUD ? (float) $programacion->LATITUD : null,
                    'longitud' => $programacion->LONGITUD ? (float) $programacion->LONGITUD : null,
                    'tipo_visita' => $programacion->TIPO_VISITA,
                    'frecuencia' => $programacion->FRECUENCIA,
                    'status' => $programacion->STATUS,
                    'dia_mes' => $dia->DIA_MES,
                    'fecha_completa' => $dia->FECHA_COMPLETA ? Carbon::parse($dia->FECHA_COMPLETA)->format('Y-m-d') : null,
                    'es_extraordinario' => (bool) $dia->es_extraordinario,
                ];
            }

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Detalle del día obtenido correctamente",
                "data" => $transformedData,
                "pagination" => [
                    "current_page" => $rows->currentPage(),
                    "per_page" => $rows->perPage(),
                    "total" => $rows->total(),
                    "last_page" => $rows->lastPage(),
                ],
                "fecha" => $fechaFormateada,
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en detalleDia PDVVisitasAD: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al obtener detalle del día: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Obtener días del mes con visitas programadas
     * Para marcar en el calendario
     */
    public function diasConVisitas($año, $mes)
    {
        try {
            // Validar año y mes
            if ($año < 2020 || $año > 2100) {
                return response()->json([
                    "status" => Response::HTTP_BAD_REQUEST,
                    "message" => "Año inválido. Debe estar entre 2020 y 2100",
                ], Response::HTTP_BAD_REQUEST);
            }

            if ($mes < 1 || $mes > 12) {
                return response()->json([
                    "status" => Response::HTTP_BAD_REQUEST,
                    "message" => "Mes inválido. Debe estar entre 1 y 12",
                ], Response::HTTP_BAD_REQUEST);
            }

            // Obtener el primer y último día del mes
            $primerDia = Carbon::create($año, $mes, 1)->format('Y-m-d');
            $ultimoDia = Carbon::create($año, $mes, 1)->endOfMonth()->format('Y-m-d');

            // Obtener días con visitas programadas en el mes
            $diasConVisitas = PDV_VISITAS_AD_DIAS::whereBetween('FECHA_COMPLETA', [$primerDia, $ultimoDia])
                ->where('PROGRAMADO', 1)
                ->select('FECHA_COMPLETA', DB::raw('COUNT(*) as cantidad'))
                ->groupBy('FECHA_COMPLETA')
                ->get();

            // Formatear respuesta: array de fechas con cantidad
            $diasFormateados = [];
            foreach ($diasConVisitas as $dia) {
                $fecha = Carbon::parse($dia->FECHA_COMPLETA);
                $diasFormateados[] = [
                    'fecha' => $dia->FECHA_COMPLETA,
                    'dia' => (int) $fecha->format('d'),
                    'cantidad' => (int) $dia->cantidad,
                ];
            }

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Días con visitas obtenidos correctamente",
                "data" => [
                    "año" => $año,
                    "mes" => $mes,
                    "dias" => $diasFormateados,
                ],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en diasConVisitas PDVVisitasAD: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al obtener días con visitas: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }
}

