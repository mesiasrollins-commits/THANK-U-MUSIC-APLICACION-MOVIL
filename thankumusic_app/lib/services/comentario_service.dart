// Importa la librería nativa de Dart para decodificar caracteres UTF-8 y convertir texto en formato JSON a estructuras de datos.
import 'dart:convert';

// Importa el paquete 'http' bajo el alias 'http' para realizar peticiones web hacia el servidor FastAPI.
import 'package:http/http.dart' as http;

// Importa el servicio de autenticación para reutilizar la excepción personalizada 'SesionInvalida'.
import 'auth_service.dart';

import 'api_config.dart';

// Crea un alias de tipo ('typedef') para abreviar la escritura de 'List>' como 'ListaComentarios'.
typedef ListaComentarios = List<Map<String, dynamic>>;

// Clase encargada de comunicarse con el servidor para gestionar las operaciones relacionadas con los comentarios.
class ComentarioService {
  // Solicita los comentarios de una publicación específica enviando su identificador y el token de sesión activo.
  Future<ListaComentarios> obtenerComentarios({
    required int idPublicacion,
    required String tokenSesion,
  }) async {
    // Envía una petición HTTP GET al endpoint de comentarios de esa publicación incluyendo el token en la cabecera 'Authorization'.
    // Si el servidor tarda más de 10 segundos en responder, cancela la espera lanzando un error de tiempo agotado ('TimeoutException').
    final respuesta = await http.get(
      Uri.parse(
        '$apiBaseUrl/publicaciones/$idPublicacion/comentarios',
      ),
      headers: {'Authorization': 'Bearer $tokenSesion'},
    ).timeout(const Duration(seconds: 10));

    // Si el servidor responde con código 401 (No autorizado), lanza 'SesionInvalida' para que la pantalla redirija al usuario al login.
    if (respuesta.statusCode == 401) {
      throw SesionInvalida();
    }

    // Si el código de respuesta es distinto de 200 (Éxito), lanza un error indicando que no se pudieron cargar los comentarios.
    if (respuesta.statusCode != 200) {
      throw StateError('No se pudieron cargar los comentarios.');
    }

    // Decodifica los bytes crudos de la respuesta en formato UTF-8 (evitando errores con tildes o la letra 'ñ') y transforma el texto JSON en objetos de Dart.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));

    // Verifica que la estructura recibida sea realmente una lista; si el servidor devolvió otro tipo de dato, detiene el proceso con un error.
    if (datos is! List) {
      throw StateError('El servidor no devolvió comentarios.');
    }

    // Convierte la lista genérica al tipo estricto 'List>' esperado por el resto de la aplicación.
    return List<Map<String, dynamic>>.from(datos);
  }

  // Envía un comentario nuevo al servidor para guardarlo en la publicación indicada.
  Future<void> enviarComentario({
    required int idPublicacion,
    required String tokenSesion,
    required String comentario,
  }) async {
    // Hace una petición POST enviando el token de sesión, avisando que el contenido va en formato JSON y con un límite de espera de 10 segundos.
    final respuesta = await http.post(
      Uri.parse(
        '$apiBaseUrl/publicaciones/$idPublicacion/comentarios',
      ),
      headers: {
        'Authorization': 'Bearer $tokenSesion',
        'Content-Type': 'application/json',
      },
      // Convierte el texto del comentario a formato JSON antes de enviarlo.
      body: jsonEncode({'comentario': comentario}),
    ).timeout(const Duration(seconds: 10));

    // Si el servidor responde con 401, avisa que la sesión ya caducó para regresar al inicio de sesión.
    if (respuesta.statusCode == 401) {
      throw SesionInvalida();
    }

    // Si el servidor responde con 201, significa que el comentario se guardó bien y termina la función.
    if (respuesta.statusCode == 201) return;

    // Si hubo algún otro error, lee el mensaje de detalle que envió el servidor (por ejemplo, si el comentario iba vacío o el usuario no tiene permiso).
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (datos is Map<String, dynamic> && datos['detail'] is String) {
      throw StateError(datos['detail'] as String);
    }

    // Si el servidor no envió un mensaje específico, lanza un aviso general de error.
    throw StateError('No se pudo publicar el comentario.');
  }
// Envía una petición al servidor para borrar un comentario específico dentro de una publicación.
  Future<void> eliminarComentario({
    required int idPublicacion,
    required int idComentario,
    required String tokenSesion,
  }) async {
    // Realiza la solicitud DELETE indicando el ID de la publicación y del comentario, enviando el token de sesión en la cabecera y cortando si tarda más de 10 segundos.
    final respuesta = await http.delete(
      Uri.parse(
        '$apiBaseUrl/publicaciones/$idPublicacion/comentarios/$idComentario',
      ),
      headers: {'Authorization': 'Bearer $tokenSesion'},
    ).timeout(const Duration(seconds: 10));

    // Si el servidor indica que la sesión ya caducó (código 401), lanza la excepción para volver al inicio de sesión.
    if (respuesta.statusCode == 401) {
      throw SesionInvalida();
    }

    // Si el servidor confirma el borrado con éxito (código 200), termina la función sin hacer nada más.
    if (respuesta.statusCode == 200) return;

    // Si hubo otro error, lee la respuesta del servidor y extrae el mensaje exacto que envió FastAPI en 'detail'.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (datos is Map<String, dynamic> && datos['detail'] is String) {
      throw StateError(datos['detail'] as String);
    }

    // Si el servidor falló sin enviar un mensaje específico, lanza un error general.
    throw StateError('No se pudo eliminar el comentario.');
  }
}