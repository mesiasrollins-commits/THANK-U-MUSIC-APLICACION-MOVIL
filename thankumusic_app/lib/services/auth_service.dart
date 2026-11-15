import 'dart:convert';

import 'package:http/http.dart' as http;

// Clase encargada de concentrar la lógica y validaciones de autenticación (separada de la interfaz gráfica).
class AuthService {
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
    final respuesta = await http.post(
      // Convierte la dirección web en texto a un objeto Uri que Flutter entiende.
      Uri.parse('http://127.0.0.1:8000/login'),
      // Avisa al servidor FastAPI que los datos viajan en formato JSON.
      headers: {'Content-Type': 'application/json'},
      // Convierte el diccionario de Dart a texto JSON; usa la llave 'mail' porque así la espera LoginRequest en FastAPI.
      body: jsonEncode({
        'mail': correo,
        'password': password,
      }),
    // Si el servidor tarda más de 10 segundos en responder, cancela la espera y lanza un error de tiempo agotado.
    ).timeout(const Duration(seconds: 10));

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
}

