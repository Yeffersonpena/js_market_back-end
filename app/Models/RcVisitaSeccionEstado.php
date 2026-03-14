<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RcVisitaSeccionEstado extends Model
{
    protected $connection = 'sqlsrv';
    protected $table = 'RC_VISITA_SECCION_ESTADO';
    protected $primaryKey = 'id';
    public $incrementing = true;
    public $timestamps = false;

    protected $fillable = [
        'visita_id',
        'seccion_id',
        'estado',
        'porcentaje_avance',
        'fecha_guardado',
        'usuario_guardado',
    ];

    protected $casts = [
        'visita_id' => 'integer',
        'seccion_id' => 'integer',
        'porcentaje_avance' => 'decimal:2',
        'fecha_guardado' => 'datetime',
    ];

    public function visita()
    {
        return $this->belongsTo(RcVisitaFormulario::class, 'visita_id', 'id');
    }

    public function seccion()
    {
        return $this->belongsTo(RcSeccion::class, 'seccion_id', 'id');
    }
}
