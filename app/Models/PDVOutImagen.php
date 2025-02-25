<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PDVOutImagen extends Model
{
    use HasFactory;

    protected $table = 'PDV_OUT_IMAGENES'; 

    protected $fillable = [
        'id',
        'nombre_imagen',
        'fecha_modificacion',
        'ruta_imagen'
    ];

    public $timestamps = false;
}
