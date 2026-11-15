from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from pwdlib import PasswordHash
from pwdlib.exceptions import UnknownHashError
from pwdlib.hashers.bcrypt import BcryptHasher
from sqlalchemy import text

from database import engine
from fastapi.middleware.cors import CORSMiddleware
from secrets import token_urlsafe
from time import monotonic


app = FastAPI(title="API Thank U Music")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:58984"],
    allow_methods=["POST"],
    allow_headers=["Content-Type"],
)

# Guardamos las sesiones mientras FastAPI esté ejecutándose.
sesiones = {}

@app.get("/")
def inicio():
    # Abrimos la conexión para consultar qué base estamos usando.
    with engine.connect() as conexion:
        base = conexion.exec_driver_sql("SELECT DATABASE()").scalar_one()
        total = conexion.exec_driver_sql("SELECT COUNT(*) FROM usuarios").scalar_one()

    return {"base": base, "usuarios": total}

# Define el molde (esquema) de los datos que debe enviar la app en Flutter al intentar iniciar sesión.
# Si falta algún campo o no cumple el tamaño, FastAPI rechaza la petición automáticamente antes de entrar a la función.
class LoginRequest(BaseModel):
    # Exige que el campo 'mail' sea texto de entre 1 y 150 caracteres.
    mail: str = Field(min_length=1, max_length=150)
    # Exige que la contraseña sea texto de al menos 8 caracteres.
    password: str = Field(min_length=8)


# Configura el verificador de contraseñas usando el algoritmo Bcrypt (compatible con el password_hash de PHP).
password_hash = PasswordHash((BcryptHasher(),))


# Crea la ruta POST '/login' en la API para recibir las credenciales y validar el acceso.
@app.post("/login")
def iniciar_sesion(datos: LoginRequest):
    # Limpia espacios sobrantes al inicio o final (.strip) y convierte el correo a minúsculas (.lower) para buscarlo sin errores.
    correo = datos.mail.strip().lower()

    # Abre una conexión temporal con la base de datos y la cierra automáticamente al terminar el bloque 'with'.
    with engine.connect() as conexion:
        # Ejecuta la consulta SQL buscando al usuario por su correo.
        # Usar ':correo' y pasar el diccionario aparte evita ataques de inyección SQL.
        # .mappings().first() devuelve el primer resultado como un diccionario (accediendo por nombre de columna) o None si no existe.
        usuario = conexion.execute(
            text("""
                SELECT id_usuario, nombre, correo, password, rol, estado
                FROM usuarios
                WHERE correo = :correo
            """),
            {"correo": correo},
        ).mappings().first()

    # Bandera inicial que asume que el acceso es inválido hasta comprobar lo contrario.
    password_correcta = False

    # Solo intenta revisar la contraseña si el correo sí apareció en la base de datos.
    if usuario is not None:
        try:
            # Convierte la contraseña escrita a bytes UTF-8, toma máximo los primeros 72 bytes (límite técnico de bcrypt en PHP)
            # y la compara contra el texto encriptado (hash) guardado en la base de datos.
            password_correcta = password_hash.verify(
                datos.password.encode("utf-8")[:72],
                usuario["password"],
            )
        # Si el hash en la base de datos tiene un formato desconocido o está dañado, evita que el servidor se caiga y marca falso.
        except (UnknownHashError, ValueError):
            password_correcta = False

    # Si no existía el usuario o la contraseña no coincidió, responde con error HTTP 401 (No autorizado).
    # Se usa el mismo mensaje genérico para no darle pistas a un atacante sobre si el correo existe o no.
    if not password_correcta:
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos.")

    # Si las credenciales son correctas pero la cuenta está baneada o suspendida, bloquea el paso con error HTTP 403 (Prohibido).
    if usuario["estado"] != "activo":
        raise HTTPException(status_code=403, detail="Tu cuenta no está activa.")

    # Si todo está en orden, responde con código 200 y envía en JSON los datos básicos del usuario para guardarlos en Flutter.

# Genera un código secreto aleatorio y seguro (32 bytes en formato seguro para URL) que servirá como pase de entrada para el usuario.
    token_sesion = token_urlsafe(32)

    # Guarda la sesión activa en la memoria del servidor usando el token generado como llave.
    sesiones[token_sesion] = {
        # Asocia este pase con el identificador único del usuario que inició sesión.
        "id_usuario": usuario["id_usuario"],
        # Calcula el momento exacto en que caducará la sesión sumando 3600 segundos (1 hora) al reloj interno del sistema (monotonic).
        "vence_en": monotonic() + 3600,
    }

    # Devuelve en formato JSON los datos del usuario junto con el nuevo token para que Flutter lo guarde y lo envíe en futuras peticiones.
    return {
        "id_usuario": usuario["id_usuario"],
        "nombre": usuario["nombre"],
        "correo": usuario["correo"],
        "rol": usuario["rol"],
        "token_sesion": token_sesion,
    }