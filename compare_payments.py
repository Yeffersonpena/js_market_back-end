import sys
import math
import requests

# URL base del backend en producción
BASE_URL = "https://addeep.portal-comercial.com/api/v1"

# Tolerancia para comparar números decimales
FLOAT_TOLERANCE = 0.01


def login(dni: str) -> str:
    """
    Hace login usando el DNI como usuario y contraseña.
    Devuelve el token JWT.
    """
    url = f"{BASE_URL}/users/login"
    payload = {
        "user": dni,
        "password": dni,
    }

    resp = requests.post(url, json=payload, timeout=15)
    resp.raise_for_status()
    data = resp.json()

    if data.get("status") != 200 or "token" not in data:
        raise RuntimeError(f"Login fallido: {data}")

    return data["token"]


def call_payment(token: str, dni: str, anio: int, mes: int, optimized: bool = False) -> dict:
    """
    Llama al endpoint de payment (original u optimizado) y devuelve el JSON completo.
    """
    if optimized:
        path = f"/pdv/getPaymentOptimized/{dni}/{anio}/{mes}"
    else:
        path = f"/pdv/getPayment/{dni}/{anio}/{mes}"

    url = f"{BASE_URL}{path}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
    }

    resp = requests.get(url, headers=headers, timeout=20)
    resp.raise_for_status()
    return resp.json()


def compare_values(key: str, v1, v2) -> bool:
    """
    Compara dos valores. Si son numéricos, usa una tolerancia para floats.
    Devuelve True si son equivalentes.
    """
    # Ambos None
    if v1 is None and v2 is None:
        return True

    # Uno es None y el otro no
    if (v1 is None) != (v2 is None):
        return False

    # Intentar convertir a float para comparar números
    try:
        f1 = float(v1)
        f2 = float(v2)
        return math.isclose(f1, f2, rel_tol=0, abs_tol=FLOAT_TOLERANCE)
    except (ValueError, TypeError):
        # Si no son numéricos, comparar directamente (strings, bool, etc.)
        return v1 == v2


def compare_data(data_orig: dict, data_opt: dict) -> None:
    """
    Compara los objetos 'data' de ambos endpoints.
    Imprime diferencias y un resumen.
    """
    keys_orig = set(data_orig.keys())
    keys_opt = set(data_opt.keys())

    only_orig = keys_orig - keys_opt
    only_opt = keys_opt - keys_orig
    common = keys_orig & keys_opt

    print("===== Comparación de estructura (claves) =====")
    if only_orig:
        print("Claves que SOLO están en ORIGINAL:", sorted(only_orig))
    if only_opt:
        print("Claves que SOLO están en OPTIMIZADO:", sorted(only_opt))
    if not only_orig and not only_opt:
        print("Las claves de 'data' coinciden exactamente.")

    print("\n===== Comparación de valores =====")
    diffs = []
    for k in sorted(common):
        v1 = data_orig.get(k)
        v2 = data_opt.get(k)
        if not compare_values(k, v1, v2):
            diffs.append((k, v1, v2))

    if not diffs:
        print("Todos los valores coinciden dentro de la tolerancia.")
    else:
        print(f"Hay {len(diffs)} diferencias:")
        for k, v1, v2 in diffs:
            print(f" - {k}: original={v1} | optimizado={v2}")


def main():
    if len(sys.argv) < 4:
        print("Uso: py compare_payments.py <dni> <anio> <mes>")
        print("Ejemplo: py compare_payments.py 12345678 2025 12")
        sys.exit(1)

    dni = sys.argv[1]
    anio = int(sys.argv[2])
    mes = int(sys.argv[3])

    print(f"=== Probando con DNI={dni}, año={anio}, mes={mes} ===")

    # 1. Login
    print("Haciendo login...")
    token = login(dni)
    print("Login OK.")

    # 2. Llamar endpoints
    print("Llamando endpoint ORIGINAL...")
    resp_orig = call_payment(token, dni, anio, mes, optimized=False)

    print("Llamando endpoint OPTIMIZADO...")
    resp_opt = call_payment(token, dni, anio, mes, optimized=True)

    # 3. Validar status y extraer data
    status_orig = resp_orig.get("status")
    status_opt = resp_opt.get("status")
    data_orig = resp_orig.get("data")
    data_opt = resp_opt.get("data")

    print("\n===== Status generales =====")
    print("status original  :", status_orig)
    print("status optimizado:", status_opt)

    if not data_orig:
        print("El endpoint ORIGINAL no devolvió datos (data vacío o null).")
    if not data_opt:
        print("El endpoint OPTIMIZADO no devolvió datos (data vacío o null).")

    if not data_orig or not data_opt:
        print("No se puede comparar porque uno de los endpoints no tiene datos.")
        sys.exit(0)

    # 4. Comparar contenido de data
    compare_data(data_orig, data_opt)


if __name__ == "__main__":
    main()


