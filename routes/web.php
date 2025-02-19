<?php

use App\Http\Controllers\Admin\GestorController;
use App\Http\Controllers\All\LogicController;
use App\Http\Controllers\Controller;
use App\Http\Controllers\LoginController;
use App\Http\Controllers\Multimarca\AvanceDiarioController as MultimarcaAvanceDiarioController;
use App\Http\Controllers\Pdv\AvanceDiarioController;
use Illuminate\Support\Facades\Route;


Route::post('/api/v1/users/login', [LoginController::class, 'loginLocalUser'])->name('login.user.api');
Route::get('/api/v1/users/validation-user/{user}', [LoginController::class, 'validarUser'])->name('validation.user.api');

// Route::get('/users/create-user', [Controller::class, 'createUser'])->name('create.user.api');


Route::middleware(['jwt.apiRest.jsMarket'])->group(function () {
    Route::get('/api/v1/users/view-token-user', [LoginController::class, 'viewToken'])->name('viewPerfil.user.api');
    
});


Route::middleware(['jwt.apiRest.jsMarket', 'jwt.user.admin'])->group(function () {
    Route::post('/api/v1/admin/create-user', [LoginController::class, 'createUser_new'])->name('create.user.api');
    Route::get('/api/v1/admin/getListUser', [GestorController::class, 'getListUser'])->name('getListUser.user.api');
    Route::get('/api/v1/admin/deleteUser/{dni}', [GestorController::class, 'deleteUser'])->name('delete.user.api');
    Route::put('/api/v1/admin/updateUser/{dni}', [GestorController::class, 'updateDataUser'])->name('update.user.api');
    Route::get('/api/v1/admin/getListPerfil', [GestorController::class, 'getListPerfil'])->name('getListPerfil.user.api');

});
Route::middleware(['jwt.apiRest.jsMarket', 'jwt.user.pdv'])->group(function () {
    Route::get('/api/v1/pdv/getAvanceDiario/{dni}/{anio}/{mes}', [LogicController::class, 'getAvanceDiario'])->name('avanceDiarioMM.user.api');
    Route::get('/api/v1/pdv/getFlyers/{dni}/{anio}/{mes}', [LogicController::class, 'getFlyers'])->name('flyers.user.api');
    Route::get('/api/v1/pdv/getAbono/{dni}/{anio}/{mes}', [LogicController::class, 'getAbono'])->name('flyers.user.api');
    Route::get('/api/v1/pdv/getHistoryVenta/{dni}/{anio}/{mes}', [LogicController::class, 'getHistoryVenta'])->name('history.user.api');
    Route::get('/api/v1/pdv/getDataPdv/{dni}/{anio}/{mes}', [AvanceDiarioController::class, 'getDataPdv'])->name('getDataPdv.user.api');
    // 
    Route::get('/api/v1/pdv/getAllMonto/{dni}/{anio}/{mes}', [AvanceDiarioController::class, 'getAllMonto'])->name('getAllMonto.user.api');

});
Route::middleware(['jwt.apiRest.jsMarket', 'jwt.user.multimarca'])->group(function () {
    Route::get('/api/v1/multimarca/getAvanceDiario/{dni}/{anio}/{mes}', [LogicController::class, 'getAvanceDiario'])->name('avanceDiarioMM.user.api');
    Route::get('/api/v1/multimarca/getFlyers/{dni}/{anio}/{mes}', [LogicController::class, 'getFlyers'])->name('flyers.user.api');
    Route::get('/api/v1/multimarca/getAbono/{dni}/{anio}/{mes}', [LogicController::class, 'getAbono'])->name('flyers.user.api');
    // Route::get('/api/v1/multimarca/getAbono/{dni}/{anio}/{mes}', [LogicController::class, 'getAbono'])->name('flyers.user.api');
    Route::get('/api/v1/multimarca/getHistoryVenta/{dni}/{anio}/{mes}', [LogicController::class, 'getHistoryVenta'])->name('history.user.api');
    Route::get('/api/v1/multimarca/getDataMM/{dni}/{anio}/{mes}', [LogicController::class, 'getDataMM'])->name('getDataMM.user.api');
    
});
