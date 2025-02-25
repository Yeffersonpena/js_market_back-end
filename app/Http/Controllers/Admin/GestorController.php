<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Perfil;
use App\Models\User;
use App\Models\ViewUser;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Tymon\JWTAuth\Facades\JWTAuth;
use Tymon\JWTAuth\Exceptions\JWTException;
use Illuminate\Support\Facades\DB;

class GestorController extends Controller
{
    public function getListUser(Request $request)
    {
        try {
            $existeUser = ViewUser::exists();
            $search = $request->input('search', '');
            $perPage = $request->input('per_page', 10);

            if ($existeUser) {
                $listUser = ViewUser::where('usuario', 'LIKE', "%$search%")
                    ->orderBy('created_at', 'desc')
                    ->paginate($perPage);

                return response()->json([
                    'data' => $listUser->items(),
                    'current_page' => $listUser->currentPage(),
                    'per_page' => $listUser->perPage(),
                    'total' => $listUser->total(),
                    'last_page' => $listUser->lastPage(),
                ]);
            } else {
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "No hay usuarios"
                ], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    public function deleteUser($dni)
    {
        try {
            $existeUser = User::where('user', '=', $dni)->exists();
            if ($existeUser) {
                $deleteUser = User::where('user', '=', $dni)->first();
                $deleteUser->delete();
                return response()->json(["status" => Response::HTTP_OK, "message" => "El usuario " . $dni . " se elimino"], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "El usuario a eliminar no existe"], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    public function updateDataUser(Request $request, $dni)
    {
        try {
            $datosToken = JWTAuth::parseToken()->authenticate();
            $existeUser = User::where('id', '=', $dni)->exists();
            if ($existeUser) {
                $updateUser = User::where('id', '=', $dni)->first();
                $updateUser->idPerfil = $request->idPerfil;
                $updateUser->zonal = $request->zonal;
                $updateUser->updated_by = $datosToken->user;
                $updateUser->updated_at = now();
                $updateUser->save();
                return response()->json(["status" => Response::HTTP_OK, "message" => "Se actualizo los datos del usuario " . $dni], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "El usuario no existe"], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    public function getListPerfil()
    {
        try {
            $existePerfil = Perfil::exists();
            if ($existePerfil) {
                $lisPerfil = Perfil::all();
                return response()->json(["status" => Response::HTTP_OK, "message" => "Lista de perfiles", "data" => $lisPerfil], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay lista de perfiles"], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    function actualizaClave(Request $request)
    {
        try {
            $userData = DB::statement(
                "EXEC paActualizarClave ?, ?",
                [$request->idUsuario, $request->clave]
            );
            if ($userData) {
                return response()->json(["status" => Response::HTTP_OK, "message" => "Clave actualizada"], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No se pudo actualizar la clave"], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
