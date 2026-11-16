# Importa las herramientas principales de FastAPI: inyección de dependencias (Depends), la aplicación (FastAPI) y el manejo de errores HTTP (HTTPException).
from fastapi import Depends, FastAPI, HTTPException
# Importa las clases para leer y validar el token de sesión tipo Bearer que envía Flutter en los encabezados HTTP.
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
# Importa BaseModel para definir la estructura de datos, Field para reglas de longitud, ConfigDict para configuración global y EmailStr para validar correos.
from pydantic import BaseModel, Field, ConfigDict, EmailStr
# Importa el gestor para encriptar contraseñas nuevas y verificar si coinciden al iniciar sesión.
from pwdlib import PasswordHash
# Importa la excepción que se lanza si una contraseña guardada en la base de datos tiene un formato desconocido o corrupto.
from pwdlib.exceptions import UnknownHashError
# Importa el algoritmo Bcrypt, encargado de convertir la contraseña en texto plano a un código encriptado seguro.
from pwdlib.hashers.bcrypt import BcryptHasher
# Importa la función 'text' de SQLAlchemy para escribir consultas SQL puras de forma segura evitando inyecciones SQL.
from sqlalchemy import text
# Importa el error 'IntegrityError' para detectar cuando la base de datos rechaza un registro duplicado (como un correo ya existente).
from sqlalchemy.exc import IntegrityError

# Importa la conexión configurada a la base de datos desde tu archivo local 'database.py'.
from database import engine
# Importa el middleware CORS para permitir que la aplicación de Flutter se comunique con este servidor desde otro origen o puerto.
from fastapi.middleware.cors import CORSMiddleware
# Importa 'token_urlsafe' para generar tokens aleatorios y criptográficamente seguros al iniciar sesión.
from secrets import token_urlsafe
# Importa 'fullmatch' para validar mediante expresiones regulares que un texto completo cumpla con un formato exacto.
from re import fullmatch
# Importa 'monotonic', un reloj interno que solo avanza hacia adelante y sirve para medir cuánto tiempo lleva activa una sesión sin verse afectado por cambios de hora del sistema.
from time import monotonic


app = FastAPI(title="API Thank U Music")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8080"],
    allow_methods=["POST", "GET"],
    allow_headers=["Content-Type", "Authorization"],
)

# Guardamos las sesiones mientras FastAPI esté ejecutándose.
sesiones = {}
# Crea un lector para extraer el token de sesión que la app en Flutter envía dentro del encabezado HTTP "Authorization: Bearer <token>".
# auto_error=False evita que FastAPI corte la petición con un error genérico automático si el encabezado falta; en su lugar devuelve None para que tú mismo puedas validar el token y responder con tu propio mensaje de error personalizado.
leer_token = HTTPBearer(auto_error=False)

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

class RegistroRequest(BaseModel):
    #Limpia los espacios de los extremos antes de medir la longitud
    model_config = ConfigDict(str_strip_whitespace=True)

    # Nombre del usuario: texto obligatorio de mínimo 2 caracteres y máximo 100.
    nombre: str = Field(min_length=2, max_length=100)
    # Correo electrónico: valida automáticamente que tenga formato real de correo y no pase de 150 caracteres.
    mail: EmailStr = Field(max_length=150)
    # Dirección física: texto obligatorio de mínimo 5 caracteres y máximo 255.
    direccion: str = Field(min_length=5, max_length=255)
    # Contraseña: texto obligatorio de mínimo 8 caracteres por seguridad.
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

