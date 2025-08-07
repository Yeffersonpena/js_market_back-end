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
    function getPayment($dni, $anio, $mes, $typeQuincena)
    {
        try {
            if ($anio == 2025 && $mes > 0 && $mes < 6) {
                $typeQuincena = 2;
            }

            if (!$typeQuincena) {
                $getPayment = DB::select('EXEC spResumenGanaciaCampaña_MM_Payment @dni=?, @año=?, @mes=?', [$dni, $anio, $mes]);

                if (!empty($getPayment)) {
                    if ($mes == 6) {
                        $payment = collect($getPayment)->map(function ($item) {
                            return [
                                "dni_vendedor" => $item->dni_vendedor ?? '',
                                "ventasLog" => isset($item->ventasLog) ? (float) $item->ventasLog : 0.00,
                                "cantidadCalidad" => isset($item->cantidadCalidad) ? (float) $item->cantidadCalidad : 0.00,
                                "pagoUniCalidad" => isset($item->pagoUniCalidad) ? (float) $item->pagoUniCalidad : 0.00,
                                "mes_6" => isset($item->ganaciaPorRecarga) ? (float) $item->ganaciaPorRecarga : 0.00,
                                "mes_7" => 0.00,
                                "mes_8" => 0.00,
                                "mes_9" => 0.00,
                                "mes_10" => 0.00,
                                "mes_11" => 0.00,
                                "bonoRecargaNxVendedor" => isset($item->bonoRecargaNxVendedorSubTotal) ? (float) $item->bonoRecargaNxVendedorSubTotal : 0.00,
                                "bonoCalidad" => isset($item->bonoCalidad) ? (float) $item->bonoCalidad : 0.00,
                                "bonoTotal" => isset($item->bonoTotal) ? (float) $item->bonoTotal : 0.00
                            ];
                        });

                        return response()->json([
                            "status" => Response::HTTP_OK,
                            "message" => "Hay pago para el vendedor Multimarca",
                            "data" => $payment[0]
                        ], Response::HTTP_OK);
                    } else {
                        $payment = collect($getPayment)->reduce(function ($carry, $item) {
                            // Asignación dinámica de mes según PERIODO_EVALUACION
                            $mesActual = (int)date('n'); // mes actual (1-12)
                            $n = (int)str_replace('N', '', $item->PERIODO_EVALUACION); // extrae el número de N
                            $mesDestino = $mesActual - $n;
                            // Si el mes destino es menor a 1, puedes decidir si saltar o ajustar (por ahora, solo asigna si es válido)
                            if ($mesDestino >= 1 && $mesDestino <= 12) {
                                $claveMes = 'mes_' . $mesDestino;
                                $carry[$claveMes] = (float) $item->ganaciaPorRecarga;
                            }

                            $carry['dni_vendedor'] = $item->dni_vendedor ?? '';
                            $carry['ventasLog'] = isset($item->ventasLog) ? (float) $item->ventasLog : 0.00;
                            $carry['cantidadCalidad'] = isset($item->cantidadCalidad) ? (float) $item->cantidadCalidad : 0.00;
                            $carry['pagoUniCalidad'] = isset($item->pagoUniCalidad) ? (float) $item->pagoUniCalidad : 0.00;
                            $carry['bonoRecargaNxVendedor'] = isset($item->bonoRecargaNxVendedorSubTotal) ? (float) $item->bonoRecargaNxVendedorSubTotal : 0.00;
                            $carry['bonoCalidad'] = isset($item->bonoCalidad) ? (float) $item->bonoCalidad : 0.00;
                            $carry['bonoTotal'] = isset($item->bonoTotal) ? (float) $item->bonoTotal : 0.00;
                            $carry['cantidadPortaPostOPre'] = isset($item->cantidadPortaPostOPre) ? (float) $item->cantidadPortaPostOPre : 0.00;
                            $carry['precioPortaPostOPre'] = isset($item->precioPortaPostOPre) ? (float) $item->precioPortaPostOPre : 0.00;
                            $carry['cantidadPortaPostOPost'] = isset($item->cantidadPortaPostOPost) ? (float) $item->cantidadPortaPostOPost : 0.00;
                            $carry['precioPortaPostOPost'] = isset($item->precioPortaPostOPost) ? (float) $item->precioPortaPostOPost : 0.00;
                            $carry['bonoPortaPostOPre'] = isset($item->bonoPortaPostOPre) ? (float) $item->bonoPortaPostOPre : 0.00;
                            $carry['bonoPortaPostOPost'] = isset($item->bonoPortaPostOPost) ? (float) $item->bonoPortaPostOPost : 0.00;

                            return $carry;
                        }, []);

                        $payment = array_merge([
                            "mes_6" => 0.00,
                            "mes_7" => 0.00,
                            "mes_8" => 0.00,
                            "mes_9" => 0.00,
                            "mes_10" => 0.00,
                            "mes_11" => 0.00
                        ], $payment);

                        return response()->json([
                            "status" => Response::HTTP_OK,
                            "message" => "Hay pago para el vendedor Multimarca",
                            "data" => $payment
                        ], Response::HTTP_OK);
                    }
                } else {
                    // CONSULTAS AUXILIARES
                    $paymentCalidad = DB::select("select count(*) as cantidadCalidad from dbo.PDV_OUT_FUNNEL where DNI_VENDEDOR=? and YEAR(fecha)=? and month(fecha)=? and CALIDAD_CLUSTER in ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')", [$dni, $anio, $mes]);
                    $paymentVentaLog = DB::select("select count(*) as ventasLog from dbo.tbl_ventas_prepago_MM where DNI_VENDEDOR=? and YEAR(fecha)=? and month(fecha)=?", [$dni, $anio, $mes]);
                    $paymentPrecioUniCalidad = DB::select("select top 1 valor as precioUniCalidad from dbo.parametros where tipo=7 and [level]=0 and year(fecha)=? and month(fecha)=?", [$anio, $mes]);

                    $cantidadCalidad = isset($paymentCalidad[0]) ? $paymentCalidad[0]->cantidadCalidad : 0;
                    $ventasLog = isset($paymentVentaLog[0]) ? $paymentVentaLog[0]->ventasLog : 0;
                    $precioUniCalidad = isset($paymentPrecioUniCalidad[0]) ? $paymentPrecioUniCalidad[0]->precioUniCalidad : 0;
                    $bonoCalidad = $cantidadCalidad * $precioUniCalidad;

                    $noFountPayment = [
                        "dni_vendedor" => $dni,
                        "ventasLog" => (float) $ventasLog,
                        "cantidadCalidad" => (float) $cantidadCalidad,
                        "pagoUniCalidad" => (float) $precioUniCalidad,
                        "mes_6" => 0.00,
                        "mes_7" => 0.00,
                        "mes_8" => 0.00,
                        "mes_9" => 0.00,
                        "mes_10" => 0.00,
                        "mes_11" => 0.00,
                        "bonoRecargaNxVendedor" => 0.00,
                        "bonoCalidad" => (float) $bonoCalidad,
                        "bonoTotal" => (float) $bonoCalidad,
                        "cantidadPortaPostOPre" => 0.00,
                        "precioPortaPostOPre" => 0.00,
                        "cantidadPortaPostOPost" => 0.00,
                        "precioPortaPostOPost" => 0.00,
                        "bonoPortaPostOPre" => 0.00,
                        "bonoPortaPostOPost" => 0.00,
                    ];

                    return response()->json([
                        "status" => Response::HTTP_OK,
                        "message" => "No hay pagos ",
                        "data" => $noFountPayment
                    ], Response::HTTP_OK);
                }
            }

            // QUINCENA != 0: EJECUTAR spCalculoPaymentAll...
            // (El resto de la función lo dejaste bien, no cambia, solo querías la corrección del error del array vacío.)

            // ...
            // Resto de la función continúa sin cambios
            // ...
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        }
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
            $existeAvance = DB::select("EXEC spView_Avances_Diarios_MM ?, ?, ?", [$dni, $anio, $mes]);
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
