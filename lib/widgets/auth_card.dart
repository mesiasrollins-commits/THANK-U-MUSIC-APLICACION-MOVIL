import 'package:flutter/material.dart';

// Widget reutilizable que crea el cuadro o tarjeta principal donde va el formulario de login o registro.
class AuthCard extends StatelessWidget {
  // Guarda los elementos (campos de texto, botones, título) que se mostrarán dentro de la tarjeta.
  final Widget child;

  // Constructor que obliga ('required') a pasarle el contenido interno cada vez que se use esta tarjeta.
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Crea una tarjeta con sombra y relieve propia de Material Design.
    return Card(
      // Color de fondo blanco con un toque muy ligero de rosa.
      color: const Color(0xFFFFFAFC),
      // Nivel de elevación: entre más alto el número, más marcada se ve la sombra debajo de la tarjeta.
      elevation: 6,
      // Define la forma del contorno redondeando las cuatro esquinas con un radio de 24 píxeles.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      // Agrega un espacio interno (relleno) de 24 píxeles en los cuatro lados para que el texto no quede pegado al borde.
      child: Padding(
        padding: const EdgeInsets.all(24),
        // Fija un ancho máximo ideal de 420 píxeles (útil si se abre en pantallas grandes o tabletas), ajustándose si el celular es más angosto.
        child: SizedBox(
          width: 420,
          child: child,
        ),
      ),
    );
  }
}