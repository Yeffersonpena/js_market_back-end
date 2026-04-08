<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RecopilacionMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->get('user');
        $idPerfil = $user ? (int) data_get($user, 'idPerfil', 0) : 0;

        // 6 = ejecutor (DNI), 7 = supervisor zonal (login tipo ayacucho/cusco/...)
        if (!$user || ! in_array($idPerfil, [6, 7], true)) {
            return response()->json(
                [
                    'status' => Response::HTTP_UNAUTHORIZED,
                    'message' => 'Usuario sin permiso de recopilacion',
                ],
                Response::HTTP_UNAUTHORIZED
            );
        }

        return $next($request);
    }
}

