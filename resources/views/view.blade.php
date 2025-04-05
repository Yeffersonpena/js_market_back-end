<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Subir múltiples imágenes de manera asíncrona</title>
</head>
<body>
    <h2>Subir múltiples imágenes (Asíncrono)</h2>

    <form id="imageForm">
        <label for="images">Selecciona las imágenes:</label>
        <input type="file" name="images[]" id="images" accept="image/*" multiple>
        <br><br>
        <button type="submit">Subir imágenes</button>
    </form>

    <div id="response"></div>

    <script>
        document.getElementById('imageForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            // const domain = 'http://127.0.0.1:8000';
            const domain = 'https://addeep.portal-comercial.com';
            var formData = new FormData();
            var files = document.getElementById('images').files;
            for (var i = 0; i < files.length; i++) {
                formData.append('images[]', files[i]);
            }

            try {
                const response = await fetch(`${domain}/api/v1/imagenes/allImg`, {
                    method: 'POST',
                    body: formData
                });

                if (response.ok) {
                    const result = await response.json();
                    document.getElementById('response').innerHTML = '<strong>' + result.message + '</strong>';
                    if (result.urls) {
                        result.urls.forEach(function(url) {
                            document.getElementById('response').innerHTML += `<br><img src="${url}" width="100">`;
                        });
                    }
                } else {
                    document.getElementById('response').innerHTML = 'Error al subir las imágenes';
                }
            } catch (error) {
                document.getElementById('response').innerHTML = 'Error al enviar la solicitud: ' + error.message;
            }
        });
    </script>
</body>
</html>
