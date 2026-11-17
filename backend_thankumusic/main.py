# Importa las herramientas principales de FastAPI: inyección de dependencias (Depends), la aplicación (FastAPI) y el manejo de errores HTTP (HTTPException).
from fastapi import Depends, FastAPI, HTTPException, File, Form, UploadFile
# Importa 'ImageOps' para aplicar ajustes automáticos sencillos a las imágenes (como corregir su orientación según los datos de la cámara o recortarlas).
from PIL import Image, ImageOps
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
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

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
# Importa 'getenv' para leer variables de entorno del sistema (como contraseñas, usuarios o URLs configuradas fuera del código).
from os import getenv
# Importa 'quote' para codificar caracteres especiales en texto (por ejemplo, símbolos en una contraseña) para que no rompan una dirección URL.
from urllib.parse import quote
# Importa 'Path' para manejar rutas de carpetas y archivos de forma limpia y compatible con cualquier sistema operativo.
from pathlib import Path
# Importa 'uuid4' para generar identificadores únicos aleatorios (útil para nombrar archivos subidos sin que se sobrescriban).
from uuid import uuid4


app = FastAPI(title="API Thank U Music")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8080"],
    allow_methods=["*"],
    allow_headers=["Content-Type", "Authorization"],
)

# Guardamos las sesiones mientras FastAPI esté ejecutándose.
sesiones = {}

