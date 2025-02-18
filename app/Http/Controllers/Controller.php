<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

// use Illuminate\Support\Facades\Auth;
// use Illuminate\Support\Facades\Cookie;
// use Symfony\Component\HttpFoundation\Response;
// use Tymon\JWTAuth\Facades\JWTAuth;


abstract class Controller
{
    // function createUser(Request $request){
        function createUser(){
        return 2;
        // try {

        //     // return $request->all();
        //     $createUser=new User();
        //     $createUser->idPerfil = $request->idPerfil;
        //     $createUser->user = $request->user;
        //     $createUser->password = bcrypt($request->password);
        //     $createUser->zonal = $request->zonal;
        //     $createUser->created_by = $request->created_by;
        //     $createUser->created_at = now();
        //     $createUser->updated_by = $request->updated_by;
        //     $createUser->updated_at = now();
        //     $createUser->save();
        //     return response()->json(["status" => Response::HTTP_OK, "message" => "usuario creado", "data_users" => $createUser], Response::HTTP_OK);
        // } catch (\Exception $ex) {
        //     return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message- " => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
            
        // }
        
    }
}
