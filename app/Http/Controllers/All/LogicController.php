<?php

namespace App\Http\Controllers\All;

use App\Http\Controllers\Controller;
use App\Models\Incidencia;
use App\Models\PDV_ABONOS;
use App\Models\PDV_AVANCES_DIARIOS_MM;
use App\Models\VI_AVANCES_DIARIOS;
use App\Models\VI_FLYERS;
use App\Models\VI_PDV_PAYMENT;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class LogicController extends Controller
{
    public function getAvanceDiario($dni, $anio, $mes)
    {
        try {

            // $existeAvance = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->whereYear('FECHA', $anio)->whereMonth('FECHA', $mes)->exists();
            // $existeAvance = VI_AVANCES_DIARIOS::whereRaw("CAST(DNI_RESPONSABLE AS VARCHAR) = ?", [$dni])
            // ->whereYear('FECHA', $anio)
            // ->whereMonth('FECHA', $mes)
            // ->exists();
            // $existeAvance = DB::select( "EXEC spView_Avances_Diarios_test_1 ?, ?, ?", [$dni, $anio, $mes]);
            $existeAvance = DB::select("EXEC spView_Avances_Diarios ?, ?, ?", [$dni, $anio, $mes]);
            if ($existeAvance) {
                $avances = $existeAvance;
                // return $avances;
                // $avances = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->whereYear('FECHA', $anio)->whereMonth('FECHA', $mes)->orderBy('FECHA')->get();
                // $avances = VI_AVANCES_DIARIOS::whereRaw("CAST(DNI_RESPONSABLE AS VARCHAR) = ?", [$dni])
                // ->whereYear('FECHA', $anio)
                // ->whereMonth('FECHA', $mes)
                // ->orderBy('FECHA')
                // ->get();
                // return response()->json($avances);

                // $avances->makeHidden(['id', 'DNI ', 'MAX_FECHA']);
                // ------------
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

    public function getHistoryVenta($dni, $anio, $mes)
    {
        try {
            $existeAvance = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->whereYear('FECHA', $anio)->whereMonth('FECHA', $mes)->exists();
            if ($existeAvance) {
                // $avances->makeHidden(['id', 'canal', 'cluster', 'DNI_RESPONSABLE', 'Nombre AD', 'Vendedor AD', 'Cuota PDV', 'cuota_enero', 'Celular Vendedor AD', 'MAX_FECHA', 'RECARGAS']);
                $avances = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->whereYear('FECHA', $anio)->whereMonth('FECHA', $mes)->orderBy('FECHA', 'asc')->get();
                $avances->makeHidden(['id', 'DNI ', 'MAX_FECHA']);
                $avances = $avances->map(function ($item) {
                    return [
                        "fecha" => $item->FECHA,
                        "altaPrepago" => (float)$item->{"ALTA PREPAGO"},
                        "portaPrepago" => (float)$item->{"PORTA PREPAGO"},
                        "altaPostpago" => (float)$item->{"ALTA POSTPAGO"},
                        "portaPostpago" => (float)$item->{"PORTA POSTPAGO"},
                    ];
                });
                return response()->json(["status" => Response::HTTP_OK, "message" => "Historial de Venta", "data" => $avances], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay historial de venta", "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    public function getFlyers($dni, $anio, $mes)
    {
        try {
            $existeAvance = VI_FLYERS::where('DNI_Responsable', $dni)->exists();
            if ($existeAvance) {
                $avances = VI_FLYERS::where('DNI_Responsable', $dni)->whereRaw('? BETWEEN MONTH(fecha_inicio) AND MONTH(fecha_fin)', [$mes])->orderBy('fecha_fin', 'asc')->get();
                $agrupados = $avances->groupBy('tipoImg');
                $agrupados->each(function ($items) {
                    foreach ($items as $item) {
                        // foreach ($items as $key=>$item) {
                        // foreach ($items as $key=>$item) {
                        // $item[$key]= [
                        //     "año" => $item->año,
                        //     "mes" => $item->mes,
                        //     "dni_responsable" => $item->dni_responsable,
                        //     "zonal" => $item->zonal,
                        //     "foto_esquema" => env('APP_DOMAIN') . '/storage/img/' . $item->foto_esquema,
                        //     "fecha_inicio" => $item->fecha_inicio,
                        //     "fecha_fin" => $item->fecha_fin,
                        //     "tipoImg"=> $item->tipoImg
                        // ];
                        $item->foto_esquema = env('APP_DOMAIN') . '/storage/img/' . $item->foto_esquema;
                    }
                });
                // return $agrupados;
                return response()->json(["status" => Response::HTTP_OK, "message" => "Fyers", "data" => $agrupados], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay fyers " . $dni, "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function getAbono($dni, $anio, $mes)
    {
        try {
            $existeAbono = PDV_ABONOS::where('DNI RESP', $dni)->where('año', '=', $anio)->where('mes', '=', $mes)->exists();
            if ($existeAbono) {
                $abono = PDV_ABONOS::where('DNI RESP', $dni)->where('año', '=', $anio)->where('mes', '=', $mes)->get();
                // return 2;
                // return $abono;
                $abono->makeHidden(['DNI ']);
                $abono = $abono->map(function ($item) {
                    return [
                        // "id" => $item->id,
                        "año" => $item->AÑO,
                        "mes" => $item->MES,
                        "detalle" => $item->DETALLE,
                        // "estado" => $item->{"STATUS DEL ABONO"},
                        "estado" => $item->{"MÉTODO DE PAGO"},
                        "total" => (float)$item->{"BONO TOTAL"},
                        "fecha" => $item->{"FECHAS_ ABONO"},
                        "dniGanador" => $item->{"DNI GANADOR"},
                    ];
                });
                return response()->json(["status" => Response::HTTP_OK, "message" => "Historial de Abono", "data" => $abono], Response::HTTP_OK);
            } else {
                $existeAbono = PDV_ABONOS::where('DNI GANADOR', $dni)->where('año', '=', $anio)->where('mes', '=', $mes)->exists();
                // return $existeAbono;
                // return $abono;
                if ($existeAbono) {
                    $abono = PDV_ABONOS::where('DNI GANADOR', $dni)->where('año', '=', $anio)->where('mes', '=', $mes)->get();
                    // $abono = PDV_ABONOS::where('DNI RESP', $dni)->where('año', '=', $anio)->where('mes', '=', $mes)->get();
                    // $abono->makeHidden(['DNI ']);
                    // return $abono;
                    $abono = $abono->map(function ($item) {
                        return [
                            // "id" => $item->id,
                            "año" => $item->AÑO,
                            "mes" => $item->MES,
                            "detalle" => $item->DETALLE,
                            // "estado" => $item->{"STATUS DEL ABONO"},
                            "estado" => $item->{"MÉTODO DE PAGO"},
                            "total" => (float)$item->{"BONO TOTAL"},
                            "fecha" => $item->{"FECHAS_ ABONO"},
                            "dniGanador" => $item->{"DNI GANADOR"},
                        ];
                    });
                    return response()->json(["status" => Response::HTTP_OK, "message" => "Historial de Abono", "data" => $abono], Response::HTTP_OK);
                    // return response()->json(["status" => Response::HTTP_OK, "message" => "No hay historial de Abono", "data" => []], Response::HTTP_OK);
                } else {
                    return response()->json(["status" => Response::HTTP_OK, "message" => "No hay historial de Abono", "data" => []], Response::HTTP_OK);
                }
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function getAbonoMm($dni, $anio, $mes)
    {
        try {
            $existeAbono = PDV_ABONOS::where('DNI GANADOR', $dni)->where('año', '=', $anio)->where('mes', '=', $mes)->exists();
            if ($existeAbono) {
                $abono = PDV_ABONOS::where('DNI GANADOR', $dni)->where('año', '=', $anio)->where('mes', '=', $mes)->get();
                $abono->makeHidden(['DNI ']);
                $abono = $abono->map(function ($item) {
                    return [
                        "año" => $item->AÑO,
                        "mes" => $item->MES,
                        "detalle" => $item->DETALLE,
                        "estado" => $item->{"MÉTODO DE PAGO"},
                        "total" => (float)$item->{"BONO TOTAL"},
                        "fecha" => $item->{"FECHAS_ ABONO"},
                        "dniGanador" => $item->{"DNI GANADOR"},
                    ];
                });
                return response()->json(["status" => Response::HTTP_OK, "message" => "Historial de Abono", "data" => $abono], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay historial de Abono", "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function getDataMM($dni, $anio, $mes)
    {
        try {
            // $existeAvance = PDV_AVANCES_DIARIOS_MM::where('DNI_VENDEDOR', $dni)->where('año', '=', $anio)->where('mes', '=', $mes)->exists();
            $existeAvance = PDV_AVANCES_DIARIOS_MM::where('DNI_VENDEDOR', $dni)->where('año', '=', $anio)->exists();
            if ($existeAvance) {
                // $infoVendedor = PDV_AVANCES_DIARIOS_MM::where('DNI_VENDEDOR', $dni)->where('año', '=', $anio)->where('mes', '=', $mes)->firstOrFail();
                $infoVendedor = PDV_AVANCES_DIARIOS_MM::where('DNI_VENDEDOR', $dni)->where('año', '=', $anio)->orderByDesc('mes')->firstOrFail();
                $infoVendedor = [
                    "zonal" => $infoVendedor->ZONAL,
                    "dni_vendedor" => $infoVendedor->{'DNI_VENDEDOR'},
                    "nombre_vendedor" => $infoVendedor->{'NOMBRE_VENDEDOR'},
                    "fecha_inicio" => $infoVendedor->{'FECHA INICIO'},
                    "fecha_cierre" => $infoVendedor->{'FECHA CIERRE'},
                    "dni_responsable" => $infoVendedor->{'DNI_RESPONSABLE'},
                    "supervisor" => $infoVendedor->{'NOMBRE_SUPERVISOR'},
                    "proyecto" => $infoVendedor->PROYECTO,
                    "prepago_total_1" => (float)$infoVendedor->{'PREPAGO TOTAL'},
                    "porta_pre_1" => (float)$infoVendedor->{'PORTA PRE'},
                    "recarga_total_1" => (float)$infoVendedor->{'RECARGAS TOTAL'},
                    "porta_post_1" => (float)$infoVendedor->{'PORTA POST'},
                    "rango_pre_total_2" => $infoVendedor->{'RANGO PRE TOTAL'},
                    "rango_porta_pre_2" => $infoVendedor->{'RANGO PORTA PRE'},
                    "rango_recarga_2" => $infoVendedor->{'RANGO RECARGAS'},
                    "rango_final_2" => $infoVendedor->{'RANGO FINAL'},
                    "bono_pre_3" => (float)$infoVendedor->{'BONO PRE'},
                    "bono_porta_post_3" => (float)$infoVendedor->{'BONO PORTA POST'},
                    "bono_adicional_porta_post_3" => (float)$infoVendedor->{'BONO ADICIONAL PORTA POST'},
                    "bono_total_3" => (float)$infoVendedor->{'BONO TOTAL'},
                    "raecarga_finaciada_3" => (float)$infoVendedor->{'RECARGA FINANCIADA'},
                    "chips_financiados_3" => (float)$infoVendedor->{'CHIPS FINANCIADO'},
                    "total_financiado_3" => (float)$infoVendedor->{'TOTAL FINANCIADO'},
                    "bono_total_a_pagar_3" => (float)$infoVendedor->{'BONO TOTAL A PAGAR'}
                ];
                return response()->json(["status" => Response::HTTP_OK, "message" => "Información", "data" => $infoVendedor], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay información", "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    function getPayment($dni, $anio, $mes)
    {
        try {
            $spPayment = DB::select("exec spCalculoPaymentAll ?,?,?,?,?", [$dni, $anio, $mes, 1, 2]);
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
                    // 
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
                    "levelUser" => 0.00,
                    "cantidadRecarga" => 0.00,
                    "bonoDevolucionChips" => 0.00,
                    "precioUniCalidadAdi" => 0.00,
                    "cantidadCalidad" => 0.00,
                    "bonoCalidad" => 0.00,
                    "zonal" => "",
                ];

                foreach ($spPayment as $item) {
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
                    // 
                    $acumuladorPayment["faltaVenta"] = (float) $item->faltaVenta;
                    $acumuladorPayment["cantidadPortaPre"] = (float) $item->cantidadPortaPre;
                    $acumuladorPayment["precioUniPortaPre"] = (float) $item->precioUniPortaPre;
                    $acumuladorPayment["cantidadAltaPost"] = (float) $item->cantidadAltaPost;
                    $acumuladorPayment["precioUniAltaPost"] = (float) $item->precioUniAltaPost;
                    $acumuladorPayment["cantidadPortaPostOPost"] = (float) $item->cantidadPortaPostOPost;
                    $acumuladorPayment["precioPortaPostOPost"] = (float) $item->precioPortaPostOPost;
                    $acumuladorPayment["cantidadPortaPostOPre"] = (float) $item->cantidadPortaPostOPre;
                    $acumuladorPayment["precioPortaPostOPre"] = (float) $item->precioPortaPostOPre;
                    $acumuladorPayment["precioUniSchema"] = (float) $item->precioUniSchema;
                    $acumuladorPayment["levelUser"] = (float) $item->levelUser;
                    $acumuladorPayment["cantidadRecarga"] = (float) $item->cantidadRecarga;
                    $acumuladorPayment["cantidadRecarga"] = (float) $item->cantidadRecarga;
                    $acumuladorPayment["ventaTotal"] = (float) $item->bonoChips;
                    $acumuladorPayment["bonoDevolucionChips"] = (float) $item->bonoDevolucionChips;
                    $acumuladorPayment["precioUniCalidadAdi"] = property_exists($item, 'precioUniCalidadAdi') ? (float) $item->precioUniCalidadAdi : 0;
                    $acumuladorPayment["cantidadCalidad"] = property_exists($item, 'cantidadCalidad') ? (float) $item->cantidadCalidad : 0;
                    $acumuladorPayment["bonoCalidad"] = property_exists($item, 'bonoCalidad') ? (float) $item->bonoCalidad : 0;
                    $acumuladorPayment["zonal"] = property_exists($item, 'zonal') ? $item->zonal : "";
                }
                // $payment= $spPayment;
                $payment = $acumuladorPayment;
                return response()->json(["status" => Response::HTTP_OK, "message" => "Hay pago para el vendedor Pdv del mes de " . $mes, "data" => $payment], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay pagos ", "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    function getIncidencia($dni, $anio, $mes)
    {
        try {
            $existIncidencia = Incidencia::exists();
            if ($existIncidencia) {
                $incidencia = DB::select('exec dbo.spViewInfoIncidencia ?,?,?', [$dni, $anio, $mes]);
                $dataIncidencia = [];
                if ($incidencia) {
                    foreach ($incidencia as $item) {
                        $dataIncidencia[] = [
                            "id" => $item->id,
                            "dni_incidencia" => $item->dni_incidencia,
                            "fechaReporte" => $item->{'FECHA ENVIO JEFE'},
                            "errorReportado" => $item->{'ERROR'},
                            "statusIncidencia" => $item->{'Status de Incidencia'},
                            "seSupero" => $item->{'SE SUPERO SI/NO'} ?? "",
                            "tipoDni" => $item->dni_enrolado,
                            "dniResponsable" => 0,
                        ];
                    }
                    return response()->json(["status" => Response::HTTP_OK, "message" => "Información de incidencia", "data" => $dataIncidencia], Response::HTTP_OK);
                } else {
                    return response()->json(["status" => Response::HTTP_OK, "message" => "No se encontro la Información de la incidencia para el usuario " . $dni, "data" => []], Response::HTTP_OK);
                }
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay información de incidencia", "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
