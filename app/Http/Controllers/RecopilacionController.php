<?php

namespace App\Http\Controllers;

use App\Exports\RecopilacionFinalizadasExport;
use App\Models\RcClientePdv;
use App\Models\RcFormulario;
use App\Models\RcPregunta;
use App\Models\RcPreguntaOpcion;
use App\Models\RcRespuesta;
use App\Models\RcRespuestaMedia;
use App\Models\RcRespuestaOpcion;
use App\Models\RcSeccion;
use App\Models\RcVisitaFormulario;
use App\Services\RecopilacionMediaStorage;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\Response;
use Tymon\JWTAuth\Facades\JWTAuth;

class RecopilacionController extends Controller
{
    /** Recopilación: ejecutor (lista por asignación + DNI en users.user) */
    private const PERFIL_RECOPILACION_EJECUTOR = 6;

    /** Recopilación: supervisor zonal (lista por users.zonal) */
    private const PERFIL_RECOPILACION_ZONAL = 7;

    /** Recopilación: maestro (lista y visitas sin restricción por zonal/asignación) */
    private const PERFIL_RECOPILACION_MAESTRO = 8;

    private function getZonalUsuario()
    {
        try {
            $user = JWTAuth::parseToken()->authenticate();
            return $user->zonal ?? null;
        } catch (\Exception $e) {
            return null;
        }
    }

    private function getUsuarioRecopilacion(): ?object
    {
        try {
            return JWTAuth::parseToken()->authenticate();
        } catch (\Exception $e) {
            return null;
        }
    }

    private function getDniUsuario(object $user): int
    {
        $dniToken = $user->user ?? null;
        if ($dniToken !== null && is_numeric((string) $dniToken)) {
            return (int) $dniToken;
        }
        return (int) ($user->dni ?? $user->id ?? 0);
    }

    private function getDniUsuarioDesdeToken(object $user): ?string
    {
        $dni = trim((string) ($user->user ?? ''));
        return $dni !== '' ? $dni : null;
    }

    private function esPerfilRecopilacionEjecutor(object $user): bool
    {
        return (int) ($user->idPerfil ?? 0) === self::PERFIL_RECOPILACION_EJECUTOR;
    }

    private function esPerfilRecopilacionZonal(object $user): bool
    {
        return (int) ($user->idPerfil ?? 0) === self::PERFIL_RECOPILACION_ZONAL;
    }

    private function esPerfilRecopilacionMaestro(object $user): bool
    {
        return (int) ($user->idPerfil ?? 0) === self::PERFIL_RECOPILACION_MAESTRO;
    }

    /** Ejecutor y zonal requieren zonal en token; maestro puede no tenerla. */
    private function tokenRequiereZonalUsuario(object $user): bool
    {
        return ! $this->esPerfilRecopilacionMaestro($user);
    }

    private function puedeGestionarVisitaRecopilacion(object $user, RcVisitaFormulario $visita, ?string $zonal): bool
    {
        if ($this->esPerfilRecopilacionMaestro($user)) {
            return true;
        }

        return $this->visitaPerteneceAZonal($visita, $zonal);
    }

    private function visitaPerteneceAZonal(RcVisitaFormulario $visita, ?string $zonal): bool
    {
        return $zonal !== null && $visita->zonal_usuario === $zonal;
    }

    /**
     * Lista de puntos (RC_CLIENTE_PDV) de la zonal del usuario que aun no tienen
     * instancia de visita (RC_VISITA_FORMULARIO) para el formulario y periodo dados.
     */
    public function puntosPendientes(Request $request)
    {
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }

