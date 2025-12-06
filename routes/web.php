<?php

use App\Http\Controllers\Admin\AdminController;
use App\Http\Controllers\Admin\Config\ConfigController;
use App\Http\Controllers\Admin\GestorController;
use App\Http\Controllers\Admin\GestorEntregableController;
use App\Http\Controllers\All\LogicController;
use App\Http\Controllers\Controller;
use App\Http\Controllers\LoginController;
use App\Http\Controllers\Multimarca\AvanceDiarioController as MultimarcaAvanceDiarioController;
use App\Http\Controllers\Pdv\AvanceDiarioController;
use App\Http\Controllers\Admin\PerfilController;
use App\Http\Controllers\Admin\ImagenController;
use App\Http\Controllers\Admin\MenuPerfilController;
use App\Http\Controllers\Admin\ImportacionController;
use App\Http\Controllers\Admin\ReporteController;
use App\Http\Controllers\General\IncidenciaController;
use App\Http\Controllers\Multimarca\MultimarcaControlller;
use App\Http\Controllers\Multimarca\VentasRecargasController;
use App\Http\Controllers\SupervisorController;
use App\Models\PDV_ABONOS;
use Illuminate\Support\Facades\Route;

Route::get('/view/loadImagenPicture', function () {
    return view('view');
});
Route::post('/api/v1/imagenes/allImg', [ImagenController::class, 'updateImg'])->name('updateImg.imagen.api');
Route::get('/view/reporte/viewReporte', function(){ return view('reporte');});
// Route::get('/view/reporte/mm/viewReporte', function(){ return view('reporte');});
Route::get('/api/v1/reporte/all', [ReporteController::class, 'reporteAll'])->name('reporteAll.reporte.api');
Route::get('/api/v1/reporte/pdv-regular', [ReporteController::class, 'reportePdvRegular'])->name('reportePdvRegular.reporte.api');
Route::get('/api/v1/reporte/pdv-premium', [ReporteController::class, 'reportePremiun'])->name('reportePremium.reporte.api');
// Route::get('/api/v1/reporte/pdv-premiun', [ReporteController::class, 'reporteMultimarca'])->name('reporteMultimarca.reporte.api');
Route::get('/api/v1/reporte/mm/getReporte/{typeReporte}', [ReporteController::class, 'getReporte'])->name('getReporteMM.reporte.api');
Route::get('/api/v1/reporte/pdv/getReporte/{typeReporte}', [ReporteController::class, 'getReportePdv'])->name('getReportePdv.reporte.api');
Route::get('/api/v1/reporte/all/getFinanza/{typeReporte}/{anio}/{mes}', [ReporteController::class, 'getReporteFinanza'])->name('getFinanza.reporte.api');
Route::get('/api/v1/reporte/getFin',[LoginController::class, 'testRep']);

