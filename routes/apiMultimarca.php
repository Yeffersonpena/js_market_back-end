<?php

use App\Http\Controllers\Controller;
use App\Http\Controllers\LoginController;
use App\Http\Controllers\Multimarca\AvanceDiarioController as MultimarcaAvanceDiarioController;
use App\Http\Controllers\Pdv\AvanceDiarioController;
use Illuminate\Support\Facades\Route;


// Route::post('/users/login', [LoginController::class, 'loginLocalUser'])->name('login.user.api');
// Route::get('/users/validation-user/{user}', [LoginController::class, 'validarUser'])->name('validation.user.api');

// // Route::get('/users/create-user', [Controller::class, 'createUser'])->name('create.user.api');
// Route::post('/users/create-user', [LoginController::class, 'createUser_new'])->name('create.user.api');


Route::get('/api/v1/multimarca/getAvanceDiario/{dni}', [MultimarcaAvanceDiarioController::class, 'getAvanceDiario'])->name('avanceDiarioMM  .user.api');
Route::middleware(['jwt.apiRest.jsMarket'])->group(function () {

});