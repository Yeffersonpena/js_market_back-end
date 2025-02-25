<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\VI_AVANCES_DIARIOS;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cookie;
use Symfony\Component\HttpFoundation\Response;
use Tymon\JWTAuth\Facades\JWTAuth;
use Tymon\JWTAuth\Exceptions\JWTException;
use Illuminate\Support\Facades\DB;

class LoginController extends Controller
{
    function loginLocalUser(Request $request)
    {
        try {
            $request->validate([
                'user' => 'required|max:10|min:3',
                'password' => 'required|max:10|min:4',
            ], [
                'user.min' => 'El usuario debe tener al menos 3 caracteres.',
                'password.min' => 'La contraseña debe tener al menos 4 caracteres.',
                'password.max' => 'La contraseña no puede tener más de 10 caracteres.',
                'user.max' => 'El usuario no puede tener más de 10 caracteres.',
            ]);

            $userData = DB::selectOne("EXEC sp_LoginUser ?, ?", [$request->user, $request->password]);

            if (!$userData) {
                return response()->json(["status" => Response::HTTP_UNAUTHORIZED, "message" => "Usuario no encontrado"], Response::HTTP_UNAUTHORIZED);
            }

            $user = User::where('user', $userData->user)->first();
            if (!$user) {
                return response()->json(["status" => Response::HTTP_UNAUTHORIZED, "message" => "Error al cargar el usuario"], Response::HTTP_UNAUTHORIZED);
            }

            try {
                $token = JWTAuth::fromUser($user);
            } catch (JWTException $e) {
                return response()->json(["status" => Response::HTTP_INTERNAL_SERVER_ERROR, "message" => "No se pudo generar el token"], Response::HTTP_INTERNAL_SERVER_ERROR);
            }

            return response()->json(["status" => Response::HTTP_OK, "message" => "Login exitoso", "token" => $token], Response::HTTP_OK);
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    function validarUser($userExists)
    {
        try {
            $userConsulta = User::where('user', $userExists)->exists();
            if ($userConsulta) {
                return response()->json(["status" => Response::HTTP_OK, "message" => "El usuario " . $userExists . " existe ", "user" => $userConsulta], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "El usuario " . $userExists . " no existe", "data" => []], Response::HTTP_OK);
            }
        } catch (\Throwable $th) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $th], Response::HTTP_BAD_REQUEST);
        }
    }

    function viewToken(Request $request)
    {
        try {
            $tokenData = $request->bearerToken();
            $token = JWTAuth::parseToken()->authenticate();
            $user = [
                // "id"=>$token->id,
                "user" => $token->user,
                "perfil" => $token->idPerfil,
                "zonal" => $token->zonal,
            ];
            return response()->json(["status" => Response::HTTP_OK, "message" => "token valido", "user" => $user], Response::HTTP_OK);
        } catch (\Throwable $th) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $th], Response::HTTP_BAD_REQUEST);
        }
    }
    function createUserSp(Request $request)
    {
        try {
            $datosToken = JWTAuth::parseToken()->authenticate();
            $userConsulta = User::where('user', $request->usuario)->exists();
            if ($userConsulta) {
                return response()->json(["status" => Response::HTTP_OK, "message" => "El usuario " . $request->usuario . " ya existe"], Response::HTTP_OK);
            }
            $userData = DB::statement(
                "EXEC paCrearUsuario ?, ?, ?, ?, ?",
                [$request->usuario, $request->clave, $request->idPerfil,  $request->zonal,  $datosToken->user]
            );
            if ($userData) {
                return response()->json(["status" => Response::HTTP_OK, "message" => "Se ejecuto exitosamente el Store Procedure"], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No se pudo ejecutar el Store Procedure"], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    function createUserAll()
    {
        try {
            $createUserList = DB::statement("EXEC paRegistrarUsuariosMasivo");
            if ($createUserList) {
                return response()->json(["status" => Response::HTTP_OK, "message" => "Se ejecuto exitosamente la creación de todo los usuario del excel entregable"], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No se pudo ejecutar el Store Procedure"], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    function createUser_new(Request $request)
    {
        try {
            $userConsulta = User::where('user', $request->userName)->exists();
            if ($userConsulta) {
                return response()->json(["status" => Response::HTTP_OK, "message" => "Usuario " . $request->userName . " existe "], Response::HTTP_OK);
            }
            $createUser = new User();
            $createUser->idPerfil = $request->idPerfil;
            $createUser->user = $request->userName;
            $createUser->password = bcrypt($request->password);
            $createUser->zonal = $request->zonal;
            $createUser->created_by = $request->created_by;
            $createUser->created_at = now();
            $createUser->updated_by = $request->updated_by;
            $createUser->updated_at = now();
            // $createUser->save();
            if ($createUser->save()) {
                $userData = [
                    'user' => $request->userName,
                    'perfil' => $request->idPerfil
                ];
                return response()->json(["status" => Response::HTTP_OK, "message" => "usuario creado", "data_users" => $userData], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "El usuario " . $userConsulta . " no se puedo crear"], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message- " => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
