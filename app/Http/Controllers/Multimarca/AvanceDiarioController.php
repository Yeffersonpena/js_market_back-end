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
                $existeAvance = DB::select( "EXEC spViewInfoVendedorMM ?, ?, ?", [$dni, $anio, $mes]);
                if($existeAvance){
                    $infoVendedor=$existeAvance[0];
                    // return $infoVendedor;
                    // $dateUpdateCalidad = Carbon::now()->subDays(4)->toDateString();
                    $infoVendedor=[
                            "zonal" => $infoVendedor->ZONAL,
                            "dni_responsable" => $infoVendedor->{'DNI_RESPONSABLE'},
                            "dni_vendedor" => $infoVendedor->{'DNI_VENDEDOR'},
                            "dni_supervisor" => $infoVendedor->{'DNI SUPERVISOR'},
                            "nombre_vendedor" => $infoVendedor->{'NOMBRE_VENDEDOR'},
                            "supervisor" => $infoVendedor->{'NOMBRE_SUPERVISOR'},
                            // "celularVendedor"=> $infoVendedor->CELULAR_VENDEDOR !=0 ? $infoVendedor->CELULAR_VENDEDOR: "" ,
                            "celularSupervisor"=> $infoVendedor->{'NUM SUPERVISOR'} !=0 ? $infoVendedor->{'NUM SUPERVISOR'}: "" ,
                            "celularRecargador"=> $infoVendedor->NUMERO_RECARGADOR !=0 ? $infoVendedor->NUMERO_RECARGADOR: "" ,
                            // "celular"=> $infoVendedor->CELULAR_VENDEDOR !=0 ? $infoVendedor->CELULAR_VENDEDOR: "" ,
                            "proyecto" => $infoVendedor->{'ACCION_2'},
                            "cuotaPrepago"=>(float)$infoVendedor->CUOTA_PREPAGO,
                            "recargasTotales"=>(float)$infoVendedor->RECARGA_TOTAL,
                            "avancePrepago"=>(float)$infoVendedor->{'AVANCE PREPAGO'},
                            "fecha_inicio" => $infoVendedor->FECHA_INICIO,
                            "fecha_cierre"=> $infoVendedor->ULTIMA_FECHA,
                            "cantidadDayVentaPre"=> (float)$infoVendedor->cantidaDayConVentasPre,
                            "minRatio"=> (float)$infoVendedor->minRatio,
                            "maxRatio"=> (float)$infoVendedor->maxRatio,
                            "entidadBancaria" => $infoVendedor->{'ENTIDAD BANCARIA MM'},
                            "cctaBancario" => $infoVendedor->{'CCTA BANCARIA MM'},
                            "levelCalidad" =>(float)$infoVendedor->{'CALIDAD_CLUSTER'} ?? 0, 
                            "infoUpdateCalidad" => $infoVendedor->{'DATE_UPDATE_CALIDAD'} ?? 0, 
                        ];
                return response()->json(["status" => Response::HTTP_OK, "message" => "Información", "data"=>$infoVendedor ], Response::HTTP_OK);
                } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay información","data"=>[]], Response::HTTP_OK);
                }
        } catch (\Exception $ex) {
                return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
        }
        function getPayment($dni, $anio, $mes, $typeQuincena){
                try{
                    if(!$typeQuincena){
                        $getPayment=DB::select('EXEC spResumenGanaciaCampaña_MM_Payment @dni=?, @año=?, @mes=?', [$dni, $anio, $mes]);
                        if($getPayment){
                            $payment=collect($getPayment)->map(function($item){
                                return [
                                        "dni_vendedor"=> $item->dni_vendedor?? '',
                                        "ventasLog"=>(float) $item->ventasLog?? 0.00,
                                        "cantidadCalidad"=>(float) $item->cantidadCalidad?? 0.00,
                                        "pagoUniCalidad"=>(float) $item->pagoUniCalidad?? 0.00,
                                        "mes_6"=>(float)$item->mes_6 ?? 0.00,
                                        "mes_7"=>(float)$item->mes_7 ?? 0.00,
                                        "mes_8"=>(float)$item->mes_8 ?? 0.00,
                                        "mes_9"=>(float)$item->mes_9 ?? 0.00,
                                        "mes_10"=>(float)$item->mes_10 ?? 0.00,
                                        "mes_11"=>(float)$item->mes_11 ?? 0.00,
                                        "bonoRecargaNxVendedor"=> (float) $item->bonoRecargaNxVendedor ?? 0.00,
                                        "bonoCalidad"=> (float) $item->bonoCalidad ?? 0.00,
                                        "bonoTotal"=> (float) $item->bonoTotal ?? 0.00
                                ];
                            });
                            // return $getPayment;
                            // return $dataPament;
                            return response()->json(["status" => Response::HTTP_OK, "message" => "Hay pago para el vendedor Multimarca", "data" => $payment[0]], Response::HTTP_OK);
                        } else {
                            $paymentCalidad=DB::select("select count(*) as cantidadCalidad from dbo.PDV_OUT_FUNNEL where DNI_VENDEDOR=? and YEAR(fecha)=? and month(fecha)=? and CALIDAD_CLUSTER in ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')", [$dni, $anio, $mes]);
                            $paymentVentaLog=DB::select("select count(*) as ventasLog from dbo.tbl_ventas_prepago_MM where DNI_VENDEDOR=? and YEAR(fecha)=? and month(fecha)=?", [$dni, $anio, $mes]);
                            // $paymentRecarga=DB::select("select sum(RECARGA_TOTAL) FROM dbo.PDV_OUT_FUNNEL_RESUMEN_MM where DNI_VENDEDOR=? and ANIO=? and MES=?", [$dni, $anio, $mes]);
                            // $paymentRecarga=0;
                            // return $paymentVentaLog;
                            // return (object)[
                            //           'calidad' => $paymentCalidad->cantidadCalidad ?? 0,
                            //             'ventas' => $paymentVentaLog->ventasLog ?? 0,
                            //             // 'recarga_total' => $paymentRecarga->total ?? 0,
                            // ];
                            // return $paymentC}alidad;
                            	// select @ventaLog=count(*) from dbo.tbl_ventas_prepago_MM where dni_vendedor=@dni AND YEAR(fecha)=@año and month(fecha)=@mes;
                                // select @recargaTotal =sum(RECARGA_TOTAL) FROM dbo.PDV_OUT_FUNNEL_RESUMEN_MM WHERE DNI_VENDEDOR = @dni and ANIO=@año and MES=@mes 
                            // select @cantidadCalidad=count(*) from dbo.PDV_OUT_FUNNEL where DNI_VENDEDOR=@dni and YEAR(fecha)=@año and month(fecha)=@mes and CALIDAD_CLUSTER in ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')
                            // set @gananciaCalidad=@cantidadCalidad *10;
                            // return $paymentCalidad[0];
                            $noFountPayment=[
                                        "dni_vendedor"=> $dni,
                                        "ventasLog"=>$paymentVentaLog[0]->ventasLog ?? 0,
                                        "cantidadCalidad"=>$paymentCalidad[0]->cantidadCalidad ?? 0,
                                        "pagoUniCalidad"=>10.00,
                                        "mes_6"=>0.00,
                                        "mes_7"=>0.00,
                                        "mes_8"=>0.00,
                                        "mes_9"=>0.00,
                                        "mes_10"=>0.00,
                                        "mes_11"=>0.00,
                                        "bonoRecargaNxVendedor"=> 0.00,
                                        "bonoCalidad"=> $paymentCalidad[0]->cantidadCalidad * 10 ?? 0.00,
                                        "bonoTotal"=>$paymentCalidad[0]->cantidadCalidad * 10 ?? 0.00
                            ];
                            return response()->json(["status" => Response::HTTP_OK, "message" => "No hay pagos ", "data" => $noFountPayment], Response::HTTP_OK);
                        }
                    }
                    $spPayment=DB::select("exec spCalculoPaymentAll ?,?,?,?,?", [$dni, $anio, $mes, $typeQuincena, 3]);
                    // return $spPayment;
                    if ($spPayment) {
                            $acumuladorPayment = [
                                "bonoPre" => 0.0,
                                "bonoRecargaPre" => 0.0,
                                "bonoPortaPre" => 0.0,
                                "bonoAltaPost" => 0.0,
                                "bonoPortaPostOPost" => 0.0,
                                "bonoPortaPostOPre" => 0.0,
                                "bonoChips"=>0.00,
                                "bonoTotalEfectivo"=>0.00,
                                "bonoTotal"=>0.00,
                                "ventaTotal"=>0.00,
                                // "precioUni"=>0.00,
                                // 
                                // "cantidadDayVentaPre"=>0.00,
                                "faltaVenta"=>0.00,
                                "cantidadPortaPre"=>0.00,
                                "precioUniPortaPre"=>0.00,
                                "cantidadAltaPost"=>0.00,
                                "precioUniAltaPost"=>0.00,
                                "cantidadPortaPostOPost"=>0.00,
                                "precioPortaPostOPost"=>0.00,
                                "cantidadPortaPostOPre"=>0.00,
                                "precioPortaPostOPre"=>0.00,
                                "precioUniSchema"=>0.00,
                                "precioUniRecarga"=>0.00,
                                "cantidadRecarga"=>0.00,
                                "recuerdaVentaPostCost"=>0.00,
                                "cantidadVenta"=>0.00,
                                
                                "cantidadRecargaPost"=>0.00,
                                "bonoUniRecargaPost"=>0.00,
                                "bonoTotalRecargaPost"=>0.00,
                                "cantidadPostSchemaPost"=>0.00,
                                "precioUniPostSchema"=>0.00,
                                "cantidadChipDevolucion"=>0.00,
                                "financiamientoSaldo"=>0.00,
                                "financiamientoChip"=>0.00,
                                "financiamientoTotal"=>0.00,

                                "nivelRatio" =>0.00,
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
                                $acumuladorPayment["precioUniPortaPre"] =(float) $item->precioUniPortaPre;
                                $acumuladorPayment["cantidadAltaPost"] =(float) $item->cantidadAltaPost;
                                $acumuladorPayment["precioUniAltaPost"] =(float) $item->precioUniAltaPost;
                                $acumuladorPayment["cantidadPortaPostOPost"] =(float) $item->cantidadPortaPostOPost;
                                $acumuladorPayment["precioPortaPostOPost"] =(float) $item->precioPortaPostOPost;
                                $acumuladorPayment["cantidadPortaPostOPre"] =(float) $item->cantidadPortaPostOPre;
                                $acumuladorPayment["precioPortaPostOPre"] =(float) $item->precioPortaPostOPre;
                                $acumuladorPayment["precioUniSchema"] =(float) $item->precioUniPortaPre;//precioUniSchema; unitaro del tabla esquema
                                $acumuladorPayment["precioUniRecarga"] =(float) $item->precioUniRecarga;
                                $acumuladorPayment["cantidadRecarga"] =(float) $item->cantidadRecarga;
                                $acumuladorPayment["cantidadRecarga"] =(float) $item->cantidadRecarga;
                                $acumuladorPayment["ventaTotal"] =(float) $item->bonoChips;

                                $acumuladorPayment["cantidadVenta"] =(float) $item->cantidadVenta;
                                
                                $acumuladorPayment["recuerdaVentaPostCost"] =(float) $item->recuerdaVentaPostCost;
                                $acumuladorPayment["cantidadRecargaPost"] =(float) $item->cantidadRecargaPost;
                                $acumuladorPayment["bonoUniRecargaPost"] =(float) $item->bonoUniRecargaPost;
                                $acumuladorPayment["bonoTotalRecargaPost"] =(float) $item->bonoTotalRecargaPost;
                                $acumuladorPayment["cantidadPostSchemaPost"] =(float) $item->cantidadPostSchemaPost;
                                $acumuladorPayment["precioUniPostSchema"] =(float) $item->precioUniPostSchema;
                                $acumuladorPayment["cantidadChipDevolucion"] =(float) $item->cantidadChipDevolucion;
                                $acumuladorPayment["financiamientoSaldo"] =(float) $item->financiamientoSaldo;
                                $acumuladorPayment["financiamientoChip"] =(float) $item->financiamientoChip;
                                $acumuladorPayment["financiamientoTotal"] =(float) $item->financiamiento;
                                $acumuladorPayment["nivelRatio"] =(float) $item->nivelRatio;
                                $acumuladorPayment["minRatio"] =(float) $item->minRatio;
                                $acumuladorPayment["maxRatio"] =(float) $item->maxRatio;
                                $acumuladorPayment["diaMinVenta"] =(float) $item->diaMinVenta;
                            }
                            $payment= $acumuladorPayment;
                        return response()->json(["status" => Response::HTTP_OK, "message" => "Hay pago para el vendedor Multimarca", "data" => $payment], Response::HTTP_OK);
                    } else {
                        return response()->json(["status" => Response::HTTP_OK, "message" => "No hay pagos ", "data" => []], Response::HTTP_OK);
                    }
                }catch(\Exception $ex){
                    return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
                }
            }

            public function getAvanceQuinDiario($dni, $anio, $mes, $typeQuincena)
            {
                try {
                    $getDay = Carbon::now()->day;
                    // return $getDay;
                    $getDay== 16?$typeQuincena=1:2;
                $existeAvance = DB::select( "EXEC spView_Avances_Diarios_Quincenal_MM ?, ?, ?, ?", [$dni, $anio, $mes, $typeQuincena]);
                    if ($existeAvance) {
                        $avances=$existeAvance;
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
                $existeAvance = DB::select( "EXEC spView_Avances_Diarios_MM ?, ?, ?", [$dni, $anio, $mes]);
                    if ($existeAvance) {
                        $avances=$existeAvance;
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
