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

## Actualizar el proyecto en local 
- Ejecutar el comando `composer update`

##### Habilitar el key para el jwt [optional, si no lo tines agregado en el .env]
- Generar el key con `php artisan jwt:secret` te generara un key y el mismo lo agregas en el .env `JWT_SECRET=your_generated_secret_key`

## Gerarquida de perfiles
- -2 => `Anonymous`
- -1 => `Admin`
-  0 => `Default`
-  1 => `Pdv`
-  2 => `Multimarca`    
### Nuevo id para Perfiles
- 1 => `admin`
- 2 => `pdv`
- 3 => `multimarca`
- 4 => `default`

## Documentación del ApiRest
- Postman (link)[]

#### user de Pruebas
#### Complemento del sql
> Para la creación de los perfiles y los usuarios ejecutar el script.sql que se encuentra en la misma ruta del readme.
- admin = user=admin , pass=07640716
- (pdv) = user=10236231
- (multimarca)= user=10300144

### 
- user pdv [45203397 = data ]  -- 10487996 
- user actual mm_ 42575210 --  [data history= 42575210]