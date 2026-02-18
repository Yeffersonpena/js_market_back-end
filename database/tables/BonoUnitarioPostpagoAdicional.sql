-- Tabla y carga base para adicionales unitarios por Postpago
-- Reglas configurables por periodo

IF OBJECT_ID('dbo.BonoUnitarioPostpagoAdicional', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.BonoUnitarioPostpagoAdicional (
        id INT IDENTITY(1,1) PRIMARY KEY,
        fecha_inicio DATE NOT NULL,
        fecha_fin DATE NOT NULL,
        criterio VARCHAR(30) NOT NULL, -- 'porta_pre_post', 'porta_post', 'altas_post'
        rango_min INT NOT NULL,
        rango_max INT NULL,            -- NULL = sin tope superior
        adicional_unitario DECIMAL(10,2) NOT NULL,
        prioridad INT NOT NULL DEFAULT 1,
        descripcion VARCHAR(200) NULL,
        created_at DATETIME NOT NULL DEFAULT GETDATE(),
        updated_at DATETIME NULL
    );
END;

-- Eliminar registros existentes de Febrero 2026 (si ya fueron insertados previamente)
DELETE FROM dbo.BonoUnitarioPostpagoAdicional
WHERE fecha_inicio = '2026-02-01'
  AND fecha_fin = '2026-02-28';

-- Reglas de Febrero 2026 según escala
INSERT INTO dbo.BonoUnitarioPostpagoAdicional
(fecha_inicio, fecha_fin, criterio, rango_min, rango_max, adicional_unitario, prioridad, descripcion)
VALUES
-- +0.5 por 1 porta (pre o post)
('2026-02-01','2026-02-28','porta_pre_post',1,1,0.50,10,'1 Porta O. Pre o Post'),

-- +0.5 por 3 altas o más
('2026-02-01','2026-02-28','altas_post',3,NULL,0.50,10,'3 Altas o más'),

-- +1.0 por 2 portas post
('2026-02-01','2026-02-28','porta_post',2,2,1.00,20,'2 Portas O. Post'),

-- +1.5 por 3 a más portas post
('2026-02-01','2026-02-28','porta_post',3,NULL,1.50,30,'3 a más Portas O. Post');
