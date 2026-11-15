// Importa los componentes visuales de Material Design (pantallas, textos, botones, campos de formulario).
import 'package:flutter/material.dart';

import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

// Define una pantalla con estado (StatefulWidget) porque más adelante guardará lo que el usuario escriba en los campos, errores de validación o si está cargando.
class LoginPage extends StatefulWidget {
  // Constructor que pasa una llave opcional (super.key) para que Flutter identifique este widget en pantalla.
  const LoginPage({super.key});

  // Crea y conecta el objeto privado (_LoginPageState) donde vivirá la lógica y la memoria de esta pantalla.
  @override
  State<LoginPage> createState() => _LoginPageState();
}

// Clase privada (el guion bajo al inicio significa que solo se usa dentro de este archivo) que maneja los cambios y dibuja la interfaz del login.
class _LoginPageState extends State<LoginPage> {
  // Los controladores nos permiten leer lo que se escribe en cada campo.
  final usuarioController = TextEditingController();
  final passwordController = TextEditingController();
  bool ocultarPassword = true;

  @override
  void dispose() {
    // Liberamos los controladores cuando se cierra la pantalla.
    usuarioController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void iniciarSesion() {
    // Quitamos espacios del correo y leemos la contraseña tal como se escribió.
    final correo = usuarioController.text.trim();
    final password = passwordController.text;
    final formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    String? error;

    if (correo.isEmpty || password.isEmpty) {
      error = 'Escribe tu correo y contraseña.';
    } else if (correo.runes.length > 150) {
      // El correo tiene el mismo límite que en la base de datos.
      error = 'El correo no puede superar los 150 caracteres.';
    } else if (!formatoCorreo.hasMatch(correo)) {
      error = 'Escribe un correo electrónico válido.';
    } else if (password.runes.length < 8) {
      error = 'La contraseña debe tener al menos 8 caracteres.';
    }

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Cuando conectemos el servidor, la comprobación de la cuenta irá aquí.
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Los campos son válidos.')));
  }

  // Se ejecuta cada vez que Flutter necesita dibujar o actualizar visualmente la pantalla.
  @override
  Widget build(BuildContext context) {
    // Scaffold crea la estructura base de la pantalla; Center y Text colocan el título provisional justo en medio.
    // Crea la estructura base de la pantalla.
    return Scaffold(
      // Coloca como fondo el degradado rosa personalizado (AuthBackground).
      body: AuthBackground(
        // Evita que el contenido choque con la barra de hora/batería arriba o la cámara (notch) del teléfono.
        child: SafeArea(
          // Centra vertical y horizontalmente todo lo que esté adentro.
          child: Center(
            // Permite deslizar la pantalla hacia arriba o abajo (scroll) para que el teclado del celular no tape el formulario al escribir.
            child: SingleChildScrollView(
              // Deja un margen externo de 20 píxeles alrededor para que la tarjeta no toque los bordes del celular.
              padding: EdgeInsets.all(20),
              // Dibuja la tarjeta blanca redondeada (AuthCard) que creaste antes.
              child: AuthCard(
                // Muestra el título principal centrado y en negritas con tamaño de letra 26.
                // Organiza los elementos uno debajo del otro en forma vertical.
                child: Column(
                  // Hace que la columna ocupe solo la altura mínima necesaria según su contenido, en lugar de estirarse a toda la pantalla.
                  mainAxisSize: MainAxisSize.min,
                  // Lista de elementos que irán apilados de arriba hacia abajo.
                  children: [
                    // Carga y muestra la imagen del logo guardada localmente en la carpeta assets del proyecto.
                    Image.asset(
                      'assets/logo.png',
                      // Fija el ancho máximo de la imagen en 220 píxeles.
                      width: 220,
                      // Asegura que toda la imagen se vea completa sin recortarse ni deformarse dentro de ese espacio.
                      fit: BoxFit.contain,
                    ),
                    // Crea una caja invisible de 20 píxeles de alto para dar separación vertical entre el logo y el título.
                    const SizedBox(height: 20),
                    // Muestra el título principal centrado y en negritas con tamaño de letra 26.
                    const Text(
                      'Iniciar sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Deja un espacio vertical de 24 píxeles debajo del título antes de mostrar el primer campo.
                    const SizedBox(height: 24),

                    // Dibuja el campo de correo usando tu widget personalizado CustomTextField.
                    CustomTextField(
                      // Conecta el controlador que guardará el correo que escriba el usuario.
                      controller: usuarioController,
                      label: 'Correo electrónico',
                      // Muestra un ícono de sobre a la izquierda.
                      prefixIcon: Icons.mail_outline,
                      // Abre el teclado del celular optimizado para correos (con @ y .com a la mano).
                      keyboardType: TextInputType.emailAddress,
                    ),

                    // Deja una separación de 16 píxeles entre el campo de correo y el de contraseña.
                    const SizedBox(height: 16),

                    // Dibuja el campo de contraseña reutilizando el mismo widget CustomTextField.
                    CustomTextField(
                      // Conecta el controlador que guardará la contraseña escrita.
                      controller: passwordController,
                      label: 'Contraseña',
                      // Muestra un ícono de candado a la izquierda.
                      prefixIcon: Icons.lock_outline,
                      // Oculta o muestra los caracteres dependiendo de lo que valga la variable booleana ocultarPassword.
                      obscureText: ocultarPassword,
                      // Coloca un botón con ícono al extremo derecho del campo para alternar la visibilidad.
                      suffixIcon: IconButton(
                        // Muestra un mensaje flotante al mantener presionado o pasar el cursor, cambiando el texto según el estado actual.
                        tooltip: ocultarPassword
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        // Cambia el dibujo del ojo: ojo abierto si está oculta, ojo tachado si ya está visible.
                        icon: Icon(
                          ocultarPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        // Se ejecuta al tocar el botón del ojo.
                        onPressed: () {
                          // setState avisa a Flutter que un dato cambió y vuelve a dibujar esta pantalla con el nuevo estado.
                          setState(() {
                            // Invierte el valor: si era true pasa a false, y si era false pasa a true.
                            ocultarPassword = !ocultarPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    PrimaryButton(text: 'Entrar', onPressed: iniciarSesion),
                    // Deja un espacio vertical pequeño de 8 píxeles debajo del botón principal antes del enlace de registro.
                    const SizedBox(height: 8),

                    // Acomoda elementos en fila horizontal, pero si la pantalla es muy angosta (o la letra del celular está muy grande), baja automáticamente lo que no quepa a un renglón nuevo para evitar el error amarillo de desbordamiento (overflow).
                    Wrap(
                      // Centra los elementos horizontalmente en cada renglón.
                      alignment: WrapAlignment.center,
                      // Alinea verticalmente el texto normal con el botón para que queden a la misma altura.
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Texto informativo estático.
                        const Text('¿No tienes cuenta?'),
                        // Botón sin fondo ni bordes que funciona como un enlace web tradicional.
                        TextButton(
                          // Se ejecuta al tocar "Regístrate".
                          onPressed: () {
                            // Navega hacia la pantalla registrada con la ruta '/register' dentro de MaterialApp, dejando el login atrás para poder volver con el botón de regreso.
                            Navigator.pushNamed(context, '/register');
                          },
                          // Estiliza el texto del botón con el rojo oficial (#B50020), en negritas y subrayado para que parezca un link.
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                              color: Color(0xFFB50020),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
