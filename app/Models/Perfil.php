<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Perfil extends Model
{
    use HasFactory;

    protected $table = 'tbl_perfil';
    protected $primaryKey = 'idPerfil';
    public $timestamps = false;

    protected $fillable = [
        'perfil',
    ];
}
