<?php

use App\Http\Controllers\LoginController;
use Illuminate\Support\Facades\Route;


Route::post('/users/login', [LoginController::class, 'loginLocalUser'])->name('login.user.api');
Route::get('/users/validation-user/{user}', [LoginController::class, 'validarUser'])->name('validation.user.api');


Route::middleware(['jwt.apiRest.jsMarket'])->group(function () {
    Route::get('/users/view-token-user', [LoginController::class, 'viewToken'])->name('viewPerfil.user.api');

});