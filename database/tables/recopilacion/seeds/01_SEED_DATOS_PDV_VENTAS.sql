-- =============================================
-- Seed: DATOS PDV VENTAS
-- Descripcion: Carga catalogo base del formulario
-- Nota: Script idempotente (insert/update)
-- =============================================

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @FormularioCodigo VARCHAR(50) = 'DATOS_PDV_VENTAS';
    DECLARE @FormularioNombre VARCHAR(200) = 'DATOS PDV VENTAS';
    DECLARE @Version INT = 1;
    DECLARE @FormularioId INT;

    -- 1) Formulario
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.RC_FORMULARIO
        WHERE codigo = @FormularioCodigo
          AND version = @Version
    )
    BEGIN
        INSERT INTO dbo.RC_FORMULARIO (
            codigo, nombre, version, descripcion, activo,
            fecha_inicio_vigencia, usuario_creacion
        )
        VALUES (
            @FormularioCodigo,
            @FormularioNombre,
            @Version,
            'Formulario de recopilacion de datos comerciales en PDV',
            1,
            CAST(GETDATE() AS DATE),
            'SEED'
        );
    END
    ELSE
    BEGIN
        UPDATE dbo.RC_FORMULARIO
        SET
            nombre = @FormularioNombre,
            descripcion = 'Formulario de recopilacion de datos comerciales en PDV',
            activo = 1,
            fecha_actualizacion = GETDATE(),
            usuario_actualizacion = 'SEED'
        WHERE codigo = @FormularioCodigo
          AND version = @Version;
    END

    SELECT @FormularioId = id
    FROM dbo.RC_FORMULARIO
    WHERE codigo = @FormularioCodigo
      AND version = @Version;

    -- 2) Secciones (estructura de las imagenes)
    DECLARE @Secciones TABLE (
        codigo VARCHAR(50),
        titulo VARCHAR(200),
        descripcion VARCHAR(500),
        orden INT
    );

    INSERT INTO @Secciones (codigo, titulo, descripcion, orden)
    VALUES
    ('PASO_1', 'Antes de la visita - Preparate', 'Preparacion previa del punto de venta', 1),
    ('PASO_2_CAPA_1', 'Paso 2 - Capa 1 - Identidad del canal', 'Perfil base del canal', 2),
    ('PASO_2_CAPA_2', 'Paso 2 - Capa 2 - Posicion competitiva', 'Categoria, volumen y proveedor actual', 3),
    ('PASO_2_CAPA_3', 'Paso 2 - Capa 3 - Potencial y fit', 'Observacion visual del punto', 4),
    ('PASO_3', 'Paso 3 - Validacion de marca, producto y garantia', 'Interes por producto y garantia extendida', 5),
    ('PASO_4', 'Paso 4 - Cierre y compromiso', 'Temperatura comercial y siguientes pasos', 6);

    MERGE dbo.RC_SECCION AS target
    USING (
        SELECT @FormularioId AS formulario_id, codigo, titulo, descripcion, orden
        FROM @Secciones
    ) AS src
    ON target.formulario_id = src.formulario_id
       AND target.codigo = src.codigo
    WHEN MATCHED THEN
        UPDATE SET
            target.titulo = src.titulo,
            target.descripcion = src.descripcion,
            target.orden = src.orden,
            target.activo = 1,
            target.fecha_actualizacion = GETDATE(),
            target.usuario_actualizacion = 'SEED'
    WHEN NOT MATCHED THEN
        INSERT (
            formulario_id, codigo, titulo, descripcion, orden, activo, usuario_creacion
        )
        VALUES (
            src.formulario_id, src.codigo, src.titulo, src.descripcion, src.orden, 1, 'SEED'
        );

    -- 3) Preguntas
    DECLARE @Preguntas TABLE (
        seccion_codigo VARCHAR(50),
        codigo VARCHAR(50),
        texto VARCHAR(1000),
        texto_ayuda VARCHAR(500),
        tipo_respuesta VARCHAR(30),
        obligatoria BIT,
        permite_no_aplica BIT,
        requiere_foto BIT,
        min_fotos INT,
        max_fotos INT,
        orden INT,
        max_longitud INT NULL,
        valor_minimo DECIMAL(18,4) NULL,
        valor_maximo DECIMAL(18,4) NULL
    );

    INSERT INTO @Preguntas
    VALUES
    -- PASO 1
    ('PASO_1', 'P01', 'Cuanto compra en EQ por mes?', 'Anotar ticket promedio mensual en soles', 'decimal', 1, 0, 0, 0, 0, 1, NULL, 0, NULL),
    ('PASO_1', 'P02', 'Cuanto deberia comprar en AXX?', 'Meta mensual estimada en soles', 'decimal', 1, 0, 0, 0, 0, 2, NULL, 0, NULL),
    ('PASO_1', 'P03', 'Ya compra AXX a JS hoy?', 'Indicar si/no y, si aplica, monto referencial', 'opcion_unica', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
    ('PASO_1', 'P04', 'Que zona y quien atiende?', 'Confirmar jefe zonal y vendedor de ruta', 'texto_corto', 1, 0, 0, 0, 0, 4, 150, NULL, NULL),
    ('PASO_1', 'P05', 'Que llevo para mostrar?', 'Marcar evidencia de fotos y kit de muestra', 'opcion_multiple', 1, 0, 0, 0, 0, 5, NULL, NULL, NULL),

    -- PASO 2 - CAPA 1
    ('PASO_2_CAPA_1', 'P06', 'Cual es el nombre completo del dueno del local?', 'Tal como aparece en su DNI', 'texto_corto', 1, 0, 0, 0, 0, 1, 150, NULL, NULL),
    ('PASO_2_CAPA_1', 'P07', 'Cual es su DNI?', 'Campo obligatorio, 8 digitos', 'numero', 1, 0, 0, 0, 0, 2, NULL, 10000000, 99999999),
    ('PASO_2_CAPA_1', 'P08', 'Cuantos anos lleva este local operando?', 'Si no sabe exacto, puede usar rango', 'numero', 1, 1, 0, 0, 0, 3, NULL, 0, NULL),
    ('PASO_2_CAPA_1', 'P09', 'Maneja otros puntos de venta ademas de este?', 'Si responde si, indicar cuantos o zonas', 'si_no', 1, 0, 0, 0, 0, 4, NULL, NULL, NULL),
    ('PASO_2_CAPA_1', 'P10', 'Con que nombre comercial se identifica este local?', 'Puede ser diferente al RUC registrado', 'texto_corto', 1, 0, 0, 0, 0, 5, 200, NULL, NULL),
    ('PASO_2_CAPA_1', 'E01', 'Evidencia del local y DNI del dueno', 'Foto de fachada y foto del DNI (con permiso)', 'texto_largo', 1, 0, 1, 2, 4, 6, NULL, NULL, NULL),

    -- PASO 2 - CAPA 2
    ('PASO_2_CAPA_2', 'P11', 'Que productos vende principalmente?', 'Marcar celulares, accesorios, recargas u otros', 'opcion_multiple', 1, 0, 0, 0, 0, 1, NULL, NULL, NULL),
    ('PASO_2_CAPA_2', 'P12', 'Cuanto estima que vende en accesorios por mes?', 'Seleccionar rango estimado', 'opcion_unica', 1, 0, 0, 0, 0, 2, NULL, NULL, NULL),
    ('PASO_2_CAPA_2', 'P13', 'Que accesorios se venden mas en su local?', 'Top 3 productos: cables, audifonos, cargadores, etc.', 'texto_largo', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
    ('PASO_2_CAPA_2', 'P14', 'A quien le compra accesorios hoy?', 'Proveedor o distribuidor actual', 'texto_largo', 1, 0, 0, 0, 0, 4, NULL, NULL, NULL),
    ('PASO_2_CAPA_2', 'P15', 'Que marcas maneja en gondola?', 'Anotar marcas visibles en exhibicion', 'texto_largo', 1, 0, 0, 0, 0, 5, NULL, NULL, NULL),
    ('PASO_2_CAPA_2', 'P16', 'Que valora mas de su proveedor actual?', 'Precio, rapidez, credito, garantia, variedad, etc.', 'opcion_multiple', 1, 0, 0, 0, 0, 6, NULL, NULL, NULL),
    ('PASO_2_CAPA_2', 'E02', 'Evidencia de gondola de accesorios', 'Foto de gondola con marcas y precios visibles', 'texto_largo', 1, 0, 1, 1, 3, 7, NULL, NULL, NULL),

    -- PASO 2 - CAPA 3
    ('PASO_2_CAPA_3', 'P17', 'Tamano del local', 'Clasificar pequeno, mediano o grande', 'opcion_unica', 1, 0, 0, 0, 0, 1, NULL, NULL, NULL),
    ('PASO_2_CAPA_3', 'P18', 'Trafico visible al momento de la visita', 'Sin clientes, 1-3 clientes, mas de 3 clientes', 'opcion_unica', 1, 0, 0, 0, 0, 2, NULL, NULL, NULL),
    ('PASO_2_CAPA_3', 'P19', 'Tiene vitrina o display activo de accesorios?', 'Evaluar si hay exhibicion activa', 'opcion_unica', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
    ('PASO_2_CAPA_3', 'P20', 'Nivel de organizacion general del local', 'Alto, medio o bajo', 'opcion_unica', 1, 0, 0, 0, 0, 4, NULL, NULL, NULL),
    ('PASO_2_CAPA_3', 'P21', 'Tiene letrero o senalizacion visible de operador?', 'Indicar operadores visibles', 'texto_largo', 1, 1, 0, 0, 0, 5, NULL, NULL, NULL),
    ('PASO_2_CAPA_3', 'P22', 'Observacion libre del jefe zonal', 'Intuicion o dato relevante adicional', 'texto_largo', 0, 1, 0, 0, 0, 6, NULL, NULL, NULL),
    ('PASO_2_CAPA_3', 'E03', 'Evidencia visual del local', 'Foto frontal e interior del punto', 'texto_largo', 1, 0, 1, 2, 4, 7, NULL, NULL, NULL),

    -- PASO 3
    ('PASO_3', 'P23', 'Reaccion al packaging del producto JS', 'Calificacion del 1 al 5 y comentario breve', 'opcion_unica', 1, 0, 0, 0, 0, 1, NULL, NULL, NULL),
    ('PASO_3', 'P24', 'Que linea le interesaria probar primero?', 'Parlantes, audifonos, cables, baterias, relojes u otros', 'opcion_multiple', 1, 0, 0, 0, 0, 2, NULL, NULL, NULL),
    ('PASO_3', 'P25', 'A que precio estaria dispuesto a comprar en cada linea?', 'Registrar rango por categoria', 'texto_largo', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
    ('PASO_3', 'P26', 'Hay algo del producto o empaque que cambiaria?', 'Comentario libre', 'texto_largo', 0, 1, 0, 0, 0, 4, NULL, NULL, NULL),
    ('PASO_3', 'P27', 'Ha tenido problemas con garantias de su proveedor actual?', 'Si o no, con experiencia breve', 'si_no', 1, 0, 0, 0, 0, 5, NULL, NULL, NULL),
    ('PASO_3', 'P28', 'Una garantia de 12 meses cambiaria su decision de compra?', 'Mucho, algo, poco o nada', 'opcion_unica', 1, 0, 0, 0, 0, 6, NULL, NULL, NULL),
    ('PASO_3', 'P29', 'Que tan importante es la garantia para su cliente final?', 'Muy, moderado o poco', 'opcion_unica', 1, 0, 0, 0, 0, 7, NULL, NULL, NULL),
    ('PASO_3', 'E04', 'Evidencia de validacion de producto', 'Foto de reaccion del canal y audio con comentarios espontaneos', 'audio', 1, 0, 1, 1, 3, 8, NULL, NULL, NULL),

    -- PASO 4
    ('PASO_4', 'P30', 'Nivel de receptividad general', '1 sin interes, 2 esceptico, 3 neutral, 4 interesado, 5 muy receptivo', 'opcion_unica', 1, 0, 0, 0, 0, 1, NULL, NULL, NULL),
    ('PASO_4', 'P31', 'Estaria dispuesto a recibir un pedido de prueba cuando llegue el embarque?', 'Si, no o tal vez', 'opcion_unica', 1, 0, 0, 0, 0, 2, NULL, NULL, NULL),
    ('PASO_4', 'P32', 'Que cantidad minima necesitaria para probar y en que linea?', 'Numero y categoria', 'texto_largo', 1, 0, 0, 0, 0, 3, NULL, NULL, NULL),
    ('PASO_4', 'P33', 'Hay alguna condicion necesaria para arrancar?', 'Credito, precio, volumen u otra condicion', 'texto_largo', 0, 1, 0, 0, 0, 4, NULL, NULL, NULL),
    ('PASO_4', 'P34', 'Observaciones libres del jefe zonal', 'Texto libre o comentario de audio', 'audio', 0, 1, 0, 0, 0, 5, NULL, NULL, NULL);

    MERGE dbo.RC_PREGUNTA AS target
    USING (
        SELECT
            s.id AS seccion_id,
            p.codigo,
            p.texto,
            p.texto_ayuda,
            p.tipo_respuesta,
            p.obligatoria,
            p.permite_no_aplica,
            p.requiere_foto,
            p.min_fotos,
            p.max_fotos,
            p.orden,
            p.max_longitud,
            p.valor_minimo,
            p.valor_maximo
        FROM @Preguntas p
        INNER JOIN dbo.RC_SECCION s
            ON s.formulario_id = @FormularioId
           AND s.codigo = p.seccion_codigo
    ) AS src
    ON target.seccion_id = src.seccion_id
       AND target.codigo = src.codigo
    WHEN MATCHED THEN
        UPDATE SET
            target.texto = src.texto,
            target.texto_ayuda = src.texto_ayuda,
            target.tipo_respuesta = src.tipo_respuesta,
            target.obligatoria = src.obligatoria,
            target.permite_no_aplica = src.permite_no_aplica,
            target.requiere_foto = src.requiere_foto,
            target.min_fotos = src.min_fotos,
            target.max_fotos = src.max_fotos,
            target.orden = src.orden,
            target.max_longitud = src.max_longitud,
            target.valor_minimo = src.valor_minimo,
            target.valor_maximo = src.valor_maximo,
            target.activo = 1,
            target.fecha_actualizacion = GETDATE(),
            target.usuario_actualizacion = 'SEED'
    WHEN NOT MATCHED THEN
        INSERT (
            seccion_id, codigo, texto, texto_ayuda, tipo_respuesta,
            obligatoria, permite_no_aplica, requiere_foto, min_fotos, max_fotos,
            orden, activo, max_longitud, valor_minimo, valor_maximo, usuario_creacion
        )
        VALUES (
            src.seccion_id, src.codigo, src.texto, src.texto_ayuda, src.tipo_respuesta,
            src.obligatoria, src.permite_no_aplica, src.requiere_foto, src.min_fotos, src.max_fotos,
            src.orden, 1, src.max_longitud, src.valor_minimo, src.valor_maximo, 'SEED'
        );

    -- 4) Opciones de preguntas cerradas
    DECLARE @Opciones TABLE (
        pregunta_codigo VARCHAR(50),
        codigo VARCHAR(50),
        etiqueta VARCHAR(200),
        valor VARCHAR(200),
        orden INT
    );

    INSERT INTO @Opciones
    VALUES
    -- P03
    ('P03', 'SI', 'Si', 'SI', 1),
    ('P03', 'NO', 'No', 'NO', 2),

    -- P05
    ('P05', 'FOTOS', 'Fotos', 'FOTOS', 1),
    ('P05', 'KIT', 'Kit de muestra', 'KIT', 2),

    -- P09
    ('P09', 'SI', 'Si', 'SI', 1),
    ('P09', 'NO', 'No', 'NO', 2),

    -- P11
    ('P11', 'CELULARES', 'Celulares', 'CELULARES', 1),
    ('P11', 'ACCESORIOS', 'Accesorios', 'ACCESORIOS', 2),
    ('P11', 'RECARGAS', 'Recargas', 'RECARGAS', 3),
    ('P11', 'OTROS', 'Otros', 'OTROS', 4),

    -- P12
    ('P12', 'R1', '< S/500', '<500', 1),
    ('P12', 'R2', 'S/500 - 2K', '500-2000', 2),
    ('P12', 'R3', 'S/2K - 5K', '2000-5000', 3),
    ('P12', 'R4', '+ S/5K', '>5000', 4),

    -- P16
    ('P16', 'PRECIO', 'Precio', 'PRECIO', 1),
    ('P16', 'RAPIDEZ', 'Rapidez', 'RAPIDEZ', 2),
    ('P16', 'CREDITO', 'Credito', 'CREDITO', 3),
    ('P16', 'GARANTIA', 'Garantia', 'GARANTIA', 4),
    ('P16', 'VARIEDAD', 'Variedad', 'VARIEDAD', 5),

    -- P17
    ('P17', 'PEQUENO', 'Pequeno (<20m2)', 'PEQUENO', 1),
    ('P17', 'MEDIANO', 'Mediano (20-50m2)', 'MEDIANO', 2),
    ('P17', 'GRANDE', 'Grande (+50m2)', 'GRANDE', 3),

    -- P18
    ('P18', 'SIN_CLIENTES', 'Sin clientes', 'SIN_CLIENTES', 1),
    ('P18', 'UNO_A_TRES', '1 - 3 clientes', '1_3_CLIENTES', 2),
    ('P18', 'MAS_DE_TRES', '+3 clientes', 'MAS_3_CLIENTES', 3),

    -- P19
    ('P19', 'SI_ORDENADO', 'Si, bien organizado', 'SI_ORDENADO', 1),
    ('P19', 'SI_DESORDENADO', 'Si, desordenado', 'SI_DESORDENADO', 2),
    ('P19', 'NO_TIENE', 'No tiene', 'NO_TIENE', 3),

    -- P20
    ('P20', 'ALTO', 'Alto', 'ALTO', 1),
    ('P20', 'MEDIO', 'Medio', 'MEDIO', 2),
    ('P20', 'BAJO', 'Bajo', 'BAJO', 3),

    -- P23
    ('P23', '1', '1', '1', 1),
    ('P23', '2', '2', '2', 2),
    ('P23', '3', '3', '3', 3),
    ('P23', '4', '4', '4', 4),
    ('P23', '5', '5', '5', 5),

    -- P24
    ('P24', 'PARLANTES', 'Parlantes', 'PARLANTES', 1),
    ('P24', 'AUDIFONOS', 'Audifonos', 'AUDIFONOS', 2),
    ('P24', 'CABLES', 'Cables', 'CABLES', 3),
    ('P24', 'BATERIAS', 'Baterias', 'BATERIAS', 4),
    ('P24', 'RELOJES', 'Relojes', 'RELOJES', 5),
    ('P24', 'OTROS', 'Otros', 'OTROS', 6),

    -- P27
    ('P27', 'SI', 'Si', 'SI', 1),
    ('P27', 'NO', 'No', 'NO', 2),

    -- P28
    ('P28', 'MUCHO', 'Mucho', 'MUCHO', 1),
    ('P28', 'ALGO', 'Algo', 'ALGO', 2),
    ('P28', 'POCO', 'Poco', 'POCO', 3),
    ('P28', 'NADA', 'Nada', 'NADA', 4),

    -- P29
    ('P29', 'MUY', 'Muy', 'MUY', 1),
    ('P29', 'MODERADO', 'Moderado', 'MODERADO', 2),
    ('P29', 'POCO', 'Poco', 'POCO', 3),

    -- P30
    ('P30', 'NIVEL_1', '1 - Sin interes', '1', 1),
    ('P30', 'NIVEL_2', '2 - Esceptico', '2', 2),
    ('P30', 'NIVEL_3', '3 - Neutral', '3', 3),
    ('P30', 'NIVEL_4', '4 - Interesado', '4', 4),
    ('P30', 'NIVEL_5', '5 - Muy receptivo', '5', 5),

    -- P31
    ('P31', 'SI', 'Si', 'SI', 1),
    ('P31', 'NO', 'No', 'NO', 2),
    ('P31', 'TAL_VEZ', 'Tal vez', 'TAL_VEZ', 3);

    MERGE dbo.RC_PREGUNTA_OPCION AS target
    USING (
        SELECT
            q.id AS pregunta_id,
            o.codigo,
            o.etiqueta,
            o.valor,
            o.orden
        FROM @Opciones o
        INNER JOIN dbo.RC_PREGUNTA q
            ON q.codigo = o.pregunta_codigo
        INNER JOIN dbo.RC_SECCION s
            ON s.id = q.seccion_id
        WHERE s.formulario_id = @FormularioId
    ) AS src
    ON target.pregunta_id = src.pregunta_id
       AND target.codigo = src.codigo
    WHEN MATCHED THEN
        UPDATE SET
            target.etiqueta = src.etiqueta,
            target.valor = src.valor,
            target.orden = src.orden,
            target.activo = 1,
            target.fecha_actualizacion = GETDATE(),
            target.usuario_actualizacion = 'SEED'
    WHEN NOT MATCHED THEN
        INSERT (
            pregunta_id, codigo, etiqueta, valor, orden, activo, usuario_creacion
        )
        VALUES (
            src.pregunta_id, src.codigo, src.etiqueta, src.valor, src.orden, 1, 'SEED'
        );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
