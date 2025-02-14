# Laravel 11
##### Requisitos previos 
- php 8.3
- Composer
- Driver de sql server para la version de php 
- Tener instalado sql server
### Requisitos para levantar un proyecto en local
- crear la base de datos js_BD_PLANIFICACION_OUTLET_AD
- ejecutar la migración con `php artisan migrate:fresh --seed`
- Para iniciar el servidor de laravel `php artisan serve` te mostrara la url del proyecto local en la terminal


## Gerarquida de perfiles
- -2 => `Anonymous`
- -1 => `Admin`
-  0 => `Default`
-  1 => `Pdv`
-  2 => `Multimarca`

## Documentación del ApiRest
- Postman (link)[]

#### user
- admin = user=admin , pass=07640716
- (pdv) = user=10236231
- (multimarca)= user=10300144