# Define el tiempo máximo de inactividad permitido antes de cerrar la sesión automáticamente.
# Se escribe como 10 * 60 para indicar claramente que son 10 minutos expresados en segundos (600 segundos en total).
TIEMPO_INACTIVIDAD = 10 * 60  # Segundos.

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
        "vence_en": monotonic() + TIEMPO_INACTIVIDAD,
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

        # Consultamos el estado y el rol actuales de la cuenta en MySQL.
    with engine.connect() as conexion:
        cuenta = conexion.execute(
            text("""
                SELECT estado, rol
                FROM usuarios
                WHERE id_usuario = :id_usuario
            """),
            {"id_usuario": id_usuario},
        ).mappings().first()
        # Podemos leer las dos columnas por nombre. Si no hay usuario, cuenta vale None.

    if cuenta is None or cuenta["estado"] != "activo":
        sesiones.pop(token_sesion, None)
        raise HTTPException(
            status_code=401,
            detail="La cuenta ya no está activa.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Calcula y guarda el momento en el que caducará la sesión.
    # Usamos monotonic() para que los cambios en la hora del servidor no alteren el plazo.
    sesion["vence_en"] = monotonic() + TIEMPO_INACTIVIDAD

    return {"id_usuario": id_usuario, "rol": cuenta["rol"]}

@app.get("/perfil")
def consultar_perfil(sesion: dict = Depends(consultar_sesion)):
    # Buscamos el perfil usando el ID de la cuenta que inició sesión.
    with engine.connect() as conexion:
        perfil = conexion.execute(
            text("""
                SELECT nombre, correo, direccion, foto
                FROM usuarios
                WHERE id_usuario = :id_usuario
            """),
            {"id_usuario": sesion["id_usuario"]},
        ).mappings().first()

    if perfil is None:
        raise HTTPException(status_code=404, detail="No se encontró el perfil.")

# Convierte el registro obtenido de la base de datos en un diccionario modificable de Python.
    datos = dict(perfil)
    # Extrae el nombre o ruta del archivo de la foto guardado en el registro.
    foto = datos["foto"]
    # Lee la dirección web base desde las variables de entorno y le quita la barra diagonal final si existe.
    url_base = getenv("PORTADAS_BASE_URL", "").rstrip("/")

    # Si existen tanto la dirección base como una foto asignada, arma la URL completa codificando caracteres especiales del nombre del archivo; si no, deja el campo vacío (None).
    datos["foto_url"] = (
        f"{url_base}/{quote(Path(foto).name, safe='')}"
        if url_base and foto
        else None
    )

    # Devuelve el diccionario del perfil con la dirección web de la foto ya incluida.
    return datos

class PerfilRequest(BaseModel):
    nombre: str
    correo: str
    direccion: str


@app.patch("/perfil")
def actualizar_perfil(
    datos: PerfilRequest,
    sesion: dict = Depends(consultar_sesion),
):
    nombre = datos.nombre.strip()
    correo = datos.correo.strip().lower()
    direccion = datos.direccion.strip()

    if not nombre or not correo or not direccion:
        raise HTTPException(status_code=422, detail="Completa todos los campos.")

    if len(nombre) > 100 or not all(
        letra.isalpha() or letra == " " for letra in nombre
    ):
        raise HTTPException(
            status_code=422,
            detail="El nombre debe tener hasta 100 caracteres y solo letras y espacios.",
        )

    if len(correo) > 150 or not fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", correo):
        raise HTTPException(status_code=422, detail="Escribe un correo electrónico válido.")

    if len(direccion) > 255:
        raise HTTPException(
            status_code=422,
            detail="La dirección no puede superar los 255 caracteres.",
        )

    try:
        with engine.begin() as conexion:
            # El ID sale de la sesión, igual que al consultar el perfil.
            conexion.execute(
                text("""
                    UPDATE usuarios
                    SET nombre = :nombre, correo = :correo, direccion = :direccion
                    WHERE id_usuario = :id_usuario
                """),
                {
                    "nombre": nombre,
                    "correo": correo,
                    "direccion": direccion,
                    "id_usuario": sesion["id_usuario"],
                },
            )
    except IntegrityError as error:
        if error.orig.args[0] == 1062:
            raise HTTPException(
                status_code=409,
                detail="Ese correo ya está en uso.",
            ) from error
        raise

    return {"nombre": nombre, "correo": correo, "direccion": direccion}

# Ruta POST para subir una nueva imagen y guardarla como foto de perfil del usuario conectado.
@app.post("/perfil/foto")
def actualizar_foto_perfil(
    foto: UploadFile = File(...),
    sesion: dict = Depends(consultar_sesion),
):
    # Guarda el archivo recibido en el disco del servidor con el prefijo 'perfil_' y devuelve su ruta.
    ruta = guardar_portada_publicacion(foto, prefijo="perfil_")

    try:
        # Inicia una transacción segura en la base de datos para actualizar el nombre del archivo de la foto.
        with engine.begin() as conexion:
            resultado = conexion.execute(
                text("""
                    UPDATE usuarios
                    SET foto = :foto
                    WHERE id_usuario = :id_usuario
                """),
                {
                    "foto": ruta.name,
                    "id_usuario": sesion["id_usuario"],
                },
            )

            # Si no se actualizó ningún registro porque el usuario no existe, borra la imagen recién subida y lanza error 404.
            if resultado.rowcount == 0:
                ruta.unlink(missing_ok=True)
                raise HTTPException(
                    status_code=404,
                    detail="No se encontró el perfil.",
                )
    except SQLAlchemyError as error:
        # Si ocurre algún fallo con la base de datos, elimina el archivo guardado para no dejar basura y devuelve error 500.
        ruta.unlink(missing_ok=True)
        raise HTTPException(
            status_code=500,
            detail="No se pudo guardar la foto de perfil.",
        ) from error

    # Devuelve los datos completos y actualizados del perfil (incluyendo la nueva URL de la foto).
    return consultar_perfil(sesion)

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
    return guardar_usuario(datos,rol="visor")

def guardar_usuario(datos: RegistroRequest, rol: str):
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
                    INSERT INTO usuarios (nombre, correo, direccion, password, rol)
                    VALUES (:nombre, :correo, :direccion, :password, :rol)
                """),
                # Diccionario con los valores reales que reemplazarán a cada marcador de posición, guardando la contraseña ya encriptada.
                {
                    "nombre": nombre,
                    "correo": correo,
                    "direccion": direccion,
                    "password": hash_password,
                    "rol": rol,
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

@app.post("/administradores", status_code=201)
def registrar_administrador(
    datos: RegistroRequest,
    sesion: dict = Depends(consultar_sesion),
):
    if sesion["rol"] != "administrador":
        raise HTTPException(
            status_code=403,
            detail="Solo un administrador puede crear otra cuenta de administrador.",
        )

    return guardar_usuario(datos, rol="administrador")

@app.get("/administradores/usuarios")
def listar_usuarios(sesion: dict = Depends(consultar_sesion)):
    # Solo un administrador con sesión válida puede consultar la lista.
    if sesion.get("rol") != "administrador":
        raise HTTPException(
            status_code=403,
            detail="Solo un administrador puede consultar los usuarios.",
        )

    # Consulta los datos que necesita la pantalla de Gestión de usuarios.
    with engine.connect() as conexion:
        usuarios = conexion.execute(
            text("""
                SELECT id_usuario, nombre, correo, rol, estado, foto
                FROM usuarios
                ORDER BY nombre ASC, id_usuario ASC
            """)
        ).mappings().all()

    return [dict(usuario) for usuario in usuarios]

@app.get("/publicaciones", dependencies=[Depends(consultar_sesion)])
def listar_publicaciones():
    with engine.connect() as conexion:
        filas = conexion.execute(
            text("""
               SELECT p.id_publicacion, p.titulo, p.contenido, p.imagen,
                u.nombre AS autor, p.fecha_publicacion
                FROM publicaciones AS p
                LEFT JOIN usuarios AS u ON u.id_usuario = p.id_autor
                WHERE p.estado = 'publicada'
                ORDER BY p.fecha_publicacion DESC, p.id_publicacion DESC
            """)
        ).mappings().all()

    url_base = getenv("PORTADAS_BASE_URL", "").rstrip("/")
    publicaciones = []

    for fila in filas:
        publicacion = dict(fila)
        imagen = publicacion["imagen"]

        publicacion["imagen_url"] = (
            f"{url_base}/{quote(imagen, safe='')}" if url_base and imagen else None
        )

        publicaciones.append(publicacion)

    return publicaciones

def publicaciones_con_portada(filas):
    url_base = getenv("PORTADAS_BASE_URL", "").rstrip("/")
    publicaciones = []

    for fila in filas:
        publicacion = dict(fila)
        imagen = publicacion["imagen"]
        publicacion["imagen_url"] = (
            f"{url_base}/{quote(imagen, safe='')}" if url_base and imagen else None
        )
        publicaciones.append(publicacion)

    return publicaciones

# Ruta GET para obtener únicamente las publicaciones creadas por el administrador que tiene la sesión iniciada.
@app.get("/publicaciones/mias")
def listar_mis_publicaciones(sesion: dict = Depends(consultar_sesion)):
    # Verifica que el usuario tenga rol de administrador; si no, bloquea el acceso (error 403).
    if sesion["rol"] != "administrador":
        raise HTTPException(
            status_code=403,
            detail="Solo un administrador puede consultar esta lista.",
        )

    # Abre una conexión de lectura a la base de datos.
    with engine.connect() as conexion:
        # Busca todas las publicaciones del usuario conectado que estén en borrador o publicadas, ordenadas de la más reciente a la más antigua.
        filas = conexion.execute(
            text("""
                SELECT id_publicacion, titulo, contenido, imagen, tags,
                       estado, fecha_publicacion
                FROM publicaciones
                WHERE id_autor = :id_autor
                  AND estado IN ('borrador', 'publicada')
                ORDER BY fecha_publicacion DESC, id_publicacion DESC
            """),
            {"id_autor": sesion["id_usuario"]},
        ).mappings().all()

    # Agrega la ruta completa de la imagen de portada a cada resultado y devuelve la lista final.
    return publicaciones_con_portada(filas)

# Define un endpoint GET en FastAPI que recibe el ID de una publicación en la ruta y exige que la sesión sea válida ('consultar_sesion') antes de ejecutar la función.
@app.get(
    "/publicaciones/{id_publicacion}/comentarios",
    dependencies=[Depends(consultar_sesion)],
)
def listar_comentarios(id_publicacion: int):
    # Abre una conexión temporal a la base de datos 
    with engine.connect() as conexion:
        # Ejecuta una consulta SQL  y obtiene todas las filas como diccionarios ('mappings().all()').
        filas = conexion.execute(
            text("""
                -- Selecciona el identificador, texto y fecha del comentario, junto con el nombre del usuario que lo escribió.
                SELECT c.id_comentario, c.comentario, c.fecha_comentario,
                       u.nombre AS autor
                FROM comentarios AS c
                -- Une con la tabla de usuarios para obtener el nombre del autor y con publicaciones para verificar su estado.
                INNER JOIN usuarios AS u ON u.id_usuario = c.id_usuario
                INNER JOIN publicaciones AS p
                    ON p.id_publicacion = c.id_publicacion
                -- Filtra únicamente los comentarios de esa publicación siempre y cuando la publicación esté activa ('publicada').
                WHERE c.id_publicacion = :id_publicacion
                  AND p.estado = 'publicada'
                -- Ordena los comentarios del más antiguo al más reciente.
                ORDER BY c.fecha_comentario DESC, c.id_comentario DESC
            """),
            {"id_publicacion": id_publicacion},
        ).mappings().all()

    # Convierte cada fila obtenida en un diccionario estándar de Python para que FastAPI los devuelva en formato JSON.
    return [dict(fila) for fila in filas]

# Define la estructura de datos que se espera recibir del usuario (un texto llamado 'comentario').
class ComentarioRequest(BaseModel):
    comentario: str


# Ruta POST para guardar un comentario nuevo en una publicación y responder con código 201 (creado con éxito).
@app.post("/publicaciones/{id_publicacion}/comentarios", status_code=201)
def crear_comentario(
    id_publicacion: int,
    datos: ComentarioRequest,
    sesion: dict = Depends(consultar_sesion),
):

    # Quita los espacios en blanco al inicio y al final; si el texto queda vacío, rechaza la petición (error 422).
    comentario = datos.comentario.strip()
    if not comentario:
        raise HTTPException(
            status_code=422,
            detail="Escribe un comentario.",
        )

    # Abre una conexión segura a la base de datos que guarda los cambios automáticamente al terminar.
    with engine.begin() as conexion:
        # Inserta el comentario en la tabla solo si la publicación existe y su estado sigue siendo 'publicada'.
        resultado = conexion.execute(
            text("""
                INSERT INTO comentarios
                    (id_publicacion, id_usuario, comentario, fecha_comentario)
                SELECT p.id_publicacion, :id_usuario, :comentario, CURRENT_TIMESTAMP
                FROM publicaciones AS p
                WHERE p.id_publicacion = :id_publicacion
                  AND p.estado = 'publicada'
            """),
            {
                "id_publicacion": id_publicacion,
                "id_usuario": sesion["id_usuario"],
                "comentario": comentario,
            },
        )

        # Si no se guardó ninguna fila (porque la publicación no existe o fue ocultada), avisa que no está disponible (error 404).
        if resultado.rowcount == 0:
            raise HTTPException(
                status_code=404,
                detail="La publicación no está disponible.",
            )

    # Confirma a la aplicación móvil que el comentario se guardó correctamente.
    return {"mensaje": "Comentario publicado."}

# Ruta DELETE para borrar un comentario específico dentro de una publicación concreta.
@app.delete("/publicaciones/{id_publicacion}/comentarios/{id_comentario}")
def eliminar_comentario(
    id_publicacion: int,
    id_comentario: int,
    sesion: dict = Depends(consultar_sesion),
):
    # Verifica que el usuario conectado tenga rol de administrador; si no, bloquea la acción (error 403).
    if sesion["rol"] != "administrador":
        raise HTTPException(
            status_code=403,
            detail="Solo un administrador puede eliminar comentarios.",
        )

    # Abre una transacción segura en la base de datos que confirma el borrado al terminar o lo revierte si hay error.
    with engine.begin() as conexion:
        # Usamos ambos ID para borrar solo el comentario de esta publicación.
        resultado = conexion.execute(
            text("""
                DELETE FROM comentarios
                WHERE id_comentario = :id_comentario
                  AND id_publicacion = :id_publicacion
            """),
            {
                "id_comentario": id_comentario,
                "id_publicacion": id_publicacion,
            },
        )

        # Si no se borró ninguna fila porque el comentario no existe o pertenece a otra publicación, devuelve error 404.
        if resultado.rowcount == 0:
            raise HTTPException(status_code=404, detail="No se encontró el comentario.")

    # Devuelve confirmación en formato JSON indicando que el comentario fue eliminado.
    return {"mensaje": "Comentario eliminado."}

# Revisa que el título, el contenido y la etiqueta cumplan con las reglas antes de guardar o actualizar una publicación.
def validar_datos_publicacion(titulo: str, contenido: str, tags: str):
    # Quita los espacios en blanco sobrantes al inicio y al final del título y de la etiqueta.
    titulo = titulo.strip()
    tags = tags.strip()

    # Comprueba que el título no quede vacío ni supere los 200 caracteres; si falla, detiene el proceso (error 422).
    if not titulo or len(titulo) > 200:
        raise HTTPException(status_code=422, detail="Escribe un título de hasta 200 caracteres.")

    # Comprueba que el contenido tenga texto real y no rebase los 15,000 caracteres.
    if not contenido.strip() or len(contenido) > 15000:
        raise HTTPException(status_code=422, detail="Escribe un contenido de hasta 15 000 caracteres.")

    # Lista cerrada de etiquetas permitidas; si envían otra distinta, devuelve un error de validación (422).
    etiquetas = ("analisis", "resena", "recomendacion", "Aviso", "Conciertos")
    if tags not in etiquetas:
        raise HTTPException(status_code=422, detail="Selecciona una etiqueta válida.")

    # Devuelve el título y la etiqueta ya limpios de espacios extra para guardarlos en la base de datos.
    return titulo, tags


def guardar_portada_publicacion(imagen: UploadFile, *, prefijo: str = "") -> Path:
    directorio = getenv("PORTADAS_DIRECTORIO", "")
    if not directorio or not Path(directorio).is_dir():
        raise HTTPException(
            status_code=500,
            detail="Revisa la carpeta compartida de portadas.",
        )

    # Detectamos el formato real de la imagen y corregimos su orientación.
    extensiones = {"JPEG": ".jpg", "PNG": ".png", "WEBP": ".webp"}

    try:
        with Image.open(imagen.file, formats=list(extensiones)) as portada:
            formato = portada.format
            portada_lista = ImageOps.exif_transpose(portada)
    except (OSError, ValueError, Image.DecompressionBombError) as error:
        raise HTTPException(
            status_code=422,
            detail="Selecciona una imagen JPG, PNG o WebP válida.",
        ) from error

    nombre = f"{prefijo}{uuid4().hex}{extensiones[formato]}"
    ruta = Path(directorio) / nombre

    try:
        with portada_lista:
            portada_lista.save(ruta, format=formato)
    except (OSError, ValueError) as error:
        ruta.unlink(missing_ok=True)
        raise HTTPException(
            status_code=500,
            detail="No se pudo guardar la portada.",
        ) from error

    return ruta

@app.post("/publicaciones", status_code=201)
def crear_publicacion(
    titulo: str = Form(...),
    contenido: str = Form(...),
    tags: str = Form(...),
    imagen: UploadFile = File(...),
    estado: str = Form("publicada"),
    sesion: dict = Depends(consultar_sesion),
):
    if sesion["rol"] != "administrador":
        raise HTTPException(
            status_code=403,
            detail="Solo un administrador puede publicar.",
        )

    if estado not in ("borrador", "publicada"):
        raise HTTPException(status_code=422, detail="Elige un estado válido.")

    titulo, tags = validar_datos_publicacion(titulo, contenido, tags)
    ruta_imagen = guardar_portada_publicacion(imagen)

    try:
        with engine.begin() as conexion:
            resultado = conexion.execute(
                text("""
                    INSERT INTO publicaciones
                        (titulo, contenido, imagen, tags, id_autor, estado)
                    VALUES
                        (:titulo, :contenido, :imagen, :tags, :id_autor, :estado)
                """),
                {
                    "titulo": titulo,
                    "contenido": contenido,
                    "imagen": ruta_imagen.name,
                    "tags": tags,
                    "id_autor": sesion["id_usuario"],
                    "estado": estado,
                },
            )
            id_publicacion = resultado.lastrowid
    except SQLAlchemyError as error:
        ruta_imagen.unlink(missing_ok=True)
        raise HTTPException(
            status_code=500,
            detail="No se pudo guardar la publicación.",
        ) from error

    return {"id_publicacion": id_publicacion, "mensaje": "Publicación creada."}

# Ruta PATCH para editar una publicación existente por su ID, aceptando textos y opcionalmente una nueva imagen de portada.
@app.patch("/publicaciones/{id_publicacion}")
def editar_publicacion(
    id_publicacion: int,
    titulo: str = Form(...),
    contenido: str = Form(...),
    tags: str = Form(...),
    publicar: bool = Form(False),
    imagen: UploadFile | None = File(None),
    sesion: dict = Depends(consultar_sesion),
):
    # Verifica que el usuario conectado tenga rol de administrador; si no, bloquea la edición (error 403).
    if sesion["rol"] != "administrador":
        raise HTTPException(status_code=403, detail="Solo un administrador puede editar.")

    # Valida longitud y formato del título, contenido y etiqueta antes de tocar la base de datos.
    titulo, tags = validar_datos_publicacion(titulo, contenido, tags)
    # Variable para guardar la ruta del nuevo archivo de imagen si es que el usuario subió uno.
    ruta_nueva = None

    try:
        # Abre una transacción segura en la base de datos que guarda todo al final o revierte si algo falla.
        with engine.begin() as conexion:
            # Comprobamos que la publicación pertenezca al administrador conectado.
            estado_actual = conexion.execute(
                text("""
                    SELECT estado FROM publicaciones
                    WHERE id_publicacion = :id AND id_autor = :autor
                      AND estado IN ('borrador', 'publicada')
                    FOR UPDATE
                """),
                {"id": id_publicacion, "autor": sesion["id_usuario"]},
            ).scalar_one_or_none()

            # Si no existe esa publicación o pertenece a otro autor, devuelve error 404.
            if estado_actual is None:
                raise HTTPException(status_code=404, detail="No se encontró la publicación.")

            # Si el usuario envió una nueva imagen de portada, la valida y la guarda en el servidor.
            if imagen is not None:
                ruta_nueva = guardar_portada_publicacion(imagen)

            # Determina si se está pasando un borrador a estado publicado por primera vez.
            publicar_borrador = publicar and estado_actual == "borrador"
            estado = "publicada" if publicar_borrador else estado_actual

            # Actualiza los datos; 'COALESCE' mantiene la imagen anterior si no se subió una nueva, y la fecha solo cambia al publicar un borrador.
            conexion.execute(
                text("""
                    UPDATE publicaciones
                    SET titulo = :titulo, contenido = :contenido, tags = :tags,
                        imagen = COALESCE(:imagen, imagen),
                        estado = :estado,
                        fecha_publicacion = CASE
                            WHEN :publicar_borrador THEN CURRENT_TIMESTAMP
                            ELSE fecha_publicacion
                        END
                    WHERE id_publicacion = :id AND id_autor = :autor
                """),
                {
                    "titulo": titulo,
                    "contenido": contenido,
                    "tags": tags,
                    "imagen": ruta_nueva.name if ruta_nueva else None,
                    "estado": estado,
                    "publicar_borrador": publicar_borrador,
                    "id": id_publicacion,
                    "autor": sesion["id_usuario"],
                },
            )
    except SQLAlchemyError as error:
        # Si falla la actualización en la base de datos y se alcanzó a guardar una imagen nueva, la borra para no dejar archivos sueltos.
        if ruta_nueva is not None:
            ruta_nueva.unlink(missing_ok=True)
        raise HTTPException(status_code=500, detail="No se pudieron guardar los cambios.") from error

    # Devuelve confirmación y el estado final con el que quedó guardada la publicación.
    return {"mensaje": "Cambios guardados.", "estado": estado}