# Thank U Music

Thank U Music es un blog de música que permite registrar usuarios, iniciar sesión, consultar publicaciones y escribir comentarios.

La aplicación utiliza Flutter, una API desarrollada con FastAPI y una base de datos MySQL/MariaDB.

## Integrantes

- Juan José Gutiérrez Castro.
- Wesly Giovanny Orozco Pedraza.

## Funciones

- Registro, inicio y cierre de sesión.
- Consulta de publicaciones y comentarios.
- Creación de comentarios.
- Edición del perfil y fotografía.
- Creación y edición de publicaciones para administradores.
- Administración de usuarios y moderación de comentarios.

## Preparemos todo lo que necesitas para correr el programa

### Instalar Git

Git permite descargar el proyecto 

1. Entra a [Git para Windows](https://git-scm.com/install/win).
2. Descarga y ejecuta el instalador.
3. Completa la instalación.
4. Abre una nueva ventana de PowerShell y comprueba que funcione:

```powershell
git --version
```

Debe aparecer la versión instalada de Git.

### Instalar Python

Python permite ejecutar el backend de FastAPI.

1. Entra a [Descargas de Python para Windows](https://www.python.org/downloads/windows/).
2. Descarga un instalador de Python 3.
3. Actíva la opcion. "Add Python to PATH"
4. Abre una nueva terminal y ejecuta:

```powershell
py --version
py -m pip --version
```

Ambos comandos deben mostrar una versión.

### Instalar Chrome

Chrome permite probar la aplicación Flutter desde la computadora.

1. Entra a [Descargar Chrome](https://www.google.com/chrome/).
2. Descarga y ejecuta el instalador.
3. Espera a que termine la instalación.

### Instalar Flutter y Dart

Flutter permite crear y ejecutar la aplicación. Dart es el lenguaje que utilizamos para escribir el código y viene incluido en el SDK de Flutter.

Entra a [Instalación de Flutter](https://docs.flutter.dev/install/manual), selecciona Windows y descarga el SDK del canal estable.

Descomprime el archivo en una carpeta fija, por ejemplo:

```text
C:\src\flutter
```

Para utilizar Flutter desde la terminal, agrega su carpeta bin al PATH:

1. Busca variables de entorno en el buscador de Windows.
2. Abre Editar las variables de entorno del sistema.
3. Presiona Variables de entorno.
4. En las variables de tu usuario, selecciona Path y presiona Editar.
5. Presiona Nuevo y agrega:

```text
C:\src\flutter\bin
```

Guarda los cambios con Aceptar. Cierra y vuelve a abrir PowerShell y el editor.

Si guardaste Flutter en otra ubicación, utiliza la ruta de su carpeta bin.

Comprueba la instalación con estos comandos:

```powershell
flutter --version
dart --version
flutter doctor
```

Los primeros dos muestran las versiones instaladas. El último revisa las herramientas disponibles. Para probar la aplicación en Chrome, comprueba que Flutter y Chrome estén detectados.

### Instalar Visual Studio Code

Visual Studio Code sirve para abrir y editar el proyecto.

1. Descárgalo desde [Visual Studio Code](https://code.visualstudio.com/download).
2. Instálalo y abre el programa.
3. Entra a **Extensiones**.
4. Busca e instala **Flutter**, publicada por Dart Code.

La extensión de Flutter también instala la extensión de Dart.

### Instalar XAMPP

XAMPP proporciona la base de datos y Apache, que utilizamos para mostrar las imágenes.

1. Entra a [Apache Friends](https://www.apachefriends.org/).
2. Descarga XAMPP para Windows.
3. Ejecuta el instalador e incluye **Apache**, **MySQL** y **phpMyAdmin**.
4. Utiliza esta ubicación para que coincida con los ejemplos:

```text
C:\xampp
```

XAMPP incluye MariaDB, aunque su panel muestra el botón con el nombre MySQL.

## 1. Descargar el proyecto

Abre PowerShell en la carpeta donde quieras guardar el proyecto:

```powershell
git clone https://github.com/mesiasrollins-commits/THANK-U-MUSIC-APLICACION-MOVIL.git
cd THANK-U-MUSIC-APLICACION-MOVIL
```

Encuentra estas carpetas:

- `backend_thankumusic`: contiene `main.py` y `database.py`.
- `thankumusic_app`: contiene `pubspec.yaml` y la carpeta `lib`.

Si están dentro de otra carpeta o tienen otro nombre, ajusta las rutas de los siguientes comandos.

## 2. Preparar la base de datos

1. Abre el panel de XAMPP.
2. Presiona **Start** en **MySQL** y **Apache**.
3. Entra a [phpMyAdmin](http://localhost/phpmyadmin/).
4. Selecciona **Importar**.
5. Elige el script `bd_thankumusic.sql` del proyecto.
6. Presiona **Importar** para ejecutarlo.

Comprueba que exista la base `bd_thankumusic` con estas tablas:

- `usuarios`
- `publicaciones`
- `comentarios`

Si el script solo contiene la estructura, las tablas estarán vacías. Más adelante podrás registrar una cuenta y crear publicaciones.

## 3. Instalar las dependencias

En PowerShell, desde la carpeta que contiene `backend_thankumusic` y `thankumusic_app`, pega esta línea completa:

```powershell
cmd /c 'py -m venv backend_thankumusic\.venv && backend_thankumusic\.venv\Scripts\python.exe -m pip install fastapi "uvicorn[standard]" sqlalchemy pymysql python-dotenv "pwdlib[bcrypt]" pillow python-multipart email-validator && cd thankumusic_app && flutter pub get'
```

Este comando crea el entorno de Python, instala los paquetes del backend y descarga las dependencias de Flutter.

Los paquetes del backend permiten ejecutar la API, conectarse a la base de datos, validar correos, verificar contraseñas y recibir imágenes.

`flutter pub get` instala lo indicado en `pubspec.yaml`, como `http` e `image_picker`. Ya está incluido en el comando anterior.

Espera a que termine:

- **`Requirement already satisfied`** significa que un paquete de Python ya estaba instalado.
- **`Got dependencies!`** indica que Flutter terminó de obtener sus dependencias.

Para revisar si hay conflictos entre los paquetes de Python, ejecuta desde la carpeta principal:

```powershell
.\backend_thankumusic\.venv\Scripts\python.exe -m pip check
```

El resultado esperado es:

```text
No broken requirements found.
```

## 4. Configurar el backend

Dentro de `backend_thankumusic`, crea un archivo llamado `.env`. Asegúrate de que no termine en `.txt`.

Pega lo siguiente:

```dotenv
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=bd_thankumusic
DB_USER=root
DB_PASSWORD=

PORTADAS_DIRECTORIO=C:/xampp/htdocs/thankumusicv1/uploads
PORTADAS_BASE_URL=http://localhost/thankumusicv1/uploads
```

Revisa los valores según tu instalación:

- `DB_HOST`: dirección de la computadora donde está MySQL.
- `DB_PORT`: puerto de MySQL.
- `DB_NAME`: nombre de la base importada.
- `DB_USER`: usuario de MySQL.
- `DB_PASSWORD`: contraseña del usuario. Déjala vacía únicamente si no tiene contraseña.
- `PORTADAS_DIRECTORIO`: carpeta donde se guardan las imágenes.
- `PORTADAS_BASE_URL`: dirección web que permite abrir esas imágenes.

Crea esta carpeta si todavía no existe:

```text
C:\xampp\htdocs\thankumusicv1\uploads
```

Si utilizas otro nombre de carpeta, cambia las dos rutas de imágenes en `.env`.

Para mostrar fotografías de publicaciones anteriores, copia sus archivos a `uploads`. **Importar la base de datos no copia las imágenes.**

## 5. Ejecutar FastAPI

Desde la carpeta principal del proyecto, entra al backend:

```powershell
cd backend_thankumusic
```

Ejecuta:

```powershell
.\.venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Abre esta dirección:

http://127.0.0.1:8000/docs

Si aparece la documentación de FastAPI, el servidor está respondiendo.

**Mantén esta terminal abierta mientras utilizas la aplicación.**

## 6. Ejecutar Flutter en Chrome

Abre otra terminal en la carpeta principal del repositorio y entra a la aplicación:

```powershell
cd thankumusic_app
```

Ejecuta:

```powershell
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

La aplicación utiliza `API_BASE_URL` para conocer la dirección del backend. Los servicios del proyecto deben leer este valor mediante su configuración `api_config.dart`.

Espera a que Chrome abra la aplicación.

Durante las pruebas deben seguir funcionando:

- **MySQL**, para guardar y consultar información.
- **Apache**, para mostrar las imágenes.
- **FastAPI**, para recibir las peticiones de Flutter.

## 7. Registrar una cuenta y comprobar el funcionamiento

1. Abre la opción de registro.
2. Completa los datos solicitados.
3. Registra la cuenta.
4. Inicia sesión con el correo y la contraseña registrados.
5. Revisa las publicaciones disponibles.
6. Abre una publicación y envía un comentario.
7. Entra al perfil y prueba actualizar tus datos.
8. Cierra sesión.

Si todavía no existen publicaciones, prepara una cuenta de administrador para agregarlas.

### Preparar la primera cuenta de administrador

Primero registra una cuenta desde la aplicación.

Después abre phpMyAdmin, selecciona `bd_thankumusic`, entra a **SQL** y ejecuta:

```sql
UPDATE usuarios
SET rol = 'administrador'
WHERE correo = 'correo_de_tu_cuenta@ejemplo.com';
```

Cambia el correo del ejemplo por el de la cuenta que registraste.

Cierra sesión y vuelve a entrar. Desde las opciones de administrador podrás crear una publicación con su título, contenido, etiqueta y portada.

Después comprueba que aparezca en el inicio y que permita consultar y enviar comentarios.

## 8. Ejecutar en Android por USB de forma opcional

La aplicación también puede probarse en un celular Android.

### Instalar las herramientas de Android

1. Descarga e instala [Android Studio](https://developer.android.com/studio).
2. Abre **SDK Manager**.
3. Instala la plataforma Android que requiera el proyecto y las herramientas **SDK Build-Tools**, **SDK Command-line Tools** y **SDK Platform-Tools**.
4. Si la compilación solicita el NDK `28.2.13676358`, instala esa versión desde **SDK Tools → Show Package Details → NDK (Side by side)**.
5. En PowerShell ejecuta:

```powershell
flutter doctor --android-licenses
flutter doctor
```

Acepta las licencias cuando se solicite.

### Conectar el celular

1. Conecta la computadora y el celular a la misma red Wi-Fi.
2. Activa las **Opciones de desarrollador** y la **Depuración USB**.
3. Conecta el celular con un cable de datos.
4. Acepta la autorización de depuración en el teléfono.

Desde la carpeta de Flutter ejecuta:

```powershell
flutter devices
```

Copia el ID del celular que aparezca en la lista.

### Configurar la conexión

En otra terminal ejecuta:

```powershell
ipconfig
```

Busca la IPv4 del adaptador Wi-Fi de la computadora.

Por ejemplo:

```text
192.168.1.25
```

Desde el navegador del celular comprueba que abra:

```text
http://192.168.1.25:8000/docs
```

Usa la IP real de tu computadora.

En el `.env` del backend cambia también la dirección de las imágenes:

```dotenv
PORTADAS_BASE_URL=http://192.168.1.25/thankumusicv1/uploads
```

Conserva `PORTADAS_DIRECTORIO` con la ruta física de Windows y reinicia FastAPI para cargar el cambio.

Después ejecuta desde `thankumusic_app`:

```powershell
flutter run -d ID_DEL_CELULAR --dart-define=API_BASE_URL=http://192.168.1.25:8000
```

Sustituye el ID y la IP por los de tus equipos.

En Android, la dirección de la API y de las imágenes debe apuntar a la computadora. `localhost` en el teléfono apunta al propio teléfono.

## Referencia de la configuración inicial del proyecto

Este apartado explica cómo preparar una estructura nueva durante el desarrollo. Si descargaste el proyecto terminado con `git clone`, continúa utilizando sus archivos existentes.

Para generar una estructura inicial:

```powershell
mkdir APP_THANKUMUSIC
cd APP_THANKUMUSIC
flutter create thankumusic_app
mkdir backend_thankumusic
```

Dentro de `thankumusic_app` se agregan los paquetes utilizados por la aplicación:

```powershell
cd thankumusic_app
flutter pub add http image_picker
cd ..
```

En `backend_thankumusic` se crean `main.py`, `database.py` y `.env`. Después se prepara el entorno de Python y se instalan los paquetes descritos en el paso 3.

Estos comandos crean la estructura inicial. Las pantallas, los servicios, las rutas y las consultas del blog se desarrollan dentro de esos archivos y carpetas.

### Guardar el desarrollo en GitHub

Para publicar por primera vez un proyecto local en un repositorio nuevo y vacío:

1. Crea el repositorio en GitHub.
2. En la carpeta principal del proyecto, crea un archivo `.gitignore`.
3. Agrega estas líneas:

```gitignore
.venv/
venv/
__pycache__/
*.pyc
.env
.dart_tool/
build/
```

Esto evita subir el entorno virtual, la configuración privada y los archivos generados.

Configura tu nombre y correo en Git:

```powershell
git config --global user.name "Tu nombre"
git config --global user.email "tu_correo@ejemplo.com"
```

Después, desde la carpeta principal:

```powershell
git init
git add .
git commit -m "Primera version de Thank U Music"
git branch -M main
```

Vincula el repositorio y sube los archivos, reemplazando la URL por la de tu repositorio nuevo:

```powershell
git remote add origin https://github.com/TU_USUARIO/TU_REPOSITORIO.git
git push -u origin main
```

Completa el inicio de sesión de GitHub si se solicita.

Este procedimiento corresponde a la publicación inicial. Al utilizar `git clone`, la conexión con el repositorio ya viene configurada.

## Problemas frecuentes

| Problema | Qué revisar |
|---|---|
| No se reconoce `flutter` | Revisa el PATH y abre nuevamente la terminal. |
| No encuentra `pubspec.yaml` | Ejecuta Flutter dentro de `thankumusic_app`. |
| La aplicación no conecta | Comprueba MySQL, FastAPI y la dirección de la API. |
| Las imágenes no cargan | Revisa Apache, los archivos de `uploads` y `PORTADAS_BASE_URL`. |
| El celular no aparece | Revisa la depuración USB, el cable y la autorización del teléfono. |
| Cambiaste la IP y sigue usando la anterior | Detén Flutter y ejecútalo otra vez con el comando completo. |

## Volver a ejecutar el proyecto

Después de completar la instalación:

1. Inicia MySQL y Apache en XAMPP.
2. Ejecuta FastAPI desde la carpeta del backend.
3. Abre otra terminal en `thankumusic_app`.
4. Ejecuta el comando de Chrome o Android.

No necesitas volver a crear el entorno virtual cada vez que abras el proyecto. Con los servicios activos, ya puedes iniciar sesión y utilizar la aplicación.
