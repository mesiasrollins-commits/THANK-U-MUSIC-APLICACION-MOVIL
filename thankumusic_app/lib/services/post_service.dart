// Herramientas para decodificar texto UTF-8 y convertir datos en formato JSON.
import 'dart:convert';

// Cliente HTTP para hacer peticiones al servidor.
import 'package:http/http.dart' as http;

// Reutiliza la excepción 'SesionInvalida' definida en el servicio de autenticación.
import 'auth_service.dart';

/// Servicio encargado de consultar las publicaciones desde la API.
class PostService {
  /// Descarga la lista de publicaciones enviando el token del usuario.
  Future<List<Map<String, dynamic>>> obtenerPublicaciones(
    String tokenSesion,
  ) async {
    // Hace la petición GET con el token de autorización y un límite de espera de 10 segundos.
    final respuesta = await http
        .get(
          Uri.parse('http://127.0.0.1:8000/publicaciones'),
          headers: {'Authorization': 'Bearer $tokenSesion'},
        )
        .timeout(const Duration(seconds: 10));

    // Si el servidor rechaza el token (error 401), avisa que la sesión expiró.
    if (respuesta.statusCode == 401) {
      throw SesionInvalida();
    }

    // Si ocurre cualquier otro error en el servidor, detiene la carga con un mensaje claro.
    if (respuesta.statusCode != 200) {
      throw StateError('No se pudieron cargar las publicaciones.');
    }

    // Convierte los bytes de la respuesta a texto legible (respetando acentos y eñes) y lo pasa de JSON a objetos de Dart.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));

    // Comprueba que el servidor realmente haya enviado una lista antes de continuar.
    if (datos is! List) {
      throw StateError('El servidor no devolvió una lista de publicaciones.');
    }

    // Devuelve los datos asegurándose de que cada elemento sea un mapa
    return List<Map<String, dynamic>>.from(datos);
  }
}
