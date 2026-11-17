import 'package:flutter/material.dart';

import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';
import '../widgets/actividad_sesion.dart';

// Convierte RegisterPage en StatefulWidget para poder guardar los controladores de texto y estados (como ocultar contraseñas) más adelante.
class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    this.tokenAdministrador,
    this.registrarActividad,
    this.volverAlLogin,
  });

  final String? tokenAdministrador;
  final Future<void> Function(BuildContext)? registrarActividad;
  final void Function(BuildContext, {String? aviso})? volverAlLogin;

  // Crea y conecta el objeto privado (_RegisterPageState) donde vivirá la memoria y lógica del formulario.
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

// Clase privada que maneja los datos cambiantes y construye la interfaz de registro.
class _RegisterPageState extends State<RegisterPage> {
  // Cada controlador guarda lo que se escribe en su campo.
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final direccionController = TextEditingController();

  // Cada campo de contraseña guarda su propio texto y empieza oculto.
  final passwordController = TextEditingController();
  final confirmarPasswordController = TextEditingController();
  bool ocultarPassword = true;
  bool ocultarConfirmarPassword = true;
  final AuthService authService = AuthService();

  @override
  void dispose() {
    // Liberamos los controladores al salir de Registro.
    nombreController.dispose();
    correoController.dispose();
    direccionController.dispose();
    passwordController.dispose();
    confirmarPasswordController.dispose();
    super.dispose();
  }

