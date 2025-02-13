<?php

use App\Http\Controllers\LoginController;
use Illuminate\Support\Facades\Route;


Route::post('/login', [LoginController::class, 'loginLocalUser'])->name('login.user.api');
Route::get('/validation-user/{user}', [LoginController::class, 'validarUser'])->name('validation.user.api');

