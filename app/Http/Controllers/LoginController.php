<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\VI_AVANCES_DIARIOS;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cookie;
use Symfony\Component\HttpFoundation\Response;
use Tymon\JWTAuth\Facades\JWTAuth;

class LoginController extends Controller
{
    function loginLocalUser(Request $request)
    {
        try {
            try {
                $request->validate([
                    'user' => 'required|max:10|min:3',
                    'password' => 'required|max:10|min:4',
                ],
                [
                    'user.min' => 'El campo de usuario debe tener al menos 8 caracteres.',
                    'password.min' => 'El campo de contraseña debe tener al menos 8 caracteres.',
                    'password.max' => 'El campo de contraseña no puede tener más de 10 caracteres.',
                    'user.max' => 'El campo de usuario no puede tener más de 10 caracteres.',
                ]);
            } catch (\Illuminate\Validation\ValidationException $e) {
                return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message-" => $e->errors()], Response::HTTP_BAD_REQUEST);
            }
            $credencials = [
                'user' => $request->user,
                'password' => $request->password
            ];
            if ($token = JWTAuth::attempt($credencials)) {
                // if (password_verify('10167834', $hashedPasswordFromDB)) {
                // $user = User::where('user', $request->user)->get();
                // foreach ($user as $item) {
                //     $data = [
                //         'id' => $item->id,
                //         'name' => $item->user,
                //         'perfil' => $item->perfil,
                //     ];
                // }
                return response()->json(["status" => Response::HTTP_OK, "message" => "Usuario valido", "token" => $token], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "Usuario invalido o contraseña no valida"], Response::HTTP_OK);
            }
    } catch (\Exception $ex) {
        return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
    }
    }
    function validarUser($userExists)
    {
        try {
            $userConsulta = User::where('user', $userExists)->exists();
            if ($userConsulta) {
                return response()->json(["status" => Response::HTTP_OK, "message" => "Usuario ".$userExists." existe ", "user" => $userConsulta], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "Usuario ".$userExists." no existe"], Response::HTTP_OK);
            }
        } catch (\Throwable $th) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $th], Response::HTTP_BAD_REQUEST);
        }
    }

    function viewToken(Request $request)
    {
        try{
            $tokenData = $request->bearerToken();
            $token = JWTAuth::parseToken()->authenticate();
            $user=[
                // "id"=>$token->id,
                "user"=>$token->user,
                "perfil"=>$token->idPerfil,
                "zonal"=>$token->zonal,
            ];
            return response()->json(["status" => Response::HTTP_OK, "message" => "token valido", "user" => $user], Response::HTTP_OK);
        } catch (\Throwable $th) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $th], Response::HTTP_BAD_REQUEST);
        }
    }

    function createUser_new(Request $request){
            try {
                $userConsulta = User::where('user', $request->userName)->exists();
                if ($userConsulta) {
                    return response()->json(["status" => Response::HTTP_OK, "message" => "Usuario ".$request->userName." existe "], Response::HTTP_OK);
                }
                $createUser=new User();
                $createUser->idPerfil = $request->idPerfil;
                $createUser->user = $request->userName;
                $createUser->password = bcrypt($request->password);
                $createUser->zonal = $request->zonal;
                $createUser->created_by = $request->created_by;
                $createUser->created_at = now();
                $createUser->updated_by = $request->updated_by;
                $createUser->updated_at = now();
                // $createUser->save();
                if($createUser->save()){
                $userData=[
                    'user'=>$request->userName,
                    'perfil'=>$request->idPerfil
                ];
                return response()->json(["status" => Response::HTTP_OK, "message" => "usuario creado", "data_users" => $userData], Response::HTTP_OK);
            } 
                else {
                    return response()->json(["status" => Response::HTTP_OK, "message" => "El usuario ".$userConsulta." no se puedo crear"], Response::HTTP_OK);
                }
            } catch (\Exception $ex) {
                return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message- " => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
                
            }
        }
}
