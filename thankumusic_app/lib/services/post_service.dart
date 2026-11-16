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

  // Envía todos los datos de la nueva publicación (textos y archivo de imagen) al servidor FastAPI para guardarla.
  Future<void> crearPublicacion({
    required String tokenSesion,
    required String titulo,
    required String contenido,
    required String etiqueta,
    required List<int> portada,
  }) async {
    // Crea una petición especial de tipo 'MultipartRequest', necesaria cuando se envían textos y archivos juntos en un mismo formulario.
    final solicitud = http.MultipartRequest(
      'POST',
      Uri.parse('http://127.0.0.1:8000/publicaciones'),
    );

    // Agrega el token de sesión en la cabecera para que el servidor compruebe que el usuario tiene permiso de administrador.
    solicitud.headers['Authorization'] = 'Bearer $tokenSesion';

    // Añade los campos de texto del formulario con los nombres exactos que espera recibir FastAPI.
    solicitud.fields.addAll({
      'titulo': titulo,
      'contenido': contenido,
      'tags': etiqueta,
    });

    // Adjunta los bytes de la imagen bajo el campo 'imagen'; FastAPI detectará el formato real y le pondrá un nombre único.
    solicitud.files.add(
      http.MultipartFile.fromBytes('imagen', portada, filename: 'portada'),
    );

    // Envía la petición, espera a que termine de subirse el archivo y convierte la respuesta en un formato legible, con un límite de espera de 30 segundos.
    final respuesta = await solicitud
        .send()
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 30));

    // Si el servidor responde con 401, avisa que la sesión caducó para regresar al usuario al inicio de sesión.
    if (respuesta.statusCode == 401) {
      throw SesionInvalida();
    }

    // Si el servidor responde con 201, la publicación se creó con éxito y termina la función.
    if (respuesta.statusCode == 201) return;

    // Si ocurrió otro error (por ejemplo, título muy largo o imagen inválida), extrae el mensaje de detalle que envió el servidor.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (datos is Map<String, dynamic> && datos['detail'] is String) {
      throw StateError(datos['detail'] as String);
    }

    // Si no venía un mensaje específico del servidor, lanza un aviso general de fallo.
    throw StateError('No se pudo crear la publicación.');
  }
}
