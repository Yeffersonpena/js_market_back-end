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
                    $infoVendedor=[
                            "zonal" => $infoVendedor->ZONAL,
                            "dni_responsable" => $infoVendedor->{'DNI_RESPONSABLE'},
                            "dni_vendedor" => $infoVendedor->{'DNI_VENDEDOR'},
                            "nombre_vendedor" => $infoVendedor->{'NOMBRE_VENDEDOR'},
                            "supervisor" => $infoVendedor->{'NOMBRE_SUPERVISOR'},
                            "celularVendedor"=> $infoVendedor->CELULAR_VENDEDOR !=0 ? $infoVendedor->CELULAR_VENDEDOR: "" ,
                            "proyecto" => $infoVendedor->{'ACCION_2'},
                            "cuotaPrepago"=>(float)$infoVendedor->CUOTA_PREPAGO,
                            "recargasTotales"=>(float)$infoVendedor->RECARGA_TOTAL,
                            "avancePrepago"=>(float)$infoVendedor->{'AVANCE PREPAGO'},
                            "fecha_inicio" => $infoVendedor->FECHA_INICIO,
                            "fecha_cierre"=> $infoVendedor->ULTIMA_FECHA,
                            "cantidadDayVentaPre"=> (float)$infoVendedor->cantidaDayConVentasPre,
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
                    // $spPayment=DB::select("exec spCalculoPaymentMM ?,?,?", [$dni, $anio, $mes]);
                    $spPayment=DB::select("exec spCalculoPaymentAll ?,?,?,?", [$dni, $anio, $mes, 3]);
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

            public function getAvanceQuinDiario($dni, $anio, $mes)
            {
                try {
                $existeAvance = DB::select( "EXEC spView_Avances_Diarios_Quincenal_MM ?, ?, ?", [$dni, $anio, $mes]);
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
