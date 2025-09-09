<?php

namespace App\Http\Controllers\Multimarca;

use App\Http\Controllers\Controller;
use App\Models\VI_AVANCES_DIARIOS;
use App\Models\VI_FLYERS;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class AvanceDiarioController extends Controller
{
    private const ZERO_DEFAULTS = [
        'mes_6'                 => 0.00,
        'mes_7'                 => 0.00,
        'mes_8'                 => 0.00,
        'mes_9'                 => 0.00,
        'mes_10'                => 0.00,
        'mes_11'                => 0.00,
        'bonoRecargaNxVendedor' => 0.00,
        'bonoCalidad'           => 0.00,
        'bonoTotal'             => 0.00,
        'cantidadPortaPostOPre' => 0.00,
        'precioPortaPostOPre'   => 0.00,
        'cantidadPortaPostOPost' => 0.00,
        'precioPortaPostOPost'  => 0.00,
        'bonoPortaPostOPre'     => 0.00,
        'bonoPortaPostOPost'    => 0.00,
    ];

    public function getDataMM($dni, $anio, $mes)
    {
        try {
            $existeAvance = DB::select("EXEC spViewInfoVendedorMM ?, ?, ?", [$dni, $anio, $mes]);
            if ($existeAvance) {
                $infoVendedor = $existeAvance[0];
                // return $infoVendedor;
                // $dateUpdateCalidad = Carbon::now()->subDays(4)->toDateString();
                $infoVendedor = [
                    "zonal" => $infoVendedor->ZONAL,
                    "dni_responsable" => $infoVendedor->{'DNI_RESPONSABLE'},
                    "dni_vendedor" => $infoVendedor->{'DNI_VENDEDOR'},
                    "dni_supervisor" => $infoVendedor->{'DNI SUPERVISOR'},
                    "nombre_vendedor" => $infoVendedor->{'NOMBRE_VENDEDOR'},
                    "supervisor" => $infoVendedor->{'NOMBRE_SUPERVISOR'},
                    // "celularVendedor"=> $infoVendedor->CELULAR_VENDEDOR !=0 ? $infoVendedor->CELULAR_VENDEDOR: "" ,
                    "celularSupervisor" => $infoVendedor->{'NUM SUPERVISOR'} != 0 ? $infoVendedor->{'NUM SUPERVISOR'} : "",
                    "celularRecargador" => $infoVendedor->NUMERO_RECARGADOR != 0 ? $infoVendedor->NUMERO_RECARGADOR : "",
                    // "celular"=> $infoVendedor->CELULAR_VENDEDOR !=0 ? $infoVendedor->CELULAR_VENDEDOR: "" ,
                    "proyecto" => $infoVendedor->{'ACCION_2'},
                    "cuotaPrepago" => (float)$infoVendedor->CUOTA_PREPAGO,
                    "recargasTotales" => (float)$infoVendedor->RECARGA_TOTAL,
                    "avancePrepago" => (float)$infoVendedor->{'AVANCE PREPAGO'},
                    "fecha_inicio" => $infoVendedor->FECHA_INICIO,
                    "fecha_cierre" => $infoVendedor->ULTIMA_FECHA,
                    "cantidadDayVentaPre" => (float)$infoVendedor->cantidaDayConVentasPre,
                    "minRatio" => (float)$infoVendedor->minRatio,
                    "maxRatio" => (float)$infoVendedor->maxRatio,
                    "entidadBancaria" => $infoVendedor->{'ENTIDAD BANCARIA MM'},
                    "cctaBancario" => $infoVendedor->{'CCTA BANCARIA MM'},
                    "levelCalidad" => (float)$infoVendedor->{'CALIDAD_CLUSTER'} ?? 0,
                    "infoUpdateCalidad" => $infoVendedor->{'DATE_UPDATE_CALIDAD'} ?? 0,
                ];
                return response()->json(["status" => Response::HTTP_OK, "message" => "Información", "data" => $infoVendedor], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay información", "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    public function getPayment(int $dni, int $anio, int $mes, int $typeQuincena)
    {
        try {
            if ($anio === 2025 && $mes > 0 && $mes < 6) {
                $typeQuincena = 2;
            }
            $raw    = $this->fetchRawData($dni, $anio, $mes, $typeQuincena);
            $data   = !empty($raw)
                ? $this->processRawData($raw, $mes, $anio)
                : $this->fetchAuxiliaryData($dni, $anio, $mes);
            $status = Response::HTTP_OK;
            $msg    = !empty($raw) ? 'Hay pago para el vendedor Multimarca' : 'No hay pagos';
            return response()->json(compact('status', 'msg', 'data'), $status);
        } catch (\Exception $ex) {
            return response()->json([
                'status'  => Response::HTTP_BAD_REQUEST,
                'message' => $ex->getMessage(),
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    private function fetchRawData(int $dni, int $anio, int $mes, int $typeQuincena): array
    {
        if ($typeQuincena !== 0) {
            return [];
        }
        return DB::select(
            'EXEC spResumenGanaciaCampaña_MM_Payment @dni=?, @año=?, @mes=?',
            [$dni, $anio, $mes]
        );
    }

    private function processRawData(array $rows, int $mes, int $anio): array
    {
        if ($mes === 6) {
            $item = collect($rows)->first();
            return array_merge(
                $this->getCommonFields($item),
                self::ZERO_DEFAULTS,
                ['mes_6' => (float) ($item->ganaciaPorRecarga ?? 0)]
            );
        }

        // Obtener la fecha máxima del parámetro tipo=1
        $fechaMaxima = DB::table('parametros')
            ->where('tipo', 1)
            ->value('valor');
        
        // Convertir la fecha máxima a mes de referencia
        $mesReferencia = $fechaMaxima ? (int) date('n', strtotime($fechaMaxima)) : (int) date('n');

        $result = collect($rows)->reduce(function (array $carry, $item) use ($mesReferencia, $mes, $anio) {
            // Mes destino dinámico basado en la fecha máxima del parámetro
            $n          = (int) str_replace('N', '', $item->PERIODO_EVALUACION);
            $mesDestino = $mesReferencia - $n;

            if ($mesDestino >= 1 && $mesDestino <= 12) {
                // Validación para agosto 2025: si ventasLog < 10, establecer ganancias en 0
                $gananciaPorRecarga = (float) $item->ganaciaPorRecarga;
                if ($mes === 8 && $anio === 2025 && ($item->ventasLog ?? 0) < 10) {
                    $gananciaPorRecarga = 0.0;
                }
                $carry['mes_' . $mesDestino] = $gananciaPorRecarga;
            }

            return array_merge($carry, $this->getCommonFields($item));
        }, self::ZERO_DEFAULTS);

        return $result;
    }

    private function fetchAuxiliaryData(int $dni, int $anio, int $mes): array
    {
        $calidad   = DB::table('PDV_OUT_FUNNEL')
            ->where('DNI_VENDEDOR', $dni)
            ->whereYear('fecha', $anio)
            ->whereMonth('fecha', $mes)
            ->whereIn('CALIDAD_CLUSTER', [
                'Cluster 1: IMEI nuevo',
                'Cluster 2: IMEI reutilizado',
            ])->count();

        $ventasLog = DB::table('PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL')
            ->where('DNI_VENDEDOR', $dni)
            ->whereYear('fecha', $anio)
            ->whereMonth('fecha', $mes)
            ->where('PRODUCTO', 'PREPAGO')
            ->count();

        $precioUni = DB::table('parametros')
            ->where('tipo', 7)
            ->where('level', 0)
            ->whereYear('fecha', $anio)
            ->whereMonth('fecha', $mes)
            ->value('valor') ?? 0;

        $data = array_merge(
            [
                'dni_vendedor'    => $dni,
                'ventasLog'       => (float) $ventasLog,
                'cantidadCalidad' => (float) $calidad,
                'pagoUniCalidad'  => (float) $precioUni,
            ],
            self::ZERO_DEFAULTS
        );
        $data['bonoCalidad'] = $calidad * $precioUni;
        $data['bonoTotal']   = $data['bonoCalidad'];
        return $data;
    }

    private function getCommonFields($item): array
    {
        return [
            'dni_vendedor'          => $item->dni_vendedor ?? '',
            'ventasLog'             => (float) ($item->ventasLog ?? 0),
            'cantidadCalidad'       => (float) ($item->cantidadCalidad ?? 0),
            'pagoUniCalidad'        => (float) ($item->pagoUniCalidad ?? 0),
            'bonoRecargaNxVendedor' => (float) ($item->bonoRecargaNxVendedorSubTotal ?? 0),
            'bonoCalidad'           => (float) ($item->bonoCalidad ?? 0),
            'bonoTotal'             => (float) ($item->bonoTotal ?? 0),
            'cantidadPortaPostOPre' => (float) ($item->cantidadPortaPostOPre ?? 0),
            'precioPortaPostOPre'   => (float) ($item->precioPortaPostOPre ?? 0),
            'cantidadPortaPostOPost' => (float) ($item->cantidadPortaPostOPost ?? 0),
            'precioPortaPostOPost'  => (float) ($item->precioPortaPostOPost ?? 0),
            'bonoPortaPostOPre'     => (float) ($item->bonoPortaPostOPre ?? 0),
            'bonoPortaPostOPost'    => (float) ($item->bonoPortaPostOPost ?? 0),
        ];
    }

    public function getAvanceQuinDiario($dni, $anio, $mes, $typeQuincena)
    {
        try {
            $getDay = Carbon::now()->day;
            // return $getDay;
            $getDay == 16 ? $typeQuincena = 1 : 2;
            $existeAvance = DB::select("EXEC spView_Avances_Diarios_Quincenal_MM ?, ?, ?, ?", [$dni, $anio, $mes, $typeQuincena]);
            if ($existeAvance) {
                $avances = $existeAvance;
                $avances = array_map(function ($item) {
                    return [
                        "fecha" => Carbon::parse($item->FECHA)->format('m-d'),
                        "altaPrepago" => (float) $item->ALTA_PREPAGO,
                        "altaPostpago" => (float) $item->ALTA_POSTPAGO,
                        "portaPre" => (float) $item->PORTA_PREPAGO,
                        "porta_post_o_pre" => (float) $item->PORTA_POST_O_PRE,
                        "porta_post_o_pos" => (float) $item->PORTA_POST_O_POS,
                    ];
                }, $existeAvance);
                return response()->json(["status" => Response::HTTP_OK, "message" => "Avance Diario", "data" => $avances], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay avance diario para el usuario " . $dni, "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    public function getAvanceDiario($dni, $anio, $mes)
    {
        try {
            $existeAvance = DB::select("EXEC spView_Avances_Diarios_Quincenal_MM ?, ?, ?, ?", [$dni, $anio, $mes, 2]);
            if ($existeAvance) {
                $avances = $existeAvance;
                $avances = array_map(function ($item) {
                    return [
                        "fecha" => Carbon::parse($item->FECHA)->format('m-d'),
                        "altaPrepago" => (float) $item->ALTA_PREPAGO,
                        "altaPostpago" => (float) $item->ALTA_POSTPAGO,
                        "portaPre" => (float) $item->PORTA_PREPAGO,
                        "porta_post_o_pre" => (float) $item->PORTA_POST_O_PRE,
                        "porta_post_o_pos" => (float) $item->PORTA_POST_O_POS,
                    ];
                }, $existeAvance);
                return response()->json(["status" => Response::HTTP_OK, "message" => "Avance Diario", "data" => $avances], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay avance diario para el usuario " . $dni, "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    private function fetchBaseData(int $dni, int $anio, int $mes): ?object
    {
        $result = DB::select('EXEC spResumenGanancia_MM_Base_Payment @dni=?, @año=?, @mes=?', [$dni, $anio, $mes]);
        
        return !empty($result) ? $result[0] : null;
    }

    private function fetchPeriodsData(int $dni, int $anio, int $mes): array
    {
        return DB::select('EXEC spResumenGanancia_MM_Periodos_Payment @dni=?, @año=?, @mes=?', [$dni, $anio, $mes]);
    }

    private function buildOptimizedPaymentData(object $baseData, array $periodsData, int $mes, int $anio): array
    {
        if ($mes === 6) {
            return $this->buildMes6Data($baseData, $periodsData);
        }
        
        return $this->buildOtherMonthsData($baseData, $periodsData, $mes, $anio);
    }

    private function buildMes6Data(object $baseData, array $periodsData): array
    {
        $periodo = collect($periodsData)->first();
        
        return array_merge(
            [
                'dni_vendedor'          => $baseData->dni_vendedor,
                'ventasLog'             => (float) $baseData->ventasLog,
                'cantidadCalidad'       => (float) $baseData->cantidadCalidad,
                'pagoUniCalidad'        => (float) $baseData->pagoUniCalidad,
                'bonoRecargaNxVendedor' => (float) ($periodo->ganaciaPorRecarga ?? 0),
                'bonoCalidad'           => (float) $baseData->bonoCalidad,
                'bonoTotal'             => (float) ($baseData->bonoTotal + ($periodo->ganaciaPorRecarga ?? 0)),
                'cantidadPortaPostOPre' => (float) $baseData->cantidadPortaPostOPre,
                'precioPortaPostOPre'   => (float) $baseData->precioPortaPostOPre,
                'cantidadPortaPostOPost' => (float) $baseData->cantidadPortaPostOPost,
                'precioPortaPostOPost'  => (float) $baseData->precioPortaPostOPost,
                'bonoPortaPostOPre'     => (float) $baseData->bonoPortaPostOPre,
                'bonoPortaPostOPost'    => (float) $baseData->bonoPortaPostOPost,
            ],
            self::ZERO_DEFAULTS,
            ['mes_6' => (float) ($periodo->ganaciaPorRecarga ?? 0)]
        );
    }

    private function buildOtherMonthsData(object $baseData, array $periodsData, int $mes, int $anio): array
    {
        $fechaMaxima = DB::table('parametros')
            ->where('tipo', 1)
            ->value('valor');
        
        $mesReferencia = $fechaMaxima ? (int) date('n', strtotime($fechaMaxima)) : (int) date('n');
        
        $result = array_merge(
            [
                'dni_vendedor'          => $baseData->dni_vendedor,
                'ventasLog'             => (float) $baseData->ventasLog,
                'cantidadCalidad'       => (float) $baseData->cantidadCalidad,
                'pagoUniCalidad'        => (float) $baseData->pagoUniCalidad,
                'bonoRecargaNxVendedor' => (float) $baseData->bonoRecargaNxVendedorSubTotal,
                'bonoCalidad'           => (float) $baseData->bonoCalidad,
                'bonoTotal'             => (float) $baseData->bonoTotal,
                'cantidadPortaPostOPre' => (float) $baseData->cantidadPortaPostOPre,
                'precioPortaPostOPre'   => (float) $baseData->precioPortaPostOPre,
                'cantidadPortaPostOPost' => (float) $baseData->cantidadPortaPostOPost,
                'precioPortaPostOPost'  => (float) $baseData->precioPortaPostOPost,
                'bonoPortaPostOPre'     => (float) $baseData->bonoPortaPostOPre,
                'bonoPortaPostOPost'    => (float) $baseData->bonoPortaPostOPost,
            ],
            self::ZERO_DEFAULTS
        );
        
        foreach ($periodsData as $periodo) {
            $n = (int) str_replace('N', '', $periodo->PERIODO_EVALUACION);
            $mesDestino = $mesReferencia - $n;
            
            if ($mesDestino >= 1 && $mesDestino <= 12) {
                // Validación para agosto 2025: si ventasLog < 10, establecer ganancias en 0
                $gananciaPorRecarga = (float) $periodo->ganaciaPorRecarga;
                if ($mes === 8 && $anio === 2025 && ($baseData->ventasLog ?? 0) < 10) {
                    $gananciaPorRecarga = 0.0;
                }
                $result['mes_' . $mesDestino] = $gananciaPorRecarga;
            }
        }
        
        return $result;
    }

    public function getOptimizedPayment(int $dni, int $anio, int $mes, int $typeQuincena)
    {
        try {
            if ($anio === 2025 && $mes > 0 && $mes < 6) {
                $typeQuincena = 2;
            }

            if ($typeQuincena !== 0) {
                return $this->fetchAuxiliaryData($dni, $anio, $mes);
            }

            $baseData = $this->fetchBaseData($dni, $anio, $mes);
            $periodsData = $this->fetchPeriodsData($dni, $anio, $mes);

            if (!$baseData) {
                $data = $this->fetchAuxiliaryData($dni, $anio, $mes);
                $msg = 'No hay pagos';
            } else {
                $data = $this->buildOptimizedPaymentData($baseData, $periodsData, $mes, $anio);
                $msg = 'Hay pago para el vendedor Multimarca';
            }

            $status = Response::HTTP_OK;
            return response()->json(compact('status', 'msg', 'data'), $status);
        } catch (\Exception $ex) {
            return response()->json([
                'status'  => Response::HTTP_BAD_REQUEST,
                'message' => $ex->getMessage(),
            ], Response::HTTP_BAD_REQUEST);
        }
    }
}
