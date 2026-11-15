# Permite interactuar con el sistema operativo para leer las variables de entorno (como usuario, clave o nombre de la base de datos).
import os

# Importa la función que lee el archivo oculto '.env' y carga sus datos como variables disponibles en el sistema.
from dotenv import load_dotenv
# Importa la función principal de SQLAlchemy para construir el motor que administra la conexión con la base de datos.
from sqlalchemy import create_engine
# Importa la clase URL, que sirve para armar de forma segura y ordenada la dirección de conexión sin concatenar texto manualmente.
from sqlalchemy.engine import URL

# Busca el archivo '.env' en tu proyecto y carga sus variables al sistema para no escribir contraseñas directo en el código.
load_dotenv()

# Arma de forma segura la dirección completa de conexión (URL) hacia tu base de datos MariaDB/MySQL.
url = URL.create(
    # Indica que usaremos SQLAlchemy junto con el conector 'pymysql' para hablar con MySQL o MariaDB.
    drivername="mysql+pymysql",
    # Lee el usuario de la base de datos desde .env; usa corchetes [] para que marque error de inmediato si olvidaste definirlo.
    username=os.environ["DB_USER"],
    # Lee la contraseña desde .env; si no existe, usa un texto vacío "" por defecto (útil en XAMPP local sin clave).
    password=os.getenv("DB_PASSWORD", ""),
    # Lee la dirección del servidor; si no está en .env, apunta a tu propia computadora ("127.0.0.1").
    host=os.getenv("DB_HOST", "127.0.0.1"),
    # Lee el puerto de conexión (3306 por defecto en MySQL/MariaDB) y lo convierte de texto a número entero (int).
    port=int(os.getenv("DB_PORT", "3306")),
    # Lee el nombre exacto de la base de datos (por ejemplo, 'thankumusic'); exige que exista en .env.
    database=os.environ["DB_NAME"],
    # Configura la codificación utf8mb4 para guardar acentos, la letra ñ y emojis sin que se dañen.
    query={"charset": "utf8mb4"},
)

# Crea el motor principal de conexión que administrará las peticiones a la base de datos.
# pool_pre_ping=True revisa que la conexión siga viva antes de cada consulta, evitando fallos si MariaDB la cerró por inactividad.
engine = create_engine(url, pool_pre_ping=True)