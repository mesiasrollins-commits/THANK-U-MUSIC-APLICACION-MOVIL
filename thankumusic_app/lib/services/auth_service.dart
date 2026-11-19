import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class SesionInvalida extends StateError {
  SesionInvalida() : super('La sesión es inválida o venció.');
}

// Clase encargada de concentrar la lógica y validaciones de autenticación (separada de la interfaz gráfica).
class AuthService {
  // Crea un cronómetro interno para medir cuánto tiempo ha pasado desde la última vez que se le avisó al servidor que el usuario sigue activo.
  // Sirve para no saturar FastAPI con peticiones cada milisegundo cuando el usuario hace una interaccion en la app sin parar.
  final Stopwatch _tiempoDesdeUltimaConsulta = Stopwatch();

  // Método que revisa los datos del formulario de registro.
  // Devuelve un texto (String) con el mensaje de error si algo falla, o 'null' (vacío) si todo está correcto.
  String? validarRegistro({
    required String nombre,
    required String correo,
    required String direccion,
    required String password,
    required String confirmarpassword,
  }) {
    // Primera regla: verifica que ningún campo venga completamente vacío.
    if (nombre.isEmpty ||
        correo.isEmpty ||
        direccion.isEmpty ||
        password.isEmpty ||
        confirmarpassword.isEmpty) {
      return 'Completa todos los campos.';
    }
    // Define la plantilla (expresión regular) que exige el formato básico: usuario@dominio.extension
    // ^ y $ obligan a revisar todo el texto de principio a fin sin dejar texto sobrante.
    // [^@\s]+ exige al menos un carácter que no sea '@' ni espacio en cada bloque (usuario, dominio y extensión).
    // @ y \. exigen un arroba literal y un punto real separando cada parte.
    final formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    // Segunda regla: comprueba que el correo escrito cumpla con ese formato básico.
    if (!formatoCorreo.hasMatch(correo)) {
      return 'Escribe un correo válido.';
    }

    // Tercera regla: exige que la contraseña tenga como mínimo 8 caracteres de longitud.
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }

    // Cuarta regla: verifica que ambas contraseñas escritas sean exactamente iguales.
    if (password != confirmarpassword) {
      return 'Las contraseñas no coinciden.';
    }

