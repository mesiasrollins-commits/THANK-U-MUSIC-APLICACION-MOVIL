import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class UsuarioService {
  // Pide la lista de usuarios usando el token de la sesión actual.
  Future<List<Map<String, dynamic>>> obtenerUsuarios(String tokenSesion) async {
    final respuesta = await http
        .get(
          Uri.parse('http://127.0.0.1:8000/administradores/usuarios'),
          headers: {'Authorization': 'Bearer $tokenSesion'},
        )
        .timeout(const Duration(seconds: 10));

    // Si la sesión venció, la pantalla puede regresar al login.
    if (respuesta.statusCode == 401) {
      throw SesionInvalida();
    }

    // Si la cuenta sigue activa pero perdió el rol de admin, muestra el motivo.
    if (respuesta.statusCode == 403) {
      throw StateError('Solo un administrador puede consultar los usuarios.');
    }

    if (respuesta.statusCode != 200) {
      throw StateError('No se pudieron cargar los usuarios.');
    }

    // Decodifica los datos en UTF-8 para conservar los acentos y la ñ.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    return List<Map<String, dynamic>>.from(datos);
  }

  // Envía el rol o el estado elegido desde el diálogo.
  Future<void> actualizarUsuario(
    String tokenSesion,
    int idUsuario, {
    required String campo,
    required String valor,
  }) async {
    // Envía una petición PATCH indicando el usuario y el campo a modificar ('rol' o 'estado') en la URL, adjuntando el token y el nuevo valor en formato JSON; corta si tarda más de 10 segundos.
    final respuesta = await http
        .patch(
          Uri.parse(
            'http://127.0.0.1:8000/administradores/usuarios/$idUsuario/$campo',
          ),
          headers: {
            'Authorization': 'Bearer $tokenSesion',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({campo: valor}),
        )
        .timeout(const Duration(seconds: 10));

    // Si el servidor responde con código 401, indica que la sesión caducó y lanza la excepción para volver al inicio de sesión.
    if (respuesta.statusCode == 401) {
      throw SesionInvalida();
    }
    // Si el servidor responde con código 403, indica que la cuenta conectada no tiene permisos de administrador.
    if (respuesta.statusCode == 403) {
      throw StateError('Solo un administrador puede editar usuarios.');
    }
    // Si el servidor responde con código 404, significa que el usuario seleccionado fue eliminado o no existe.
    if (respuesta.statusCode == 404) {
      throw StateError('El usuario ya no existe.');
    }
    // Si ocurre cualquier otro error diferente de 200 (éxito), lanza un aviso general indicando que no se guardó el cambio.
    if (respuesta.statusCode != 200) {
      throw StateError('No se pudo guardar el cambio.');
    }
  }
}
