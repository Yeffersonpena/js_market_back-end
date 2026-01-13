<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ZonalMiddleware
{
    /**
     * Handle an incoming request.
     * Verifica que el usuario tenga perfil de jefe zonal
     * Asume que idPerfil 4 es jefe zonal (ajustar según corresponda)
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->get('user');

        // Verificar que el usuario tenga perfil de jefe zonal
        // idPerfil 4 = Jefe Zonal (ajustar según la configuración real)
        // Alternativamente, se puede verificar por lógica de negocio (ej: tiene zonal asignado y perfil específico)
        if ($user['idPerfil'] != 4) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'Usuario sin permiso de jefe zonal'
            ], Response::HTTP_UNAUTHORIZED);
        }

        // Verificar que tenga zonal asignado
        if (empty($user['zonal'])) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'Usuario sin zonal asignado'
            ], Response::HTTP_UNAUTHORIZED);
        }

        return $next($request);
    }
}