# Crea la ruta GET '/sesion' para comprobar si el token guardado en Flutter sigue siendo válido.
@app.get("/sesion")
def consultar_sesion(
    # Usa Depends(leer_token) para extraer automáticamente el token Bearer del encabezado HTTP; si no viene, recibe None.
    credenciales: HTTPAuthorizationCredentials | None = Depends(leer_token),
):
    # Si la app no envió ningún token en la petición, bloquea el acceso con error 401 (No autorizado).
    if credenciales is None:
        raise HTTPException(
            status_code=401,
            detail="Inicia sesión primero.",
            # Encabezado estándar HTTP que indica al cliente que debe autenticarse usando un token Bearer.
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Extrae el texto limpio del token enviado por Flutter (quitando la palabra "Bearer ").
    token_sesion = credenciales.credentials
    # Busca ese token dentro del diccionario de sesiones activas en la memoria del servidor.
    sesion = sesiones.get(token_sesion)
    
    if sesion is None:
        print("Sesión no encontrada en memoria.")
    else:
        segundos_restantes = sesion["vence_en"] - monotonic()
        print(f"Segundos restantes de la sesión: {segundos_restantes:.1f}")

    # Si la sesión existe pero el reloj actual del sistema ya alcanzó o superó la hora de vencimiento ('vence_en'):
    if sesion is not None and monotonic() >= sesion["vence_en"]:
        # Borra el token caducado de la memoria para liberar espacio y marca la sesión como nula.
        sesiones.pop(token_sesion, None)
        sesion = None

    # Si el token nunca existió o acaba de ser eliminado por caducidad, rechaza la petición con error 401.
    if sesion is None:
        raise HTTPException(
            status_code=401,
            detail="La sesión es inválida o venció.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    id_usuario = sesion["id_usuario"]

    # Consultamos el estado actual de la cuenta en MySQL.
    with engine.connect() as conexion:
        estado = conexion.execute(
            text("SELECT estado FROM usuarios WHERE id_usuario = :id_usuario"),
            {"id_usuario": id_usuario},
        # Ejecuta la consulta SQL esperando un único valor (una sola columna de una sola fila, como el id o la contraseña encriptada).
        # Si encuentra el registro, devuelve ese valor directo; si no existe ningún usuario que coincida, devuelve None sin lanzar error
        ).scalar_one_or_none()

    if estado != "activo":
        sesiones.pop(token_sesion, None)
        raise HTTPException(
            status_code=401,
            detail="La cuenta ya no está activa.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return {"id_usuario": id_usuario}

# Crea la ruta POST '/logout' en la API para invalidar y cerrar la sesión activa del usuario.
@app.post("/logout")
def cerrar_sesion(
    # Extrae automáticamente el token Bearer del encabezado HTTP 'Authorization' mediante la dependencia leer_token.
    credenciales: HTTPAuthorizationCredentials | None = Depends(leer_token),
):
    # Si la app hizo la petición sin enviar ningún token, rechaza la solicitud con error HTTP 401 (No autorizado).
    if credenciales is None:
        raise HTTPException(
            status_code=401,
            detail="Envía el token de sesión.",
            # Encabezado estándar que indica al cliente que el acceso requiere autenticación por token Bearer.
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Busca el token recibido dentro del diccionario 'sesiones' en memoria y lo elimina (.pop).
    # El segundo parámetro 'None' evita que Python lance un error si el token ya había vencido o no existía.
    sesiones.pop(credenciales.credentials, None)

    # Responde con código 200 confirmando en JSON que la sesión quedó cerrada en el servidor.
    return {"mensaje": "Sesión cerrada."}

@app.post("/registro", status_code=201)
def registrar_usuario(datos: RegistroRequest):
    nombre = datos.nombre.strip()
    correo = datos.mail.strip().lower()
    direccion = datos.direccion.strip()

    if not nombre or not correo or not direccion:
        raise HTTPException(status_code=422, detail="Completa todos los campos.")

    # Recorre cada carácter del nombre para verificar que todos sean letras (incluyendo acentos y la ñ) o espacios en blanco.
    # Si encuentra algún número o símbolo raro, detiene el registro y devuelve el error HTTP 422 (Datos no procesables).
    if not all(letra.isalpha() or letra == " " for letra in nombre):
        raise HTTPException(
            status_code=422,
            detail="El nombre solo puede contener letras y espacios.",
        )

    if not fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", correo):
        raise HTTPException(
            status_code=422,
            detail="Escribe un correo electrónico válido.",
        )

    if len(datos.password.encode("utf-8")) > 72:
        raise HTTPException(
            status_code=422,
            detail="La contraseña es demasiado larga (máximo 72 caracteres)",
        )
    # Rechaza contraseñas que contengan el carácter nulo ('\x00') porque Bcrypt corta el texto al encontrar ese símbolo e ignora el resto de la clave.
    if "\x00" in datos.password:
        raise HTTPException(status_code=422, detail="La contraseña contiene un carácter inválido.")

    # Convierte la contraseña en texto plano a un código encriptado seguro usando el algoritmo Bcrypt.
    hash_password = BcryptHasher().hash(datos.password)
    
    # Cambia el prefijo '$2b$' (que usa Python) por '$2y$' (que usa PHP) para que el blog web en PHP pueda leer esta misma contraseña encriptada.
    # Se usa [4:] para cortar los primeros 4 caracteres ('$2b$') y conservar intacto el resto de la contraseña encriptada desde la posición 4 hasta el final.
    if hash_password.startswith("$2b$"):
        hash_password = "$2y$" + hash_password[4:]
        
    try:
        # Guardamos la cuenta cuando el INSERT termina correctamente.
        with engine.begin() as conexion:
            conexion.execute(
                text("""
                    INSERT INTO usuarios (nombre, correo, direccion, password)
                    VALUES (:nombre, :correo, :direccion, :password)
                """),
                # Diccionario con los valores reales que reemplazarán a cada marcador de posición, guardando la contraseña ya encriptada.
                {
                    "nombre": nombre,
                    "correo": correo,
                    "direccion": direccion,
                    "password": hash_password,
                },
            )
    except IntegrityError as error:
        # MySQL devuelve 1062 cuando el correo único ya existe.
        if error.orig.args[0] == 1062:
            raise HTTPException(
                status_code=409,
                detail="Ese correo ya está registrado.",
            ) from error
        # Si el error de integridad fue por otra causa distinta a correo duplicado, vuelve a lanzar el error original para no ocultarlo.
        raise

    return {"mensaje": "Cuenta creada correctamente."}