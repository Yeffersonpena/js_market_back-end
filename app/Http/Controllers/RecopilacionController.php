<?php

namespace App\Http\Controllers;

use App\Models\RcClientePdv;
use App\Models\RcFormulario;
use App\Models\RcPregunta;
use App\Models\RcRespuesta;
use App\Models\RcRespuestaMedia;
use App\Models\RcRespuestaOpcion;
use App\Models\RcSeccion;
use App\Models\RcVisitaFormulario;
use App\Services\RecopilacionMediaStorage;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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
     * la recopilacion finalizada para el formulario y periodo dados.
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
            ->where(function ($q) {
                $q->whereNull('v.id')
                    ->orWhere('v.estado', '!=', 'finalizado');
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
     * GET reporte/avance-zonal
     * Resumen por zonal: programados, ejecutados (finalizados) y porcentaje de avance.
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
                    ->where('v.formulario_id', $formulario->id)
                    ->where('v.estado', 'finalizado');

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
                'preguntas' => $preguntas->map(fn ($p) => [
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
                    'opciones' => $p->opciones->where('activo', 1)->map(fn ($o) => [
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
            $query->whereHas('pregunta', fn ($q) => $q->where('seccion_id', $seccionId));
        }
        $respuestas = $query->get();

        $data = $respuestas->map(function (RcRespuesta $r) {
            $opciones = $r->opcionesSeleccionadas->map(fn ($ro) => [
                'id' => $ro->opcion_id,
                'codigo' => $ro->opcion?->codigo,
                'etiqueta' => $ro->opcion?->etiqueta,
            ])->values();
            $media = $r->media->map(fn ($m) => [
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
                $respuesta->no_aplica = isset($item['no_aplica']) ? (bool) $item['no_aplica'] : $respuesta->no_aplica;
                $respuesta->usuario_guardado = $usuarioGuardado;
                $respuesta->save();

                if (array_key_exists('opcion_ids', $item) && is_array($item['opcion_ids'])) {
                    $opcionIds = array_values(array_unique(array_map('intval', $item['opcion_ids'])));
                    $opcionIds = array_values(array_filter($opcionIds, fn ($id) => $id > 0));

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
        ], Response::HTTP_OK);
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
            ->whereHas('seccion', fn ($q) => $q->where('formulario_id', $visita->formulario_id))
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
        $fotos = array_filter($fotos, fn ($f) => $f instanceof \Illuminate\Http\UploadedFile);

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
}
