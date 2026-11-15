// Importa los componentes visuales básicos de Android/Material Design (botones, textos, pantallas, colores).
import 'package:flutter/material.dart';

import 'screens/login_user_page.dart';
import 'screens/register_user_page.dart';

// Punto de entrada de la aplicación: lo primero que ejecuta Dart al abrir la app.
void main() {
  // Dibuja en pantalla el widget principal de la aplicación; 'const' ayuda a que use menos memoria.
  runApp(const ThankUMusicApp());
}

// Widget raíz sin estado interno (StatelessWidget), porque su configuración base no cambia mientras se usa la app.
class ThankUMusicApp extends StatelessWidget {
  // Constructor que recibe una llave opcional (super.key) para que Flutter identifique este widget si se reconstruye.
  const ThankUMusicApp({super.key});

  // Método obligatorio donde se describe cómo se debe dibujar este widget en pantalla.
  @override
  Widget build(BuildContext context) {
    // Contenedor principal que configura la navegación, el idioma y los estilos visuales de toda la app.
    return MaterialApp(
      title: 'Thank U Music',
      // Quita la cinta roja que dice "DEBUG" en la esquina superior derecha.
      debugShowCheckedModeBanner: false,

      // Define la paleta de colores de la app generando tonos automáticos a partir del rojo principal (#B50020).
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB50020)),
      ),

      // Define la primera pantalla que verá el usuario al abrir la app.
      // Scaffold da la estructura básica de una pantalla blanca; Center y Text acomodan el título justo en medio.
      // Abrimos el login al iniciar la app.
      home: const LoginPage(),
      // Esta ruta abre Registro cuando se pulsa «Regístrate».
      routes: {'/register': (context) => const RegisterPage()},
    );
  }
}
