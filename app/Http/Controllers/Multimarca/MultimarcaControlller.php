<?php

namespace App\Http\Controllers\Multimarca;

use App\Http\Controllers\Controller;
use App\Models\Incidencia;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class MultimarcaControlller extends Controller
{
    function getIncidencia($dni, $anio, $mes){
        try{
            $existIncidencia=Incidencia::exists();
            if($existIncidencia){
                $incidencia=Incidencia::where('dni_incidencia','=',$dni)->exists();
                // $incidencia=Incidencia::where('dni_enrolado','=',$dni)->exists();
                    if($incidencia){
                        // $getIncidencia=Incidencia::where('dni_enrolado','=',$dni)->get();
                        $getIncidencia=Incidencia::where('dni_incidencia','=',$dni)->get();
                        $dataIncidencia=$getIncidencia->map(function ($item){
                            return [
                            "id"=> $item->id,
                            "dni_incidencia"=> $item->dni_incidencia,
                            "fechaReporte"=> $item->{'FECHA ENVIO JEFE'},
                            "errorReportado"=> $item->{'ERROR'},
                            "statusIncidencia"=> $item->{'Status de Incidencia'},
                            "seSupero"=> $item->{'SE SUPERO SI/NO'} ?? "",
                            "tipoDni"=> $item->{'dni_enrolado'},
                            "dniResponsable"=>0,
                        ];
                    });
                    return response()->json(["status" => Response::HTTP_OK, "message" => "Información de incidencia", "data" => $dataIncidencia], Response::HTTP_OK);
                }else{
                    return response()->json(["status" => Response::HTTP_OK, "message" => "No se encontro la Información de la incidencia para el usuario ".$dni, "data" => []], Response::HTTP_OK);
                }
            } else {
            return response()->json(["status" => Response::HTTP_OK, "message" => "No hay información de incidencia", "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
