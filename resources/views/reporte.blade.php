<!DOCTYPE html>
<html>
<head>
    <title>Descargar Reporte</title>
</head>
<body>
    <h1>Reporte General</h1>

    <form action="{{ route('reporteAll.reporte.api') }}" method="GET">
        <button type="submit">📥 Descargar Reporte Excel</button>
    </form>
</body>
</html>
