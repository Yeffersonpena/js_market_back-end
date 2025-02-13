<?php

use App\Http\Controllers\Admin\LoginController as AdminLoginController;
use Illuminate\Support\Facades\Route;
// use App\Http\Controllers\LoginController;
// use App\Http\Controllers\ViewController;


// Route::post('/login', [AdminLoginController::class, 'login'])->name('login.admin.api');
//     Route::middleware(['jwt.apiRest.tonarum','jwt.user.admin'])->group(function () {
//         Route::get('/perfil', [AdminLoginController::class, 'perfil'])->name('perfil.admin.api');
    
//     Route::get('/view-token-user', [AdminLoginController::class, 'viewToken'])->name('viewPerfil.admin.api');
// });