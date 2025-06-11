<?php

namespace App\Http\Controllers\General;

use App\Http\Controllers\Controller;
use App\Models\Incidencia_2;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class IncidenciaController extends Controller
{
    function create(Request $request){
        try{
            $create=new Incidencia_2();
            $create->DNI_CON_ERROR = $request->dni_error;
            $create->ZONAL = $request->zonal;
            $create->NOMBRE_USUARIO_CON_ERROR = $request->nombre_usuario_error;
            $create->TIPO_DNI = $request->tipo_dni;
            $create->INDICAR_DNI_RESPONSABLE = $request->dni_responsable;
            $create->TIPO_DOC = $request->tipo_doc;
            $create->PROYECTO = $request->proyecto;
            $create->ERROR = $request->error;
            $create->FECHA_ENVIO_TDP = $request->fecha_envio_tdp;
            $create->FECHA_DE_RESPUESTA_TDP = $request->fecha_respuesta_tdp;
            $create->ULTIMA_FECHA_ENVIO_ZONAL = $request->ultima_fecha_envio_zonal;
            $create->STATUS_INCIDENCIA = $request->status_incidencia;
            $create->SE_SUPERO_SI_NO = $request->se_supero;
            $create->ULTIMA_FECHA_VALIDACION_ZONAL = $request->ultima_fecha_validacion_zonal;
            $create->OBSERVACION = $request->observacion;
            $create->SE_ENVIO_A_TDP = $request->se_envio_a_tdp;
            // return $request->all();
            // $create->save();
            // $existIncidencia=Incidencia::exists();
            if($create->save()){
            //     $incidencia=Incidencia::where('dni_incidencia','=',$dni)->exists();
            //     // $incidencia=Incidencia::where('dni_enrolado','=',$dni)->exists();
            //         if($incidencia){
            //             // $getIncidencia=Incidencia::where('dni_enrolado','=',$dni)->get();
            //             $getIncidencia=Incidencia::where('dni_incidencia','=',$dni)->get();
            //             $dataIncidencia=$getIncidencia->map(function ($item){
            //                 return [
            //                 "id"=> $item->id,
            //                 "dni_incidencia"=> $item->dni_incidencia,
            //                 "fechaReporte"=> $item->{'FECHA ENVIO JEFE'},
            //                 "errorReportado"=> $item->{'ERROR'},
            //                 "statusIncidencia"=> $item->{'Status de Incidencia'},
            //                 "seSupero"=> $item->{'SE SUPERO SI/NO'} ?? "",
            //                 "tipoDni"=> $item->{'dni_enrolado'},
            //                 "dniResponsable"=>0,
            //             ];
            //         });
            //         return response()->json(["status" => Response::HTTP_OK, "message" => "Información de incidencia", "data" => $dataIncidencia], Response::HTTP_OK);
            //     }else{
                //     }
                return response()->json(["status" => Response::HTTP_OK, "message" => "Se inserto la incidencia"], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No se pudo insertar la incidencia, vuelva a intentarlo", "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    function getList($typeSearch, $id){
    // function getList($dni, $anio, $mes){
        try{
            $existIncidencia=Incidencia_2::exists();
            // return $existIncidencia;
            if($existIncidencia){
                if($typeSearch){
                    $dataIncidencia=Incidencia_2::find($id);
                    if(!$dataIncidencia){
                        return response()->json(["status" => Response::HTTP_OK, "message" => "No hay información de incidencia", "data" => []], Response::HTTP_OK);
                    }
                    return response()->json(["status" => Response::HTTP_OK, "message" => "Información de incidencia", "data" => $dataIncidencia], Response::HTTP_OK);
                }
                $dataIncidencia=Incidencia_2::all();
                return response()->json(["status" => Response::HTTP_OK, "message" => "Información de incidencia", "data" => $dataIncidencia], Response::HTTP_OK);
                // return response()->json(["status" => Response::HTTP_OK, "message" => "Se inserto la incidencia"], Response::HTTP_OK);
            } else {
                // return response()->json(["status" => Response::HTTP_OK, "message" => "No se pudo insertar la incidencia, vuelva a intentarlo", "data" => []], Response::HTTP_OK);
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay información de incidencia", "data" => []], Response::HTTP_OK);
                
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    // function getList($dni, $anio, $mes){
    //     try{

    //     } catch (\Exception $ex) {
    //         return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
    //     }
    // }


    function update(Request $request, $id){
        try{
            $update=Incidencia_2::find($id);
              if($update){
                //   return response()->json(["status" => Response::HTTP_OK, "message" => "Información de incidencia a actualizar", "data" => $update], Response::HTTP_OK);
                //   return $update;
                // return $request->all();
                $update->DNI_CON_ERROR = $request->dni_error;
                $update->ZONAL = $request->zonal;
                $update->NOMBRE_USUARIO_CON_ERROR = $request->nombre_usuario_error;
                $update->TIPO_DNI = $request->tipo_dni;
                $update->INDICAR_DNI_RESPONSABLE = $request->dni_responsable;
                $update->TIPO_DOC = $request->tipo_doc;
                $update->PROYECTO = $request->proyecto;
                $update->ERROR = $request->error;
                $update->FECHA_ENVIO_TDP = $request->fecha_envio_tdp;
                $update->FECHA_DE_RESPUESTA_TDP = $request->fecha_respuesta_tdp;
                $update->ULTIMA_FECHA_ENVIO_ZONAL = $request->ultima_fecha_envio_zonal;
                $update->STATUS_INCIDENCIA = $request->status_incidencia;
                $update->SE_SUPERO_SI_NO = $request->se_supero;
                $update->ULTIMA_FECHA_VALIDACION_ZONAL = $request->ultima_fecha_validacion_zonal;
                $update->OBSERVACION = $request->observacion;
                $update->SE_ENVIO_A_TDP = $request->se_envio_a_tdp; 
                $update->save(); 
                // $dataIncidencia=Incidencia_2::all();
                return response()->json(["status" => Response::HTTP_OK, "message" => "Se actualizo la incidencia"], Response::HTTP_OK);
            } else {
                // return response()->json(["status" => Response::HTTP_OK, "message" => "No se pudo insertar la incidencia, vuelva a intentarlo", "data" => []], Response::HTTP_OK);
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay información de incidencia a actualizar", "data" => []], Response::HTTP_OK);
                
            }
            return $update;
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }


    function delete($id){
        try{
            $delete=Incidencia_2::destroy($id);
            if($delete){

                 return response()->json(["status" => Response::HTTP_OK, "message" => "Se elimino la incidencia"], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No se pudo eliminar la incidencia, vuelva a intentarlo", "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
