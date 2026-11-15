import 'package:flutter/material.dart';

// Widget reutilizable para crear el botón principal rojo de la aplicación (como "Iniciar sesión" o "Registrarse").
class PrimaryButton extends StatelessWidget {
  // Texto que se mostrará escrito dentro del botón.
  final String text;
  // Función que se ejecutará cada vez que el usuario toque el botón.
  final VoidCallback onPressed;

  // Constructor que obliga ('required') a pasarle tanto el texto como la acción al tocarlo.
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Caja que obliga al botón a estirarse a todo el ancho disponible (double.infinity) con una altura fija de 48 píxeles.
    return SizedBox(
      width: double.infinity,
      height: 48,
      // Botón con relleno sólido propio de Material Design.
      child: ElevatedButton(
        // Conecta la acción recibida con el evento de toque del botón.
        onPressed: onPressed,
        // Personaliza los colores, sombra y forma del botón.
        style: ElevatedButton.styleFrom(
          // Pinta el fondo con el rojo oficial del proyecto (#B50020).
          backgroundColor: const Color(0xFFB50020),
          // Pinta el texto (y efectos de toque) en color blanco para que resalte sobre el rojo.
          foregroundColor: Colors.white,
          // Quita la sombra debajo del botón (0) para darle un aspecto plano y moderno.
          elevation: 0,
          // Redondea las cuatro esquinas del botón con un radio de 10 píxeles, igual que los campos de texto.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        // Muestra el texto recibido en negritas y con tamaño de letra 16.
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}