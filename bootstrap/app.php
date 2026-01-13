<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use App\Http\Middleware\Cors;
return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
          $middleware->alias([
            'jwt.apiRest.jsMarket'=> \App\Http\Middleware\JwtJsMarket::class,
            'jwt.user.admin'=>\App\Http\Middleware\AdminMiddleware::class,
            'jwt.user.pdv'=>\App\Http\Middleware\PdvMiddleware::class,
            'jwt.user.multimarca'=>\App\Http\Middleware\MultimarcaMiddleware::class,
            'jwt.user.zonal'=>\App\Http\Middleware\ZonalMiddleware::class,
            'jwt.user.vvddzonal'=>\App\Http\Middleware\VvddZonalMiddleware::class,
        ]);
        $middleware->validateCsrfTokens(except: ['*']);
        $middleware->append(Cors::class);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
