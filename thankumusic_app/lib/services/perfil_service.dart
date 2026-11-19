// Importa las utilidades de Dart para convertir texto JSON y codificar caracteres en UTF-8.
import 'dart:convert';

// Importa el paquete 'http' para hacer peticiones web al servidor.
import 'package:http/http.dart' as http;

// Importa la excepción 'SesionInvalida' definida en el servicio de autenticación.
import 'auth_service.dart';

import 'api_config.dart';


// Clase encargada de comunicarse con el servidor para obtener la información de la cuenta del usuario.
class PerfilService {
  // Consulta los datos de la cuenta que inició sesión.
  Future<Map<String, dynamic>> obtenerPerfil(String tokenSesion) async {
    // Envía una petición GET a la ruta '/perfil' incluyendo el token de autorización y corta la espera si tarda más de 10 segundos.
    final respuesta = await http
        .get(
          Uri.parse('$apiBaseUrl/perfil'),
          headers: {'Authorization': 'Bearer $tokenSesion'},
        )
        .timeout(const Duration(seconds: 10));

    // Si el servidor responde con código 401, avisa que la sesión ya caducó.
    if (respuesta.statusCode == 401) {
      throw SesionInvalida();
    }

    // Si el código de respuesta es distinto de 200 (éxito), lanza un error indicando que no se pudo cargar el perfil.
    if (respuesta.statusCode != 200) {
      throw StateError('No se pudo cargar tu perfil.');
    }

    // Decodifica los bytes recibidos usando UTF-8 (para respetar acentos y eñes) y los transforma de JSON a objetos de Dart.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));

    // Verifica que el resultado sea un diccionario clave-valor; si no lo es, detiene el proceso por formato incorrecto.
    if (datos is! Map<String, dynamic>) {
      throw StateError('La respuesta del perfil no tiene el formato esperado.');
    }

    // Devuelve el mapa con los datos del perfil del usuario.
    return datos;
  }

  Future<Map<String, dynamic>> actualizarPerfil({
    required String tokenSesion,
    required String nombre,
    required String correo,
    required String direccion,
  }) async {
    final respuesta = await http
        .patch(
          Uri.parse('$apiBaseUrl/perfil'),
          headers: {
            'Authorization': 'Bearer $tokenSesion',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'nombre': nombre,
            'correo': correo,
            'direccion': direccion,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode == 401) throw SesionInvalida();

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (datos is Map<String, dynamic>) {
      if (respuesta.statusCode == 200) return datos;
      if (datos['detail'] is String) {
        throw StateError(datos['detail'] as String);
      }
    }

    throw StateError('No se pudieron guardar los cambios.');
  }

    Future<String> actualizarFoto({
    required String tokenSesion,
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    final solicitud = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBaseUrl/perfil/foto'),
    );

// Agrega el token de autorización en la cabecera de la petición para identificar al usuario conectado.
    solicitud.headers['Authorization'] = 'Bearer $tokenSesion';
    // Adjunta la imagen como un archivo binario dentro del campo llamado 'foto', conservando su nombre original.
    solicitud.files.add(
      http.MultipartFile.fromBytes('foto', bytes, filename: nombreArchivo),
    );

    // Envía la petición con el archivo al servidor, convierte el flujo de respuesta a un objeto Response normal y corta la espera si tarda más de 30 segundos.
    final respuesta = await solicitud
        .send()
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 30));

    // Si el servidor responde con código 401, indica que la sesión caducó y lanza la excepción para volver al login.
    if (respuesta.statusCode == 401) throw SesionInvalida();

    // Decodifica los bytes recibidos usando UTF-8 (para respetar acentos) y los transforma de JSON a un objeto de Dart.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));

    // Verifica que la respuesta sea un diccionario clave-valor.
    if (datos is Map<String, dynamic>) {
      // Extrae el enlace de la nueva foto de perfil enviada por el servidor.
      final fotoUrl = datos['foto_url'];
      // Si la subida fue exitosa (código 200) y el enlace recibido es un texto válido, devuelve esa URL.
      if (respuesta.statusCode == 200 && fotoUrl is String) {
        return fotoUrl;
      }

      // Si hubo un error controlado en el servidor, lanza una excepción con el mensaje exacto que envió FastAPI en 'detail'.
      if (datos['detail'] is String) {
        throw StateError(datos['detail'] as String);
      }
    }

    throw StateError('No se pudo confirmar el guardado de la foto.');
  }
}
