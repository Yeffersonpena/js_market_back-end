<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\HistoryStoreProcedure;
use App\Models\IngresoUser;
use App\Models\Perfil;
use App\Models\User;
use App\Models\ViewUser;
use App\Models\Zonal;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Symfony\Component\HttpFoundation\Response;
use Tymon\JWTAuth\Facades\JWTAuth;
use Tymon\JWTAuth\Exceptions\JWTException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

use function Laravel\Prompts\select;

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
                [$request->usuario, $request->clave]
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

    function loadFileSp(Request $request){
        try {
            $request->validate([
                'typeSp' => 'required|integer|min:1|max:12',
                'monthSp' => 'required|integer|min:1|max:12'
            ]);
            $mapingSp=[
                1 => "spLoadFileEntregable",
                2 => "spLoadFileFunnel",
                3 => "spLoadFileAbono",
                4 => "spLoadFileAvanceDiario",
                5 => "spLoadFileEsquema",
                6 => "spLoadFileMesaAyuda",
                7 => "spLoadFileVentaLog",
            ];
            $msgAlert=[
                1 => "entregable",
                2 => "funnel",
                3 => "abono",
                4 => "avance diario",
                5 => "esquema",
                6 => "mesa de ayuda",
                7 => "venta log",
            ];
            $pathFileInfo=[
                1 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\ENTREGABLE\Entregable.xlsx',
                2 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\FUNNEL\Funnel.xlsm',
                3 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\ABONOS\Abonos.xlsx',
                4 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\AVANCE_DIARIO\carga_avance_multimarca.xlsx',
                5 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\ESQUEMAS\Listado de incentivos.xlsx',
                6 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\MESA DE AYUDA\Mesa_de_ayuda.xlsx',
                7 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\ENTREGABLE\VentasLog.xlsm'
            ];
            $nameSp=$mapingSp[$request->typeSp] ?? "";
            $msgAlertFile=$msgAlert[$request->typeSp] ?? "";
            // sp
            $fechaHoy = Carbon::now()->toDateString();
            $validateSp=HistoryStoreProcedure::where('nombre_procedimiento','=', $nameSp)->whereDate('fecha_hora_registro', $fechaHoy)->exists();
            if(!($validateSp)){
                // $loadEntregable = DB::statement("EXEC $nameSp");
                $month=(int)$request->monthSp;
                $typeSpName= $request->typeSp;
                $fileExist=DB::select("SELECT dbo.fnCheckFileExists($typeSpName) AS fileExists");
                $textPathLoad=$pathFileInfo[$request->typeSp] ?? "";
                if($fileExist[0]->fileExists !=1){
                    return response()->json(["status" => Response::HTTP_OK, "message" => "El archivo {$msgAlertFile} no existe, porfavor cargalo en la ruta {$textPathLoad}"], Response::HTTP_OK);
                }
                $loadEntregable = DB::statement("EXEC $nameSp ?", [$month]);
                if ($loadEntregable) {
                    return response()->json(["status" => Response::HTTP_OK, "message" => "Se ejecuto exitosamente la carga del archivo {$msgAlertFile}"], Response::HTTP_OK);
                } else {
                    return response()->json(["status" => Response::HTTP_OK, "message" => "No se pudo ejecutar el Store Procedure {$mapingSp}"], Response::HTTP_OK);
                }
            }
            return response()->json(["status" => Response::HTTP_OK, "message" => "El archivo {$msgAlertFile} ya se ejecuto el dia de hoy"], Response::HTTP_OK);
            // return response()->json(["status" => Response::HTTP_OK, "message" => $nameSp], Response::HTTP_OK);
            
            // if ($request->hasFile('file_entregable') && $request->file('file_entregable')->isValid()) {
            //     $file = $request->file('file_entregable');
            //     $fileName = 'Entregable' . '.' . $file->getClientOriginalExtension();
            //     $pathEntregable = 'file_xlsx/' . $fileName;
            //     Storage::exists($pathEntregable) ? Storage::delete($pathEntregable) : false;
            //     $path = $file->storeAs('file_xlsx', $fileName);
            //     if ($path) {
            //         // server 
            //         // $pathAllEntregable=env("PATH_LOAD_XLSX").$fileName;
            //         // $loadEntregable=DB::select("EXEC spLoadFileEntregable ?", [$pathAllEntregable]);
            //         $loadEntregable = DB::statement("EXEC spLoadFileEntregable");
            //             if ($loadEntregable) {
            //                 return response()->json(["status" => Response::HTTP_OK, "message" => "Se ejecuto exitosamente la carga del archivo entregable"], Response::HTTP_OK);
            //             } else {
            //                 return response()->json(["status" => Response::HTTP_OK, "message" => "No se pudo ejecutar el Store Procedure spLoadFileEntregable"], Response::HTTP_OK);
            //             }
            //     }
            // } else {
            //     return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => "Problema al cargar el archivo entregable"], Response::HTTP_BAD_REQUEST);
            // }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    
    function loadFunnel(Request $request){
        try{
            $request->validate([
                'file_funnel' => 'required|file|max:51200',
            ]);
            if ($request->hasFile('file_funnel') && $request->file('file_funnel')->isValid()) {
                $file = $request->file('file_funnel');
                $fileName = 'Funnel'.'.'.$file->getClientOriginalExtension();
                $pathFunnel='file_xlsx/'.$fileName;
                Storage::exists($pathFunnel)? Storage::delete($pathFunnel):false;
                $path = $file->storeAs('file_xlsx', $fileName);
                if($path){
                    $loadEntregable=DB::statement("EXEC spLoadFileFunnel");
                    if ($loadEntregable) {
                        return response()->json(["status" => Response::HTTP_OK, "message" => "Se ejecuto exitosamente la carga del archivo funnel"], Response::HTTP_OK);
                    } else {
                        return response()->json(["status" => Response::HTTP_OK, "message" => "No se pudo ejecutar el Store Procedure spLoadFileFunnel"], Response::HTTP_OK);
                    }
                }
                // return response()->json([ "status" => Response::HTTP_OK, "message" => "Carga de archivo Funnel", "file_path" => Storage::url($path),
                //     "name_file"=>$fileName
                // ]);

            }else{
                return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => "Problema al cargar el archivo Funnel"], Response::HTTP_BAD_REQUEST);
            }
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    function validateLoadFile($typeFile){
        try{
            $msgAlert=[
                1 => "entregable",
                2 => "funnel",
                3 => "abono",
                4 => "avance diario",
                5 => "esquema",
                6 => "mesa de ayuda",
            ];
            $pathFileInfo=[
                1 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\ENTREGABLE\Entregable.xlsx',
                2 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\FUNNEL\Funnel.xlsm',
                3 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\ABONOS\Abonos.xlsx',
                4 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\AVANCE_DIARIO\carga_avance_multimarca.xlsx',
                5 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\ESQUEMAS\Listado de incentivos.xlsx',
                6 => 'PLANIFICACION\MAESTRAS\fuente_portal_AD\MESA DE AYUDA\Mesa_de_ayuda.xlsx'
            ];
            $msgAlertFile=$msgAlert[$typeFile] ?? "";
            $typeSpName= $typeFile;
            $fileExist=DB::select("SELECT dbo.fnCheckFileExists($typeSpName) AS fileExists");
            $textPathLoad=$pathFileInfo[$typeFile] ?? "";
            if($fileExist[0]->fileExists !=1){
                return response()->json(["status" => Response::HTTP_OK, "message" => "El archivo {$msgAlertFile} no existe, porfavor cargalo en la ruta {$textPathLoad}", "boolExist"=>0], Response::HTTP_OK);
            }else{
                return response()->json(["status" => Response::HTTP_OK, "message" => "El archivo {$msgAlertFile} existe","boolExist"=>1], Response::HTTP_OK);
            }
    }catch(\Exception $ex){
        return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
    }
        
    }
    function getZonal(){
        try{
            $listZonal=Zonal::get();
            if($listZonal){
                return response()->json(["status"=>Response::HTTP_OK, "message"=>"Existe lista de zonal", "data"=>$listZonal],Response::HTTP_OK); 
            }else{
                return response()->json(["status"=>Response::HTTP_OK, "message"=>"No hay zonal", "data"=>[]],Response::HTTP_OK,); 
            }
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    function historyIngreso($user, $fecha){
        try{
            $exitsDate=IngresoUser::exists();
            if($exitsDate){
                if($user !=0 && $fecha !=0){
                    $getUserData=IngresoUser::where('user','=',$user)->whereDate('fecha',$fecha)->get();
                    // $getUserData->makeHidden(['id']);
                }else{
                    if($user !=0){
                        $getUserData=IngresoUser::where('user','=',$user)->get();
                        // $getUserData->makeHidden(['id']);    
                    }
                    if($fecha !=0){
                        $getUserData=IngresoUser::whereDate('fecha',$fecha)->get();
                        // $getUserData->makeHidden(['id']);
                    }
                }
                // json obj
                // return
            return response()->json(["status" => Response::HTTP_OK, "message" => "Si hay historial de sesiones", "data"=>$getUserData], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_OK, "message" => "No hay historial de sesiones"], Response::HTTP_OK);
        }

        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
