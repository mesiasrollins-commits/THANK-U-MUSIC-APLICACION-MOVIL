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

Dentro de `backend_thankumusic`, crea un archivo llamado `.env`.

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

Mantén esta terminal abierta mientras utilizas la aplicación.

## 6. Ejecutar Flutter en Chrome

Abre otra terminal en la carpeta principal del repositorio y entra a la aplicación:

```powershell
cd thankumusic_app
```

Ejecuta:

```powershell
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```
y listo, API y aplicacion funcionan correctamente
## Problemas frecuentes

  - **Problema:** No se reconoce `flutter`.
  
    **Solución:** Revisa que la carpeta `flutter\bin` esté agregada al PATH. Cierra y vuelve a abrir la terminal.
  
  - **Problema:** No se reconoce `py`.
  
    **Solución:** Reinicia Visual Studio Code y vuelve a ejecutar el comando de instalación. En ocasiones, el editor no reconoce correctamente Python.
  
  - **Problema:** No se reconoce `git`.
  
    **Solución:** Comprueba que Git esté instalado y reinicia Visual Studio Code.
  
  - **Problema:** No encuentra `pubspec.yaml`.
  
    **Solución:** Comprueba que estés ejecutando los comandos dentro de la carpeta `thankumusic_app`.
  
  - **Problema:** Aparece un error al instalar las dependencias.
  
    **Solución:** Comprueba tu conexión a internet y vuelve a ejecutar el comando de instalación desde la carpeta principal del proyecto.
  
  - **Problema:** La aplicación no conecta con el backend.
  
    **Solución:** Comprueba que MySQL y FastAPI estén funcionando y que `API_BASE_URL` tenga la dirección correcta.
  
  - **Problema:** No abre la documentación de FastAPI.
  
    **Solución:** Comprueba que el backend esté ejecutándose en el puerto `8000` y abre `http://127.0.0.1:8000/docs`.
  
  - **Problema:** Aparece un error de conexión con MySQL.
  
    **Solución:** Inicia MySQL desde XAMPP y revisa los datos de conexión del archivo `.env`.
  
  - **Problema:** No encuentra la base de datos.
  
    **Solución:** Comprueba que hayas importado `bd_thankumusic.sql` y que `DB_NAME` tenga el nombre correcto.
  
  - **Problema:** Las imágenes no cargan.
  
    **Solución:** Comprueba que Apache esté iniciado, que exista la carpeta `uploads` y que `PORTADAS_BASE_URL` tenga la dirección correcta.
  
  - **Problema:** No encuentra el archivo `.env`.
  
    **Solución:** Comprueba que esté dentro de `backend_thankumusic`, junto a `main.py` y `database.py`.
  
  - **Problema:** El puerto `8000` está ocupado.
  
    **Solución:** Cierra el proceso que esté utilizando ese puerto antes de iniciar FastAPI nuevamente.
  
  - **Problema:** Chrome no aparece como dispositivo disponible.
  
    **Solución:** Comprueba que Google Chrome esté instalado y ejecuta `flutter doctor`.
  
  - **Problema:** Cambiaste la IP y la aplicación sigue utilizando la anterior.
  
    **Solución:** Detén Flutter y vuelve a ejecutar la aplicación con el comando completo y la nueva dirección de `API_BASE_URL`.

## Volver a ejecutar el proyecto

Después de completar la instalación:

1. Inicia MySQL y Apache en XAMPP.
2. Ejecuta FastAPI desde la carpeta del backend.
3. Abre otra terminal en `thankumusic_app`.
4. Ejecuta el comando de Chrome.

No necesitas volver a crear el entorno virtual cada vez que abras el proyecto. Con los servicios activos, ya puedes iniciar sesión y utilizar la aplicación.
