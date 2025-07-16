<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PDV_ENTREGABLE;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class GestorEntregableController extends Controller
{
    public function getList($anio, $mes, $stateSearch, $dni){
        try{
            if($stateSearch){
                $getListEntregable=DB::select('select * from dbo.PDV_OUT_ENTREGABLE where AÑO=? and mes=?', [$anio, $mes]);
                $msgSearch="la lista de usuarios";    
            }else{
                $getListEntregable=DB::select('select * from dbo.PDV_OUT_ENTREGABLE where AÑO=? and mes=? and DNI_RESPONSABLE=? or dni_vendedor=?', [$anio, $mes, $dni, $dni]);
                $msgSearch="el usuarios con el dni ".$dni."";    
            }
            if(!$getListEntregable){
                return response()->json(["status"=>200, "message"=>"No se encontro ".$msgSearch." ", "data"=>[]], Response::HTTP_OK);
            }
            return response()->json(["status"=>200, "message"=>"Se encontro ".$msgSearch." ", "data"=>$getListEntregable], Response::HTTP_OK);
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function post(Request $request){
        try{
            $createEntregable=new PDV_ENTREGABLE();
            $createEntregable->AÑO = $request->anio;
            $createEntregable->MES = $request->mes;
            $createEntregable->SOCIO = "JS MARKET";
            $createEntregable->ZONAL = $request->zonal;
            $createEntregable->DNI_RESPONSABLE = $request->dni_responsable;
            $createEntregable->{'DNI/CE'} = "";
            $createEntregable->DNI_VENDEDOR = $request->dni_vendedor;
            $createEntregable->NOMBRE_RESPONSABLE = $request->nombre_responsable;
            $createEntregable->NOMBRE_VENDEDOR = $request->nombre_vendedor;
            $createEntregable->NOMBRE_SUPERVISOR = $request->nombre_supervisor;
            $createEntregable->ESTADO = "ACTIVO";
            $createEntregable->FECHA_INICIO = null;
            $createEntregable->FECHA_FIN = null;
            $createEntregable->ACCION_1 = $request->accion_1;
            $createEntregable->ACCION_2 = $request->accion_2;
            $createEntregable->DISTRITO = $request->distrito;
            $createEntregable->CONGLOMERADO = $request->conglomerado;
            $createEntregable->NUMERO_RECARGADOR = $request->numero_recargador;
            $createEntregable->CHIP_MM = $request->chip_mm;
            $createEntregable->COORDENADA_X = $request->coordenada_x;
            $createEntregable->COORDENADA_Y = $request->coordenada_y;
            $createEntregable->CLUSTER_PDV_REGULAR = "";
            $createEntregable->NOMBRE_VENDEDOR1 = $request->nombre_vendedor1;
            $createEntregable->TEAM_LIDER = "";
            $createEntregable->TEAM_LIDER_FECHA_INICIO = null;
            $createEntregable->TEAM_LIDER_FECHA_FIN = null;
            $createEntregable->CUOTA_PREPAGO = $request->cuota_prepago;
            $createEntregable->CELULAR_VENDEDOR = $request->celular_vendedor;
            $createEntregable->GRUPO = $request->grupo;
            $createEntregable->FINANCIAMIENTO_SALDO = "0";
            $createEntregable->FINANCIAMIENTO_CHIPS = "0";
            $createEntregable->FINANCIAMIENTO_TOTAL = "0";
            $createEntregable->{'DNI SUPERVISOR'} = $request->dni_supervisor;
            $createEntregable->{'CCTA BANCARIA MM'} = $request->ccta_bancaria_mm;
            $createEntregable->{'ENTIDAD BANCARIA MM'} = $request->entidad_bancaria_mm;
            $createEntregable->{'DNI SI ES TERCERO MM'} = $request->dni_si_es_tercero_mm;
            $createEntregable->{'NUM SUPERVISOR'} = $request->num_supervisor;
            $createEntregable->{'FINANCIAMIENTO SALDO AL 1Q'} = "0";
            $createEntregable->{'FINANCIAMIENTO CHIPS AL 1Q'} = "0";
            $createEntregable->{'TOTA FINANCIAMIENTO 1Q'} = "0";
            $createEntregable->{'FINANCIAMIENTO SALDO AL 2Q'} = "0";
            $createEntregable->{'FINANCIAMIENTO CHIPS AL 2Q'} = "0";
            $createEntregable->{'TOTA FINANCIAMIENTO 2Q'} = "0";
            $createEntregable->dateUpdateFile = $request->dateupdatefile;
            $createEntregable->RESPONSABLE_CREACION_PDV = "";
            $createEntregable->NOMBRE_RESPONSABLE_CREACION = "";
            $createEntregable->FINANCIAMIENTO_TOTAL_DEL_MES = ".00";
            $createEntregable->Provincia = $request->provincia;
            $createEntregable->NUM_DE_DNI_VVDD = $request->num_de_dni_vvdd;
            if(!$createEntregable->save()){
                $valueCreate=[];
                $msgCreate="Vuelva a intentarlo más tarde, hay problema al crear el usuario";
            }
            $valueCreate=$createEntregable;
            $msgCreate="Se creo el usuaro satisfactoriamente";
            return response()->json(["status" => Response::HTTP_OK, "message" => $msgCreate, "data" => $valueCreate], Response::HTTP_OK);
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function delete($anio, $mes, $dniResponsable, $dniVendedor){
        try{
            $searchDelete=DB::select('select * from dbo.PDV_OUT_ENTREGABLE where AÑO=? and mes=? and DNI_RESPONSABLE=? and dni_vendedor=?', [$anio, $mes, $dniResponsable, $dniVendedor]);
            if(!$searchDelete){
                $msgDelete="El usuario a eliminar, no se encontro";
            }else{
                $deleteEntregable=DB::delete('delete from dbo.PDV_OUT_ENTREGABLE where AÑO=? and mes=? and DNI_RESPONSABLE=? and dni_vendedor=?', [$anio, $mes, $dniResponsable, $dniVendedor]);
                if(!$deleteEntregable){
                    $msgDelete="Vuelva a intentarlo más tarde, hay problema al eliminar el usuario";
                }
                $msgDelete="Se elimino el usuario de la tabla entregable";    
            }
            return response()->json(["status"=>200, "message"=>$msgDelete." para el periodo del ".$anio." y mes ".$mes."", "data"=>[]], Response::HTTP_OK);
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function update($anio, $mes, $dniResponsable, $dniVendedor, Request $request){
        try{
           $searchUpdate=DB::select('select * from dbo.PDV_OUT_ENTREGABLE where AÑO=? and mes=? and DNI_RESPONSABLE=? and dni_vendedor=?', [$anio, $mes, $dniResponsable, $dniVendedor]);
            if(!$searchUpdate){
                $msgUpdate="El usuario a actualizar, no se encontro";
            }else{
                // $update=('AÑO=? and mes=? and DNI_RESPONSABLE=? and dni_vendedor=?'):?"true":"no se encontro";
                // $updateEntregable=PDV_ENTREGABLE::find('AÑO'=$anio, 'and',  'mes', '=', $mes 'DNI_RESPONSABLE', '=', $dniResponsable,  'dni_vendedor', '=', $dniVendedor)->get();
                $updateEntregable=PDV_ENTREGABLE::where('AÑO',$anio)->where('mes',$mes)->where('DNI_RESPONSABLE',$dniResponsable)->where('dni_vendedor',$dniVendedor)->get();
                $updateEntregable->AÑO = $request->anio;
                $updateEntregable->MES = $request->mes;
                $updateEntregable->SOCIO = "JS MARKET";
                $updateEntregable->ZONAL = $request->zonal;
                $updateEntregable->DNI_RESPONSABLE = $request->dni_responsable;
                $updateEntregable->{'DNI/CE'} = "";
                $updateEntregable->DNI_VENDEDOR = $request->dni_vendedor;
                $updateEntregable->NOMBRE_RESPONSABLE = $request->nombre_responsable;
                $updateEntregable->NOMBRE_VENDEDOR = $request->nombre_vendedor;
                $updateEntregable->NOMBRE_SUPERVISOR = $request->nombre_supervisor;
                $updateEntregable->ESTADO = "ACTIVO";
                $updateEntregable->FECHA_INICIO = null;
                $updateEntregable->FECHA_FIN = null;
                $updateEntregable->ACCION_1 = $request->accion_1;
                $updateEntregable->ACCION_2 = $request->accion_2;
                $updateEntregable->DISTRITO = $request->distrito;
                $updateEntregable->CONGLOMERADO = $request->conglomerado;
                $updateEntregable->NUMERO_RECARGADOR = $request->numero_recargador;
                $updateEntregable->CHIP_MM = $request->chip_mm;
                $updateEntregable->COORDENADA_X = $request->coordenada_x;
                $updateEntregable->COORDENADA_Y = $request->coordenada_y;
                $updateEntregable->CLUSTER_PDV_REGULAR = "";
                $updateEntregable->NOMBRE_VENDEDOR1 = $request->nombre_vendedor1;
                $updateEntregable->TEAM_LIDER = "";
                $updateEntregable->TEAM_LIDER_FECHA_INICIO = null;
                $updateEntregable->TEAM_LIDER_FECHA_FIN = null;
                $updateEntregable->CUOTA_PREPAGO = $request->cuota_prepago;
                $updateEntregable->CELULAR_VENDEDOR = $request->celular_vendedor;
                $updateEntregable->GRUPO = $request->grupo;
                $updateEntregable->FINANCIAMIENTO_SALDO = "0";
                $updateEntregable->FINANCIAMIENTO_CHIPS = "0";
                $updateEntregable->FINANCIAMIENTO_TOTAL = "0";
                $updateEntregable->{'DNI SUPERVISOR'} = $request->dni_supervisor;
                $updateEntregable->{'CCTA BANCARIA MM'} = $request->ccta_bancaria_mm;
                $updateEntregable->{'ENTIDAD BANCARIA MM'} = $request->entidad_bancaria_mm;
                $updateEntregable->{'DNI SI ES TERCERO MM'} = $request->dni_si_es_tercero_mm;
                $updateEntregable->{'NUM SUPERVISOR'} = $request->num_supervisor;
                $updateEntregable->{'FINANCIAMIENTO SALDO AL 1Q'} = "0";
                $updateEntregable->{'FINANCIAMIENTO CHIPS AL 1Q'} = "0";
                $updateEntregable->{'TOTA FINANCIAMIENTO 1Q'} = "0";
                $updateEntregable->{'FINANCIAMIENTO SALDO AL 2Q'} = "0";
                $updateEntregable->{'FINANCIAMIENTO CHIPS AL 2Q'} = "0";
                $updateEntregable->{'TOTA FINANCIAMIENTO 2Q'} = "0";
                $updateEntregable->dateUpdateFile = $request->dateupdatefile;
                $updateEntregable->RESPONSABLE_CREACION_PDV = "";
                $updateEntregable->NOMBRE_RESPONSABLE_CREACION = "";
                $updateEntregable->FINANCIAMIENTO_TOTAL_DEL_MES = ".00";
                $updateEntregable->Provincia = $request->provincia;
                $updateEntregable->NUM_DE_DNI_VVDD = $request->num_de_dni_vvdd;
                // return $updateEntregable[0];
                // $updateEntregable=DB::select('update dbo.PDV_OUT_ENTREGABLE where AÑO=? and mes=? and DNI_RESPONSABLE=? and dni_vendedor=?', [$anio, $mes, $dniResponsable, $dniVendedor]);
                if(!$updateEntregable->save()){
                    $msgUpdate="Vuelva a intentarlo más tarde, hay problema al eliminar el usuario";
                }
                $msgUpdate="Se elimino el usuario de la tabla entregable";    
            }
            return response()->json(["status"=>200, "message"=>$msgUpdate." para el periodo del ".$anio." y mes ".$mes."", "data"=>[]], Response::HTTP_OK);
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
