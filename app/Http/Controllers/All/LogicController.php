<?php

namespace App\Http\Controllers\All;

use App\Http\Controllers\Controller;
use App\Models\Incidencia;
use App\Models\PDV_ABONOS;
use App\Models\PDV_AVANCES_DIARIOS_MM;
use App\Models\PDV_VENTAS_BONOS;
use App\Models\PDV_OUT_ESQUEMA_RESUMEN;
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
            $existeAvance = VI_FLYERS::where('DNI_Responsable', $dni)
                ->whereRaw('? BETWEEN MONTH(fecha_inicio) AND MONTH(fecha_fin)', [$mes])
                ->where(function ($query) use ($anio) {
                    $query->whereYear('fecha_inicio', $anio)
                        ->orWhereYear('fecha_fin', $anio);
                })
                ->exists();
            if (!$existeAvance) {
                // Primero: buscar por año y mes específicos
                $getDniResp = DB::select("SELECT TOP 1 DNI_RESPONSABLE FROM dbo.PDV_OUT_FUNNEL WHERE DNI_VENDEDOR = ? AND SOCIO = 'JS MARKET' AND year(fecha) = ? AND month(fecha) = ?", [$dni, $anio, $mes]);

                // Si no encuentra resultados para el mes/año, buscar la fecha más reciente
                if (empty($getDniResp)) {
                    // Obtener la fecha máxima en consulta separada
                    $maxFecha = DB::select("SELECT MAX(fecha) as max_fecha FROM dbo.PDV_OUT_FUNNEL WHERE DNI_VENDEDOR = ? AND SOCIO = 'JS MARKET'", [$dni]);

                    if (!empty($maxFecha) && $maxFecha[0]->max_fecha) {
                        // Usar la fecha máxima para obtener el DNI_RESPONSABLE
                        $getDniResp = DB::select("SELECT TOP 1 DNI_RESPONSABLE FROM dbo.PDV_OUT_FUNNEL WHERE DNI_VENDEDOR = ? AND SOCIO = 'JS MARKET' AND fecha = ?", [$dni, $maxFecha[0]->max_fecha]);
                    }
                }

                $dni = $getDniResp[0]->DNI_RESPONSABLE ?? 0;
            }
            $avances = VI_FLYERS::where('DNI_Responsable', $dni)->whereRaw('? BETWEEN MONTH(fecha_inicio) AND MONTH(fecha_fin)', [$mes])->orderBy('fecha_fin', 'asc')->get();
            if (!$avances->isEmpty()) {
                $agrupados = $avances->groupBy('tipoImg');
                $agrupados->each(function ($items) {
                    foreach ($items as $item) {
                        $item->foto_esquema = env('APP_DOMAIN') . '/storage/img/' . $item->foto_esquema;
                    }
                });
                return response()->json(["status" => Response::HTTP_OK, "message" => "Fyers", "data" => $agrupados], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay fyers para el dni " . $dni, "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function getAbono($dni, $anio, $mes)
    {
        try {
            $abono = PDV_ABONOS::where('DNI RESP', $dni)->where('año', '=', $anio)->where('mes', '=', $mes)->get();
            $flagAbono = false;
            if (!$abono->isEmpty()) {
                $flagAbono = true;
            } else {
                $abono = PDV_ABONOS::where('DNI GANADOR', $dni)->where('año', '=', $anio)->where('mes', '=', $mes)->get();
                !$abono->isEmpty() ? $flagAbono = true : $flagAbono = false;
            }
            if ($flagAbono) {
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
            // Lógica de selección: usar optimizado para diciembre 2025 en adelante
            // Para meses anteriores (noviembre 2025 o antes), usar el SP original
            $usarOptimizado = ($anio > 2025) || ($anio == 2025 && $mes >= 12);

            if ($usarOptimizado) {
                // Usar el endpoint optimizado que consulta PDV_OUT_ESQUEMA_RESUMEN
                return $this->getPaymentOptimized($dni, $anio, $mes);
            }

            // Respuesta vacía con defaults para evitar null/undefined en el frontend
            $emptyPayment = [
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
                "nivel_rango" => 0,
                // Nuevos campos para bonos por rango
                "rango_mes_anterior" => 0,
                "tipo_bono" => null,
                "bono_rango" => 0.00,
                "ratio_min_requerido" => 0.00,
                "adicional_post_unitario" => 0.00,
            ];

            // Para meses anteriores a diciembre 2025, usar el SP original
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
                    "nivel_rango" => 0,
                    // Nuevos campos para bonos por rango
                    "rango_mes_anterior" => 0,
                    "tipo_bono" => null,
                    "bono_rango" => 0.00,
                    "ratio_min_requerido" => 0.00,
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
                    $acumuladorPayment["nivel_rango"] = property_exists($item, 'nivel_rango') ? (int) $item->nivel_rango : 0;
                    // Nuevos campos para bonos por rango
                    $acumuladorPayment["rango_mes_anterior"] = property_exists($item, 'rango_mes_anterior') ? (int) $item->rango_mes_anterior : 0;
                    $acumuladorPayment["tipo_bono"] = property_exists($item, 'tipo_bono') ? $item->tipo_bono : null;
                    $acumuladorPayment["bono_rango"] = property_exists($item, 'bono_rango') ? (float) $item->bono_rango : 0.00;
                    $acumuladorPayment["ratio_min_requerido"] = property_exists($item, 'ratio_min_requerido') ? (float) $item->ratio_min_requerido : 0.00;
                }
                // $payment= $spPayment;
                $payment = $acumuladorPayment;
                return response()->json(["status" => Response::HTTP_OK, "message" => "Hay pago para el vendedor Pdv del mes de " . $mes, "data" => $payment], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay pagos ", "data" => $emptyPayment], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    /**
     * Nueva función optimizada que consulta la tabla PDV_OUT_ESQUEMA_RESUMEN
     * Mantiene la misma estructura de respuesta que getPayment para compatibilidad con el frontend
     *
     * NOTA: Este método es público para permitir pruebas directas.
     * El método getPayment() lo utiliza internamente para diciembre 2025 en adelante.
     * Para meses anteriores (noviembre 2025 o antes), getPayment() usa el SP original.
     */
    function getPaymentOptimized($dni, $anio, $mes)
    {
        try {
            // Respuesta vacía con defaults para evitar null/undefined en el frontend
            $emptyPayment = [
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
                "nivel_rango" => 0,
                // Nuevos campos para bonos por rango
                "rango_mes_anterior" => 0,
                "tipo_bono" => null,
                "bono_rango" => 0.00,
                "ratio_min_requerido" => 0.00,
            ];

            // Consultar directamente la tabla PDV_OUT_ESQUEMA_RESUMEN
            $paymentData = PDV_OUT_ESQUEMA_RESUMEN::where('DNI_RESPONSABLE', $dni)
                ->where('AÑO', $anio)
                ->where('MES', $mes)
                ->first();

            if ($paymentData) {
                // Valores base para cálculos
                $ventaAvancePrepago   = (float) $paymentData->VENTA_AVANCE_PREPAGO;
                $ventaPrepagoLimitada = (float) $paymentData->VentaPrepagoLimitada;
                $bonoUnitarioEquipo   = (float) $paymentData->BONO_UNITARIO_EQUIPO;
                $totalRecargas        = (float) $paymentData->TOTAL_RECARGAS;
                $totalVCalidad        = (float) $paymentData->TOTAL_VCALIDAD;
                $maxVenta             = (float) $paymentData->MAX_VENTA;

                // Mismo formato que getPayment
                $payment = [
                    // Bonos principales
                    "bonoPre"            => $bonoUnitarioEquipo * $ventaPrepagoLimitada,
                    "bonoRecargaPre"     => (float) $paymentData->bonoRecargaPre,
                    "bonoPortaPre"       => (float) $paymentData->bonoPortaPre,
                    "bonoAltaPost"       => 0.00, // Si existe responsable (@existResp = 1), bonoAltaPost = 0
                    "bonoPortaPostOPost" => (float) $paymentData->bonoPortaPostOPost,
                    "bonoPortaPostOPre"  => (float) $paymentData->bonoPortaPostOPre,
                    "bonoChips"          => (float) $paymentData->bonoChips,
                    "bonoTotalEfectivo"  => (float) ($paymentData->bonoTotalEfectivo ?? 0),
                    "bonoTotal"          => (float) ($paymentData->bonoTotal ?? 0),
                    "ventaTotal"         => $ventaAvancePrepago,

                    // Detalle y métricas
                    "faltaVenta"         => 0.00, // Valor fijo del SP original (spCalculoPayment_12 línea 152)
                    "cantidadPortaPre"   => (float) $paymentData->cantPrepagoPorta,
                    "precioUniPortaPre"  => 4.00,
                    "cantidadAltaPost"   => (float) $paymentData->cantidadAltaPost,
                    "precioUniAltaPost"  => 0.00, // Si existe responsable (@existResp = 1), precioUniAltaPost = 0
                    "cantidadPortaPostOPost" => (float) $paymentData->cantidadPortaPostOPost,
                    "precioPortaPostOPost"   => 35.00,
                    "cantidadPortaPostOPre"  => (float) $paymentData->cantidadPortaPostOPre,
                    "precioPortaPostOPre"    => 20.00,
                    "precioUniSchema"        => $bonoUnitarioEquipo,
                    "levelUser"              => 2.00, // Todos PDV REGULAR
                    "cantidadRecarga"        => $totalRecargas,
                    "bonoDevolucionChips"    => (float) $paymentData->bonoDevolucionChips,
                    "precioUniCalidadAdi"    => (float) $paymentData->precioUniCalidadAdi,
                    "cantidadCalidad"        => $totalVCalidad,
                    "bonoCalidad"            => (float) $paymentData->bonoCalidad,
                    "zonal"                  => $paymentData->ZONAL ?? "",

                    // Bonos por rango
                    "nivel_rango"        => (int) $paymentData->nivel_rango,
                    "rango_mes_anterior" => (int) $paymentData->RANGO_MES_ANTERIOR,
                    "tipo_bono"          => $paymentData->tipo_bono,
                    "bono_rango"         => (float) $paymentData->bono_rango,
                    "ratio_min_requerido" => (float) $paymentData->ratio_min_requerido,
                    "adicional_post_unitario" => (float) ($paymentData->adicional_post_unitario ?? 0),
                ];

                return response()->json([
                    "status"  => Response::HTTP_OK,
                    "message" => "Hay pago para el vendedor PDV del mes de " . $mes,
                    "data"    => $payment
                ], Response::HTTP_OK);
            } else {
                return response()->json([
                    "status"  => Response::HTTP_OK,
                    "message" => "No hay pagos",
                    "data"    => $emptyPayment
                ], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json([
                "status"  => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
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

    /**
     * Obtener la fecha máxima de actualización del esquema PDV
     * Consulta el parámetro tipo=9 que contiene la fecha máxima común calculada por sp_ActualizarEsquemaPDV
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function getFechaMaximaEsquemaPDV()
    {
        try {
            // Obtener el parámetro tipo=9 que contiene la fecha máxima común
            $parametro = DB::select('
                SELECT valor, comentario
                FROM PORTAL_COMERCIAL.dbo.parametros
                WHERE tipo = 9 AND [level] = 0
            ');

            if ($parametro && count($parametro) > 0) {
                $fechaMaxima = $parametro[0]->valor;
                $comentario = $parametro[0]->comentario ?? '';

                // Extraer la fecha del esquema PDV del comentario
                // Formato esperado: "... Actualizado: YYYY-MM-DD"
                $fechaEsquemaPDV = null;
                if (!empty($comentario) && preg_match('/Actualizado:\s*(\d{4}-\d{2}-\d{2})/', $comentario, $matches)) {
                    $fechaEsquemaPDV = $matches[1];
                }

                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "Fechas obtenidas correctamente",
                    "data" => [
                        "fecha_maxima_datos" => $fechaMaxima,
                        "fecha_esquema_pdv" => $fechaEsquemaPDV
                    ]
                ], Response::HTTP_OK);
            } else {
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "No se encontró información de fechas",
                    "data" => [
                        "fecha_maxima_datos" => null,
                        "fecha_esquema_pdv" => null
                    ]
                ], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => "Error al obtener las fechas: " . $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    /**
     * Ejecutar el stored procedure sp_ActualizarEsquemaPDV
     * Actualiza el esquema PDV para un año y mes específicos
     *
     * @param int $anio Año del período a actualizar
     * @param int $mes Mes del período a actualizar
     * @return \Illuminate\Http\JsonResponse
     */
    public function ejecutarActualizarEsquemaPDV($anio, $mes)
    {
        try {
            // Validar parámetros
            if (!is_numeric($anio) || !is_numeric($mes) || $mes < 1 || $mes > 12) {
                return response()->json([
                    "status" => Response::HTTP_BAD_REQUEST,
                    "message" => "Parámetros inválidos. Año y mes deben ser numéricos, mes entre 1 y 12."
                ], Response::HTTP_BAD_REQUEST);
            }

            // Ejecutar el stored procedure
            $resultado = DB::select('EXEC dbo.sp_ActualizarEsquemaPDV ?, ?', [$anio, $mes]);

            if ($resultado && count($resultado) > 0) {
                $data = $resultado[0];
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "Esquema PDV actualizado correctamente",
                    "data" => [
                        "cantidad_registros" => (int) $data->cantidad_registros,
                        "año" => (int) $anio,
                        "mes" => (int) $mes
                    ]
                ], Response::HTTP_OK);
            } else {
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "El stored procedure se ejecutó pero no devolvió resultados",
                    "data" => []
                ], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => "Error al ejecutar el stored procedure: " . $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        }
    }
}
