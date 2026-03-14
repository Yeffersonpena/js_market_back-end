<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RcRespuesta extends Model
{
    protected $connection = 'sqlsrv';
    protected $table = 'RC_RESPUESTA';
    protected $primaryKey = 'id';
    public $incrementing = true;
    public $timestamps = false;

    protected $fillable = [
        'visita_id',
        'pregunta_id',
        'valor_texto',
        'valor_numero',
        'valor_decimal',
        'valor_booleano',
        'valor_fecha',
        'valor_hora',
        'observacion',
        'no_aplica',
        'fecha_guardado',
        'usuario_guardado',
    ];

    protected $casts = [
        'visita_id' => 'integer',
        'pregunta_id' => 'integer',
        'valor_numero' => 'integer',
        'valor_decimal' => 'decimal:4',
        'valor_booleano' => 'boolean',
        'valor_fecha' => 'date',
        'no_aplica' => 'boolean',
        'fecha_guardado' => 'datetime',
    ];

    public function visita()
    {
        return $this->belongsTo(RcVisitaFormulario::class, 'visita_id', 'id');
    }

    public function pregunta()
    {
        return $this->belongsTo(RcPregunta::class, 'pregunta_id', 'id');
    }

    public function opcionesSeleccionadas()
    {
        return $this->hasMany(RcRespuestaOpcion::class, 'respuesta_id', 'id');
    }

    public function media()
    {
        return $this->hasMany(RcRespuestaMedia::class, 'respuesta_id', 'id')->orderBy('orden');
    }
}
