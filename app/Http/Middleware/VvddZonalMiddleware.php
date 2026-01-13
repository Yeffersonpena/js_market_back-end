<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class VvddZonalMiddleware
{
    /**
     * Handle an incoming request.
     * Verifica que el usuario tenga perfil de vendedor zonificado
     * Asume que idPerfil 5 es vendedor zonificado (ajustar según corresponda)
     *
     * Nota: El vendedor zonificado es diferente al usuario PDV (punto de venta)
     * El vendedor zonificado es quien visita los puntos de venta
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->get('user');

        // Verificar que el usuario tenga perfil de vendedor zonificado
        // idPerfil 5 = Vendedor Zonificado (ajustar según la configuración real)
        if ($user['idPerfil'] != 5) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'Usuario sin permiso de vendedor zonificado'
            ], Response::HTTP_UNAUTHORIZED);
        }

        return $next($request);
    }
}

