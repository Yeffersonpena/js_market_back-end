<?php

namespace App\Http\Controllers\Zonal;

use App\Http\Controllers\Controller;
use App\Models\PDV_VISITAS_AD_DIAS;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;
use Tymon\JWTAuth\Facades\JWTAuth;

class PDVVisitasADZonalController extends Controller
{
    /**
     * Obtener zonal del usuario autenticado desde el token JWT
     */
    private function getZonalUsuario()
    {
        try {
            $datosToken = JWTAuth::parseToken()->authenticate();
            return $datosToken->zonal ?? null;
        } catch (\Exception $e) {
            Log::error('Error obteniendo zonal del usuario: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Dashboard: Resumen de visitas de un día específico
     * Filtrado automáticamente por zonal del usuario
     */
    public function dashboardDia($fecha)
    {
        try {
            // Obtener zonal del usuario
            $zonalUsuario = $this->getZonalUsuario();

            if (!$zonalUsuario) {
                return response()->json([
                    "status" => Response::HTTP_UNAUTHORIZED,
                    "message" => "No se pudo obtener el zonal del usuario",
                ], Response::HTTP_UNAUTHORIZED);
            }

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

            // Obtener PDVs programados para esta fecha, filtrados por zonal del usuario
            $pdvsDelDia = PDV_VISITAS_AD_DIAS::where('FECHA_COMPLETA', $fechaFormateada)
                ->where('PROGRAMADO', 1)
                ->whereHas('programacion', function ($q) use ($zonalUsuario) {
                    $q->where('ZONAL', $zonalUsuario);
                })
                ->with('programacion')
                ->get();

            if ($pdvsDelDia->isEmpty()) {
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "No hay visitas programadas para esta fecha en su zonal",
                    "data" => [
                        "fecha" => $fechaFormateada,
                        "zonal" => $zonalUsuario,
                        "resumen" => [
                            "total_pdvs" => 0,
                            "total_zonales" => 0,
                            "total_vendedores" => 0,
                        ],
                        "resumen_por_zonal" => [],
                    ],
                ], Response::HTTP_OK);
            }

            // Agrupar por vendedor (solo del zonal del usuario)
            $agrupadoPorVendedor = [];
            $vendedoresUnicos = [];

            foreach ($pdvsDelDia as $dia) {
                $programacion = $dia->programacion;
                if (!$programacion) {
                    continue;
                }

                $codVvdd = $programacion->COD_VVDD ?? null;
                $vendedor = $programacion->VENDEDORES ?? 'SIN VENDEDOR';

                // Inicializar vendedor si no existe
                $keyVendedor = $codVvdd ? (string) $codVvdd : $vendedor;
                if (!isset($agrupadoPorVendedor[$keyVendedor])) {
                    $agrupadoPorVendedor[$keyVendedor] = [
                        'vendedor' => $vendedor,
                        'cod_vvdd' => $codVvdd,
                        'cantidad' => 0,
                    ];
                    $vendedoresUnicos[$keyVendedor] = true;
                }

                // Incrementar contador
                $agrupadoPorVendedor[$keyVendedor]['cantidad']++;
            }

            // Formatear resumen por zonal (solo un zonal en este caso)
            $vendedoresArray = array_values($agrupadoPorVendedor);
            $resumenPorZonal = [
                [
                    'zonal' => $zonalUsuario,
                    'cantidad' => $pdvsDelDia->count(),
                    'vendedores' => count($vendedoresArray),
                    'detalle_vendedores' => $vendedoresArray,
                ]
            ];

            // Calcular totales
            $totalPDVs = $pdvsDelDia->count();
            $totalVendedores = count($vendedoresUnicos);

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Resumen del día obtenido correctamente",
                "data" => [
                    "fecha" => $fechaFormateada,
                    "zonal" => $zonalUsuario,
                    "resumen" => [
                        "total_pdvs" => $totalPDVs,
                        "total_zonales" => 1,
                        "total_vendedores" => $totalVendedores,
                    ],
                    "resumen_por_zonal" => $resumenPorZonal,
                ],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en dashboardDia PDVVisitasADZonal: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al obtener resumen del día: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Detalle completo de PDVs a visitar en un día específico
     * Filtrado automáticamente por zonal del usuario
     */
    public function detalleDia(Request $request, $fecha)
    {
        try {
            // Obtener zonal del usuario
            $zonalUsuario = $this->getZonalUsuario();

            if (!$zonalUsuario) {
                return response()->json([
                    "status" => Response::HTTP_UNAUTHORIZED,
                    "message" => "No se pudo obtener el zonal del usuario",
                ], Response::HTTP_UNAUTHORIZED);
            }

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

            // Filtros opcionales (solo vendedor y búsqueda, no zonal)
            $vendedor = $request->input('vendedor'); // COD_VVDD
            $search = $request->input('search'); // Búsqueda general

            // Query base: PDVs del día, filtrados por zonal del usuario
            $query = PDV_VISITAS_AD_DIAS::where('FECHA_COMPLETA', $fechaFormateada)
                ->where('PROGRAMADO', 1)
                ->whereHas('programacion', function ($q) use ($zonalUsuario) {
                    $q->where('ZONAL', $zonalUsuario);
                })
                ->with('programacion');

            // Aplicar filtros adicionales si existen
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
                "zonal" => $zonalUsuario,
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en detalleDia PDVVisitasADZonal: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al obtener detalle del día: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Obtener días del mes con visitas programadas
     * Filtrado automáticamente por zonal del usuario
     */
    public function diasConVisitas($año, $mes)
    {
        try {
            // Obtener zonal del usuario
            $zonalUsuario = $this->getZonalUsuario();

            if (!$zonalUsuario) {
                return response()->json([
                    "status" => Response::HTTP_UNAUTHORIZED,
                    "message" => "No se pudo obtener el zonal del usuario",
                ], Response::HTTP_UNAUTHORIZED);
            }

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

            // Obtener días con visitas programadas en el mes, filtrados por zonal
            $diasConVisitas = PDV_VISITAS_AD_DIAS::whereBetween('FECHA_COMPLETA', [$primerDia, $ultimoDia])
                ->where('PROGRAMADO', 1)
                ->whereHas('programacion', function ($q) use ($zonalUsuario) {
                    $q->where('ZONAL', $zonalUsuario);
                })
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
                    "zonal" => $zonalUsuario,
                    "dias" => $diasFormateados,
                ],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en diasConVisitas PDVVisitasADZonal: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al obtener días con visitas: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }
}