    // Si pasó todas las pruebas sin errores, devuelve null para indicar que el registro es válido.
    return null;
  }

  // Método asíncrono (Future) que envía el correo y la contraseña a la API de FastAPI.
  // Devuelve un mapa (clave-valor) con los datos del usuario si el inicio de sesión tiene éxito.
  Future<Map<String, dynamic>> autenticar({
    required String correo,
    required String password,
  }) async {
    // Hace una petición HTTP de tipo POST a la ruta '/login' del servidor local y espera ('await') la respuesta.
    final respuesta = await http
        .post(
          // Convierte la dirección web en texto a un objeto Uri que Flutter entiende.
          Uri.parse('$apiBaseUrl/login'),
          // Avisa al servidor FastAPI que los datos viajan en formato JSON.
          headers: {'Content-Type': 'application/json'},
          // Convierte el diccionario de Dart a texto JSON; usa la llave 'mail' porque así la espera LoginRequest en FastAPI.
          body: jsonEncode({'mail': correo, 'password': password}),
          // Si el servidor tarda más de 10 segundos en responder, cancela la espera y lanza un error de tiempo agotado.
        )
        .timeout(const Duration(seconds: 10));

    // Decodifica los bytes crudos de la respuesta usando UTF-8 (para conservar acentos y la letra ñ) y convierte el JSON a datos de Dart.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));

    // Si el servidor respondió con código 200 (éxito) y el contenido es un objeto JSON válido, devuelve los datos del usuario.
    if (respuesta.statusCode == 200 && datos is Map<String, dynamic>) {
      return datos;
    }

    // Si hubo un error controlado (como 401 o 403), lee el texto que FastAPI envió dentro de la llave 'detail' y lo lanza como excepción para mostrarlo en pantalla.
    if (datos is Map<String, dynamic> && datos['detail'] is String) {
      throw StateError(datos['detail'] as String);
    }

    // Si ocurrió cualquier otro fallo inesperado sin mensaje claro, lanza este aviso genérico.
    throw StateError('No se pudo iniciar sesión.');
  }

  // Método asíncrono que verifica con el servidor FastAPI si el token de sesión guardado sigue vigente.
  // No devuelve datos ('Future<void>'); si la sesión sigue activa termina en silencio, y si no, lanza un error.
  Future<void> comprobarSesion(String tokenSesion) async {
    // Define la ruta de destino según si existe un token de administrador: si es nulo envía a '/registro', de lo contrario a '/administradores'.
    // Hace una petición HTTP GET a la ruta '/sesion' del backend y espera ('await') la respuesta.
    final respuesta = await http
        .get(
          // Convierte la dirección web en texto a un objeto Uri que Flutter entiende.
          Uri.parse('$apiBaseUrl/sesion'),
          // Envía el token en el encabezado 'Authorization' con el formato estándar 'Bearer <token>' que espera HTTPBearer en FastAPI.
          headers: {'Authorization': 'Bearer $tokenSesion'},
          // Si el servidor tarda más de 10 segundos en responder, cancela la petición para que la app no se quede trabada.
        )
        .timeout(const Duration(seconds: 10));

    // Si FastAPI responde con código 401 (No autorizado), significa que el token no existe o ya pasó su hora de vigencia; lanza un error específico para cerrar la sesión en la app.
    if (respuesta.statusCode == 401) {
      throw SesionInvalida();
    }

    // Si el servidor responde con cualquier otro código distinto a 200 (éxito), lanza un error general de validación.
    if (respuesta.statusCode != 200) {
      throw StateError('No se pudo comprobar la sesión.');
    }
  }

  // Registra que el usuario sigue activo y renueva su sesión en el servidor, limitando los envíos a máximo una petición por minuto.
    Future<void> registrarActividad(String tokenSesion) async {
    // Si el cronómetro ya está corriendo y aún no pasa 1 minuto desde el último aviso al servidor, sale de la función sin hacer nada para evitar saturar la red.
    if (_tiempoDesdeUltimaConsulta.isRunning &&
        _tiempoDesdeUltimaConsulta.elapsed < const Duration(minutes: 1)) {
      return;
    }

    // Reinicia el cronómetro a cero ('reset') y lo vuelve a arrancar ('start') usando el operador cascada ('..') para empezar a contar el nuevo minuto.
    _tiempoDesdeUltimaConsulta
      ..reset()
      ..start();

    // Envía la petición HTTP a FastAPI con el token actual para verificar que la sesión siga válida y extender su tiempo de expiración.
    await comprobarSesion(tokenSesion);
  }

  // Método asíncrono que envía el token activo al servidor FastAPI para invalidarlo y cerrar la sesión.
  // No devuelve datos ('Future<void>'); si el cierre funciona termina en silencio, y si falla lanza un error.
  Future<void> cerrarSesion(String tokenSesion) async {
    // Hace una petición HTTP de tipo POST a la ruta '/logout' del servidor local y espera ('await') la respuesta.
    final respuesta = await http
        .post(
          // Convierte la dirección web en texto a un objeto Uri que Flutter entiende.
          Uri.parse('$apiBaseUrl/logout'),
          // Envía el token en el encabezado 'Authorization' con el formato estándar 'Bearer <token>' que espera HTTPBearer en FastAPI.
          headers: {'Authorization': 'Bearer $tokenSesion'},
          // Si el servidor tarda más de 10 segundos en responder, cancela la petición para evitar que la app se quede cargando indefinidamente.
        )
        .timeout(const Duration(seconds: 10));

    // Si FastAPI responde con cualquier código diferente a 200 (éxito), lanza un error para avisar en pantalla que no se pudo cerrar la sesión.
    if (respuesta.statusCode != 200) {
      throw StateError('No se pudo cerrar la sesión.');
    }
  }

  // Envía los datos del formulario a FastAPI para crear la cuenta.
  Future<void> registrar({
    required String nombre,
    required String correo,
    required String direccion,
    required String password,
    String? tokenAdministrador,

  }) async {
    // Elegimos la ruta según si el registro viene del login o del menú de administrador.
    final ruta = tokenAdministrador == null ? '/registro' : '/administradores';
    // Envía una petición HTTP POST a la ruta '/registro' del servidor FastAPI y espera ('await') la respuesta.
    final respuesta = await http
        .post(
          // Convierte la dirección web en texto a un objeto Uri que Flutter entiende.
          Uri.parse('$apiBaseUrl$ruta'),
          // Le avisa al servidor que los datos enviados en el cuerpo van en formato JSON.
          headers: {
            'Content-Type': 'application/json',
            if (tokenAdministrador != null)
              'Authorization': 'Bearer $tokenAdministrador',
          },
          // Convierte el mapa de datos de Dart a una cadena de texto JSON con las llaves exactas que espera RegistroRequest en FastAPI.
          body: jsonEncode({
            'nombre': nombre,
            'mail': correo,
            'direccion': direccion,
            'password': password,
          }),
        )
        // Si el servidor tarda más de 10 segundos en responder, cancela la petición para evitar que la pantalla se quede congelada.
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode == 401) throw SesionInvalida();

    // Si FastAPI responde con código 201 (Creado), significa que el usuario se guardó correctamente en la base de datos y termina el método con éxito.
    if (respuesta.statusCode == 201) {
      return;
    }

    // Decodifica los bytes crudos de la respuesta en formato UTF-8 (para conservar acentos y la ñ) y los convierte de texto JSON a un objeto que Dart puede leer.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    // Verifica que la respuesta sea un mapa (diccionario) y que contenga la llave 'detail' con un mensaje de texto enviado por FastAPI.
    if (datos is Map<String, dynamic> && datos['detail'] is String) {
      // Lanza una excepción con el texto exacto del error (por ejemplo, "Ese correo ya está registrado.") para que la interfaz lo atrape y lo muestre en pantalla.
      throw StateError(datos['detail'] as String);
    }

    throw StateError('No se pudo crear la cuenta.');
  }
}
