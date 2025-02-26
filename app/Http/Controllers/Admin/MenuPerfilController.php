<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\Request;
use App\Models\MenuPerfil;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\Controller;
use Tymon\JWTAuth\Facades\JWTAuth;

class MenuPerfilController extends Controller
{
    public function asignarMenu(Request $request)
    {
        $request->validate([
            'idMenu' => 'required|integer',
            'idPerfil' => 'required|integer'
        ]);

        $existe = MenuPerfil::where('idMenu', $request->idMenu)
            ->where('idPerfil', $request->idPerfil)
            ->exists();
        if ($existe) {
            return response()->json(['message' => 'El menú ya está asignado a este perfil'], 400);
        }
        MenuPerfil::create([
            'idMenu' => $request->idMenu,
            'idPerfil' => $request->idPerfil
        ]);
        return response()->json(['message' => 'Menú asignado correctamente'], 201);
    }

    public function obtenerMenusAsignados($idPerfil)
    {
        $menus = DB::table('tbl_menu')
            ->join('tbl_menu_perfil', 'tbl_menu.idMenu', '=', 'tbl_menu_perfil.idMenu')
            ->where('tbl_menu_perfil.idPerfil', $idPerfil)
            ->orderBy('tbl_menu.orden')
            ->select([
                'tbl_menu_perfil.idMenuPerfil as id',
                'tbl_menu.nombre as menu'
            ])
            ->get();
        return response()->json($menus);
    }

    public function getPermisosPerfil()
    {
        $datosToken = JWTAuth::parseToken()->authenticate();
        $menus = DB::table('tbl_menu')
            ->join('tbl_menu_perfil', 'tbl_menu.idMenu', '=', 'tbl_menu_perfil.idMenu')
            ->where('tbl_menu_perfil.idPerfil', $datosToken->idPerfil)
            ->orderBy('tbl_menu.orden')
            ->select([
                'tbl_menu.idMenu as id',
                'tbl_menu.menu',
                'tbl_menu.ruta',
                'tbl_menu.icono',
                'tbl_menu.orden'
            ])
            ->get();
        return response()->json($menus);
    }

    public function obtenerMenusNoAsignados($idPerfil)
    {
        $menus = DB::table('tbl_menu')
            ->whereNotExists(function ($query) use ($idPerfil) {
                $query->select(DB::raw(1))
                    ->from('tbl_menu_perfil')
                    ->whereRaw('tbl_menu_perfil.idMenu = tbl_menu.idMenu')
                    ->where('tbl_menu_perfil.idPerfil', $idPerfil);
            })
            ->orderBy('tbl_menu.orden')
            ->select([
                'tbl_menu.idMenu as id',
                'tbl_menu.nombre as menu'
            ])
            ->get();
        return response()->json($menus);
    }

    public function eliminarMenu($idMenuPerfil)
    {
        $menu = MenuPerfil::find($idMenuPerfil);
        if (!$menu) {
            return response()->json(['message' => 'Menú no encontrado'], 404);
        }
        $menu->delete();
        return response()->json(['message' => 'Menú eliminado correctamente']);
    }
}
