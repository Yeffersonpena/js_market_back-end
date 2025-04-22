<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    function getListGroup(){
        try{
            $listGroup = DB::select('EXEC dbo.spGetListGroup');
            if($listGroup){
                return response()->json(["status"=>Response::HTTP_OK, "message"=>"Existe lista de grupos", "data"=>$listGroup],Response::HTTP_OK); 
            }else{
                return response()->json(["status"=>Response::HTTP_OK, "message"=>"No hay group", "data"=>[]],Response::HTTP_OK,); 
            }
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