  void registrarUsuario() {
    // Quitamos espacios de los datos de contacto. Las contraseñas se leen tal cual.
    final mensaje = authService.validarRegistro(
      nombre: nombreController.text.trim(),
      correo: correoController.text.trim(),
      direccion: direccionController.text.trim(),
      password: passwordController.text,
      confirmarpassword: confirmarPasswordController.text,
    );

    // Mostramos el error o confirmamos que los campos pasaron la validación.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje ?? 'Los datos son válidos.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esRegistroAdmin = widget.tokenAdministrador != null;

    // Centra todo el bloque en medio de la pantalla.
    final formulario = Center(
      // Permite deslizar el contenido verticalmente para que el teclado no tape los campos cuando agregues el formulario.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        // Dibuja la tarjeta blanca redondeada reutilizable.
        child: AuthCard(
          // Acomoda el logo y el título uno debajo del otro ocupando solo el alto necesario (MainAxisSize.min).
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!esRegistroAdmin) ...[
                // Muestra el logotipo del proyecto ajustado a 220 píxeles de ancho sin recortarse.
                Image.asset(
                  'assets/logo.png',
                  width: 220,
                  fit: BoxFit.contain,
                ),
                // Deja una separación de 20 píxeles entre el logo y el título.
                const SizedBox(height: 20),
              ],
              // Título principal centrado y en negritas con tamaño 26.
              const Text(
                'Registro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Deja un espacio vertical de 24 píxeles entre el título "Registro" y el primer campo de texto.
              const SizedBox(height: 24),

              // Campo para escribir el nombre completo usando el widget personalizado CustomTextField.
              CustomTextField(
                // Conecta el controlador que guardará el nombre escrito por el usuario.
                controller: nombreController,
                label: 'Nombre',
                // Muestra el contorno de una persona a la izquierda.
                prefixIcon: Icons.person_outline,
              ),

              // Deja una separación vertical de 16 píxeles entre este campo y el siguiente.
              const SizedBox(height: 16),

              // Campo para el correo electrónico.
              CustomTextField(
                // Conecta el controlador que almacenará el correo ingresado.
                controller: correoController,
                label: 'Correo electrónico',
                // Muestra el ícono de un sobre a la izquierda.
                prefixIcon: Icons.mail_outline,
                // Activa el teclado del teléfono diseñado para correos (con @ y .com accesibles).
                keyboardType: TextInputType.emailAddress,
              ),

              // Deja otros 16 píxeles de separación vertical.
              const SizedBox(height: 16),

              // Campo para la dirección del usuario.
              CustomTextField(
                // Conecta el controlador que guardará la dirección escrita.
                controller: direccionController,
                label: 'Dirección',
                // Muestra un pin de ubicación a la izquierda.
                prefixIcon: Icons.location_on_outlined,
              ),
              // Deja un espacio vertical de 16 píxeles después del campo de dirección.
              const SizedBox(height: 16),

              // Primer campo de contraseña usando el widget reutilizable CustomTextField.
              CustomTextField(
                // Conecta el controlador que guarda la contraseña principal escrita.
                controller: passwordController,
                label: 'Contraseña',
                // Muestra el ícono de un candado a la izquierda.
                prefixIcon: Icons.lock_outline,
                // Oculta o muestra los caracteres según el estado de ocultarPassword.
                obscureText: ocultarPassword,
                // Agrega un botón interactivo al final del campo para alternar la vista.
                suffixIcon: IconButton(
                  // Cambia el dibujo del ojo: abierto si está oculta, tachado si está visible.
                  icon: Icon(
                    ocultarPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  // Se ejecuta al tocar este primer ojo.
                  onPressed: () {
                    // Actualiza la interfaz invirtiendo solo la variable de este primer campo.
                    setState(() {
                      ocultarPassword = !ocultarPassword;
                    });
                  },
                ),
              ),

              // Deja otros 16 píxeles de separación vertical entre ambas contraseñas.
              const SizedBox(height: 16),

              // Segundo campo para confirmar que el usuario escribió bien su contraseña.
              CustomTextField(
                // Conecta un controlador independiente para comparar después que ambos textos coincidan.
                controller: confirmarPasswordController,
                label: 'Confirmar contraseña',
                // Muestra el mismo ícono de candado a la izquierda.
                prefixIcon: Icons.lock_outline,
                // Usa su propia variable (ocultarConfirmarPassword) para que mostrar u ocultar este campo no afecte al de arriba.
                obscureText: ocultarConfirmarPassword,
                // Agrega su propio botón del ojo a la derecha.
                suffixIcon: IconButton(
                  icon: Icon(
                    ocultarConfirmarPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  // Se ejecuta al tocar el segundo ojo.
                  onPressed: () {
                    // Actualiza la pantalla cambiando únicamente el estado de visibilidad de la confirmación.
                    setState(() {
                      ocultarConfirmarPassword = !ocultarConfirmarPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              PrimaryButton(
                text: esRegistroAdmin ? 'Crear administrador' : 'Crear cuenta',
                onPressed: () async {
                  // Quitamos espacios de los extremos. La contraseña se revisa tal cual.
                  final nombre = nombreController.text.trim();
                  final correo = correoController.text.trim();
                  final direccion = direccionController.text.trim();
                  final password = passwordController.text;
                  final formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                  String? error;

                  if (nombre.isEmpty ||
                      correo.isEmpty ||
                      direccion.isEmpty ||
                      password.isEmpty) {
                    error = 'Completa todos los campos.';
                  } else if (!formatoCorreo.hasMatch(correo)) {
                    error = 'Escribe un correo electrónico válido.';
                  } else if (RegExp(r'[0-9]').hasMatch(nombre)) {
                    error = 'No se permiten números en el nombre.';
                  } else if (RegExp(
                    r'[^\p{L}\p{M} ]',
                    unicode: true,
                  ).hasMatch(nombre)) {
                    // Detectamos cualquier carácter distinto de una letra, un acento o un espacio.
                    error = 'No se permiten caracteres especiales en el nombre.';
                  } else if (nombre.runes.length > 100) {
                    error = 'El nombre no puede superar los 100 caracteres.';
                  } else if (correo.runes.length > 150) {
                    error = 'El correo no puede superar los 150 caracteres.';
                  } else if (direccion.runes.length > 255) {
                    error = 'La dirección no puede superar los 255 caracteres.';
                  } else if (password.runes.length < 8) {
                    error = 'La contraseña debe tener al menos 8 caracteres.';
                  }

                  if (error != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(error)));
                    return; // Detenemos el registro para que puedas corregir el campo.
                  }

                  // Declara una variable de texto que puede ser nula ('String?'). Empieza vacía ('null') cuando no hay fallos, y guarda el mensaje de error si el servidor rechaza el registro para mostrarlo en pantalla.
                  String? errorRegistro;

                  try {
                    await AuthService().registrar(
                      nombre: nombre,
                      correo: correo,
                      direccion: direccion,
                      password: password,
                      tokenAdministrador: widget.tokenAdministrador,
                    );
                  } on SesionInvalida {
                    if (!context.mounted) return;

                    final volverAlLogin = widget.volverAlLogin;
                    if (volverAlLogin != null) {
                      volverAlLogin(context, aviso: 'La sesión terminó.');
                      return;
                    }

                    errorRegistro = 'La sesión terminó.';
                  } on StateError catch (error) {
                    // Muestra el mensaje que envió FastAPI cuando rechazó el registro.
                    errorRegistro = error.message;
                  } catch (_) {
                    errorRegistro = 'No se pudo comunicar con el servidor.';
                  }
                  // Verifica que el widget de esta pantalla siga activo en pantalla después de esperar
                  //la respuesta del servidor; si el usuario ya cerró o salió de la vista,
                  //detiene la función para evitar errores al intentar actualizar la interfaz o navegar.
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        errorRegistro ?? 'Cuenta creada correctamente.',
                      ),
                    ),
                  );

                  // Volvemos al login cuando FastAPI confirma que guardó la cuenta.
                  // Si el formulario se abrió desde el menú de admin, volvemos al inicio.
                  if (errorRegistro == null) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              if (!esRegistroAdmin) ...[
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB50020),
                  ),
                  onPressed: () {
                    // Cerramos Registro y regresamos al login que ya estaba abierto.
                    Navigator.pop(context);
                  },
                  child: const Text('Volver al login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Estructura base de la pantalla.
    final pantalla = Scaffold(
      appBar: esRegistroAdmin
          ? AppBar(
              backgroundColor: const Color(0xFFB50020),
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              title: Image.asset(
                'assets/logo.png',
                height: 34,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            )
          : null,
      // Aplica el mismo fondo degradado rosa que en la pantalla de login.
      body: AuthBackground(
        // Protege el contenido para que no quede debajo de la barra superior o cámara del celular.
        child: SafeArea(
          child: esRegistroAdmin
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coloca la flecha a la izquierda, debajo de la barra roja.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver al inicio'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB50020),
                        ),
                      ),
                    ),
                    Expanded(
                      // Oculta la barra de desplazamiento y permite deslizar el formulario.
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          scrollbars: false,
                        ),
                        child: formulario,
                      ),
                    ),
                  ],
                )
              : formulario,
        ),
      ),
    );

    final registrarActividad = widget.registrarActividad;

    if (registrarActividad == null) return pantalla;

    return ActividadSesion(
      onActividad: () => registrarActividad(context),
      child: pantalla,
    );
  }
}