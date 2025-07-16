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
            if($anio==2025 and $mes>0 and $mes <6){
                $typeQuincena=2;
            }
            if (!$typeQuincena) {
                // $getPayment = DB::select('EXEC spResumenGanaciaCampaña_MM_Payment @dni=?, @año=?, @mes=?', [$dni, $anio, $mes]);
                // return $mes;
                // if($mes==6){
                //     $getPayment = DB::select('EXEC spResumenGanaciaCampaña_MM_Payment @dni=?, @año=?, @mes=?', [$dni, $anio, $mes]);
                // }else{
                    $getPayment = DB::select('EXEC spResumenGanaciaCampaña_MM_Payment_test_1 @dni=?, @año=?, @mes=?', [$dni, $anio, $mes]);
                // }
                // return $getPayment;
                if ($getPayment) {
                    if($mes==6){
                        // return $getPayment;
                        $payment = collect($getPayment)->map(function ($item) {
                            // $mes_6 = $item->PERIODO_EVALUACION === 'N0' ? (float)$item->MONTO_GANANCIA : 0.00;
                            // $mes_7 = $item->PERIODO_EVALUACION == 'N1' ? (float)$item->MONTO_GANANCIA : 0.00;
                            // $mes_8 = $item->PERIODO_EVALUACION === 'N2' ? (float)$item->MONTO_GANANCIA : 0.00;
                            // $mes_9 = $item->PERIODO_EVALUACION === 'N3' ? (float)$item->MONTO_GANANCIA : 0.00;
                            // $mes_10 = $item->PERIODO_EVALUACION === 'N4' ? (float)$item->MONTO_GANANCIA : 0.00;
                            // $mes_11 = $item->PERIODO_EVALUACION === 'N5' ? (float)$item->MONTO_GANANCIA : 0.00;
                            return [
                                "dni_vendedor" => $item->dni_vendedor ?? '',
                                "ventasLog" => (float) $item->ventasLog ?? 0.00,
                                "cantidadCalidad" => (float) $item->cantidadCalidad ?? 0.00,
                                "pagoUniCalidad" => (float) $item->pagoUniCalidad ?? 0.00,
                                // "mes_6" => (float)$item->mes_6 ?? 0.00,
                                // "mes_7" => (float)$item->mes_7 ?? 0.00,
                                // "mes_8" => (float)$item->mes_8 ?? 0.00,
                                // "mes_9" => (float)$item->mes_9 ?? 0.00,
                                // "mes_10" => (float)$item->mes_10 ?? 0.00,
                                // "mes_11" => (float)$item->mes_11 ?? 0.00,
                                "mes_6" => (float) $item->MONTO_GANANCIA,
                                "mes_7" => 0.00,
                                "mes_8" => 0.00,
                                "mes_9" => 0.00,
                                "mes_10" => 0.00,
                                "mes_11" => 0.00,
                                "bonoRecargaNxVendedor" => (float) $item->bonoRecargaNxVendedor ?? 0.00,
                                "bonoCalidad" => (float) $item->bonoCalidad ?? 0.00,
                                "bonoTotal" => (float) $item->bonoTotal ?? 0.00
                            ];
                        });
                        // return $getPayment[0];
                    return response()->json(["status" => Response::HTTP_OK, "message" => "Hay pago para el vendedor Multimarca", "data" => $payment[0]], Response::HTTP_OK);

                    }else{
                        // Reducir los resultados a un solo objeto
                        $payment = collect($getPayment)->reduce(function ($carry, $item) {
                            // Asignar MONTO_GANANCIA a los meses correspondientes según el PERIODO_EVALUACION
                            switch ($item->PERIODO_EVALUACION) {
                                case 'N0':
                                    $carry['mes_6'] = (float) $item->MONTO_GANANCIA;
                                    break;
                                case 'N1':
                                    $carry['mes_7'] = (float) $item->MONTO_GANANCIA;
                                    break;
                                case 'N2':
                                    $carry['mes_8'] = (float) $item->MONTO_GANANCIA;
                                    break;
                                case 'N3':
                                    $carry['mes_9'] = (float) $item->MONTO_GANANCIA;
                                    break;
                                case 'N4':
                                    $carry['mes_10'] = (float) $item->MONTO_GANANCIA;
                                    break;
                                case 'N5':
                                    $carry['mes_11'] = (float) $item->MONTO_GANANCIA;
                                    break;
                            }
                            $carry['dni_vendedor'] = $item->dni_vendedor ?? '';
                            $carry['ventasLog'] = (float) $item->ventasLog ?? 0.00;
                            $carry['cantidadCalidad'] = (float) $item->cantidadCalidad ?? 0.00;
                            $carry['pagoUniCalidad'] = (float) $item->pagoUniCalidad ?? 0.00;
                            $carry['bonoRecargaNxVendedor'] = (float) $item->bonoRecargaNxVendedor ?? 0.00;
                            $carry['bonoCalidad'] = (float) $item->bonoCalidad ?? 0.00;
                            $carry['bonoTotal'] = (float) $item->bonoTotal ?? 0.00;
                            return $carry;
                        }, []);

                        // Asegurar que todos los meses estén presentes, incluso si no se asignaron
                        $payment = array_merge([
                            "mes_6" => 0.00,
                            "mes_7" => 0.00,
                            "mes_8" => 0.00,
                            "mes_9" => 0.00,
                            "mes_10" => 0.00,
                            "mes_11" => 0.00
                        ], $payment);
                    }
                    // return $payment;
                    return response()->json(["status" => Response::HTTP_OK, "message" => "Hay pago para el vendedor Multimarca", "data" => $payment], Response::HTTP_OK);
                } else {
                    $paymentCalidad = DB::select("select count(*) as cantidadCalidad from dbo.PDV_OUT_FUNNEL where DNI_VENDEDOR=? and YEAR(fecha)=? and month(fecha)=? and CALIDAD_CLUSTER in ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')", [$dni, $anio, $mes]);
                    $paymentVentaLog = DB::select("select count(*) as ventasLog from dbo.tbl_ventas_prepago_MM where DNI_VENDEDOR=? and YEAR(fecha)=? and month(fecha)=?", [$dni, $anio, $mes]);
                    $paymentPrecioUniCalidad= DB::select("select top 1 valor as precioUniCalidad from dbo.parametros where tipo=7 and [level]=0 and year(fecha)=? and month(fecha)=?", [$anio, $mes]);
                    $noFountPayment = [
                        "dni_vendedor" => $dni,
                        "ventasLog" => $paymentVentaLog[0]->ventasLog ?? 0,
                        "cantidadCalidad" => $paymentCalidad[0]->cantidadCalidad ?? 0,
                        "pagoUniCalidad" => $paymentPrecioUniCalidad[0]->precioUniCalidad ?? 0,
                        "mes_6" => 0.00,
                        "mes_7" => 0.00,
                        "mes_8" => 0.00,
                        "mes_9" => 0.00,
                        "mes_10" => 0.00,
                        "mes_11" => 0.00,
                        "bonoRecargaNxVendedor" => 0.00,
                        "bonoCalidad" => $paymentCalidad[0]->cantidadCalidad * $paymentPrecioUniCalidad[0]->precioUniCalidad ?? 0.00,
                        "bonoTotal" => $paymentCalidad[0]->cantidadCalidad * $paymentPrecioUniCalidad[0]->precioUniCalidad ?? 0.00
                    ];
                    return response()->json(["status" => Response::HTTP_OK, "message" => "No hay pagos ", "data" => $noFountPayment], Response::HTTP_OK);
                }
            }
            $spPayment = DB::select("exec spCalculoPaymentAll ?,?,?,?,?", [$dni, $anio, $mes, $typeQuincena, 3]);
            if ($spPayment) {
                $acumuladorPayment = [
                    "bonoPre" => 0.0,
                    "bonoRecargaPre" => 0.0,
                    "bonoPortaPre" => 0.0,
                    "bonoAltaPost" => 0.0,
                    "bonoPortaPostOPost" => 0.0,
                    "bonoPortaPostOPre" => 0.0,
                    "bonoChips" => 0.00,
                    "bonoTotalEfectivo" => 0.00,
                    "bonoTotal" => 0.00,
                    "ventaTotal" => 0.00,
                    // "precioUni"=>0.00,
                    // "cantidadDayVentaPre"=>0.00,
                    "faltaVenta" => 0.00,
                    "cantidadPortaPre" => 0.00,
                    "precioUniPortaPre" => 0.00,
                    "cantidadAltaPost" => 0.00,
                    "precioUniAltaPost" => 0.00,
                    "cantidadPortaPostOPost" => 0.00,
                    "precioPortaPostOPost" => 0.00,
                    "cantidadPortaPostOPre" => 0.00,
                    "precioPortaPostOPre" => 0.00,
                    "precioUniSchema" => 0.00,
                    "precioUniRecarga" => 0.00,
                    "cantidadRecarga" => 0.00,
                    "recuerdaVentaPostCost" => 0.00,
                    "cantidadVenta" => 0.00,

                    "cantidadRecargaPost" => 0.00,
                    "bonoUniRecargaPost" => 0.00,
                    "bonoTotalRecargaPost" => 0.00,
                    "cantidadPostSchemaPost" => 0.00,
                    "precioUniPostSchema" => 0.00,
                    "cantidadChipDevolucion" => 0.00,
                    "financiamientoSaldo" => 0.00,
                    "financiamientoChip" => 0.00,
                    "financiamientoTotal" => 0.00,

                    "nivelRatio" => 0.00,
                    "minRatio" => 0.00,
                    "maxRatio" => 0.00,
                    "diaMinVenta" => 0.00,

                ];
                foreach ($spPayment as $item) {
                    // return $item;
                    // return $spPayment;
                    // $acumuladorPayment["unitarioRec"] += $item->unitarioRec ? (float) $item->unitarioRec : 0.0;
                    $acumuladorPayment["bonoPre"] += $item->bonoPre ? (float) $item->bonoPre : 0.0;
                    $acumuladorPayment["bonoRecargaPre"] += $item->bonoRecargaPre ? (float) $item->bonoRecargaPre : 0.0;
                    $acumuladorPayment["bonoPortaPre"] += $item->bonoPortaPre ? (float) $item->bonoPortaPre : 0.0;
                    $acumuladorPayment["bonoAltaPost"] += $item->bonoAltaPost ? (float) $item->bonoAltaPost : 0.0;
                    $acumuladorPayment["bonoPortaPostOPost"] += $item->bonoPortaPostOPost ? (float) $item->bonoPortaPostOPost : 0.0;
                    $acumuladorPayment["bonoPortaPostOPre"] += $item->bonoPortaPostOPre ? (float) $item->bonoPortaPostOPre : 0.0;
                    $acumuladorPayment["bonoChips"] += $item->bonoChips ? (float) $item->bonoChips : 0.0;
                    $acumuladorPayment["bonoTotalEfectivo"] += $item->bonoTotalEfectivo ? (float) $item->bonoTotalEfectivo : 0.0;
                    $acumuladorPayment["bonoTotal"] += $item->bonoTotal ? (float) $item->bonoTotal : 0.0;
                    // $acumuladorPayment["faltaVenta"] = (float) $item->faltaVenta;
                    // $acumuladorPayment["cantidadDayVentaPre"] = (float) $item->cantidaDayConVentasPre;
                    $acumuladorPayment["cantidadPortaPre"] = (float) $item->cantidadPortaPre;
                    $acumuladorPayment["precioUniPortaPre"] = (float) $item->precioUniPortaPre;
                    $acumuladorPayment["cantidadAltaPost"] = (float) $item->cantidadAltaPost;
                    $acumuladorPayment["precioUniAltaPost"] = (float) $item->precioUniAltaPost;
                    $acumuladorPayment["cantidadPortaPostOPost"] = (float) $item->cantidadPortaPostOPost;
                    $acumuladorPayment["precioPortaPostOPost"] = (float) $item->precioPortaPostOPost;
                    $acumuladorPayment["cantidadPortaPostOPre"] = (float) $item->cantidadPortaPostOPre;
                    $acumuladorPayment["precioPortaPostOPre"] = (float) $item->precioPortaPostOPre;
                    $acumuladorPayment["precioUniSchema"] = (float) $item->precioUniPortaPre; //precioUniSchema; unitaro del tabla esquema
                    $acumuladorPayment["precioUniRecarga"] = (float) $item->precioUniRecarga;
                    $acumuladorPayment["cantidadRecarga"] = (float) $item->cantidadRecarga;
                    $acumuladorPayment["cantidadRecarga"] = (float) $item->cantidadRecarga;
                    $acumuladorPayment["ventaTotal"] = (float) $item->bonoChips;

                    $acumuladorPayment["cantidadVenta"] = (float) $item->cantidadVenta;

                    $acumuladorPayment["recuerdaVentaPostCost"] = (float) $item->recuerdaVentaPostCost;
                    $acumuladorPayment["cantidadRecargaPost"] = (float) $item->cantidadRecargaPost;
                    $acumuladorPayment["bonoUniRecargaPost"] = (float) $item->bonoUniRecargaPost;
                    $acumuladorPayment["bonoTotalRecargaPost"] = (float) $item->bonoTotalRecargaPost;
                    $acumuladorPayment["cantidadPostSchemaPost"] = (float) $item->cantidadPostSchemaPost;
                    $acumuladorPayment["precioUniPostSchema"] = (float) $item->precioUniPostSchema;
                    $acumuladorPayment["cantidadChipDevolucion"] = (float) $item->cantidadChipDevolucion;
                    $acumuladorPayment["financiamientoSaldo"] = (float) $item->financiamientoSaldo;
                    $acumuladorPayment["financiamientoChip"] = (float) $item->financiamientoChip;
                    $acumuladorPayment["financiamientoTotal"] = (float) $item->financiamiento;
                    $acumuladorPayment["nivelRatio"] = (float) $item->nivelRatio;
                    $acumuladorPayment["minRatio"] = (float) $item->minRatio;
                    $acumuladorPayment["maxRatio"] = (float) $item->maxRatio;
                    $acumuladorPayment["diaMinVenta"] = (float) $item->diaMinVenta;
                }
                $payment = $acumuladorPayment;
                return response()->json(["status" => Response::HTTP_OK, "message" => "Hay pago para el vendedor Multimarca", "data" => $payment], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay pagos ", "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
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
