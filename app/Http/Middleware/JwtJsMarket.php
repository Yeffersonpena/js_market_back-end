<?php

namespace App\Http\Middleware;

use Closure;
use Exception;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Tymon\JWTAuth\Exceptions\TokenExpiredException;
use Tymon\JWTAuth\Exceptions\TokenInvalidException;
use Tymon\JWTAuth\Facades\JWTAuth;

class JwtJsMarket
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        try {
            $token = $request->bearerToken();
            $tokenUserConsumer = JWTAuth::parseToken()->authenticate();
                } catch (Exception $e) {
                    if ($e instanceof TokenInvalidException) {
                        return response()->json(['status' => Response::HTTP_UNAUTHORIZED, 'message' => 'token invalido','token'=> $token], Response::HTTP_UNAUTHORIZED);
                    }
                    if ($e instanceof TokenExpiredException) {
                        return response()->json(['status' => Response::HTTP_UNAUTHORIZED, 'message' => 'token expirado','token'=> $token], Response::HTTP_UNAUTHORIZED);
                    }
                }
                if (empty($token)) {
                    return response()->json(['status' => Response::HTTP_BAD_REQUEST, 'message' => 'token vacio, por favor enviar un token','token'=> $token], Response::HTTP_BAD_REQUEST);
                }else{
                    return $next($request->merge(['user'=>$tokenUserConsumer]));
                }
                return $next($request);
    }
}