Route::get('/api/v1/test/server', function () {
    return response()->json(["status" => 200, "message" => "server start"]);
});
Route::get('/api/v1/test/db', function (){
    $test=PDV_ABONOS::where('año','=','2025')->where('mes','=','2')->first();
    return response()->json(["status"=>200, "message"=>$test]);
});
Route::post('/api/v1/users/login', [LoginController::class, 'loginLocalUser'])->name('login.user.api');
Route::get('/api/v1/users/validation-user/{user}', [LoginController::class, 'validarUser'])->name('validation.user.api');
// Route::get('/api/v1/users/ingreso', [LoginController::class, 'ingreso'])->name('ingreso.user.api');

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

    Route::get('/api/v1/admin/perfiles', [PerfilController::class, 'index'])->name('getListPerfilAll.perfil.api');
    Route::post('/api/v1/admin/perfiles', [PerfilController::class, 'store'])->name('createPerfil.perfil.api');
    Route::get('/api/v1/admin/perfiles/{idPerfil}', [PerfilController::class, 'show'])->name('getPerfil.perfil.api');
    Route::put('/api/v1/admin/perfiles/{idPerfil}', [PerfilController::class, 'update'])->name('updatePerfil.perfil.api');
    Route::delete('/api/v1/admin/perfiles/{idPerfil}', [PerfilController::class, 'destroy'])->name('deletePerfil.perfil.api');

    Route::get('/api/v1/imagenes/listado', [ImagenController::class, 'getPaginatedData'])->name('getPaginatedData.imagen.api');
    Route::post('/api/v1/imagenes', [ImagenController::class, 'upload'])->name('upload.imagen.api');
    Route::post('/api/v1/imagenes/actualiza/{id}', [ImagenController::class, 'update'])->name('update.imagen.api');
    Route::delete('/api/v1/imagenes/{id}', [ImagenController::class, 'delete'])->name('delete.imagen.api');
    // Route::post('/api/v1/imagenes/allImg', [ImagenController::class, 'updateImg'])->name('updateImg.imagen.api');
    Route::post('/api/v1/imagenes/load', [ImagenController::class, 'load'])->name('load.imagen.api');
    Route::get('/api/v1/imagenes/campanas-flyers/{año}/{mes}', [ImagenController::class, 'getCampanasFlyers'])->name('getCampanasFlyers.imagen.api');
    Route::post('/api/v1/imagenes/eliminar-flyer', [ImagenController::class, 'eliminarFlyer'])->name('eliminarFlyer.imagen.api');

    // Rutas para comunicación de aceleradores
    Route::post('/api/v1/imagenes/campanas/{id}/comunicacion-acelerador', [ImagenController::class, 'updateComunicacionAcelerador'])->name('updateComunicacionAcelerador.imagen.api');
    Route::get('/api/v1/imagenes/campanas/download-secure/{fileName}', [ImagenController::class, 'downloadSecureFile'])->name('downloadSecureFile.imagen.api');

    Route::post('/api/v1/admin/updateFileSp', [GestorController::class, 'loadFileSp'])->name('fileSp.carga.api');
    Route::get('/api/v1/admin/validateFileLoad/{typeFile}', [GestorController::class, 'validateLoadFile'])->name('validateLoadFile.carga.api');

    // Route::post('/api/v1/admin/updateFunnel', [GestorController::class, 'loadFunnel'])->name('funnel.carga.api');

    Route::get('/api/v1/menu-perfil/asignados/{idPerfil}', [MenuPerfilController::class, 'obtenerMenusAsignados']);
    Route::get('/api/v1/menu-perfil/no-asignados/{idPerfil}', [MenuPerfilController::class, 'obtenerMenusNoAsignados']);
    Route::post('/api/v1/menu-perfil', [MenuPerfilController::class, 'asignarMenu']);
    Route::delete('/api/v1/menu-perfil/{idMenuPerfil}', [MenuPerfilController::class, 'eliminarMenu']);

    Route::get('/api/v1/importaciones/hoy', [ImportacionController::class, 'getLogActual']);
    Route::get('/api/v1/admin/historyIngreso/{user}/{fecha}/{zonal}', [GestorController::class, 'historyIngreso'])->name('historyIngreso.admin.api');
    Route::get('/api/v1/admin/getListZonal', [GestorController::class, 'getZonal'])->name('zonal.admin.api');
    // supervisor
    Route::get('/api/v1/admin/getListGroup', [AdminController::class, 'getListGroup'])->name('getListGroup.supervisor.api');
    Route::get('/api/v1/admin/getListFlyers/{dateStart}', [AdminController::class, 'getListFlyers'])->name('getListFlyers.admin.api');
    // get list two db
    Route::get('/api/v1/admin/twoDb/getListEntregable/{dni}/{anio}/{mes}', [AdminController::class, 'getListEntregable'])->name('getListEntregable.admin.api');
    Route::get('/api/v1/admin/twoDb/getListFunnel/{dni}/{anio}/{mes}', [AdminController::class, 'getListFunnel'])->name('getListFunnel.admin.api');
    // manager config de mm
    Route::get('/api/v1/admin/config/getList', [ConfigController::class, 'getListConfig'])->name('getListConfig.admin.api');
    //Route::get('/api/v1/admin/twoDb/getListFunnel/{dni}/{anio}/{mes}', [AdminController::class, 'getListFunnel'])->name('getListFunnel.admin.api');

    // asesor
    Route::get('/api/v1/supervisor/getListZonal', [GestorController::class, 'getZonal'])->name('zonal.admin.api');
    Route::get('/api/v1/supervisor/user/getList/{zonal}', [SupervisorController::class, 'getListUser'])->name('getListUser.supervisor.api');
    // Route::get('/api/v1/supervisor/user/getListZonal', [SupervisorController::class, 'getListZonal'])->name('getListZonal.supervisor.api');
    Route::get('/api/v1/supervisor/user/create', [SupervisorController::class, 'createUser'])->name('createUser.supervisor.api');
    Route::get('/api/v1/supervisor/user/update', [SupervisorController::class, 'updateUser'])->name('updateUser.supervisor.api');
    // Route::get('/api/v1/supervisor/getListUser', [SupervisorController::class, 'getListUser'])->name('getListUser.supervisor.api');
    // Route::get('/api/v1/supervisor/sendUser/{idUser}', [ConfigController::class, 'getListConfig'])->name('getListConfig.admin.api');

    // manager entregable
    Route::get('/api/v1/admin/entregable/getList/{anio}/{mes}/{stateSearchAll}/{dni}', [GestorEntregableController::class, 'getList'])->name('getList.entregable.api');
    Route::post('/api/v1/admin/entregable/post', [GestorEntregableController::class, 'post'])->name('post.entregable.api');
    Route::delete('/api/v1/admin/entregable/delete/{anio}/{mes}/{dniResp}/{dniVen}', [GestorEntregableController::class, 'delete'])->name('delete.entregable.api');
    Route::put('/api/v1/admin/entregable/update/{anio}/{mes}/{dniResp}/{dniVen}', [GestorEntregableController::class, 'update'])->name('update.entregable.api');


});
Route::post('/api/v1/general/incidencia/create', [IncidenciaController::class, 'create'])->name('create.incidencia.api');
Route::get('/api/v1/general/incidencia/getList/{typeSearch}/{id}', [IncidenciaController::class, 'getList'])->name('getList.incidencia.api');
Route::put('/api/v1/general/incidencia/update/{id}', [IncidenciaController::class, 'update'])->name('update.incidencia.api');
Route::delete('/api/v1/general/incidencia/delete/{id}', [IncidenciaController::class, 'delete'])->name('delete.incidencia.api');


