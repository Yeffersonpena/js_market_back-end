<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Perfil;

class PerfilController extends Controller
{
    public function index()
    {
        $perfiles = Perfil::all();
        return response()->json($perfiles);
    }

    public function store(Request $request)
    {
        $request->validate([
            'perfil' => 'required|string|max:200',
        ]);
        $perfil = Perfil::create([
            'perfil' => $request->perfil,
        ]);
        return response()->json(['message' => 'Perfil creado', 'data' => $perfil], 201);
    }

    public function show($id)
    {
        $perfil = Perfil::find($id);
        if (!$perfil) {
            return response()->json(['message' => 'Perfil no encontrado'], 404);
        }
        return response()->json($perfil);
    }

    public function update(Request $request, $id)
    {
        $perfil = Perfil::find($id);

        if (!$perfil) {
            return response()->json(['message' => 'Perfil no encontrado'], 404);
        }
        $request->validate([
            'perfil' => 'required|string|max:200',
        ]);
        $perfil->update([
            'perfil' => $request->perfil,
        ]);
        return response()->json(['message' => 'Perfil actualizado', 'data' => $perfil]);
    }

    public function destroy($id)
    {
        $perfil = Perfil::find($id);

        if (!$perfil) {
            return response()->json(['message' => 'Perfil no encontrado'], 404);
        }
        $perfil->delete();
        return response()->json(['message' => 'Perfil eliminado']);
    }
}
