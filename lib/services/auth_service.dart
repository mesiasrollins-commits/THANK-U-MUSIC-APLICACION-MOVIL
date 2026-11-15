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
}
