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
                ? $this->processRawData($raw, $mes)
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

    private function processRawData(array $rows, int $mes): array
    {
        if ($mes === 6) {
            $item = collect($rows)->first();
            return array_merge(
                $this->getCommonFields($item),
                self::ZERO_DEFAULTS,
                ['mes_6' => (float) ($item->ganaciaPorRecarga ?? 0)]
            );
        }

        $result = collect($rows)->reduce(function (array $carry, $item) {
            // Mes destino dinámico
            $n          = (int) str_replace('N', '', $item->PERIODO_EVALUACION);
            $mesDestino = (int) date('n') - $n;

            if ($mesDestino >= 1 && $mesDestino <= 12) {
                $carry['mes_' . $mesDestino] = (float) $item->ganaciaPorRecarga;
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
}
