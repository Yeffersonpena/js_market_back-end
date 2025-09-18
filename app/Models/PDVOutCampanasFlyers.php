<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PDVOutCampanasFlyers extends Model
{
    use HasFactory;

    protected $table = 'PDV_OUT_CAMPAÑAS_FLYERS';
    protected $connection = 'sqlsrv';
    
    protected $fillable = [
        'nombre_campaña',
        'foto_esquema',
        'fecha_inicio',
        'fecha_fin',
        'tipoImg',
        'modo',
        'criterio_filtro',
        'zonales',
        'activa',
        'fecha_creacion'
    ];

    // 👇 Quitar casts de fechas para no romper el formato
    protected $casts = [
        'activa' => 'boolean'
    ];

    public $timestamps = false;
}
