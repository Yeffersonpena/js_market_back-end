<?php

use App\Http\Controllers\Admin\ImagenController;
use App\Http\Controllers\All\LogicController;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

it('rechaza un tamaño de página no permitido para administradores', function () {
    $request = Request::create('/', 'GET', [
        'page' => 1,
        'per_page' => 50,
        'tipo' => 'Todos',
        'multi_tienda' => 'Todos',
    ]);

    $response = app(ImagenController::class)->getCartasContratos($request, 2026);
    $payload = $response->getData(true);

    expect($response->getStatusCode())->toBe(Response::HTTP_BAD_REQUEST)
        ->and($payload['errors'])->toHaveKey('per_page');
});

it('rechaza tipos ajenos a cartas y contratos para administradores', function () {
    $request = Request::create('/', 'GET', [
        'page' => 1,
        'per_page' => 10,
        'tipo' => 'ACELERADOR',
        'multi_tienda' => 'Todos',
    ]);

    $response = app(ImagenController::class)->getCartasContratos($request, 2026);
    $payload = $response->getData(true);

    expect($response->getStatusCode())->toBe(Response::HTTP_BAD_REQUEST)
        ->and($payload['errors'])->toHaveKey('tipo');
});

it('rechaza filtros inválidos para pdv y multimarca antes de consultar datos', function () {
    $request = Request::create('/', 'GET', [
        'page' => 0,
        'per_page' => 20,
        'tipo' => 'Cartas',
        'multi_tienda' => 'DESCONOCIDO',
    ]);

    $response = app(LogicController::class)->getCartasContratos($request, '00000000', 2026);
    $payload = $response->getData(true);

    expect($response->getStatusCode())->toBe(Response::HTTP_BAD_REQUEST)
        ->and($payload['errors'])->toHaveKeys(['page', 'multi_tienda']);
});

it('rechaza años fuera del rango soportado sin consultar la base', function () {
    $request = Request::create('/', 'GET', [
        'page' => 1,
        'per_page' => 10,
        'tipo' => 'Contratos',
        'multi_tienda' => 'NO',
    ]);

    $response = app(LogicController::class)->getCartasContratos($request, '00000000', 2031);
    $payload = $response->getData(true);

    expect($response->getStatusCode())->toBe(Response::HTTP_BAD_REQUEST)
        ->and($payload['errors'])->toHaveKey('anio');
});
