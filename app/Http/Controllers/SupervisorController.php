<?php

namespace App\Http\Controllers;

use App\Models\PDV_ENTREGABLE;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class SupervisorController extends Controller
{
    function getListUser($zonal){
        try{
            $dateNowYear=Carbon::now()->year;
            $dateNowMonth=Carbon::now()->month;
            // $getList=PDV_ENTREGABLE::where('año', '=', $dateNowYear)->where('mes','=', $dateNowMonth)->get();
            if($zonal){
                $getList=DB::select('
                  SELECT DISTINCT u.[user], u.zonal, p.ACCION_1 FROM dbo.users u
                    JOIN dbo.PDV_OUT_ENTREGABLE p
                        ON (u.[user] = p.DNI_RESPONSABLE OR u.[user] = p.DNI_VENDEDOR)
                    WHERE u.idPerfil IN (2, 3) AND p.AÑO = ? AND p.MES = ? and u.zonal=?;', [$dateNowYear, $dateNowMonth, $zonal]);    
                    
            }else{
                $getList=DB::select('
                SELECT DISTINCT u.[user], u.zonal, p.ACCION_1 FROM dbo.users u
                JOIN dbo.PDV_OUT_ENTREGABLE p
                ON (u.[user] = p.DNI_RESPONSABLE OR u.[user] = p.DNI_VENDEDOR)
                WHERE u.idPerfil IN (2, 3) AND p.AÑO = ? AND p.MES = ?;', [$dateNowYear, $dateNowMonth]);
            }
            // $listUser=$getList->map(function($item){
            //     return [
            //         "user": $item->zonal,
            //         "user": $item->ACCION_1,
            //         "user": $item->zonal,
            //     ]
            // });
            if($getList){
                return response()->json(["status"=>Response::HTTP_OK, "message"=>"Existe lista de usuarios", "data"=>$getList],Response::HTTP_OK); 
            }else{
                return response()->json(["status"=>Response::HTTP_OK, "message"=>"No hay lista de usuarios", "data"=>[]],Response::HTTP_OK,); 
            }
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    // function createUser(){
    //     try{
    //         // $listGroup = DB::select('EXEC dbo.spGetListGroup');
    //         // $listGroup = DB::select('
    //         //     WITH UltimoPeriodo AS (
    //         //     SELECT TOP 1 año, mes FROM dbo.PDV_OUT_ENTREGABLE WHERE año IS NOT NULL AND mes IS NOT NULL ORDER BY año DESC, mes DESC)
    //         //     SELECT DISTINCT e.GRUPO FROM dbo.PDV_OUT_ENTREGABLE e JOIN UltimoPeriodo u ON e.año = u.año AND e.mes = u.mes
    //         //     WHERE e.GRUPO IS NOT NULL ORDER BY e.GRUPO;');
    //         if($listGroup){
    //             return response()->json(["status"=>Response::HTTP_OK, "message"=>"Existe lista de grupos", "data"=>$listGroup],Response::HTTP_OK); 
    //         }else{
    //             return response()->json(["status"=>Response::HTTP_OK, "message"=>"No hay group", "data"=>[]],Response::HTTP_OK,); 
    //         }
    //     }catch(\Exception $ex){
    //         return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
    //     }
    // }

    // function updateUser(){
    //     try{
    //         // $listGroup = DB::select('EXEC dbo.spGetListGroup');
    //         // $listGroup = DB::select('
    //         //     WITH UltimoPeriodo AS (
    //         //     SELECT TOP 1 año, mes FROM dbo.PDV_OUT_ENTREGABLE WHERE año IS NOT NULL AND mes IS NOT NULL ORDER BY año DESC, mes DESC)
    //         //     SELECT DISTINCT e.GRUPO FROM dbo.PDV_OUT_ENTREGABLE e JOIN UltimoPeriodo u ON e.año = u.año AND e.mes = u.mes
    //         //     WHERE e.GRUPO IS NOT NULL ORDER BY e.GRUPO;');
    //         if($listGroup){
    //             return response()->json(["status"=>Response::HTTP_OK, "message"=>"Existe lista de grupos", "data"=>$listGroup],Response::HTTP_OK); 
    //         }else{
    //             return response()->json(["status"=>Response::HTTP_OK, "message"=>"No hay group", "data"=>[]],Response::HTTP_OK,); 
    //         }
    //     }catch(\Exception $ex){
    //         return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
    //     }
    // }

    // function getListConfig(){
    //     try{
    //         // if($listGroup){
    //         //     return response()->json(["status"=>Response::HTTP_OK, "message"=>"Existe lista de grupos", "data"=>$listGroup],Response::HTTP_OK); 
    //         // }else{
    //         //     return response()->json(["status"=>Response::HTTP_OK, "message"=>"No hay group", "data"=>[]],Response::HTTP_OK,); 
    //         // }
    //     }catch(\Exception $ex){
    //         return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
    //     }
    // }
}
