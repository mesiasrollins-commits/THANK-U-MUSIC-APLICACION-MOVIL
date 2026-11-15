// Importa los componentes visuales básicos de Material Design (colores, contenedores, alineaciones).
import 'package:flutter/material.dart';

// Widget reutilizable sin estado (StatelessWidget) que sirve como fondo decorativo para las pantallas de login o registro.
class AuthBackground extends StatelessWidget {
  // Guarda el contenido (por ejemplo, el formulario) que se va a dibujar encima de este fondo.
  final Widget child;

  // Constructor que obliga ('required') a pasarle qué widget irá adentro cada vez que se use AuthBackground.
  const AuthBackground({super.key, required this.child});

  // Dibuja el contenedor en pantalla.
  @override
  Widget build(BuildContext context) {
    // Caja que ocupa el espacio disponible y aplica una decoración visual detrás del contenido.
    return Container(
      decoration: const BoxDecoration(
        // Crea un degradado lineal que empieza arriba a la izquierda (topLeft) y termina abajo a la derecha (bottomRight).
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Lista de colores por los que pasa el degradado: de un blanco rosado muy suave a un rosa pálido.
          colors: [
            Color(0xFFFFF7FA),
            Color(0xFFF8EAF0),
          ],
        ),
      ),
      // Coloca el contenido recibido (el formulario) justo encima del fondo degradado.
      child: child,
    );
  }
}