Route::middleware(['jwt.apiRest.jsMarket', 'jwt.user.pdv'])->group(function () {
    Route::get('/api/v1/pdv/getDataPdv/{dni}/{anio}/{mes}', [AvanceDiarioController::class, 'getDataPdv'])->name('getDataPdv.user.api');
    Route::get('/api/v1/pdv/getAvanceDiario/{dni}/{anio}/{mes}', [LogicController::class, 'getAvanceDiario'])->name('avanceDiarioMM.user.api');
    Route::get('/api/v1/pdv/getAbono/{dni}/{anio}/{mes}', [LogicController::class, 'getAbono'])->name('flyers.user.api');
    Route::get('/api/v1/pdv/getHistoryVenta/{dni}/{anio}/{mes}', [LogicController::class, 'getHistoryVenta'])->name('history.user.api');
    Route::get('/api/v1/pdv/getAllMonto/{dni}/{anio}/{mes}', [AvanceDiarioController::class, 'getAllMonto'])->name('getAllMonto.user.api');
    Route::get('/api/v1/pdv/getFlyers/{dni}/{anio}/{mes}', [LogicController::class, 'getFlyers'])->name('flyers.user.api');
    Route::get('/api/v1/pdv/getPayment/{dni}/{anio}/{mes}', [LogicController::class, 'getPayment'])->name('payment.user.api');
    Route::get('/api/v1/pdv/getPaymentOptimized/{dni}/{anio}/{mes}', [LogicController::class, 'getPaymentOptimized'])->name('payment.optimized.user.api');
    Route::get('/api/v1/pdv/getIncidencia/{dni}/{anio}/{mes}', [LogicController::class, 'getIncidencia'])->name('incidencia.user.api');
});
Route::middleware(['jwt.apiRest.jsMarket', 'jwt.user.multimarca'])->group(function () {
    Route::get('/api/v1/multimarca/getDataMM/{dni}/{anio}/{mes}', [MultimarcaAvanceDiarioController::class, 'getDataMM'])->name('getDataMM.user.api');
    Route::get('/api/v1/multimarca/getAvanceQuincenalDiario/{dni}/{anio}/{mes}/{typeQuincena}', [MultimarcaAvanceDiarioController::class, 'getAvanceQuinDiario'])->name('avanceQuinDiarioMM.user.api');
    Route::get('/api/v1/multimarca/getAvanceDiario/{dni}/{anio}/{mes}', [MultimarcaAvanceDiarioController::class, 'getAvanceDiario'])->name('avanceDiarioMM.user.api');
    Route::get('/api/v1/multimarca/getFlyers/{dni}/{anio}/{mes}', [LogicController::class, 'getFlyers'])->name('flyers.user.api');
    Route::get('/api/v1/multimarca/getAbono/{dni}/{anio}/{mes}', [LogicController::class, 'getAbonoMm'])->name('flyers.user.api');
    Route::get('/api/v1/multimarca/getHistoryVenta/{dni}/{anio}/{mes}', [LogicController::class, 'getHistoryVenta'])->name('history.user.api');
    Route::get('/api/v1/multimarca/getPayment/{dni}/{anio}/{mes}/{typeQuincena}', [MultimarcaAvanceDiarioController::class, 'getPayment'])->name('paymentMM.user.api');
    Route::get('/api/v1/multimarca/getOptimizedPayment/{dni}/{anio}/{mes}/{typeQuincena}', [MultimarcaAvanceDiarioController::class, 'getOptimizedPayment'])->name('optimizedPaymentMM.user.api');
    Route::get('/api/v1/multimarca/getResumenBase/{dni}/{anio}/{mes}', [MultimarcaAvanceDiarioController::class, 'getResumenBase'])->name('resumenBaseMM.user.api');
    Route::get('/api/v1/multimarca/getRecargasPorPeriodo/{dni}/{anio}/{mes}', [MultimarcaAvanceDiarioController::class, 'getRecargasPorPeriodo'])->name('recargasPorPeriodoMM.user.api');
    Route::get('/api/v1/multimarca/getIncidencia/{dni}/{anio}/{mes}', [LogicController::class, 'getIncidencia'])->name('incidencia.user.api');

    // Rutas para funcionalidad de N's (ventas y recargas)

    Route::get('/api/v1/multimarca/getVentasRecargasByN/{dni}/{periodoN}', [VentasRecargasController::class, 'getVentasRecargasByN'])->name('ventasRecargasN.user.api');
});
