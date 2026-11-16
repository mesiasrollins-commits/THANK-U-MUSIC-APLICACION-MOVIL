// Importa la librería nativa de Dart para decodificar caracteres UTF-8 y convertir texto en formato JSON a estructuras de datos.
import 'dart:convert';

// Importa el paquete 'http' bajo el alias 'http' para realizar peticiones web hacia el servidor FastAPI.
import 'package:http/http.dart' as http;

// Importa el servicio de autenticación para reutilizar la excepción personalizada 'SesionInvalida'.
import 'auth_service.dart';

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
        'http://127.0.0.1:8000/publicaciones/$idPublicacion/comentarios',
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
}