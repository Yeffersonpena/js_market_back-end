<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Perfil;
use App\Models\User;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class GestorController extends Controller
{
    public function getListUser(){
        try{
            $existeUser = User::exists();
            if($existeUser){
                $listUser = User::paginate(10);    
            return response()->json(["status" => Response::HTTP_OK, "message" => "Lista de usuarios", "data"=>$listUser], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_OK, "message" => "No hay usuarios"], Response::HTTP_OK);
        }

        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
       
    }
    
    public function deleteUser($dni){
        try{
            $existeUser = User::where('user','=', $dni)->exists();
            if($existeUser){
                $deleteUser = User::where('user','=', $dni)->first();
                $deleteUser->delete();
            return response()->json(["status" => Response::HTTP_OK, "message" => "El usuario ".$dni." se elimino"], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_OK, "message" => "El usuario a eliminar no existe"], Response::HTTP_OK);
        }

        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    public function updateDataUser(Request $request, $dni){
        try{
            $existeUser = User::where('user','=', $dni)->exists();
            if($existeUser){
                $updateUser = User::where('user','=', $dni)->first();
                $updateUser->idPerfil= $request->idPerfil;
                $updateUser->password= bcrypt($request->password);
                $updateUser->zonal= $request->zonal;
                $updateUser->updated_by= $request->updated_by;
                $updateUser->updated_at= now();
                $updateUser->save();
            return response()->json(["status" => Response::HTTP_OK, "message" => "Se actualizo los datos del usuario ".$dni], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_OK, "message" => "El usuario no existe"], Response::HTTP_OK);
        }

        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function getListPerfil(){
        try{
            $existePerfil = Perfil::exists();
            if($existePerfil){
                $lisPerfil = Perfil::all();    
            return response()->json(["status" => Response::HTTP_OK, "message" => "Lista de perfiles", "data"=>$lisPerfil], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_OK, "message" => "No hay lista de perfiles"], Response::HTTP_OK);
        }

        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
