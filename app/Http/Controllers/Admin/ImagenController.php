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
            $request->validate([
                'image' => 'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
                'año' => 'required|integer|min:2020|max:2030',
                'mes' => 'required|integer|min:1|max:12',
                'dateStar' => 'required|date_format:Y-m-d',
                'dateEnd' => 'required|date_format:Y-m-d|after_or_equal:dateStar',
                'type' => 'required|string',
                'modo' => 'required|string',
                'namePicture' => 'required|string',
                'zonal' => 'nullable' // puede venir string o array
            ]);

            $pictureAnio = $request->año;
            $pictureMes = $request->mes;
            $pictureDateStar = $request->dateStar; // 'Y-m-d'
            $pictureEnd = $request->dateEnd;       // 'Y-m-d'
            $pictureType = $request->type;
            $pictureModo = $request->modo;
            $pictureGroup = $request->group ?? '';
            $pictureZonal = $request->zonal ?? '';

            // Si zonal viene como array -> unirlo en un solo string (uno solo valor)
            if (is_array($pictureZonal)) {
                $pictureZonal = implode(', ', array_map('trim', $pictureZonal));
            } else {
                // trim y normalizar comas dobles si vienen mal
                $pictureZonal = trim(preg_replace('/\s*,\s*/', ', ', $pictureZonal));
            }

            $pictureFile = $request->file('image');
            $pictureName = $request->namePicture;
            $extenPicture = $pictureFile->getClientOriginalExtension();
            $nameFilePicture = $pictureName . '_' . $pictureDateStar . '_' . $pictureEnd . '_' . $pictureType . '_' . $pictureModo . '_' . $pictureGroup . '.' . $extenPicture;
            $request->file('image')->storeAs('img', $nameFilePicture, 'public');

            // Guardar historial de imagen (lo tenías bien)
            $historyFlyer = new PDVOutImagen();
            $historyFlyer->nombre_imagen = $nameFilePicture;
            $historyFlyer->fecha_modificacion = Carbon::now();
            $historyFlyer->save();

            // --- INSERT usando ELOQUENT (seguro frente a tipos y comillas) ---
            // Formatea fechas de forma segura para SQL Server: uso 'Ymd' para date (invariable por locale)
            $fechaInicioSafe = Carbon::createFromFormat('Y-m-d', $pictureDateStar)->format('Ymd');
            $fechaFinSafe   = Carbon::createFromFormat('Y-m-d', $pictureEnd)->format('Ymd');
            // fecha_creacion como datetime string (SQL Server aceptable)
            $fechaCreacion = Carbon::now()->format('Y-m-d H:i:s');

            $campana = PDVOutCampanasFlyers::create([
                'nombre_campaña'   => $pictureName,
                'foto_esquema'     => $nameFilePicture,
                'fecha_inicio'     => $fechaInicioSafe, // 'YYYYMMDD'
                'fecha_fin'        => $fechaFinSafe,    // 'YYYYMMDD'
                'tipoImg'          => $pictureType,
                'modo'             => $pictureModo,
                'criterio_filtro'  => $pictureGroup,
                'zonales'          => $pictureZonal,    // UNA sola cadena
                'activa'           => 1,
                'fecha_creacion'   => $fechaCreacion
            ]);

            // Ejecutar SP de sincronización (si lo necesitas)
            DB::statement('exec dbo.sp_Sincronizar_Flyers ?, ?', [$pictureAnio, $pictureMes]);

            if ($campana) {
                $imgUrl = env('APP_DOMAIN') . '/storage/img/' . $nameFilePicture;
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "Imagen subida exitosamente",
                    "urlPicture" => $imgUrl
                ], Response::HTTP_OK);
            }

            return response()->json(["status" => Response::HTTP_OK, "message" => "Error al subir la imagen"], Response::HTTP_OK);
        } catch (\Exception $ex) {
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