        if (
            ! $this->esPerfilRecopilacionEjecutor($user)
            && ! $this->esPerfilRecopilacionZonal($user)
            && ! $this->esPerfilRecopilacionMaestro($user)
        ) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Perfil no autorizado para recopilacion',
            ], Response::HTTP_FORBIDDEN);
        }

        $zonal = $this->getZonalUsuario();
        $esEjecutor = $this->esPerfilRecopilacionEjecutor($user);

        if ($esEjecutor) {
            $dniUsuario = $this->getDniUsuarioDesdeToken($user);
            if (!$dniUsuario) {
                return response()->json([
                    'status' => Response::HTTP_UNAUTHORIZED,
                    'message' => 'No se pudo obtener el DNI del usuario',
                ], Response::HTTP_UNAUTHORIZED);
            }
        } elseif ($this->esPerfilRecopilacionZonal($user) && !$zonal) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener la zonal del usuario',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $anio = (int) $request->get('anio', now()->year);
        $mes = (int) $request->get('mes', now()->month);
        $formularioCodigo = $request->get('formulario_codigo', 'DATOS_PDV_VENTAS');
        $page = max(1, (int) $request->get('page', 1));
        $perPage = min(100, max(5, (int) $request->get('per_page', 15)));
        $search = $request->get('search', '');
        $search = is_string($search) ? trim($search) : '';

        $formulario = RcFormulario::where('codigo', $formularioCodigo)
            ->where('activo', 1)
            ->orderByDesc('version')
            ->first();

        if (!$formulario) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => "No existe formulario activo con codigo {$formularioCodigo}",
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $query = DB::connection('sqlsrv')
            ->table('RC_CLIENTE_PDV as c');

        if ($esEjecutor) {
            $asignadosQuery = DB::connection('sqlsrv')
                ->table('RC_PDV_ASIGNACION_VISITA')
                ->select('pdv_id')
                ->where('dni_ejecutor', $dniUsuario)
                ->whereNotNull('fecha_visita_tentativa')
                ->distinct();

            $query->joinSub($asignadosQuery, 'a', function ($join) {
                $join->on('a.pdv_id', '=', 'c.id');
            });
        } elseif ($this->esPerfilRecopilacionZonal($user)) {
            $query->where('c.zonal', $zonal);
        }
        // maestro: sin filtro por asignación ni zonal

        $query->leftJoin('RC_VISITA_FORMULARIO as v', function ($join) use ($formulario, $anio, $mes) {
            $join->on('v.cliente_id', '=', 'c.id')
                ->where('v.formulario_id', $formulario->id)
                ->where('v.anio', $anio)
                ->where('v.mes', $mes);
        })
            ->whereNull('v.id');

        if ($search !== '') {
            $term = '%' . $search . '%';
            $query->where(function ($q) use ($term) {
                $q->where('c.nro_documento', 'like', $term)
                    ->orWhere('c.nombre_pdv', 'like', $term);
            });
        }

        $total = $query->count();

        $lista = (clone $query)
            ->select(
                'c.id as cliente_id',
                'c.nro_documento',
                'c.nombre_pdv',
                'c.zonal',
                'c.vendedor',
                'c.promedio_equipo',
                'c.total_s_venta_accesorio',
                'c.vende_accesorios',
                'v.id as visita_id',
                'v.estado as estado_visita',
                'v.porcentaje_avance',
                'v.fecha_ultima_edicion'
            )
            ->orderByRaw("CASE WHEN v.estado IS NULL THEN 0 WHEN v.estado = 'borrador' THEN 1 ELSE 2 END")
            ->orderByDesc('v.porcentaje_avance')
            ->orderBy('c.nombre_pdv')
            ->offset(($page - 1) * $perPage)
            ->limit($perPage)
            ->get();

        return response()->json([
            'status' => Response::HTTP_OK,
            'data' => $lista,
            'meta' => [
                'current_page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'last_page' => (int) ceil($total / $perPage),
            ],
        ], Response::HTTP_OK);
    }

    /**
     * Lista de puntos (RC_CLIENTE_PDV) que SI tienen instancia de visita
     * (RC_VISITA_FORMULARIO) para el formulario y periodo dados.
     * Pensado para módulo de "registrados/editar".
     */
    public function puntosRegistrados(Request $request)
    {
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }

        if (
            ! $this->esPerfilRecopilacionEjecutor($user)
            && ! $this->esPerfilRecopilacionZonal($user)
            && ! $this->esPerfilRecopilacionMaestro($user)
        ) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Perfil no autorizado para recopilacion',
            ], Response::HTTP_FORBIDDEN);
        }

        $zonal = $this->getZonalUsuario();
        $esEjecutor = $this->esPerfilRecopilacionEjecutor($user);

        if ($esEjecutor) {
            $dniUsuario = $this->getDniUsuarioDesdeToken($user);
            if (!$dniUsuario) {
                return response()->json([
                    'status' => Response::HTTP_UNAUTHORIZED,
                    'message' => 'No se pudo obtener el DNI del usuario',
                ], Response::HTTP_UNAUTHORIZED);
            }
        } elseif ($this->esPerfilRecopilacionZonal($user) && !$zonal) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener la zonal del usuario',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $anio = (int) $request->get('anio', now()->year);
        $mes = (int) $request->get('mes', now()->month);
        $formularioCodigo = $request->get('formulario_codigo', 'DATOS_PDV_VENTAS');
        $page = max(1, (int) $request->get('page', 1));
        $perPage = min(100, max(5, (int) $request->get('per_page', 15)));
        $search = $request->get('search', '');
        $search = is_string($search) ? trim($search) : '';

        $formulario = RcFormulario::where('codigo', $formularioCodigo)
            ->where('activo', 1)
            ->orderByDesc('version')
            ->first();

        if (!$formulario) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => "No existe formulario activo con codigo {$formularioCodigo}",
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $query = DB::connection('sqlsrv')
            ->table('RC_CLIENTE_PDV as c');

        if ($esEjecutor) {
            $asignadosQuery = DB::connection('sqlsrv')
                ->table('RC_PDV_ASIGNACION_VISITA')
                ->select('pdv_id')
                ->where('dni_ejecutor', $dniUsuario)
                ->whereNotNull('fecha_visita_tentativa')
                ->distinct();

            $query->joinSub($asignadosQuery, 'a', function ($join) {
                $join->on('a.pdv_id', '=', 'c.id');
            });
        } elseif ($this->esPerfilRecopilacionZonal($user)) {
            $query->where('c.zonal', $zonal);
        }
        // maestro: sin filtro por asignación ni zonal

        $query->join('RC_VISITA_FORMULARIO as v', function ($join) use ($formulario, $anio, $mes) {
            $join->on('v.cliente_id', '=', 'c.id')
                ->where('v.formulario_id', $formulario->id)
                ->where('v.anio', $anio)
                ->where('v.mes', $mes);
        });

        if ($search !== '') {
            $term = '%' . $search . '%';
            $query->where(function ($q) use ($term) {
                $q->where('c.nro_documento', 'like', $term)
                    ->orWhere('c.nombre_pdv', 'like', $term);
            });
        }

        $total = $query->count();

        $lista = (clone $query)
            ->select(
                'c.id as cliente_id',
                'c.nro_documento',
                'c.nombre_pdv',
                'c.zonal',
                'c.vendedor',
                'c.promedio_equipo',
                'c.total_s_venta_accesorio',
                'c.vende_accesorios',
                'v.id as visita_id',
                'v.estado as estado_visita',
                'v.porcentaje_avance',
                'v.fecha_ultima_edicion'
            )
            ->orderByDesc('v.fecha_ultima_edicion')
            ->orderByDesc('v.porcentaje_avance')
            ->orderBy('c.nombre_pdv')
            ->offset(($page - 1) * $perPage)
            ->limit($perPage)
            ->get();

        return response()->json([
            'status' => Response::HTTP_OK,
            'data' => $lista,
            'meta' => [
                'current_page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'last_page' => (int) ceil($total / $perPage),
            ],
        ], Response::HTTP_OK);
    }

    /**
     * GET reporte/avance-zonal
     * Resumen por zonal: programados, ejecutados (visita con formulario en periodo) y porcentaje de avance.
     */
    public function reporteAvanceZonal(Request $request)
    {
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }

        if (
            ! $this->esPerfilRecopilacionEjecutor($user)
            && ! $this->esPerfilRecopilacionZonal($user)
            && ! $this->esPerfilRecopilacionMaestro($user)
        ) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Perfil no autorizado para recopilacion',
            ], Response::HTTP_FORBIDDEN);
        }

        $zonal = $this->getZonalUsuario();
        if ($this->tokenRequiereZonalUsuario($user) && !$zonal) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener la zonal del usuario',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $anio = $request->filled('anio') ? (int) $request->get('anio') : null;
        $mes = $request->filled('mes') ? (int) $request->get('mes') : null;
        $filtrarPeriodo = $anio !== null && $mes !== null;
        $formularioCodigo = $request->get('formulario_codigo', 'DATOS_PDV_VENTAS');
        $dniUsuario = $this->esPerfilRecopilacionEjecutor($user) ? $this->getDniUsuarioDesdeToken($user) : null;

        if ($this->esPerfilRecopilacionEjecutor($user) && !$dniUsuario) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el DNI del usuario',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $formulario = RcFormulario::where('codigo', $formularioCodigo)
            ->where('activo', 1)
            ->orderByDesc('version')
            ->first();

        if (!$formulario) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => "No existe formulario activo con codigo {$formularioCodigo}",
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $programados = DB::connection('sqlsrv')
            ->table('RC_PDV_ASIGNACION_VISITA as a')
            ->join('RC_CLIENTE_PDV as c', 'c.id', '=', 'a.pdv_id')
            ->whereNotNull('a.fecha_visita_tentativa');

        if ($filtrarPeriodo) {
            $programados
                ->whereRaw('YEAR(a.fecha_visita_tentativa) = ?', [$anio])
                ->whereRaw('MONTH(a.fecha_visita_tentativa) = ?', [$mes]);
        }

        if ($this->esPerfilRecopilacionEjecutor($user)) {
            $programados->where('a.dni_ejecutor', $dniUsuario);
        } elseif ($this->esPerfilRecopilacionZonal($user)) {
            $programados->where('c.zonal', $zonal);
        }

        $programados = $programados
            ->groupBy('c.zonal')
            ->selectRaw('c.zonal, COUNT(DISTINCT a.pdv_id) as programados');

        $ejecutados = DB::connection('sqlsrv')
            ->table('RC_PDV_ASIGNACION_VISITA as a')
            ->join('RC_CLIENTE_PDV as c', 'c.id', '=', 'a.pdv_id')
            ->join('RC_VISITA_FORMULARIO as v', function ($join) use ($formulario, $anio, $mes) {
                $join->on('v.cliente_id', '=', 'a.pdv_id')
                    ->where('v.formulario_id', $formulario->id);

                if ($anio !== null && $mes !== null) {
                    $join->where('v.anio', $anio)
                        ->where('v.mes', $mes);
                }
            })
            ->whereNotNull('a.fecha_visita_tentativa');

        if ($filtrarPeriodo) {
            $ejecutados
                ->whereRaw('YEAR(a.fecha_visita_tentativa) = ?', [$anio])
                ->whereRaw('MONTH(a.fecha_visita_tentativa) = ?', [$mes]);
        }

        if ($this->esPerfilRecopilacionEjecutor($user)) {
            $ejecutados->where('a.dni_ejecutor', $dniUsuario);
        } elseif ($this->esPerfilRecopilacionZonal($user)) {
            $ejecutados->where('c.zonal', $zonal);
        }

        $ejecutados = $ejecutados
            ->groupBy('c.zonal')
            ->selectRaw('c.zonal, COUNT(DISTINCT v.cliente_id) as ejecutados');

        $filas = DB::connection('sqlsrv')
            ->query()
            ->fromSub($programados, 'p')
            ->leftJoinSub($ejecutados, 'e', function ($join) {
                $join->on('e.zonal', '=', 'p.zonal');
            })
            ->selectRaw('p.zonal, p.programados, ISNULL(e.ejecutados, 0) as ejecutados')
            ->orderBy('p.zonal')
            ->get();

        $data = collect($filas)->map(function ($row) {
            $programados = (int) ($row->programados ?? 0);
            $ejecutados = (int) ($row->ejecutados ?? 0);
            $avance = $programados > 0 ? round(($ejecutados * 100) / $programados, 1) : 0.0;

            return [
                'zonal' => $row->zonal,
                'programados' => $programados,
                'ejecutados' => $ejecutados,
                'porcentaje_avance' => $avance,
            ];
        })->values();

        $totalProgramados = $data->sum('programados');
        $totalEjecutados = $data->sum('ejecutados');
        $totalAvance = $totalProgramados > 0 ? round(($totalEjecutados * 100) / $totalProgramados, 1) : 0.0;

        $data->push([
            'zonal' => 'TOTAL',
            'programados' => $totalProgramados,
            'ejecutados' => $totalEjecutados,
            'porcentaje_avance' => $totalAvance,
        ]);

        return response()->json([
            'status' => Response::HTTP_OK,
            'data' => $data,
            'meta' => [
                'anio' => $anio,
                'mes' => $mes,
                'scope' => $filtrarPeriodo ? 'periodo' : 'global',
                'formulario_codigo' => $formularioCodigo,
            ],
        ], Response::HTTP_OK);
    }

    /**
     * GET reporte/opciones/grupo-si-no
     * Reporte para tabla de preguntas con opciones SI/NO.
     * Preguntas incluidas (fase 1): P03, P09, P11B.
     */
    public function reporteOpcionesGrupoSiNo(Request $request)
    {
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }

        if (! $this->esPerfilRecopilacionMaestro($user)) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Solo perfil maestro puede consultar este reporte',
            ], Response::HTTP_FORBIDDEN);
        }

        $formularioCodigo = $request->get('formulario_codigo', 'DATOS_PDV_VENTAS');
        $formulario = $this->getFormularioActivoRecopilacion($formularioCodigo);
        if (!$formulario) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => "No existe formulario activo con codigo {$formularioCodigo}",
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $preguntasObjetivo = ['P03', 'P09', 'P11B'];

        $preguntas = DB::connection('sqlsrv')
            ->table('RC_PREGUNTA as p')
            ->join('RC_SECCION as s', 's.id', '=', 'p.seccion_id')
            ->where('s.formulario_id', $formulario->id)
            ->where('p.activo', 1)
            ->whereIn('p.codigo', $preguntasObjetivo)
            ->select('p.id', 'p.codigo', 'p.texto')
            ->get();

        $orderMap = array_flip($preguntasObjetivo);
        $preguntas = $preguntas->sortBy(fn($p) => $orderMap[$p->codigo] ?? 999)->values();

        $matriz = [];
        foreach ($preguntas as $p) {
            $matriz[$p->codigo] = [
                'pregunta_codigo' => $p->codigo,
                'pregunta_texto' => $p->texto,
                'si' => 0,
                'no' => 0,
                'total' => 0,
            ];
        }

        if (!empty($matriz)) {
            $rows = DB::connection('sqlsrv')
                ->table('RC_RESPUESTA as r')
                ->join('RC_VISITA_FORMULARIO as v', 'v.id', '=', 'r.visita_id')
                ->join('RC_PREGUNTA as p', 'p.id', '=', 'r.pregunta_id')
                ->leftJoin('RC_RESPUESTA_OPCION as ro', 'ro.respuesta_id', '=', 'r.id')
                ->leftJoin('RC_PREGUNTA_OPCION as po', 'po.id', '=', 'ro.opcion_id')
                ->where('v.formulario_id', $formulario->id)
                ->whereIn('p.codigo', $preguntasObjetivo)
                ->select(
                    'p.codigo as pregunta_codigo',
                    'r.valor_booleano',
                    'po.codigo as opcion_codigo',
                    'po.valor as opcion_valor',
                    'po.etiqueta as opcion_etiqueta'
                )
                ->get();

            foreach ($rows as $row) {
                $codigoPregunta = (string) ($row->pregunta_codigo ?? '');
                if (!isset($matriz[$codigoPregunta])) {
                    continue;
                }

                $respuesta = $this->normalizarOpcionSiNo($row->opcion_codigo)
                    ?? $this->normalizarOpcionSiNo($row->opcion_valor)
                    ?? $this->normalizarOpcionSiNo($row->opcion_etiqueta);

                if ($respuesta === null && $row->valor_booleano !== null) {
                    $respuesta = ((int) $row->valor_booleano) === 1 ? 'SI' : 'NO';
                }

                if ($respuesta === 'SI') {
                    $matriz[$codigoPregunta]['si']++;
                    $matriz[$codigoPregunta]['total']++;
                } elseif ($respuesta === 'NO') {
                    $matriz[$codigoPregunta]['no']++;
                    $matriz[$codigoPregunta]['total']++;
                }
            }
        }

        return response()->json([
            'status' => Response::HTTP_OK,
            'data' => array_values($matriz),
            'meta' => [
                'grupo' => 'si_no',
                'formulario_codigo' => $formularioCodigo,
                'preguntas' => $preguntasObjetivo,
                'columnas' => ['SI', 'NO'],
            ],
        ], Response::HTTP_OK);
    }

    /**
     * GET reporte/opciones/grupo-escala-5
     * Reporte para tabla de preguntas con escala 1..5.
     * Preguntas incluidas (fase 2): P23, P30.
     */
    public function reporteOpcionesGrupoEscala5(Request $request)
    {
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }

        if (! $this->esPerfilRecopilacionMaestro($user)) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Solo perfil maestro puede consultar este reporte',
            ], Response::HTTP_FORBIDDEN);
        }

        $formularioCodigo = $request->get('formulario_codigo', 'DATOS_PDV_VENTAS');
        $formulario = $this->getFormularioActivoRecopilacion($formularioCodigo);
        if (!$formulario) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => "No existe formulario activo con codigo {$formularioCodigo}",
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $preguntasObjetivo = ['P23', 'P30'];

        $preguntas = DB::connection('sqlsrv')
            ->table('RC_PREGUNTA as p')
            ->join('RC_SECCION as s', 's.id', '=', 'p.seccion_id')
            ->where('s.formulario_id', $formulario->id)
            ->where('p.activo', 1)
            ->whereIn('p.codigo', $preguntasObjetivo)
            ->select('p.id', 'p.codigo', 'p.texto')
            ->get();

        $orderMap = array_flip($preguntasObjetivo);
        $preguntas = $preguntas->sortBy(fn($p) => $orderMap[$p->codigo] ?? 999)->values();

        $matriz = [];
        foreach ($preguntas as $p) {
            $matriz[$p->codigo] = [
                'pregunta_codigo' => $p->codigo,
                'pregunta_texto' => $p->texto,
                'nivel_1' => 0,
                'nivel_2' => 0,
                'nivel_3' => 0,
                'nivel_4' => 0,
                'nivel_5' => 0,
                'total' => 0,
            ];
        }

        if (!empty($matriz)) {
            $rows = DB::connection('sqlsrv')
                ->table('RC_RESPUESTA as r')
                ->join('RC_VISITA_FORMULARIO as v', 'v.id', '=', 'r.visita_id')
                ->join('RC_PREGUNTA as p', 'p.id', '=', 'r.pregunta_id')
                ->leftJoin('RC_RESPUESTA_OPCION as ro', 'ro.respuesta_id', '=', 'r.id')
                ->leftJoin('RC_PREGUNTA_OPCION as po', 'po.id', '=', 'ro.opcion_id')
                ->where('v.formulario_id', $formulario->id)
                ->whereIn('p.codigo', $preguntasObjetivo)
                ->select(
                    'p.codigo as pregunta_codigo',
                    'r.valor_numero',
                    'r.valor_decimal',
                    'r.valor_texto',
                    'po.codigo as opcion_codigo',
                    'po.valor as opcion_valor',
                    'po.etiqueta as opcion_etiqueta'
                )
                ->get();

            foreach ($rows as $row) {
                $codigoPregunta = (string) ($row->pregunta_codigo ?? '');
                if (!isset($matriz[$codigoPregunta])) {
                    continue;
                }

                $nivel = $this->normalizarEscalaUnoACinco($row->opcion_valor)
                    ?? $this->normalizarEscalaUnoACinco($row->opcion_codigo)
                    ?? $this->normalizarEscalaUnoACinco($row->opcion_etiqueta)
                    ?? $this->normalizarEscalaUnoACinco($row->valor_numero)
                    ?? $this->normalizarEscalaUnoACinco($row->valor_decimal)
                    ?? $this->normalizarEscalaUnoACinco($row->valor_texto);

                if ($nivel === null) {
                    continue;
                }

                $key = "nivel_{$nivel}";
                $matriz[$codigoPregunta][$key]++;
                $matriz[$codigoPregunta]['total']++;
            }
        }

        return response()->json([
            'status' => Response::HTTP_OK,
            'data' => array_values($matriz),
            'meta' => [
                'grupo' => 'escala_1_5',
                'formulario_codigo' => $formularioCodigo,
                'preguntas' => $preguntasObjetivo,
                'columnas' => ['1', '2', '3', '4', '5'],
            ],
        ], Response::HTTP_OK);
    }

    /**
     * GET reporte/opciones/grupo-perfil-local
     * Perfil del local: tres opciones por pregunta con etiquetas distintas (P08, P17, P19, P20).
     * Cada elemento de data trae opciones con cantidad para mini-tablas en frontend.
     */
    public function reporteOpcionesGrupoPerfilLocal(Request $request)
    {
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }

        if (! $this->esPerfilRecopilacionMaestro($user)) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Solo perfil maestro puede consultar este reporte',
            ], Response::HTTP_FORBIDDEN);
        }

        $formularioCodigo = $request->get('formulario_codigo', 'DATOS_PDV_VENTAS');
        $formulario = $this->getFormularioActivoRecopilacion($formularioCodigo);
        if (!$formulario) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => "No existe formulario activo con codigo {$formularioCodigo}",
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $preguntasObjetivo = ['P08', 'P17', 'P19', 'P20'];

        $catalogo = DB::connection('sqlsrv')
            ->table('RC_PREGUNTA as p')
            ->join('RC_SECCION as s', 's.id', '=', 'p.seccion_id')
            ->join('RC_PREGUNTA_OPCION as po', 'po.pregunta_id', '=', 'p.id')
            ->where('s.formulario_id', $formulario->id)
            ->where('p.activo', 1)
            ->where('po.activo', 1)
            ->whereIn('p.codigo', $preguntasObjetivo)
            ->orderBy('p.codigo')
            ->orderBy('po.orden')
            ->select(
                'p.codigo as pregunta_codigo',
                'p.texto as pregunta_texto',
                'po.id as opcion_id',
                'po.codigo as opcion_codigo',
                'po.etiqueta as opcion_etiqueta',
                'po.orden as opcion_orden'
            )
            ->get();

        $bloques = [];
        foreach ($catalogo as $row) {
            $cod = (string) $row->pregunta_codigo;
            if (! isset($bloques[$cod])) {
                $bloques[$cod] = [
                    'pregunta_codigo' => $cod,
                    'pregunta_texto' => $row->pregunta_texto,
                    'opciones' => [],
                    'total' => 0,
                ];
            }
            $bloques[$cod]['opciones'][] = [
                'opcion_id' => (int) $row->opcion_id,
                'opcion_codigo' => $row->opcion_codigo,
                'etiqueta' => $row->opcion_etiqueta,
                'orden' => (int) $row->opcion_orden,
                'cantidad' => 0,
            ];
        }

        $dataOrdenada = [];
        foreach ($preguntasObjetivo as $cod) {
            if (isset($bloques[$cod])) {
                $dataOrdenada[] = $bloques[$cod];
            }
        }

        if (! empty($bloques)) {
            $conteos = DB::connection('sqlsrv')
                ->table('RC_RESPUESTA as r')
                ->join('RC_VISITA_FORMULARIO as v', 'v.id', '=', 'r.visita_id')
                ->join('RC_PREGUNTA as p', 'p.id', '=', 'r.pregunta_id')
                ->join('RC_RESPUESTA_OPCION as ro', 'ro.respuesta_id', '=', 'r.id')
                ->join('RC_PREGUNTA_OPCION as po', 'po.id', '=', 'ro.opcion_id')
                ->where('v.formulario_id', $formulario->id)
                ->whereIn('p.codigo', $preguntasObjetivo)
                ->groupBy('p.codigo', 'po.id')
                ->selectRaw('p.codigo as pregunta_codigo, po.id as opcion_id, COUNT(*) as cantidad')
                ->get();

            $indexBloque = [];
            foreach ($dataOrdenada as $bi => $bloque) {
                $indexBloque[$bloque['pregunta_codigo']] = $bi;
            }

            foreach ($conteos as $c) {
                $pc = (string) ($c->pregunta_codigo ?? '');
                $oid = (int) ($c->opcion_id ?? 0);
                $cnt = (int) ($c->cantidad ?? 0);
                if (! isset($indexBloque[$pc])) {
                    continue;
                }
                $bi = $indexBloque[$pc];
                foreach ($dataOrdenada[$bi]['opciones'] as $oi => $op) {
                    if ((int) ($op['opcion_id'] ?? 0) === $oid) {
                        $dataOrdenada[$bi]['opciones'][$oi]['cantidad'] = $cnt;
                        $dataOrdenada[$bi]['total'] += $cnt;
                        break;
                    }
                }
            }
        }

        return response()->json([
            'status' => Response::HTTP_OK,
            'data' => $dataOrdenada,
            'meta' => [
                'grupo' => 'perfil_local',
                'formulario_codigo' => $formularioCodigo,
                'preguntas' => $preguntasObjetivo,
            ],
        ], Response::HTTP_OK);
    }

    /**
     * GET reporte/opciones/grupo-lineas-producto
     * Preguntas con opciones compartidas para tabla comparativa (P13, P24).
     */
    public function reporteOpcionesGrupoLineasProducto(Request $request)
    {
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }

        if (! $this->esPerfilRecopilacionMaestro($user)) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Solo perfil maestro puede consultar este reporte',
            ], Response::HTTP_FORBIDDEN);
        }

        $formularioCodigo = $request->get('formulario_codigo', 'DATOS_PDV_VENTAS');
        $formulario = $this->getFormularioActivoRecopilacion($formularioCodigo);
        if (!$formulario) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => "No existe formulario activo con codigo {$formularioCodigo}",
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $preguntasObjetivo = ['P13', 'P24'];

        $catalogo = DB::connection('sqlsrv')
            ->table('RC_PREGUNTA as p')
            ->join('RC_SECCION as s', 's.id', '=', 'p.seccion_id')
            ->join('RC_PREGUNTA_OPCION as po', 'po.pregunta_id', '=', 'p.id')
            ->where('s.formulario_id', $formulario->id)
            ->where('p.activo', 1)
            ->where('po.activo', 1)
            ->whereIn('p.codigo', $preguntasObjetivo)
            ->orderBy('p.codigo')
            ->orderBy('po.orden')
            ->select(
                'p.codigo as pregunta_codigo',
                'p.texto as pregunta_texto',
                'po.id as opcion_id',
                'po.codigo as opcion_codigo',
                'po.etiqueta as opcion_etiqueta',
                'po.orden as opcion_orden'
            )
            ->get();

        $bloques = [];
        $columnasMap = [];

        foreach ($catalogo as $row) {
            $codigoPregunta = (string) ($row->pregunta_codigo ?? '');
            $codigoOpcion = (string) ($row->opcion_codigo ?? '');
            if ($codigoPregunta === '' || $codigoOpcion === '') {
                continue;
            }

            if (! isset($bloques[$codigoPregunta])) {
                $bloques[$codigoPregunta] = [
                    'pregunta_codigo' => $codigoPregunta,
                    'pregunta_texto' => $row->pregunta_texto,
                    'opciones' => [],
                    'total' => 0,
                ];
            }

            $bloques[$codigoPregunta]['opciones'][$codigoOpcion] = [
                'opcion_id' => (int) $row->opcion_id,
                'opcion_codigo' => $codigoOpcion,
                'etiqueta' => (string) ($row->opcion_etiqueta ?? $codigoOpcion),
                'orden' => (int) ($row->opcion_orden ?? 999),
                'cantidad' => 0,
            ];

            if (! isset($columnasMap[$codigoOpcion])) {
                $columnasMap[$codigoOpcion] = [
                    'opcion_codigo' => $codigoOpcion,
                    'etiqueta' => (string) ($row->opcion_etiqueta ?? $codigoOpcion),
                    'orden' => (int) ($row->opcion_orden ?? 999),
                ];
            }
        }

        $conteos = DB::connection('sqlsrv')
            ->table('RC_RESPUESTA as r')
            ->join('RC_VISITA_FORMULARIO as v', 'v.id', '=', 'r.visita_id')
            ->join('RC_PREGUNTA as p', 'p.id', '=', 'r.pregunta_id')
            ->join('RC_RESPUESTA_OPCION as ro', 'ro.respuesta_id', '=', 'r.id')
            ->join('RC_PREGUNTA_OPCION as po', 'po.id', '=', 'ro.opcion_id')
            ->where('v.formulario_id', $formulario->id)
            ->whereIn('p.codigo', $preguntasObjetivo)
            ->groupBy('p.codigo', 'po.codigo')
            ->selectRaw('p.codigo as pregunta_codigo, po.codigo as opcion_codigo, COUNT(*) as cantidad')
            ->get();

        foreach ($conteos as $c) {
            $codigoPregunta = (string) ($c->pregunta_codigo ?? '');
            $codigoOpcion = (string) ($c->opcion_codigo ?? '');
            $cantidad = (int) ($c->cantidad ?? 0);

            if (! isset($bloques[$codigoPregunta])) {
                continue;
            }

            if (! isset($bloques[$codigoPregunta]['opciones'][$codigoOpcion])) {
                $metaCol = $columnasMap[$codigoOpcion] ?? [
                    'opcion_codigo' => $codigoOpcion,
                    'etiqueta' => $codigoOpcion,
                    'orden' => 999,
                ];
                $bloques[$codigoPregunta]['opciones'][$codigoOpcion] = [
                    'opcion_id' => null,
                    'opcion_codigo' => $metaCol['opcion_codigo'],
                    'etiqueta' => $metaCol['etiqueta'],
                    'orden' => $metaCol['orden'],
                    'cantidad' => 0,
                ];
            }

            $bloques[$codigoPregunta]['opciones'][$codigoOpcion]['cantidad'] = $cantidad;
            $bloques[$codigoPregunta]['total'] += $cantidad;
        }

        $columnas = collect($columnasMap)
            ->sortBy(function ($c) {
                return ((int) ($c['orden'] ?? 999)) * 1000 . '|' . ($c['opcion_codigo'] ?? '');
            })
            ->values()
            ->all();

        $dataOrdenada = [];
        foreach ($preguntasObjetivo as $codigoPregunta) {
            if (! isset($bloques[$codigoPregunta])) {
                continue;
            }

            $opcionesOrdenadas = [];
            foreach ($columnas as $col) {
                $codigoOpcion = (string) ($col['opcion_codigo'] ?? '');
                $opcionesOrdenadas[] = $bloques[$codigoPregunta]['opciones'][$codigoOpcion] ?? [
                    'opcion_id' => null,
                    'opcion_codigo' => $codigoOpcion,
                    'etiqueta' => $col['etiqueta'] ?? $codigoOpcion,
                    'orden' => (int) ($col['orden'] ?? 999),
                    'cantidad' => 0,
                ];
            }

            $bloque = $bloques[$codigoPregunta];
            $bloque['opciones'] = $opcionesOrdenadas;
            $dataOrdenada[] = $bloque;
        }

        return response()->json([
            'status' => Response::HTTP_OK,
            'data' => $dataOrdenada,
            'meta' => [
                'grupo' => 'lineas_producto',
                'formulario_codigo' => $formularioCodigo,
                'preguntas' => $preguntasObjetivo,
                'columnas' => $columnas,
            ],
        ], Response::HTTP_OK);
    }

    /**
     * GET reporte/opciones/grupo-criterios-competencia
     * Tab 5:
     * - Bloques individuales: P16, P11, P12, P21 (cada una con sus propias opciones)
     * - Tabla combinada: P25/P31 (Si, No, Variante)
     */
    public function reporteOpcionesGrupoCriteriosCompetencia(Request $request)
    {
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }

        if (! $this->esPerfilRecopilacionMaestro($user)) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Solo perfil maestro puede consultar este reporte',
            ], Response::HTTP_FORBIDDEN);
        }

        $formularioCodigo = $request->get('formulario_codigo', 'DATOS_PDV_VENTAS');
        $formulario = $this->getFormularioActivoRecopilacion($formularioCodigo);
        if (!$formulario) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => "No existe formulario activo con codigo {$formularioCodigo}",
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $preguntasIndividuales = ['P16', 'P11', 'P12', 'P21'];
        $preguntasCombinadas = ['P25', 'P31'];
        $preguntasObjetivo = array_merge($preguntasIndividuales, $preguntasCombinadas);

        $catalogo = DB::connection('sqlsrv')
            ->table('RC_PREGUNTA as p')
            ->join('RC_SECCION as s', 's.id', '=', 'p.seccion_id')
            ->join('RC_PREGUNTA_OPCION as po', 'po.pregunta_id', '=', 'p.id')
            ->where('s.formulario_id', $formulario->id)
            ->where('p.activo', 1)
            ->where('po.activo', 1)
            ->whereIn('p.codigo', $preguntasObjetivo)
            ->orderBy('p.codigo')
            ->orderBy('po.orden')
            ->select(
                'p.codigo as pregunta_codigo',
                'p.texto as pregunta_texto',
                'po.id as opcion_id',
                'po.codigo as opcion_codigo',
                'po.etiqueta as opcion_etiqueta',
                'po.valor as opcion_valor',
                'po.orden as opcion_orden'
            )
            ->get();

        $individualesMap = [];
        $combinadasMap = [];
        $combinadaTipoPorOpcionId = [];

        foreach ($catalogo as $row) {
            $preguntaCodigo = (string) ($row->pregunta_codigo ?? '');
            $opcionId = (int) ($row->opcion_id ?? 0);
            $opcionCodigo = (string) ($row->opcion_codigo ?? '');
            $opcionEtiqueta = (string) ($row->opcion_etiqueta ?? $opcionCodigo);
            $opcionOrden = (int) ($row->opcion_orden ?? 999);

            if (in_array($preguntaCodigo, $preguntasIndividuales, true)) {
                if (! isset($individualesMap[$preguntaCodigo])) {
                    $individualesMap[$preguntaCodigo] = [
                        'pregunta_codigo' => $preguntaCodigo,
                        'pregunta_texto' => $row->pregunta_texto,
                        'opciones' => [],
                        'total' => 0,
                    ];
                }
                $individualesMap[$preguntaCodigo]['opciones'][] = [
                    'opcion_id' => $opcionId,
                    'opcion_codigo' => $opcionCodigo,
                    'etiqueta' => $opcionEtiqueta,
                    'orden' => $opcionOrden,
                    'cantidad' => 0,
                ];
                continue;
            }

            if (! in_array($preguntaCodigo, $preguntasCombinadas, true)) {
                continue;
            }

            if (! isset($combinadasMap[$preguntaCodigo])) {
                $combinadasMap[$preguntaCodigo] = [
                    'pregunta_codigo' => $preguntaCodigo,
                    'pregunta_texto' => $row->pregunta_texto,
                    'si' => 0,
                    'no' => 0,
                    'variante' => 0,
                    'variante_etiqueta' => 'Variante',
                    'total' => 0,
                ];
            }

            $tipo = $this->normalizarOpcionSiNo($opcionCodigo)
                ?? $this->normalizarOpcionSiNo($row->opcion_valor)
                ?? $this->normalizarOpcionSiNo($opcionEtiqueta);

            if ($tipo === 'SI') {
                $combinadaTipoPorOpcionId[$opcionId] = 'si';
            } elseif ($tipo === 'NO') {
                $combinadaTipoPorOpcionId[$opcionId] = 'no';
            } else {
                $combinadaTipoPorOpcionId[$opcionId] = 'variante';
                $combinadasMap[$preguntaCodigo]['variante_etiqueta'] = $opcionEtiqueta;
            }
        }

        $conteos = DB::connection('sqlsrv')
            ->table('RC_RESPUESTA as r')
            ->join('RC_VISITA_FORMULARIO as v', 'v.id', '=', 'r.visita_id')
            ->join('RC_PREGUNTA as p', 'p.id', '=', 'r.pregunta_id')
            ->join('RC_RESPUESTA_OPCION as ro', 'ro.respuesta_id', '=', 'r.id')
            ->join('RC_PREGUNTA_OPCION as po', 'po.id', '=', 'ro.opcion_id')
            ->where('v.formulario_id', $formulario->id)
            ->whereIn('p.codigo', $preguntasObjetivo)
            ->groupBy('p.codigo', 'po.id')
            ->selectRaw('p.codigo as pregunta_codigo, po.id as opcion_id, COUNT(*) as cantidad')
            ->get();

        foreach ($conteos as $c) {
            $preguntaCodigo = (string) ($c->pregunta_codigo ?? '');
            $opcionId = (int) ($c->opcion_id ?? 0);
            $cantidad = (int) ($c->cantidad ?? 0);

            if (isset($individualesMap[$preguntaCodigo])) {
                foreach ($individualesMap[$preguntaCodigo]['opciones'] as $i => $op) {
                    if ((int) ($op['opcion_id'] ?? 0) !== $opcionId) {
                        continue;
                    }
                    $individualesMap[$preguntaCodigo]['opciones'][$i]['cantidad'] = $cantidad;
                    $individualesMap[$preguntaCodigo]['total'] += $cantidad;
                    break;
                }
                continue;
            }

            if (! isset($combinadasMap[$preguntaCodigo])) {
                continue;
            }

            $slot = $combinadaTipoPorOpcionId[$opcionId] ?? 'variante';
            if (! in_array($slot, ['si', 'no', 'variante'], true)) {
                $slot = 'variante';
            }
            $combinadasMap[$preguntaCodigo][$slot] += $cantidad;
            $combinadasMap[$preguntaCodigo]['total'] += $cantidad;
        }

        $individuales = [];
        foreach ($preguntasIndividuales as $codigoPregunta) {
            if (! isset($individualesMap[$codigoPregunta])) {
                continue;
            }
            $bloque = $individualesMap[$codigoPregunta];
            usort($bloque['opciones'], fn($a, $b) => ((int) ($a['orden'] ?? 999)) <=> ((int) ($b['orden'] ?? 999)));
            $individuales[] = $bloque;
        }

        $combinadaSiNoVariante = [];
        foreach ($preguntasCombinadas as $codigoPregunta) {
            if (isset($combinadasMap[$codigoPregunta])) {
                $combinadaSiNoVariante[] = $combinadasMap[$codigoPregunta];
            }
        }

        return response()->json([
            'status' => Response::HTTP_OK,
            'data' => [
                'individuales' => $individuales,
                'combinada_si_no_variante' => $combinadaSiNoVariante,
            ],
            'meta' => [
                'grupo' => 'criterios_competencia',
                'formulario_codigo' => $formularioCodigo,
                'preguntas_individuales' => $preguntasIndividuales,
                'preguntas_combinadas' => $preguntasCombinadas,
                'columnas_combinadas' => ['SI', 'NO', 'VARIANTE'],
            ],
        ], Response::HTTP_OK);
    }

    public function reporteExcelFinalizadas(Request $request)
    {
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }

        if (! $this->esPerfilRecopilacionMaestro($user)) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Solo perfil maestro puede descargar este reporte',
            ], Response::HTTP_FORBIDDEN);
        }

        $formularioCodigo = $request->get('formulario_codigo', 'DATOS_PDV_VENTAS');
        $formulario = $this->getFormularioActivoRecopilacion($formularioCodigo);
        if (!$formulario) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => "No existe formulario activo con codigo {$formularioCodigo}",
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $cabeceras = $this->getCabeceraVisitasFinalizadas($formulario->id);
        $diccionario = $this->getDiccionarioPreguntasActivas($formulario->id);
        $respuestasLegibles = $this->getRespuestasLegiblesPorVisitaPregunta($formulario->id);
        $linksFotosPorVisitaPregunta = $this->getLinksFotosPorVisitaPregunta($formulario->id);
        $maxFotosPorPregunta = $this->getMaxFotosPorPregunta($linksFotosPorVisitaPregunta);

        $baseHeadings = [
            'Fecha registro',
            'Usuario registro',
            'Zonal',
            'Ejecutor',
            'Nombre PDV',
            'Documento PDV',
            'Departamento',
            'Provincia',
            'Distrito',
            'Dirección',
            'Vendedor ruta',
        ];

        $questionColumns = [];
        $questionHeadings = [];
        $usedHeadings = [];
        foreach ($diccionario as $q) {
            $clean = preg_replace('/\s+/', ' ', trim((string) ($q['columna_excel'] ?? '')));
            $heading = $clean === '' ? (string) $q['pregunta_codigo'] : $clean;
            if (isset($usedHeadings[$heading])) {
                $heading = "{$heading} ({$q['pregunta_codigo']})";
            }
            $usedHeadings[$heading] = true;
            $questionHeadings[] = $heading;

            $requiresFoto = $this->preguntaUsaFotosEnFrontend((string) ($q['pregunta_codigo'] ?? ''));
            if ($requiresFoto) {
                $cantidadColumnasFotos = max(1, (int) ($maxFotosPorPregunta[(int) ($q['pregunta_id'] ?? 0)] ?? 1));
                for ($i = 1; $i <= $cantidadColumnasFotos; $i++) {
                    $fotoHeading = "Fotos - {$heading} {$i}";
                    if (isset($usedHeadings[$fotoHeading])) {
                        $fotoHeading = "Fotos - {$heading} {$i} ({$q['pregunta_codigo']})";
                    }
                    $usedHeadings[$fotoHeading] = true;
                    $questionHeadings[] = $fotoHeading;
                }
            }

            $questionColumns[] = [
                'pregunta_id' => (int) ($q['pregunta_id'] ?? 0),
                'pregunta_codigo' => (string) ($q['pregunta_codigo'] ?? ''),
                'requiere_foto' => $requiresFoto,
                'cantidad_columnas_fotos' => $requiresFoto
                    ? max(1, (int) ($maxFotosPorPregunta[(int) ($q['pregunta_id'] ?? 0)] ?? 1))
                    : 0,
            ];
        }

        $rows = [];
        foreach ($cabeceras as $visita) {
            $valoresPaso1Precargados = $this->getValoresPrecargadosPaso1ParaExcel($visita);
            $row = [
                $visita['fecha_registro'] ?? '',
                $visita['usuario_registro'] ?? '',
                $visita['zonal'] ?? '',
                $visita['ejecutor'] ?? '',
                $visita['nombre_pdv'] ?? '',
                $visita['documento_pdv'] ?? '',
                $visita['departamento'] ?? '',
                $visita['provincia'] ?? '',
                $visita['distrito'] ?? '',
                $visita['direccion'] ?? '',
                $visita['vendedor_ruta'] ?? '',
            ];

            foreach ($questionColumns as $col) {
                $preguntaCodigo = (string) ($col['pregunta_codigo'] ?? '');
                if (array_key_exists($preguntaCodigo, $valoresPaso1Precargados)) {
                    $row[] = $valoresPaso1Precargados[$preguntaCodigo];
                } else {
                    $key = $visita['visita_id'] . '|' . ((int) ($col['pregunta_id'] ?? 0));
                    $row[] = $respuestasLegibles[$key] ?? '';
                }

                if ((bool) ($col['requiere_foto'] ?? false)) {
                    $fotoKey = $visita['visita_id'] . '|' . ((int) ($col['pregunta_id'] ?? 0));
                    $fotoUrls = $linksFotosPorVisitaPregunta[$fotoKey] ?? [];
                    $cantidadColumnasFotos = (int) ($col['cantidad_columnas_fotos'] ?? 0);
                    for ($i = 0; $i < $cantidadColumnasFotos; $i++) {
                        $url = $fotoUrls[$i] ?? '';
                        $row[] = $url !== ''
                            ? $this->buildExcelHyperlinkFormula($url, $url)
                            : '';
                    }
                }
            }

            $rows[] = $row;
        }

        $fileName = 'encuestas_finalizadas_' . now()->format('Ymd_His') . '.xlsx';
        return Excel::download(
            new RecopilacionFinalizadasExport(array_merge($baseHeadings, $questionHeadings), $rows),
            $fileName
        );
    }

    private function getFormularioActivoRecopilacion(string $formularioCodigo): ?RcFormulario
    {
        return RcFormulario::where('codigo', $formularioCodigo)
            ->where('activo', 1)
            ->orderByDesc('version')
            ->first();
    }

    private function normalizarOpcionSiNo($value): ?string
    {
        if ($value === null) {
            return null;
        }

        $txt = strtoupper(trim((string) $value));
        if ($txt === '') {
            return null;
        }

        if (in_array($txt, ['SI', 'SÍ', 'TRUE', '1'], true)) {
            return 'SI';
        }

        if (in_array($txt, ['NO', 'FALSE', '0'], true)) {
            return 'NO';
        }

        return null;
    }

    private function normalizarEscalaUnoACinco($value): ?int
    {
        if ($value === null) {
            return null;
        }

        $txt = trim((string) $value);
        if ($txt === '') {
            return null;
        }

        if (preg_match('/([1-5])/', $txt, $m) === 1) {
            return (int) $m[1];
        }

        return null;
    }

    private function getCabeceraVisitasFinalizadas(int $formularioId): array
    {
        $rows = DB::connection('sqlsrv')
            ->table('RC_VISITA_FORMULARIO as v')
            ->join('RC_CLIENTE_PDV as c', 'c.id', '=', 'v.cliente_id')
            ->leftJoin('users as u', function ($join) {
                $join->on(DB::raw('CONVERT(VARCHAR(20), v.dni_usuario)'), '=', 'u.user');
            })
            ->where('v.formulario_id', $formularioId)
            ->select(
                'v.id as visita_id',
                'v.fecha_ultima_edicion as fecha_registro',
                'v.usuario_actualizacion as usuario_registro',
                'v.dni_usuario',
                'c.zonal',
                'c.nombre_pdv',
                'c.nro_documento as documento_pdv',
                'c.departamento',
                'c.provincia',
                'c.distrito',
                'c.direccion',
                'c.vendedor as vendedor_ruta',
                'c.promedio_equipo',
                'c.total_s_venta_accesorio',
                'c.vende_accesorios',
                'u.user as usuario_catalogo'
            )
            ->orderByDesc('v.fecha_ultima_edicion')
            ->get();

        return $rows->map(function ($r) {
            $ejecutor = $r->usuario_catalogo ?: (string) ($r->dni_usuario ?? '');
            return [
                'visita_id' => (int) $r->visita_id,
                'fecha_registro' => $r->fecha_registro,
                'usuario_registro' => $r->usuario_registro ?: $ejecutor,
                'ejecutor' => $ejecutor,
                'zonal' => $r->zonal,
                'nombre_pdv' => $r->nombre_pdv,
                'documento_pdv' => $r->documento_pdv,
                'departamento' => $r->departamento,
                'provincia' => $r->provincia,
                'distrito' => $r->distrito,
                'direccion' => $r->direccion,
                'vendedor_ruta' => $r->vendedor_ruta,
                'promedio_equipo' => $r->promedio_equipo,
                'total_s_venta_accesorio' => $r->total_s_venta_accesorio,
                'vende_accesorios' => $r->vende_accesorios,
            ];
        })->values()->all();
    }

    private function getDiccionarioPreguntasActivas(int $formularioId): array
    {
        $preguntas = DB::connection('sqlsrv')
            ->table('RC_PREGUNTA as p')
            ->join('RC_SECCION as s', 's.id', '=', 'p.seccion_id')
            ->where('s.formulario_id', $formularioId)
            ->where('s.activo', 1)
            ->where('p.activo', 1)
            ->orderBy('s.orden')
            ->orderBy('p.orden')
            ->select(
                'p.id as pregunta_id',
                'p.codigo as pregunta_codigo',
                'p.texto as pregunta_texto',
                'p.requiere_foto'
            )
            ->get();

        return $preguntas->map(function ($row) {
            return [
                'pregunta_id' => (int) $row->pregunta_id,
                'pregunta_codigo' => $row->pregunta_codigo,
                'columna_excel' => preg_replace('/\s+/', ' ', trim((string) ($row->pregunta_texto ?? ''))),
                'requiere_foto' => (bool) ($row->requiere_foto ?? false),
            ];
        })
            // Las preguntas E## son evidencia oculta en formulario; generan columnas vacías en Excel.
            // Se excluyen para mostrar solo preguntas de negocio que el usuario realmente completa.
            ->filter(fn($q) => !$this->esPreguntaEvidenciaOcultaEnFormulario((string) ($q['pregunta_codigo'] ?? '')))
            ->values()
            ->all();
    }

    private function getRespuestasLegiblesPorVisitaPregunta(int $formularioId): array
    {
        $rows = DB::connection('sqlsrv')
            ->table('RC_RESPUESTA as r')
            ->join('RC_VISITA_FORMULARIO as v', 'v.id', '=', 'r.visita_id')
            ->join('RC_PREGUNTA as p', 'p.id', '=', 'r.pregunta_id')
            ->where('v.formulario_id', $formularioId)
            ->where('p.activo', 1)
            ->select(
                'v.id as visita_id',
                'r.id as respuesta_id',
                'r.pregunta_id',
                'p.tipo_respuesta',
                'r.valor_texto',
                'r.valor_numero',
                'r.valor_decimal',
                'r.valor_booleano',
                'r.valor_fecha',
                'r.valor_hora',
                'r.no_aplica'
            )
            ->get();

        $respuestasFiltradas = DB::connection('sqlsrv')
            ->table('RC_RESPUESTA as r')
            ->join('RC_VISITA_FORMULARIO as v', 'v.id', '=', 'r.visita_id')
            ->join('RC_PREGUNTA as p', 'p.id', '=', 'r.pregunta_id')
            ->where('v.formulario_id', $formularioId)
            ->where('p.activo', 1)
            ->select('r.id as respuesta_id');

        $opcionesRows = DB::connection('sqlsrv')
            ->table('RC_RESPUESTA_OPCION as ro')
            ->joinSub($respuestasFiltradas, 'rf', function ($join) {
                $join->on('rf.respuesta_id', '=', 'ro.respuesta_id');
            })
            ->join('RC_PREGUNTA_OPCION as po', 'po.id', '=', 'ro.opcion_id')
            ->select(
                'ro.respuesta_id',
                'po.etiqueta as opcion_etiqueta',
                'po.orden as opcion_orden'
            )
            ->orderBy('po.orden')
            ->get();

        $opcionesPorRespuesta = $opcionesRows->groupBy('respuesta_id');

        $result = [];
        foreach ($rows as $row) {
            $opciones = collect($opcionesPorRespuesta->get($row->respuesta_id, []))
                ->pluck('opcion_etiqueta')
                ->filter()
                ->values();

            $tipo = (string) ($row->tipo_respuesta ?? '');
            $legible = '';

            if ((bool) $row->no_aplica) {
                $legible = 'No aplica';
            } elseif (in_array($tipo, ['opcion_unica', 'opcion_multiple'], true) && $opciones->isNotEmpty()) {
                $legible = $opciones->implode(' | ');
            } elseif ($tipo === 'si_no' && $row->valor_booleano !== null) {
                $legible = ((int) $row->valor_booleano) === 1 ? 'Sí' : 'No';
            } elseif ($tipo === 'decimal' && $row->valor_decimal !== null) {
                $legible = (string) $row->valor_decimal;
            } elseif ($tipo === 'numero' && $row->valor_numero !== null) {
                $legible = (string) $row->valor_numero;
            } elseif ($tipo === 'fecha' && $row->valor_fecha !== null) {
                $legible = (string) $row->valor_fecha;
            } elseif ($tipo === 'hora' && $row->valor_hora !== null) {
                $legible = (string) $row->valor_hora;
            } elseif ($row->valor_texto !== null && trim((string) $row->valor_texto) !== '') {
                $legible = $this->normalizarTextoConSeparadoresParaExcel(trim((string) $row->valor_texto));
            } elseif ($row->valor_booleano !== null) {
                $legible = ((int) $row->valor_booleano) === 1 ? 'Sí' : 'No';
            } elseif ($row->valor_decimal !== null) {
                $legible = (string) $row->valor_decimal;
            } elseif ($row->valor_numero !== null) {
                $legible = (string) $row->valor_numero;
            } elseif ($row->valor_fecha !== null) {
                $legible = (string) $row->valor_fecha;
            } elseif ($row->valor_hora !== null) {
                $legible = (string) $row->valor_hora;
            }

            $key = ((int) $row->visita_id) . '|' . ((int) $row->pregunta_id);
            $result[$key] = $legible;
        }

        return $result;
    }

    private function getLinksFotosPorVisitaPregunta(int $formularioId): array
    {
        $baseUrl = $this->getDominioPublicoRecopilacion();
        $codigosConFotoFrontend = ['P15', 'P19', 'P21'];
        $rows = DB::connection('sqlsrv')
            ->table('RC_RESPUESTA_MEDIA as rm')
            ->join('RC_RESPUESTA as r', 'r.id', '=', 'rm.respuesta_id')
            ->join('RC_VISITA_FORMULARIO as v', 'v.id', '=', 'r.visita_id')
            ->join('RC_PREGUNTA as p', 'p.id', '=', 'r.pregunta_id')
            ->where('v.formulario_id', $formularioId)
            ->where('p.activo', 1)
            ->where('p.requiere_foto', 1)
            ->whereIn('p.codigo', $codigosConFotoFrontend)
            ->whereRaw("LOWER(LTRIM(RTRIM(rm.tipo_media))) = 'foto'")
            ->orderBy('v.id')
            ->orderBy('r.pregunta_id')
            ->orderBy('rm.orden')
            ->orderBy('rm.id')
            ->select(
                'v.id as visita_id',
                'r.pregunta_id',
                'rm.id as media_id'
            )
            ->get();

        $map = [];
        foreach ($rows as $row) {
            $key = ((int) $row->visita_id) . '|' . ((int) $row->pregunta_id);
            $url = "{$baseUrl}/api/v1/recopilacion/media/" . ((int) $row->media_id) . '/foto';
            $map[$key] ??= [];
            $map[$key][] = $url;
        }

        return $map;
    }

    private function getDominioPublicoRecopilacion(): string
    {
        $domain = trim((string) env('APP_DOMAIN', ''));
        if ($domain !== '') {
            return rtrim($domain, '/');
        }

        return rtrim((string) config('app.url'), '/');
    }

    private function preguntaUsaFotosEnFrontend(string $preguntaCodigo): bool
    {
        return in_array(strtoupper(trim($preguntaCodigo)), ['P15', 'P19', 'P21'], true);
    }

    private function getMaxFotosPorPregunta(array $linksFotosPorVisitaPregunta): array
    {
        $max = [];
        foreach ($linksFotosPorVisitaPregunta as $key => $urls) {
            if (!is_array($urls)) {
                continue;
            }
            $parts = explode('|', (string) $key);
            if (count($parts) !== 2) {
                continue;
            }
            $preguntaId = (int) ($parts[1] ?? 0);
            if ($preguntaId <= 0) {
                continue;
            }
            $count = count($urls);
            $max[$preguntaId] = max((int) ($max[$preguntaId] ?? 0), $count);
        }

        return $max;
    }

    private function buildExcelHyperlinkFormula(string $url, string $label): string
    {
        $safeUrl = str_replace('"', '""', trim($url));
        $safeLabel = str_replace('"', '""', trim($label));
        return '=HYPERLINK("' . $safeUrl . '","' . $safeLabel . '")';
    }

    private function getValoresPrecargadosPaso1ParaExcel(array $visita): array
    {
        $promedioEquipo = $visita['promedio_equipo'] ?? null;
        $totalVentaAccesorio = $visita['total_s_venta_accesorio'] ?? null;
        $vendeAccesorios = $this->normalizarBooleanoDesdeCatalogo($visita['vende_accesorios'] ?? null);

        $p01 = $this->formatearMontoSoles($promedioEquipo, true);
        $p02 = $this->formatearMontoSoles(
            is_numeric((string) $promedioEquipo) ? ((float) $promedioEquipo) * 0.1 : null,
            true
        );

        if ($vendeAccesorios === true) {
            $monto = $this->formatearMontoSoles($totalVentaAccesorio, false);
            $p03 = $monto !== '' ? "Sí | {$monto}" : 'Sí';
        } elseif ($vendeAccesorios === false) {
            $p03 = 'No';
        } else {
            $p03 = '';
        }

        $zonal = trim((string) ($visita['zonal'] ?? ''));
        $vendedor = trim((string) ($visita['vendedor_ruta'] ?? ''));
        $p04 = "Zonal: " . ($zonal !== '' ? $zonal : '—') . "\nVendedor JS: " . ($vendedor !== '' ? $vendedor : '—');

        return [
            'P01' => $p01,
            'P02' => $p02,
            'P03' => $p03,
            'P04' => $p04,
            'P05' => 'Catálogo y fotos',
        ];
    }

    private function normalizarBooleanoDesdeCatalogo($value): ?bool
    {
        if ($value === null) {
            return null;
        }

        if (is_bool($value)) {
            return $value;
        }

        if (is_numeric((string) $value)) {
            return ((int) $value) === 1;
        }

        $txt = strtoupper(trim((string) $value));
        if ($txt === '') {
            return null;
        }

        if (in_array($txt, ['SI', 'SÍ', 'TRUE'], true)) {
            return true;
        }

        if (in_array($txt, ['NO', 'FALSE'], true)) {
            return false;
        }

        return null;
    }

    private function formatearMontoSoles($value, bool $conSufijoMes): string
    {
        if ($value === null || !is_numeric((string) $value)) {
            return '';
        }

        $formatted = number_format((float) $value, 2, '.', ',');
        $formatted = rtrim(rtrim($formatted, '0'), '.');

        return $conSufijoMes ? "S/ {$formatted} /mes" : "S/ {$formatted}";
    }

    private function normalizarTextoConSeparadoresParaExcel(string $texto): string
    {
        if (strpos($texto, '|') === false) {
            return $texto;
        }

        $partes = array_map(
            fn($p) => trim((string) $p),
            explode('|', $texto)
        );
        $partes = array_values(array_filter($partes, fn($p) => $p !== ''));

        if (empty($partes)) {
            return '';
        }

        return implode(' | ', $partes);
    }

    /**
     * GET formulario/{codigo}
     * Estructura del formulario: secciones con preguntas y opciones (para pintar pasos en el front).
     */
    public function getFormulario(string $codigo)
    {
        $formulario = RcFormulario::where('codigo', $codigo)
            ->where('activo', 1)
            ->orderByDesc('version')
            ->with(['secciones' => function ($q) {
                $q->where('activo', 1);
            }])
            ->first();

        if (!$formulario) {
            return response()->json([
                'status' => Response::HTTP_NOT_FOUND,
                'message' => "No existe formulario activo con codigo {$codigo}",
            ], Response::HTTP_NOT_FOUND);
        }

        $secciones = $formulario->secciones->map(function (RcSeccion $s) {
            $preguntas = RcPregunta::where('seccion_id', $s->id)
                ->where('activo', 1)
                ->orderBy('orden')
                ->with('opciones')
                ->get();
            return [
                'id' => $s->id,
                'codigo' => $s->codigo,
                'titulo' => $s->titulo,
                'descripcion' => $s->descripcion,
                'orden' => $s->orden,
                'preguntas' => $preguntas->map(fn($p) => [
                    'id' => $p->id,
                    'codigo' => $p->codigo,
                    'texto' => $p->texto,
                    'texto_ayuda' => $p->texto_ayuda,
                    'tipo_respuesta' => $p->tipo_respuesta,
                    'obligatoria' => (bool) $p->obligatoria,
                    'requiere_foto' => (bool) $p->requiere_foto,
                    'min_fotos' => (int) $p->min_fotos,
                    'max_fotos' => (int) $p->max_fotos,
                    'orden' => $p->orden,
                    'max_longitud' => $p->max_longitud,
                    'valor_minimo' => $p->valor_minimo !== null ? (float) $p->valor_minimo : null,
                    'valor_maximo' => $p->valor_maximo !== null ? (float) $p->valor_maximo : null,
                    'opciones' => $p->opciones->where('activo', 1)->map(fn($o) => [
                        'id' => $o->id,
                        'codigo' => $o->codigo,
                        'etiqueta' => $o->etiqueta,
                        'valor' => $o->valor,
                        'orden' => $o->orden,
                    ])->values(),
                ])->values(),
            ];
        });

        return response()->json([
            'status' => Response::HTTP_OK,
            'data' => [
                'id' => $formulario->id,
                'codigo' => $formulario->codigo,
                'nombre' => $formulario->nombre,
                'version' => $formulario->version,
                'secciones' => $secciones,
            ],
        ], Response::HTTP_OK);
    }

    /**
     * POST visita — Obtener o crear visita para cliente + formulario + periodo.
     * Body: cliente_id, formulario_codigo (opcional), anio, mes.
     */
    public function postVisita(Request $request)
    {
        $zonal = $this->getZonalUsuario();
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }

        if ($this->tokenRequiereZonalUsuario($user) && !$zonal) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener la zonal del usuario',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $validated = $request->validate([
            'cliente_id' => 'required|integer|min:1',
            'formulario_codigo' => 'nullable|string|max:50',
            'anio' => 'nullable|integer|min:2020|max:2100',
            'mes' => 'nullable|integer|min:1|max:12',
        ]);
        $clienteId = (int) $validated['cliente_id'];
        $formularioCodigo = $validated['formulario_codigo'] ?? 'DATOS_PDV_VENTAS';
        $anio = (int) ($validated['anio'] ?? now()->year);
        $mes = (int) ($validated['mes'] ?? now()->month);

        $cliente = RcClientePdv::find($clienteId);
        if (!$cliente) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Cliente no encontrado',
            ], Response::HTTP_FORBIDDEN);
        }

        if (
            ! $this->esPerfilRecopilacionEjecutor($user)
            && ! $this->esPerfilRecopilacionZonal($user)
            && ! $this->esPerfilRecopilacionMaestro($user)
        ) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Perfil no autorizado para recopilacion',
            ], Response::HTTP_FORBIDDEN);
        }

        if ($this->esPerfilRecopilacionEjecutor($user)) {
            $dniToken = $this->getDniUsuarioDesdeToken($user);
            if (!$dniToken) {
                return response()->json([
                    'status' => Response::HTTP_UNAUTHORIZED,
                    'message' => 'No se pudo obtener el DNI del usuario',
                ], Response::HTTP_UNAUTHORIZED);
            }

            $asignado = DB::connection('sqlsrv')
                ->table('RC_PDV_ASIGNACION_VISITA')
                ->where('pdv_id', $clienteId)
                ->where('dni_ejecutor', $dniToken)
                ->exists();

            if (!$asignado) {
                return response()->json([
                    'status' => Response::HTTP_FORBIDDEN,
                    'message' => 'El punto no está asignado al usuario',
                ], Response::HTTP_FORBIDDEN);
            }
        } elseif ($this->esPerfilRecopilacionZonal($user) && $cliente->zonal !== $zonal) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Cliente no pertenece a su zonal',
            ], Response::HTTP_FORBIDDEN);
        }
        // maestro: puede abrir visita de cualquier cliente

        $formulario = RcFormulario::where('codigo', $formularioCodigo)->where('activo', 1)->orderByDesc('version')->first();
        if (!$formulario) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => "No existe formulario activo con codigo {$formularioCodigo}",
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $visita = RcVisitaFormulario::where('cliente_id', $clienteId)
            ->where('formulario_id', $formulario->id)
            ->where('anio', $anio)
            ->where('mes', $mes)
            ->first();

        if (!$visita) {
            $dniUsuario = $this->getDniUsuario($user);
            $zonalUsuario = $zonal ?? ($cliente->zonal ?? '');
            $visita = RcVisitaFormulario::create([
                'cliente_id' => $clienteId,
                'programacion_id' => null,
                'formulario_id' => $formulario->id,
                'anio' => $anio,
                'mes' => $mes,
                'dni_usuario' => $dniUsuario,
                'zonal_usuario' => $zonalUsuario,
                'estado' => 'borrador',
                'porcentaje_avance' => 0,
                'cod_cliente' => $cliente->nro_documento,
                'nombre_punto' => $cliente->nombre_pdv,
                'direccion' => null,
            ]);
        }

        return response()->json([
            'status' => Response::HTTP_OK,
            'data' => [
                'id' => $visita->id,
                'cliente_id' => $visita->cliente_id,
                'formulario_id' => $visita->formulario_id,
                'anio' => $visita->anio,
                'mes' => $visita->mes,
                'estado' => $visita->estado,
                'porcentaje_avance' => (float) $visita->porcentaje_avance,
                'nombre_punto' => $visita->nombre_punto,
                'cod_cliente' => $visita->cod_cliente,
            ],
        ], Response::HTTP_OK);
    }

    /**
     * POST visita/{visitaId}/finalizar
     * Marca la instancia de encuesta como finalizada (después de guardar la última sección con éxito).
     */
    public function finalizarVisita(int $visitaId)
    {
        $zonal = $this->getZonalUsuario();
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }
        if ($this->tokenRequiereZonalUsuario($user) && !$zonal) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener la zonal del usuario',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $visita = RcVisitaFormulario::find($visitaId);
        if (!$visita || !$this->puedeGestionarVisitaRecopilacion($user, $visita, $zonal)) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Visita no encontrada o no pertenece a su zonal',
            ], Response::HTTP_FORBIDDEN);
        }

        $usuario = $user->user ?? (string) $this->getDniUsuario($user);

        if ($visita->estado === 'finalizado') {
            return response()->json([
                'status' => Response::HTTP_OK,
                'message' => 'La encuesta ya estaba finalizada',
                'data' => [
                    'visita_id' => (int) $visita->id,
                    'estado' => $visita->estado,
                    'porcentaje_avance' => (float) $visita->porcentaje_avance,
                ],
            ], Response::HTTP_OK);
        }

        $visita->estado = 'finalizado';
        $visita->porcentaje_avance = 100;
        $visita->fecha_finalizacion = now();
        $visita->fecha_ultima_edicion = now();
        $visita->usuario_actualizacion = $usuario;
        $visita->save();

        return response()->json([
            'status' => Response::HTTP_OK,
            'message' => 'Encuesta finalizada correctamente',
            'data' => [
                'visita_id' => (int) $visita->id,
                'estado' => $visita->estado,
                'porcentaje_avance' => (float) $visita->porcentaje_avance,
            ],
        ], Response::HTTP_OK);
    }

    /**
     * POST visita/{visitaId}/seccion/{seccionId}/asegurar-respuestas
     * Crea filas en RC_RESPUESTA para cada pregunta de la sección que aún no exista.
     */
    public function asegurarRespuestas(int $visitaId, int $seccionId)
    {
        $user = $this->getUsuarioRecopilacion();
        $zonal = $this->getZonalUsuario();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }
        if ($this->tokenRequiereZonalUsuario($user) && !$zonal) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener la zonal del usuario',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $visita = RcVisitaFormulario::find($visitaId);
        if (!$visita || !$this->puedeGestionarVisitaRecopilacion($user, $visita, $zonal)) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Visita no encontrada o no pertenece a su zonal',
            ], Response::HTTP_FORBIDDEN);
        }

        $seccion = RcSeccion::where('id', $seccionId)->where('formulario_id', $visita->formulario_id)->first();
        if (!$seccion) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => 'Sección no encontrada o no pertenece al formulario de esta visita',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $preguntas = RcPregunta::where('seccion_id', $seccionId)
            ->where('activo', 1)
            ->orderBy('orden')
            ->pluck('id');

        $insertadas = 0;
        foreach ($preguntas as $preguntaId) {
            try {
                $created = RcRespuesta::firstOrCreate(
                    [
                        'visita_id' => $visitaId,
                        'pregunta_id' => $preguntaId,
                    ],
                    [
                        'valor_texto' => null,
                        'valor_numero' => null,
                        'valor_decimal' => null,
                        'valor_booleano' => null,
                        'valor_fecha' => null,
                        'valor_hora' => null,
                        'observacion' => null,
                        'no_aplica' => false,
                    ]
                );
                if ($created->wasRecentlyCreated) {
                    $insertadas++;
                }
            } catch (QueryException $e) {
                // Si otra transacción insertó la misma combinación (visita_id, pregunta_id)
                // entre el SELECT y el INSERT de firstOrCreate, ignoramos el error
                // para mantener la idempotencia del endpoint.
                if (str_contains($e->getMessage(), 'UQ_RC_RESPUESTA_VISITA_PREGUNTA')) {
                    continue;
                }
                throw $e;
            }
        }

        return response()->json([
            'status' => Response::HTTP_OK,
            'message' => 'Respuestas aseguradas para la sección',
            'data' => ['insertadas' => $insertadas],
        ], Response::HTTP_OK);
    }

    /**
     * GET visita/{visitaId}/respuestas?seccion_id= (opcional)
     * Devuelve las respuestas de la visita (o de una sección) para prellenar el formulario.
     */
    public function getRespuestas(Request $request, int $visitaId)
    {
        $user = $this->getUsuarioRecopilacion();
        $zonal = $this->getZonalUsuario();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }
        if ($this->tokenRequiereZonalUsuario($user) && !$zonal) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener la zonal del usuario',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $visita = RcVisitaFormulario::find($visitaId);
        if (!$visita || !$this->puedeGestionarVisitaRecopilacion($user, $visita, $zonal)) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Visita no encontrada o no pertenece a su zonal',
            ], Response::HTTP_FORBIDDEN);
        }

        $query = RcRespuesta::where('visita_id', $visitaId)->with(['pregunta', 'opcionesSeleccionadas.opcion', 'media']);
        $seccionId = $request->integer('seccion_id');
        if ($seccionId > 0) {
            $query->whereHas('pregunta', fn($q) => $q->where('seccion_id', $seccionId));
        }
        $respuestas = $query->get();

        $data = $respuestas->map(function (RcRespuesta $r) {
            $opciones = $r->opcionesSeleccionadas->map(fn($ro) => [
                'id' => $ro->opcion_id,
                'codigo' => $ro->opcion?->codigo,
                'etiqueta' => $ro->opcion?->etiqueta,
            ])->values();
            $media = $r->media->map(fn($m) => [
                'id' => $m->id,
                'tipo_media' => $m->tipo_media,
                'nombre_archivo' => $m->nombre_archivo,
                'ruta_archivo' => $m->ruta_archivo,
                'orden' => $m->orden,
            ])->values();
            return [
                'respuesta_id' => $r->id,
                'pregunta_id' => $r->pregunta_id,
                'pregunta_codigo' => $r->pregunta?->codigo,
                'valor_texto' => $r->valor_texto,
                'valor_numero' => $r->valor_numero,
                'valor_decimal' => $r->valor_decimal,
                'valor_booleano' => $r->valor_booleano,
                'valor_fecha' => $r->valor_fecha?->format('Y-m-d'),
                'valor_hora' => $r->valor_hora,
                'observacion' => $r->observacion,
                'no_aplica' => (bool) $r->no_aplica,
                'opciones' => $opciones,
                'media' => $media,
            ];
        });

        return response()->json([
            'status' => Response::HTTP_OK,
            'data' => $data,
        ], Response::HTTP_OK);
    }

    /**
     * PUT visita/{visitaId}/respuestas
     * Body: seccion_id, respuestas: [{ pregunta_id, valor_texto?, valor_numero?, valor_decimal?, valor_booleano?, observacion?, no_aplica?, opcion_ids? }]
     * Actualiza RC_RESPUESTA y RC_RESPUESTA_OPCION para la sección. No crea respuestas (deben existir por asegurar-respuestas).
     */
    public function putRespuestas(Request $request, int $visitaId)
    {
        $zonal = $this->getZonalUsuario();
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }
        if ($this->tokenRequiereZonalUsuario($user) && !$zonal) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener la zonal del usuario',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $visita = RcVisitaFormulario::find($visitaId);
        if (!$visita || !$this->puedeGestionarVisitaRecopilacion($user, $visita, $zonal)) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Visita no encontrada o no pertenece a su zonal',
            ], Response::HTTP_FORBIDDEN);
        }

        $validated = $request->validate([
            'seccion_id' => 'required|integer|min:1',
            'respuestas' => 'required|array',
            'respuestas.*.pregunta_id' => 'required|integer|min:1',
            'respuestas.*.valor_texto' => 'nullable|string',
            'respuestas.*.valor_numero' => 'nullable|integer',
            'respuestas.*.valor_decimal' => 'nullable|numeric',
            'respuestas.*.valor_booleano' => 'nullable|boolean',
            'respuestas.*.valor_fecha' => 'nullable|date',
            'respuestas.*.valor_hora' => 'nullable|string',
            'respuestas.*.observacion' => 'nullable|string|max:1000',
            'respuestas.*.no_aplica' => 'nullable|boolean',
            'respuestas.*.opcion_ids' => 'nullable|array',
            'respuestas.*.opcion_ids.*' => 'integer|min:1',
        ]);

        $seccionId = (int) $validated['seccion_id'];
        $seccion = RcSeccion::where('id', $seccionId)->where('formulario_id', $visita->formulario_id)->first();
        if (!$seccion) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => 'Sección no encontrada o no pertenece al formulario de esta visita',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $preguntasSeccion = RcPregunta::where('seccion_id', $seccionId)
            ->where('activo', 1)
            ->orderBy('orden')
            ->get()
            ->keyBy('id');

        $preguntaIdsSeccion = $preguntasSeccion->keys()->map(fn($id) => (int) $id)->values()->all();
        $respuestasActuales = RcRespuesta::where('visita_id', $visitaId)
            ->whereIn('pregunta_id', $preguntaIdsSeccion)
            ->get()
            ->keyBy('pregunta_id');

        $payloadPorPregunta = [];
        foreach ($validated['respuestas'] as $item) {
            $payloadPorPregunta[(int) $item['pregunta_id']] = $item;
        }

        $respuestaIdsActuales = $respuestasActuales
            ->pluck('id')
            ->filter()
            ->map(fn($id) => (int) $id)
            ->values()
            ->all();

        $opcionesPorRespuesta = [];
        $fotosPorRespuesta = [];
        if (!empty($respuestaIdsActuales)) {
            $opcionesPorRespuesta = RcRespuestaOpcion::whereIn('respuesta_id', $respuestaIdsActuales)
                ->selectRaw('respuesta_id, COUNT(1) as total')
                ->groupBy('respuesta_id')
                ->pluck('total', 'respuesta_id')
                ->map(fn($v) => (int) $v)
                ->all();

            $fotosPorRespuesta = RcRespuestaMedia::whereIn('respuesta_id', $respuestaIdsActuales)
                ->whereRaw("LOWER(LTRIM(RTRIM(tipo_media))) = 'foto'")
                ->selectRaw('respuesta_id, COUNT(1) as total')
                ->groupBy('respuesta_id')
                ->pluck('total', 'respuesta_id')
                ->map(fn($v) => (int) $v)
                ->all();
        }

        $faltantes = [];
        foreach ($preguntasSeccion as $pregunta) {
            if ($this->esPreguntaEvidenciaOcultaEnFormulario((string) $pregunta->codigo)) {
                continue;
            }

            if ($this->esPreguntaAutocompletadaFormulario((string) $pregunta->codigo)) {
                continue;
            }

            if (!(bool) $pregunta->obligatoria) {
                continue;
            }

            $preguntaId = (int) $pregunta->id;
            $respuestaActual = $respuestasActuales->get($preguntaId);
            $payload = $payloadPorPregunta[$preguntaId] ?? null;

            $validacion = $this->validarCompletitudPreguntaObligatoria(
                $pregunta,
                $respuestaActual,
                $payload,
                $opcionesPorRespuesta,
                $fotosPorRespuesta
            );

            if (!$validacion['completa']) {
                $faltantes[] = [
                    'pregunta_id' => $preguntaId,
                    'pregunta_codigo' => $pregunta->codigo,
                    'pregunta_texto' => $pregunta->texto,
                    'tipo_respuesta' => $pregunta->tipo_respuesta,
                    'motivo' => $validacion['motivo'],
                ];
            }
        }

        if (!empty($faltantes)) {
            return response()->json([
                'status' => Response::HTTP_OK,
                'message' => 'Faltan preguntas obligatorias por completar en la sección',
                'data' => [
                    'guardado' => false,
                    'bloquea_avance' => true,
                    'seccion_id' => $seccionId,
                    'faltantes' => $faltantes,
                ],
            ], Response::HTTP_OK);
        }

        $usuarioGuardado = $user->user ?? (string) $this->getDniUsuario($user);

        DB::connection('sqlsrv')->beginTransaction();
        try {
            foreach ($validated['respuestas'] as $item) {
                $preguntaId = (int) $item['pregunta_id'];
                $respuesta = RcRespuesta::where('visita_id', $visitaId)->where('pregunta_id', $preguntaId)->first();
                if (!$respuesta) {
                    continue;
                }
                $pregunta = RcPregunta::find($preguntaId);
                if (!$pregunta || $pregunta->seccion_id != $seccionId) {
                    continue;
                }

                $respuesta->valor_texto = array_key_exists('valor_texto', $item) ? $item['valor_texto'] : $respuesta->valor_texto;
                $respuesta->valor_numero = isset($item['valor_numero']) ? (int) $item['valor_numero'] : $respuesta->valor_numero;
                $respuesta->valor_decimal = array_key_exists('valor_decimal', $item) ? $item['valor_decimal'] : $respuesta->valor_decimal;
                $respuesta->valor_booleano = array_key_exists('valor_booleano', $item) ? (bool) $item['valor_booleano'] : $respuesta->valor_booleano;
                $respuesta->valor_fecha = isset($item['valor_fecha']) ? $item['valor_fecha'] : $respuesta->valor_fecha;
                $respuesta->valor_hora = array_key_exists('valor_hora', $item) ? $item['valor_hora'] : $respuesta->valor_hora;
                if (array_key_exists('observacion', $item)) {
                    $obs = $item['observacion'];
                    if (is_string($obs)) {
                        $obs = trim($obs);
                    }
                    $respuesta->observacion = ($obs === '' || $obs === null) ? null : $obs;
                }
                $respuesta->no_aplica = array_key_exists('no_aplica', $item) ? (bool) $item['no_aplica'] : $respuesta->no_aplica;
                $respuesta->usuario_guardado = $usuarioGuardado;
                $respuesta->save();

                if (array_key_exists('opcion_ids', $item) && is_array($item['opcion_ids'])) {
                    $opcionIds = array_values(array_unique(array_map('intval', $item['opcion_ids'])));
                    $opcionIds = array_values(array_filter($opcionIds, fn($id) => $id > 0));

                    // En opcion_unica (ej. P08) forzamos una sola opción.
                    if ($pregunta->tipo_respuesta === 'opcion_unica' && count($opcionIds) > 1) {
                        $opcionIds = [reset($opcionIds)];
                    }

                    RcRespuestaOpcion::where('respuesta_id', $respuesta->id)->delete();
                    foreach ($opcionIds as $opcionId) {
                        RcRespuestaOpcion::create([
                            'respuesta_id' => $respuesta->id,
                            'opcion_id' => (int) $opcionId,
                            'usuario_guardado' => $usuarioGuardado,
                        ]);
                    }
                }
            }

            $visita->usuario_actualizacion = $usuarioGuardado;
            $visita->save();

            DB::connection('sqlsrv')->commit();
        } catch (\Throwable $e) {
            DB::connection('sqlsrv')->rollBack();
            return response()->json([
                'status' => Response::HTTP_INTERNAL_SERVER_ERROR,
                'message' => 'Error al guardar las respuestas: ' . $e->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }

        return response()->json([
            'status' => Response::HTTP_OK,
            'message' => 'Respuestas guardadas correctamente',
            'data' => [
                'guardado' => true,
                'bloquea_avance' => false,
                'seccion_id' => $seccionId,
            ],
        ], Response::HTTP_OK);
    }

    private function validarCompletitudPreguntaObligatoria(
        RcPregunta $pregunta,
        ?RcRespuesta $respuestaActual,
        ?array $payload,
        array $opcionesPorRespuesta,
        array $fotosPorRespuesta
    ): array {
        if (!$respuestaActual && !$payload) {
            return ['completa' => false, 'motivo' => 'sin_respuesta'];
        }

        $noAplica = $this->tomarValorProyectado($respuestaActual?->no_aplica, $payload, 'no_aplica');
        if ($noAplica === true) {
            if ((bool) $pregunta->permite_no_aplica) {
                return ['completa' => true, 'motivo' => null];
            }

            return ['completa' => false, 'motivo' => 'no_aplica_no_permitido'];
        }

        $tipo = (string) ($pregunta->tipo_respuesta ?? '');

        if (in_array($tipo, ['opcion_unica', 'opcion_multiple'], true)) {
            $totalOpciones = $this->totalOpcionesProyectadas($pregunta, $respuestaActual, $payload, $opcionesPorRespuesta);
            if ($totalOpciones <= 0) {
                return ['completa' => false, 'motivo' => 'sin_opciones'];
            }
            // Solo P19 (vitrina / display): con «Sí» hace falta al menos una foto; «No tiene» no.
            if (
                strtoupper(trim((string) $pregunta->codigo)) === 'P19'
                && (bool) $pregunta->requiere_foto
                && $this->p19VitrinaOpcionSiRequiereFoto($pregunta, $respuestaActual, $payload)
            ) {
                $respuestaId = (int) ($respuestaActual?->id ?? 0);
                $fotosActuales = $respuestaId > 0 ? (int) ($fotosPorRespuesta[$respuestaId] ?? 0) : 0;
                $minFotos = max((int) ($pregunta->min_fotos ?? 0), 1);
                if ($fotosActuales < $minFotos) {
                    return ['completa' => false, 'motivo' => 'falta_evidencia_fotografica'];
                }
            }

            return ['completa' => true, 'motivo' => null];
        }

        if ((bool) $pregunta->requiere_foto) {
            $respuestaId = (int) ($respuestaActual?->id ?? 0);
            $fotosActuales = $respuestaId > 0 ? (int) ($fotosPorRespuesta[$respuestaId] ?? 0) : 0;
            $minFotos = max((int) ($pregunta->min_fotos ?? 0), 1);
            if ($fotosActuales < $minFotos) {
                return ['completa' => false, 'motivo' => 'falta_evidencia_fotografica'];
            }
        }

        $valorTexto = $this->tomarValorProyectado($respuestaActual?->valor_texto, $payload, 'valor_texto');
        $valorNumero = $this->tomarValorProyectado($respuestaActual?->valor_numero, $payload, 'valor_numero');
        $valorDecimal = $this->tomarValorProyectado($respuestaActual?->valor_decimal, $payload, 'valor_decimal');
        $valorBooleano = $this->tomarValorProyectado($respuestaActual?->valor_booleano, $payload, 'valor_booleano');
        $valorFecha = $this->tomarValorProyectado($respuestaActual?->valor_fecha, $payload, 'valor_fecha');
        $valorHora = $this->tomarValorProyectado($respuestaActual?->valor_hora, $payload, 'valor_hora');

        return match ($tipo) {
            'texto_corto', 'texto_largo' => (is_string($valorTexto) && trim($valorTexto) !== '')
                ? ['completa' => true, 'motivo' => null]
                : ['completa' => false, 'motivo' => 'texto_vacio'],
            'numero' => $valorNumero !== null
                ? ['completa' => true, 'motivo' => null]
                : ['completa' => false, 'motivo' => 'numero_vacio'],
            'decimal' => $valorDecimal !== null
                ? ['completa' => true, 'motivo' => null]
                : ['completa' => false, 'motivo' => 'decimal_vacio'],
            'si_no' => $valorBooleano !== null
                ? ['completa' => true, 'motivo' => null]
                : ['completa' => false, 'motivo' => 'si_no_vacio'],
            'fecha' => $valorFecha !== null && (string) $valorFecha !== ''
                ? ['completa' => true, 'motivo' => null]
                : ['completa' => false, 'motivo' => 'fecha_vacia'],
            'hora' => $valorHora !== null && trim((string) $valorHora) !== ''
                ? ['completa' => true, 'motivo' => null]
                : ['completa' => false, 'motivo' => 'hora_vacia'],
            default => $this->validarCompletitudFallback(
                $valorTexto,
                $valorNumero,
                $valorDecimal,
                $valorBooleano,
                $valorFecha,
                $valorHora
            ),
        };
    }

    /**
     * P19 — «¿Tiene vitrina o display activo de accesorios?»: true si eligió «Sí» (ordenado o desordenado).
     */
    private function p19VitrinaOpcionSiRequiereFoto(
        RcPregunta $pregunta,
        ?RcRespuesta $respuestaActual,
        ?array $payload
    ): bool {
        $opcionIds = [];
        if (is_array($payload) && array_key_exists('opcion_ids', $payload) && is_array($payload['opcion_ids'])) {
            $opcionIds = array_values(array_unique(array_map('intval', $payload['opcion_ids'])));
            $opcionIds = array_values(array_filter($opcionIds, fn ($id) => $id > 0));
            if ($pregunta->tipo_respuesta === 'opcion_unica' && count($opcionIds) > 1) {
                $opcionIds = [reset($opcionIds)];
            }
        } elseif ($respuestaActual) {
            $rid = (int) $respuestaActual->id;
            if ($rid > 0) {
                $opcionIds = RcRespuestaOpcion::where('respuesta_id', $rid)
                    ->pluck('opcion_id')
                    ->map(fn ($id) => (int) $id)
                    ->unique()
                    ->values()
                    ->all();
            }
        }

        if ($opcionIds === []) {
            return false;
        }

        $codigos = RcPreguntaOpcion::where('pregunta_id', (int) $pregunta->id)
            ->whereIn('id', $opcionIds)
            ->where('activo', 1)
            ->pluck('codigo')
            ->map(fn ($c) => strtoupper(trim((string) $c)))
            ->all();

        foreach ($codigos as $cod) {
            if (in_array($cod, ['SI_ORDENADO', 'SI_DESORDENADO'], true)) {
                return true;
            }
        }

        return false;
    }

    private function totalOpcionesProyectadas(
        RcPregunta $pregunta,
        ?RcRespuesta $respuestaActual,
        ?array $payload,
        array $opcionesPorRespuesta
    ): int {
        if (is_array($payload) && array_key_exists('opcion_ids', $payload) && is_array($payload['opcion_ids'])) {
            $opcionIds = array_values(array_unique(array_map('intval', $payload['opcion_ids'])));
            $opcionIds = array_values(array_filter($opcionIds, fn($id) => $id > 0));
            if ($pregunta->tipo_respuesta === 'opcion_unica' && count($opcionIds) > 1) {
                $opcionIds = [reset($opcionIds)];
            }
            return count($opcionIds);
        }

        $respuestaId = (int) ($respuestaActual?->id ?? 0);
        if ($respuestaId <= 0) {
            return 0;
        }

        return (int) ($opcionesPorRespuesta[$respuestaId] ?? 0);
    }

    private function tomarValorProyectado($valorActual, ?array $payload, string $key)
    {
        if (is_array($payload) && array_key_exists($key, $payload)) {
            return $payload[$key];
        }

        return $valorActual;
    }

    private function validarCompletitudFallback(
        $valorTexto,
        $valorNumero,
        $valorDecimal,
        $valorBooleano,
        $valorFecha,
        $valorHora
    ): array {
        $completa = (
            ($valorTexto !== null && trim((string) $valorTexto) !== '')
            || $valorNumero !== null
            || $valorDecimal !== null
            || $valorBooleano !== null
            || ($valorFecha !== null && (string) $valorFecha !== '')
            || ($valorHora !== null && trim((string) $valorHora) !== '')
        );

        return $completa
            ? ['completa' => true, 'motivo' => null]
            : ['completa' => false, 'motivo' => 'sin_valor'];
    }

    private function esPreguntaEvidenciaOcultaEnFormulario(string $codigo): bool
    {
        return preg_match('/^E\d+$/i', trim($codigo)) === 1;
    }

    /** P01–P05: precarga / pantalla informativa; no se validan como obligatorias en guardado por sección. */
    private function esPreguntaAutocompletadaFormulario(string $codigo): bool
    {
        $c = strtoupper(trim($codigo));

        return in_array($c, ['P01', 'P02', 'P03', 'P04', 'P05'], true);
    }

    /**
     * POST visita/{visitaId}/respuestas/{preguntaId}/media
     * Sube una o más fotos para la respuesta de una pregunta. Crea la respuesta si no existe.
     * Body: multipart con "fotos[]" (array de archivos) o "foto" (un archivo).
     */
    public function postMedia(Request $request, int $visitaId, int $preguntaId)
    {
        $zonal = $this->getZonalUsuario();
        $user = $this->getUsuarioRecopilacion();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }
        if ($this->tokenRequiereZonalUsuario($user) && !$zonal) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener la zonal del usuario',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $visita = RcVisitaFormulario::find($visitaId);
        if (!$visita || !$this->puedeGestionarVisitaRecopilacion($user, $visita, $zonal)) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'Visita no encontrada o no pertenece a su zonal',
            ], Response::HTTP_FORBIDDEN);
        }

        $pregunta = RcPregunta::where('id', $preguntaId)
            ->whereHas('seccion', fn($q) => $q->where('formulario_id', $visita->formulario_id))
            ->first();
        if (!$pregunta) {
            return response()->json([
                'status' => Response::HTTP_NOT_FOUND,
                'message' => 'Pregunta no encontrada o no pertenece al formulario de esta visita',
            ], Response::HTTP_NOT_FOUND);
        }

        $maxFotos = (int) $pregunta->max_fotos;
        if ($maxFotos < 1) {
            $maxFotos = 10;
        }
        $archivos = $request->allFiles();
        $fotos = isset($archivos['fotos']) && is_array($archivos['fotos'])
            ? array_values($archivos['fotos'])
            : (isset($archivos['foto']) ? [$archivos['foto']] : []);
        $fotos = array_filter($fotos, fn($f) => $f instanceof \Illuminate\Http\UploadedFile);

        if (empty($fotos)) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => 'Debe enviar al menos un archivo (foto o fotos[])',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $respuesta = RcRespuesta::firstOrCreate(
            [
                'visita_id' => $visitaId,
                'pregunta_id' => $preguntaId,
            ],
            [
                'valor_texto' => null,
                'valor_numero' => null,
                'valor_decimal' => null,
                'valor_booleano' => null,
                'valor_fecha' => null,
                'valor_hora' => null,
                'observacion' => null,
                'no_aplica' => false,
            ]
        );

        $countActual = RcRespuestaMedia::where('respuesta_id', $respuesta->id)->where('tipo_media', 'foto')->count();
        if ($countActual + count($fotos) > $maxFotos) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => "Máximo {$maxFotos} fotos para esta pregunta. Actualmente tiene {$countActual}.",
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $storage = app(RecopilacionMediaStorage::class);
        $usuarioSubida = $user->user ?? (string) $this->getDniUsuario($user);
        $creados = [];
        $ordenBase = $countActual + 1;

        foreach ($fotos as $i => $file) {
            $errors = $storage->validatePhoto($file);
            if (!empty($errors)) {
                return response()->json([
                    'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                    'message' => $errors[0] ?? 'Archivo no válido',
                ], Response::HTTP_UNPROCESSABLE_ENTITY);
            }
            $meta = $storage->savePhoto($file, $visitaId, $preguntaId);
            $media = RcRespuestaMedia::create([
                'respuesta_id' => $respuesta->id,
                'tipo_media' => 'foto',
                'ruta_archivo' => $meta['ruta_archivo'],
                'nombre_archivo' => $meta['nombre_archivo'],
                'mime_type' => $meta['mime_type'],
                'tamano_bytes' => $meta['tamano_bytes'],
                'orden' => $ordenBase + $i,
                'usuario_subida' => $usuarioSubida,
            ]);
            $creados[] = [
                'id' => $media->id,
                'tipo_media' => $media->tipo_media,
                'nombre_archivo' => $media->nombre_archivo,
                'ruta_archivo' => $media->ruta_archivo,
                'orden' => $media->orden,
            ];
        }

        return response()->json([
            'status' => Response::HTTP_OK,
            'message' => count($creados) === 1 ? 'Foto subida correctamente' : 'Fotos subidas correctamente',
            'data' => ['media' => $creados],
        ], Response::HTTP_OK);
    }

    /**
     * DELETE media/{id}
     * Elimina una foto/audio de una respuesta. Comprueba que la visita pertenezca a la zonal del usuario.
     */
    public function deleteMedia(int $id)
    {
        $user = $this->getUsuarioRecopilacion();
        $zonal = $this->getZonalUsuario();
        if (!$user) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener el usuario autenticado',
            ], Response::HTTP_UNAUTHORIZED);
        }
        if ($this->tokenRequiereZonalUsuario($user) && !$zonal) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener la zonal del usuario',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $media = RcRespuestaMedia::with('respuesta.visita')->find($id);
        if (!$media || !$media->respuesta || !$media->respuesta->visita) {
            return response()->json([
                'status' => Response::HTTP_NOT_FOUND,
                'message' => 'Recurso no encontrado',
            ], Response::HTTP_NOT_FOUND);
        }

        $visita = $media->respuesta->visita;
        if (!$this->puedeGestionarVisitaRecopilacion($user, $visita, $zonal)) {
            return response()->json([
                'status' => Response::HTTP_FORBIDDEN,
                'message' => 'No puede eliminar archivos de esta visita',
            ], Response::HTTP_FORBIDDEN);
        }

        app(RecopilacionMediaStorage::class)->deleteByPath($media->ruta_archivo);
        $media->delete();

        return response()->json([
            'status' => Response::HTTP_OK,
            'message' => 'Archivo eliminado',
        ], Response::HTTP_OK);
    }

    public function verMediaFoto(int $id)
    {
        $media = RcRespuestaMedia::where('id', $id)
            ->where('tipo_media', 'foto')
            ->first();

        if (!$media) {
            return response()->json([
                'status' => Response::HTTP_NOT_FOUND,
                'message' => 'Foto no encontrada',
            ], Response::HTTP_NOT_FOUND);
        }

        $ruta = trim((string) $media->ruta_archivo);
        if ($ruta === '' || preg_match('/\.\./', $ruta) === 1) {
            return response()->json([
                'status' => Response::HTTP_NOT_FOUND,
                'message' => 'Archivo no disponible',
            ], Response::HTTP_NOT_FOUND);
        }

        $disk = Storage::disk(RecopilacionMediaStorage::DISK);
        if (!$disk->exists($ruta)) {
            return response()->json([
                'status' => Response::HTTP_NOT_FOUND,
                'message' => 'Archivo no encontrado',
            ], Response::HTTP_NOT_FOUND);
        }

        $headers = [];
        if (!empty($media->mime_type)) {
            $headers['Content-Type'] = (string) $media->mime_type;
        }

        return response()->file($disk->path($ruta), $headers);
    }
}
