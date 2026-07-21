<?php

namespace App\Http\Controllers;

use App\Models\IngresoUser;
use App\Models\User;
use App\Models\VI_AVANCES_DIARIOS;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
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
                'user' => 'required|max:50|min:3',
                'password' => 'required|max:100|min:3',
            ], [
                'user.min' => 'El usuario debe tener al menos 3 caracteres.',
                'password.min' => 'La contraseña debe tener al menos 3 caracteres.',
                'password.max' => 'La contraseña no puede tener más de 100 caracteres.',
                'user.max' => 'El usuario no puede tener más de 50 caracteres.',
            ]);

            $user = trim((string) $request->user);
            // La contraseña debe compararse exactamente como fue registrada.
            // Aplicar trim() aquí hace imposible iniciar sesión si la clave
            // contiene un espacio al inicio o al final.
            $password = (string) $request->password;

            $userData = DB::selectOne("EXEC sp_LoginUser ?, ?", [$user, $password]);
            if (!$userData) {
                $userConsulta = User::where('user', $user)->exists();
                $messageUser=$userConsulta?'La contraseña es incorrecta, por favor vuelve a ingresar la contraseña correcta':'Usuario no encontrado';
                return response()->json(["status" => Response::HTTP_OK, "message" => $messageUser], Response::HTTP_OK);
            }

            $userModel = User::where('user', $userData->user)->first();
            if (!$userModel) {
                return response()->json(["status" => Response::HTTP_OK, "message" => "Error al cargar el usuario"], Response::HTTP_UNAUTHORIZED);
            }

            try {
                $token = JWTAuth::fromUser($userModel);
            } catch (JWTException $e) {
                return response()->json(["status" => Response::HTTP_INTERNAL_SERVER_ERROR, "message" => "No se pudo generar el token"], Response::HTTP_INTERNAL_SERVER_ERROR);
            }

            $ingreso = new IngresoUser();
            $ingreso->user = $user;
            $ingreso->ip=$request->ip();
            $ingreso->fecha=Carbon::now();
            $ingreso->save();
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
                return response()->json(["status" => Response::HTTP_OK, "message" => "true", "user" => $userConsulta], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "false", "user" => []], Response::HTTP_OK);
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
            $dateNow=DB::select('select valor from dbo.parametros where tipo= ?',[1]);
            $user = [
                // "id"=>$token->id,
                "user" => $token->user,
                "perfil" => $token->idPerfil,
                "zonal" => $token->zonal,
                "dateNow"=>$dateNow[0]->valor ?? null,
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
            $filasAfectadas = DB::select("EXEC paRegistrarUsuariosMasivo");
            if (!empty($filasAfectadas) && isset($filasAfectadas[0]->filas_afectadas)) {
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "Usuarios registrados exitosamente.",
                    "filas_afectadas" => $filasAfectadas[0]->filas_afectadas
                ], Response::HTTP_OK);
            } else {
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "No se registraron usuarios.",
                    "filas_afectadas" => 0
                ], Response::HTTP_OK);
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
    function ingreso(Request $request)
    {
        try {
            $ingreso=new IngresoUser();
            $ingreso->user=$request->user;
            $ingreso->ip=$request->ip();
            $ingreso->fecha=now();
            $ingreso->save();
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    function testRep(){
               try {
            $año=2025;
            $mes=5;
            $listGroup = DB::select('
            select chip.*,e.DNI_VENDEDOR as DNI_FINAL, e.ACCION_1 as PROYECTO, e.ZONAL, e.ESTADO as E_ESTADO from dbo.tbl_chip_q2 chip 
            inner join
            dbo.PDV_OUT_ENTREGABLE e on chip.dni=e.DNI_VENDEDOR
            WHERE e.AÑO =? AND e.MES =?;',[$año, $mes]);

            $dni=41917771;
            //  $listGroup = DB::select('
            // select redDig.*, \'\' as MOVIMIENTO, e.DNI_VENDEDOR as DNI_FINAL, e.ACCION_1 as PROYECTO, e.ZONAL, e.ESTADO from dbo.tbl_red_digital_q2 redDig
            // inner join
            // dbo.PDV_OUT_ENTREGABLE e on redDig.dni=e.DNI_VENDEDOR
            // WHERE e.AÑO = ? AND e.MES = ? and redDig.CONDICION=? and redDig.CONDICION1=? and Columna1 <> ?  and e.DNI_VENDEDOR=?
            // ;',[$año, $mes, 'CREDITO', 'CREDITO', 'CHIP', $dni]);

                // WHERE e.AÑO =? AND e.MES =? and e.DNI_VENDEDOR=?;',[$año, $mes, $dni]);
            if ($listGroup) {
                return response()->json(["status" => Response::HTTP_OK, "message" => "Fyers", "data" => $listGroup], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay fyers para la fecha ", "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
