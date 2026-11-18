# Thank U Music

Thank U Music es un blog de música. Permite registrar usuarios, iniciar sesión, consultar publicaciones y añadir comentarios desde una aplicación móvil.

El proyecto utiliza Flutter para la aplicación, FastAPI para la API y MySQL/MariaDB para almacenar la información.

## Integrantes

- Juan Jose Gutierrez Castro
- Wesly Giovanny Orozco Pedraza

## Tecnologías utilizadas

- Flutter y Dart.
- Python y FastAPI.
- SQLAlchemy.
- MySQL/MariaDB.
- XAMPP.
- Android Studio.
- Git y GitHub.

## Funciones principales

- Registro de usuarios.
- Inicio y cierre de sesión.
- Consulta de publicaciones propias y de otros usuarios.
- Creación y lectura de comentarios.
- Edición del perfil y selección de fotografías.
- Funciones de administración según el rol del usuario.

## Requisitos de instalación

Antes de ejecutar el proyecto, se necesita instalar:

- Git.
- Python.
- Flutter SDK y sus herramientas en el PATH.
- XAMPP o un servidor MySQL/MariaDB.
- Android Studio con los plugins Flutter y Dart.
- Android SDK para ejecutar la aplicación en Android.
- Google Chrome si se desea probar la versión web de Flutter.

Para comprobar la instalación, ejecutar en PowerShell:

```powershell
git --version
py --version
flutter --version
flutter doctor
```

Los siguientes comandos están escritos para PowerShell en Windows.

## 1. Descargar el repositorio

```powershell
git clone [URL_DEL_REPOSITORIO]
cd [CARPETA_DEL_REPOSITORIO]
```

Localizar las dos carpetas principales:

- `backend_thankumusic`: contiene `main.py` y la API.
- `thankumusic_app`: contiene `pubspec.yaml` y la aplicación Flutter.

Si las carpetas tienen otros nombres, ajustar los comandos de esta guía.

## 2. Preparar la base de datos

Abrir XAMPP e iniciar MySQL. Para utilizar phpMyAdmin y servir las imágenes desde el sitio PHP, iniciar también Apache.

Abrir:

http://localhost/phpmyadmin/

Importar el script `bd_thankumusic.sql` incluido en el repositorio.

La base de datos se llama `bd_thankumusic` y contiene estas tablas:

| Tabla | Información |
| --- | --- |
| usuarios | Datos de la cuenta, contraseña, rol, estado y fotografía. |
| publicaciones | Título, contenido, imagen, etiquetas y autor. |
| comentarios | Comentarios relacionados con usuarios y publicaciones. |

El script de creación genera la estructura. Si no incluye datos de ejemplo, será necesario registrar usuarios y crear publicaciones para probar la aplicación.

## 3. Instalar las dependencias del backend

Desde la carpeta del repositorio:

```powershell
cd backend_thankumusic
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

El archivo `requirements.txt` debe incluir las dependencias utilizadas por el backend, entre ellas:

- fastapi
- uvicorn
- sqlalchemy
- pymysql
- python-dotenv
- pwdlib con soporte para bcrypt
- pillow
- python-multipart
- email-validator

Para comprobar que no existan conflictos entre las dependencias:

```powershell
.\.venv\Scripts\python.exe -m pip check
```

## 4. Configurar el backend

Crear el archivo `.env` dentro de `backend_thankumusic`.

Si existe `.env.example`, copiarlo:

```powershell
Copy-Item .env.example .env
```

Configurar los datos de conexión según la instalación local. Estos nombres deben coincidir con los que utiliza `database.py`:

```dotenv
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=bd_thankumusic
DB_USER=root
DB_PASSWORD=

PORTADAS_DIRECTORIO=C:/xampp/htdocs/blog_web/uploads
PORTADAS_BASE_URL=http://localhost/blog_web/uploads
```

En este ejemplo:

- `DB_PASSWORD` queda vacío si el usuario root de la instalación local no tiene contraseña.
- `PORTADAS_DIRECTORIO` indica la carpeta física donde se guardan las imágenes.
- `PORTADAS_BASE_URL` indica la dirección desde la que se consultan esas imágenes.

Ajustar ambas rutas si el sitio PHP tiene otro nombre o ubicación. La carpeta `uploads` debe existir.

Para visualizar fotografías de registros anteriores, también se necesitan los archivos de imagen correspondientes.

## 5. Ejecutar FastAPI

En la carpeta del backend:

```powershell
.\.venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Mantener esta terminal abierta mientras se utiliza la aplicación.

Abrir la documentación de la API:

http://127.0.0.1:8000/docs

Desde esta página se pueden consultar y probar los endpoints disponibles.

## 6. Instalar las dependencias de Flutter

Abrir otra terminal en la carpeta de la aplicación:

```powershell
cd [RUTA_DEL_REPOSITORIO]\thankumusic_app
flutter pub get
```

Este comando descarga los paquetes declarados en `pubspec.yaml`.

Entre los paquetes utilizados están:

- `http`: comunicación con FastAPI.
- `image_picker`: selección de fotografías e imágenes.

La lista completa de paquetes y versiones se encuentra en `pubspec.yaml` y `pubspec.lock`.

## 7. Configurar la dirección de la API

La aplicación utiliza una variable de compilación llamada `API_BASE_URL`.

En `api_config.dart` se define:

```dart
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);
```

Los servicios utilizan esa dirección conservando la ruta de cada petición. Por ejemplo:

```dart
Uri.parse('$apiBaseUrl/login')
```

Para cambiar la dirección de la API, ejecutar Flutter con `--dart-define`, como se muestra en los siguientes apartados.

