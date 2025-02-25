<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\JsonResponse;
use App\Models\PDVOutImagen;
use Carbon\Carbon;
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
                        'ruta_imagen' =>env('APP_DOMAIN').'/storage/img/'.$item->nombre_imagen,
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
        $path = $request->file('image')->store('images', 'public');
        $filename = basename($path);
        PDVOutImagen::create([
            'nombre_imagen' => $filename,
            'fecha_modificacion' => Carbon::now(),
        ]);

        return response()->json([
            'message' => 'Imagen subida exitosamente',
            'url' => Storage::url($path),
        ]);
    }

    public function deleteImage($id)
    {
        $imagen = PDVOutImagen::find($id);

        if (!$imagen) {
            return response()->json(['message' => 'Imagen no encontrada'], 404);
        }

        $imagePath = 'public/uploads/' . $imagen->nombre_imagen;
        if (Storage::exists($imagePath)) {
            Storage::delete($imagePath);
        }

        $imagen->delete();

        return response()->json(['message' => 'Imagen eliminada exitosamente'], 200);
    }
}
