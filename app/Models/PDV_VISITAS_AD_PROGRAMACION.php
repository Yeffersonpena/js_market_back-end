<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PDV_VISITAS_AD_PROGRAMACION extends Model
{
    use HasFactory;

    protected $connection = 'sqlsrv';
    protected $table = 'PDV_VISITAS_AD_PROGRAMACION';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'DNI_RESPONSABLE',
        'AÑO',
        'MES',
        'COD_CLIENTE',
        'ZONAL',
        'RUTA',
        'COD_VVDD',
        'MODULO',
        'NOMBRE_PUNTO',
        'CEDULA_CLIENTE',
        'DEPARTAMENTO',
        'PROVINCIA',
        'DISTRITO',
        'DIRECCION',
        'CONGLOMERADO',
        'LATITUD',
        'LONGITUD',
        'VENDEDORES',
        'TIPO_VISITA',
        'FRECUENCIA',
        'STATUS',
        'COMENTARIOS',
        'FECHA_CREACION',
        'USUARIO_CREACION',
        'FECHA_ACTUALIZACION',
        'USUARIO_ACTUALIZACION',
    ];

    protected $casts = [
        'DNI_RESPONSABLE' => 'integer',
        'AÑO' => 'integer',
        'MES' => 'integer',
        'COD_VVDD' => 'integer',
        'LATITUD' => 'decimal:8',
        'LONGITUD' => 'decimal:8',
        'FECHA_CREACION' => 'datetime',
        'FECHA_ACTUALIZACION' => 'datetime',
    ];

    /**
     * Relación con los días programados
     */
    public function dias()
    {
        return $this->hasMany(PDV_VISITAS_AD_DIAS::class, 'programacion_id', 'id');
    }
}

