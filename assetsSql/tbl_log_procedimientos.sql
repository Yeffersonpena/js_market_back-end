-- Esta tabla sirve para registrar los procedimientos que se ejecutan en la base de datos, relacionados a los archivos excel
CREATE TABLE tbl_log_procedimientos (
    idLog INT IDENTITY(1,1) PRIMARY KEY,
    nombre_procedimiento NVARCHAR(50) NULL,
    fecha_hora_registro datetime
);