## 8. Ejecutar en Chrome

Con MySQL y FastAPI funcionando:

```powershell
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

El origen utilizado por Flutter debe estar permitido en la configuración CORS del backend. Para esta ejecución se utilizan los orígenes locales del puerto 8080.

## 9. Ejecutar en un celular Android por USB

### Preparar Android

1. Activar las opciones de desarrollador del celular.
2. Activar Depuración USB.
3. Conectar el celular con un cable que permita transferir datos.
4. Aceptar el aviso de autorización de depuración en el teléfono.

En la PC, ejecutar:

```powershell
flutter doctor --android-licenses
flutter doctor
flutter devices
```

El último comando muestra los dispositivos disponibles y sus identificadores.

### Comprobar la conexión con FastAPI

Conectar la PC y el celular a la misma red Wi-Fi.

Consultar la dirección IPv4 de la PC:

```powershell
ipconfig
```

Buscar la IPv4 del adaptador que utiliza esa red.

Desde el navegador del celular, abrir:

```text
http://IP_DE_LA_PC:8000/docs
```

Por ejemplo:

```text
http://192.168.1.25:8000/docs
```

Si abre la documentación de FastAPI, ejecutar la app:

```powershell
flutter run -d ID_DEL_CELULAR --dart-define=API_BASE_URL=http://192.168.1.25:8000
```

Sustituir el ID y la IP por los valores del equipo utilizado.

La IP de `API_BASE_URL` corresponde a la PC que ejecuta FastAPI.

### Visualizar imágenes en Android

Si las imágenes se sirven desde Apache, mantenerlo encendido y cambiar la URL del archivo `.env` por una dirección accesible desde el teléfono:

```dotenv
PORTADAS_BASE_URL=http://192.168.1.25/blog_web/uploads
```

Conservar `PORTADAS_DIRECTORIO` como la ruta física de Windows y reiniciar FastAPI después de modificar el archivo.

## 10. Ejecutar desde Android Studio

1. Abrir la carpeta `thankumusic_app`, donde se encuentra `pubspec.yaml`.
2. Comprobar que los plugins Flutter y Dart estén instalados.
3. Abrir `lib/main.dart`.
4. Entrar a **Run → Edit Configurations**.
5. Seleccionar o crear una configuración de tipo Flutter.
6. Seleccionar `lib/main.dart` como punto de entrada.
7. Agregar en **Additional run args**:

```text
--dart-define=API_BASE_URL=http://192.168.1.25:8000
```

8. Ajustar la IP, seleccionar el celular y presionar **Run**.

MySQL y FastAPI deben permanecer funcionando.

## Uso de la aplicación

1. Abrir la aplicación.
2. Registrar una cuenta con los datos solicitados.
3. Iniciar sesión con el correo y la contraseña registrados.
4. Consultar las publicaciones disponibles.
5. Abrir una publicación para leer su contenido y sus comentarios.
6. Escribir un comentario desde una sesión iniciada.
7. Cerrar sesión al terminar.

Las opciones de administración dependen del rol de la cuenta.

### Preparar una cuenta de administrador

Registrar primero una cuenta de prueba desde la aplicación. Después, ejecutar en MySQL/MariaDB:

```sql
USE bd_thankumusic;

UPDATE usuarios
SET rol = 'administrador'
WHERE correo = 'correo_de_prueba@ejemplo.com';
```

Sustituir el correo por el de la cuenta registrada y volver a iniciar sesión.

## Seguridad

Las contraseñas se almacenan mediante hash con bcrypt. El inicio de sesión verifica las credenciales y el backend controla el acceso a las operaciones protegidas.

Los roles del sistema son:

- `visor`: usuario de la aplicación.
- `administrador`: usuario con acceso a las funciones de administración.

Los usuarios también cuentan con un estado: `activo` o `baneado`.

El archivo `.env` contiene la configuración local y debe mantenerse fuera del repositorio público. Para compartir la configuración, utilizar `.env.example` con datos de ejemplo.

## Problemas frecuentes

### Flutter indica que no encuentra pubspec.yaml

La terminal está ubicada fuera de la carpeta de Flutter. Entrar a `thankumusic_app` y repetir el comando.

### El celular no aparece en flutter devices

Revisar la depuración USB, aceptar la autorización del teléfono y comprobar que el cable permita transferir datos.

### La aplicación no conecta con FastAPI

Comprobar que:

- MySQL esté funcionando.
- FastAPI esté iniciado con `--host 0.0.0.0`.
- La IP utilizada corresponda a la PC.
- Ambos equipos estén en la misma red.
- La dirección `/docs` abra desde el celular.
- El firewall permita la conexión local al puerto 8000.

### Las imágenes no cargan

Comprobar que Apache esté encendido, que los archivos existan en `uploads` y que `PORTADAS_BASE_URL` sea accesible desde el dispositivo.

### Error al instalar el NDK

Si la compilación solicita `28.2.13676358`, abrir Android Studio:

**SDK Manager → SDK Tools → Show Package Details → NDK (Side by side)**

Seleccionar esa versión, completar su instalación y volver a ejecutar Flutter.

### Se modificó API_BASE_URL, pero la app conserva la dirección anterior

Detener la ejecución y volver a ejecutar el comando completo con el nuevo valor de `--dart-define`.

## Contexto académico

Proyecto desarrollado para la evaluación de la Unidad 3 de Aplicaciones Móviles.

Su objetivo es integrar una aplicación Flutter con una API en FastAPI y una base de datos MySQL/MariaDB, incorporando autenticación, publicaciones y comentarios.
