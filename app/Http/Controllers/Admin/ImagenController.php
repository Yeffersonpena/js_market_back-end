<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\JsonResponse;
use App\Models\PDVOutImagen;
use App\Models\PDVOutCampanasFlyers;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Symfony\Component\HttpFoundation\Response;

class ImagenController extends Controller
{
    public function getPaginatedData(Request $request)
    {
        try {
            $existeUser = PDVOutImagen::exists();
            $search = $request->input('search', '');
            $perPage = $request->input('per_page', 10);

            if ($existeUser) {
                $listUser = PDVOutImagen::where('nombre_imagen', 'LIKE', "%$search%")
                    ->orderBy('fecha_modificacion', 'desc')
                    ->paginate($perPage);
                $data = $listUser->items();
                $data = array_map(function ($item) {
                    return [
                        'id' => $item->id,
                        'nombre_imagen' => $item->nombre_imagen,
                        'fecha_modificacion' => $item->fecha_modificacion,
                        'ruta_imagen' => env('APP_DOMAIN') . '/storage/img/' . $item->nombre_imagen,
                    ];
                }, $data);
                return response()->json([
                    'data' => $data,
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

    public function upload(Request $request): JsonResponse
    {
        $request->validate([
            'image' => 'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);
        $filename = $request->file('image')->getClientOriginalName();
        $request->file('image')->storeAs('img', $filename, 'public');

        PDVOutImagen::create([
            'nombre_imagen' => $filename,
            'fecha_modificacion' => Carbon::now(),
        ]);


        $imageUrl = env('APP_DOMAIN') . '/storage/img/' . $filename;
        return response()->json([
            'message' => 'Imagen subida exitosamente',
            'url' => $imageUrl,
        ]);
    }

    public function updateImg(Request $request)
    {
        try {
            $request->validate([
                'images' => 'required|array',
                'images.*' => 'image|mimes:jpeg,png,jpg,gif,svg|max:2048',
            ]);

            $imageUrls = [];
            foreach ($request->file('images') as $image) {
                $filename = $image->getClientOriginalName();
                $image->storeAs('img', $filename, 'public');
                $imageUrl = env('APP_DOMAIN') . '/storage/img/' . $filename;
                $imageUrls[] = $imageUrl;
            }
            return response()->json(['message' => 'Imagen subida exitosamente', 'url' => $imageUrls]);
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    public function delete($id): JsonResponse
    {
        $imagen = PDVOutImagen::find($id);
        if (!$imagen) {
            return response()->json(['message' => 'Imagen no encontrada'], 404);
        }
        $filePath = 'public/img/' . $imagen->nombre_imagen;
        if (Storage::exists($filePath)) {
            Storage::delete($filePath);
        }
        $imagen->delete();
        return response()->json(['message' => 'Imagen eliminada correctamente']);
    }

    public function update(Request $request, $id): JsonResponse
    {
        if (!$request->hasFile('image')) {
            return response()->json([
                'message' => 'No se recibió ninguna imagen en la petición',
            ], 400);
        }
        $request->validate([
            'image' => 'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);
        $imagen = PDVOutImagen::find($id);
        if (!$imagen) {
            return response()->json(['message' => 'Imagen no encontrada'], 404);
        }
        $oldFilePath = 'public/img/' . $imagen->nombre_imagen;
        if (Storage::exists($oldFilePath)) {
            Storage::delete($oldFilePath);
        }
        $filename = $request->file('image')->getClientOriginalName();
        $request->file('image')->storeAs('img', $filename, 'public');
        $imagen->update([
            'nombre_imagen' => $filename,
            'fecha_modificacion' => Carbon::now(),
        ]);
        $imageUrl = env('APP_DOMAIN') . '/storage/img/' . $filename;
        return response()->json([
            'message' => 'Imagen actualizada exitosamente',
            'url' => $imageUrl,
        ]);
    }

    public function load(Request $request)
    {
        try {
            // Validación
            $request->validate([
                'image'       => 'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
                'año'         => 'required|integer|min:2020|max:2030',
                'mes'         => 'required|integer|min:1|max:12',
                'dateStar'    => 'required|date_format:Y-m-d',
                'dateEnd'     => 'required|date_format:Y-m-d|after_or_equal:dateStar',
                'type'        => 'required|string',
                'modo'        => 'required|string',
                'namePicture' => 'required|string',
                'group'       => 'nullable|integer|min:0|max:4',
                'zonal'       => 'nullable|integer|min:0'
            ]);

            // Inputs
            $pictureAnio     = (int) $request->input('año');
            $pictureMes      = (int) $request->input('mes');
            $pictureDateStar = $request->input('dateStar'); // 'Y-m-d'
            $pictureEnd      = $request->input('dateEnd');  // 'Y-m-d'
            $pictureType     = (string) $request->input('type');
            $pictureModo     = (string) $request->input('modo');
            
            // Mapear grupo de número a texto
            $grupoMapping = [
                1 => "G1",
                2 => "G2", 
                3 => "G3",
                4 => "Pdv Premium"
            ];
            $grupoNumber = (int) ($request->input('group') ?? 0);
            $pictureGroup = $grupoMapping[$grupoNumber] ?? '';

            // Manejar zonales - SIMPLIFICADO PARA VALIDAR
            $pictureZonal = 'HOLA';

            // Manejo del archivo
            $pictureFile     = $request->file('image');
            $pictureName     = $request->input('namePicture');
            $extenPicture    = $pictureFile->getClientOriginalExtension();
            $nameFilePicture = $pictureName . '_' . $pictureDateStar . '_' . $pictureEnd . '_' . $pictureType . '_' . $pictureModo . '_' . $pictureGroup . '.' . $extenPicture;
            $request->file('image')->storeAs('img', $nameFilePicture, 'public');

            // Guardar historial de imagen
            $historyFlyer = new \App\Models\PDVOutImagen();
            $historyFlyer->nombre_imagen = $nameFilePicture;
            $historyFlyer->fecha_modificacion = \Carbon\Carbon::now();
            $historyFlyer->save();

            // Fechas - usar formato que SQL Server acepta
            $fechaInicio   = $pictureDateStar; // Ya viene en formato Y-m-d
            $fechaFin      = $pictureEnd;      // Ya viene en formato Y-m-d
            $fechaCreacion = \Carbon\Carbon::now()->format('Y-m-d H:i:s');

            // DEBUG: log antes del insert
            Log::info('Insertando en PDV_OUT_CAMPAÑAS_FLYERS', [
                'nombre_campaña'  => $pictureName,
                'foto_esquema'    => $nameFilePicture,
                'fecha_inicio'    => $fechaInicio,
                'fecha_fin'       => $fechaFin,
                'tipoImg'         => $pictureType,
                'modo'            => $pictureModo,
                'criterio_filtro' => $pictureGroup,
                'zonales'         => $pictureZonal,
                'activa'          => 1,
                'fecha_creacion'  => $fechaCreacion,
            ]);

            // SQL con CAST para fechas
            $sql = "INSERT INTO [PDV_OUT_CAMPAÑAS_FLYERS] 
            ([nombre_campaña], [foto_esquema], [fecha_inicio], [fecha_fin], [tipoImg], [modo], [criterio_filtro], [zonales], [activa], [fecha_creacion])
            VALUES (?, ?, CAST(? AS DATE), CAST(? AS DATE), ?, ?, ?, ?, ?, ?)";

            $pdo = DB::connection('sqlsrv')->getPdo();
            $stmt = $pdo->prepare($sql);

            $stmt->bindValue(1, $pictureName, \PDO::PARAM_STR);
            $stmt->bindValue(2, $nameFilePicture, \PDO::PARAM_STR);
            $stmt->bindValue(3, $fechaInicio, \PDO::PARAM_STR);
            $stmt->bindValue(4, $fechaFin, \PDO::PARAM_STR);
            $stmt->bindValue(5, $pictureType, \PDO::PARAM_STR);
            $stmt->bindValue(6, $pictureModo, \PDO::PARAM_STR);
            $stmt->bindValue(7, $pictureGroup, \PDO::PARAM_STR);
            $stmt->bindValue(8, $pictureZonal, \PDO::PARAM_STR);
            $stmt->bindValue(9, 1, \PDO::PARAM_INT);
            $stmt->bindValue(10, $fechaCreacion, \PDO::PARAM_STR);

            $executed = $stmt->execute();

            if (!$executed) {
                $err = $stmt->errorInfo();
                Log::error('Error PDO insert', $err);
                throw new \Exception('Error en insert PDO: ' . json_encode($err));
            }

            // Ejecutar SP de sincronización
            //DB::statement('exec dbo.sp_Sincronizar_Flyers ?, ?', [$pictureAnio, $pictureMes]);

            // Respuesta
            $imgUrl = env('APP_DOMAIN') . '/storage/img/' . $nameFilePicture;
            return response()->json([
                "status"     => Response::HTTP_OK,
                "message"    => "Imagen subida exitosamente",
                "urlPicture" => $imgUrl
            ], Response::HTTP_OK);
        } catch (\PDOException $pdoEx) {
            Log::error('PDOException en load', ['message' => $pdoEx->getMessage(), 'trace' => $pdoEx->getTraceAsString()]);
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $pdoEx->getMessage()], Response::HTTP_BAD_REQUEST);
        } catch (\Exception $ex) {
            Log::error('Exception en load', ['message' => $ex->getMessage(), 'trace' => $ex->getTraceAsString()]);
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }



    public function getCampanasFlyers(Request $request, $año, $mes)
    {
        try {
            // Validar los parámetros de la ruta
            $validator = Validator::make([
                'año' => $año,
                'mes' => $mes
            ], [
                'año' => 'required|integer|min:2020|max:2030',
                'mes' => 'required|integer|min:1|max:12'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    "status" => Response::HTTP_BAD_REQUEST,
                    "message" => "Parámetros inválidos",
                    "errors" => $validator->errors()
                ], Response::HTTP_BAD_REQUEST);
            }

            $campanas = PDVOutCampanasFlyers::whereYear('fecha_inicio', $año)
                ->whereMonth('fecha_inicio', $mes)
                ->orderBy('fecha_creacion', 'desc')
                ->get();

            return response()->json([
                "status" => Response::HTTP_OK,
                "data" => $campanas,
                "total" => $campanas->count()
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        }
    }
}
