<?php

use App\Http\Controllers\Admin\GestorController;
use App\Http\Controllers\All\LogicController;
use App\Http\Controllers\Controller;
use App\Http\Controllers\LoginController;
use App\Http\Controllers\Multimarca\AvanceDiarioController as MultimarcaAvanceDiarioController;
use App\Http\Controllers\Pdv\AvanceDiarioController;
use App\Http\Controllers\Admin\PerfilController;
use App\Http\Controllers\Admin\ImagenController;
use App\Http\Controllers\Admin\MenuPerfilController;
use Illuminate\Support\Facades\Route;


Route::post('/api/v1/users/login', [LoginController::class, 'loginLocalUser'])->name('login.user.api');
Route::get('/api/v1/users/validation-user/{user}', [LoginController::class, 'validarUser'])->name('validation.user.api');

// Route::get('/users/create-user', [Controller::class, 'createUser'])->name('create.user.api');


Route::middleware(['jwt.apiRest.jsMarket'])->group(function () {
    Route::get('/api/v1/users/view-token-user', [LoginController::class, 'viewToken'])->name('viewPerfil.user.api');
    Route::get('/api/v1/menu-perfil/permisos', [MenuPerfilController::class, 'getPermisosPerfil']);
    Route::patch('/api/v1/users/actualizar-clave', [GestorController::class, 'actualizaClave'])->name('actualizaClave.user.api');
});


Route::middleware(['jwt.apiRest.jsMarket', 'jwt.user.admin'])->group(function () {
    Route::post('/api/v1/users', [LoginController::class, 'createUserSp'])->name('create.user.api');
    Route::post('/api/v1/users/registro-masivo', [LoginController::class, 'createUserAll'])->name('createAll.user.api');
    Route::get('/api/v1/users/getListUser', [GestorController::class, 'getListUser'])->name('getListUser.user.api');
    Route::get('/api/v1/admin/deleteUser/{dni}', [GestorController::class, 'deleteUser'])->name('delete.user.api');
    Route::put('/api/v1/users/{dni}', [GestorController::class, 'updateDataUser'])->name('update.user.api');
    Route::get('/api/v1/admin/getListPerfil', [GestorController::class, 'getListPerfil'])->name('getListPerfil.user.api');

    Route::get('/api/v1/admin/perfiles', [PerfilController::class, 'index'])->name('getListPerfil.perfil.api');
    Route::post('/api/v1/admin/perfiles', [PerfilController::class, 'store'])->name('createPerfil.perfil.api');
    Route::get('/api/v1/admin/perfiles/{idPerfil}', [PerfilController::class, 'show'])->name('getPerfil.perfil.api');
    Route::put('/api/v1/admin/perfiles/{idPerfil}', [PerfilController::class, 'update'])->name('updatePerfil.perfil.api');
    Route::delete('/api/v1/admin/perfiles/{idPerfil}', [PerfilController::class, 'destroy'])->name('deletePerfil.perfil.api');

    Route::get('/api/v1/imagenes', [ImagenController::class, 'getPaginatedData'])->name('getPaginatedData.imagen.api');
    Route::post('/api/v1/imagenes', [ImagenController::class, 'upload'])->name('upload.imagen.api');
    Route::post('/api/v1/imagenes/actualiza/{id}', [ImagenController::class, 'update'])->name('update.imagen.api');
    Route::delete('/api/v1/imagenes/{id}', [ImagenController::class, 'delete'])->name('delete.imagen.api');

    Route::post('/api/v1/admin/updateEntregable', [GestorController::class, 'loadEntregable'])->name('entregable.carga.api');
    Route::post('/api/v1/admin/updateFunnel', [GestorController::class, 'loadFunnel'])->name('funnel.carga.api');

    Route::get('/api/v1/menu-perfil/asignados/{idPerfil}', [MenuPerfilController::class, 'obtenerMenusAsignados']);
    Route::get('/api/v1/menu-perfil/no-asignados/{idPerfil}', [MenuPerfilController::class, 'obtenerMenusNoAsignados']);
    Route::post('/api/v1/menu-perfil', [MenuPerfilController::class, 'asignarMenu']);
    Route::delete('/api/v1/menu-perfil/{idMenuPerfil}', [MenuPerfilController::class, 'eliminarMenu']);
});
Route::middleware(['jwt.apiRest.jsMarket', 'jwt.user.pdv'])->group(function () {
    Route::get('/api/v1/pdv/getDataPdv/{dni}/{anio}/{mes}', [AvanceDiarioController::class, 'getDataPdv'])->name('getDataPdv.user.api');
    Route::get('/api/v1/pdv/getAvanceDiario/{dni}/{anio}/{mes}', [LogicController::class, 'getAvanceDiario'])->name('avanceDiarioMM.user.api');
    Route::get('/api/v1/pdv/getAbono/{dni}/{anio}/{mes}', [LogicController::class, 'getAbono'])->name('flyers.user.api');
    Route::get('/api/v1/pdv/getHistoryVenta/{dni}/{anio}/{mes}', [LogicController::class, 'getHistoryVenta'])->name('history.user.api');
    Route::get('/api/v1/pdv/getAllMonto/{dni}/{anio}/{mes}', [AvanceDiarioController::class, 'getAllMonto'])->name('getAllMonto.user.api');
    Route::get('/api/v1/pdv/getFlyers/{dni}/{anio}/{mes}', [LogicController::class, 'getFlyers'])->name('flyers.user.api');

});
Route::middleware(['jwt.apiRest.jsMarket', 'jwt.user.multimarca'])->group(function () {
    Route::get('/api/v1/multimarca/getDataMM/{dni}/{anio}/{mes}', [LogicController::class, 'getDataMM'])->name('getDataMM.user.api');
    Route::get('/api/v1/multimarca/getAvanceDiario/{dni}/{anio}/{mes}', [LogicController::class, 'getAvanceDiario'])->name('avanceDiarioMM.user.api');
    Route::get('/api/v1/multimarca/getFlyers/{dni}/{anio}/{mes}', [LogicController::class, 'getFlyers'])->name('flyers.user.api');
    Route::get('/api/v1/multimarca/getAbono/{dni}/{anio}/{mes}', [LogicController::class, 'getAbono'])->name('flyers.user.api');
    // Route::get('/api/v1/multimarca/getAbono/{dni}/{anio}/{mes}', [LogicController::class, 'getAbono'])->name('flyers.user.api');
    Route::get('/api/v1/multimarca/getHistoryVenta/{dni}/{anio}/{mes}', [LogicController::class, 'getHistoryVenta'])->name('history.user.api');
    
});
