import 'package:flutter/material.dart';

// Widget reutilizable que arma una caja de texto completa con su título arriba e íconos personalizados.
class CustomTextField extends StatelessWidget {
  // Controlador que lee o modifica el texto que el usuario escribe adentro.
  final TextEditingController controller;
  // Texto que aparece tanto arriba como dentro de la caja (pista).
  final String label;
  // Ícono que se dibuja del lado izquierdo dentro de la caja.
  final IconData prefixIcon;
  // Si es true, oculta los caracteres con puntos (ideal para contraseñas).
  final bool obscureText;
  // Widget opcional al final de la caja (por ejemplo, el botón del ojito para ver/ocultar clave).
  final Widget? suffixIcon;
  // Define qué teclado abrir en el celular (normal, correo con @, numérico, etc.).
  final TextInputType keyboardType;

  // Constructor: los tres primeros datos son obligatorios; los demás tienen valores por defecto si no se envían.
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    // Acomoda el título arriba y la caja de texto abajo, alineados a la izquierda.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Muestra el nombre del campo en negritas para que no desaparezca al empezar a escribir.
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // Deja un espacio vertical pequeño de 6 píxeles entre el título y la caja.
        const SizedBox(height: 6),
        // Campo donde el usuario toca para escribir.
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          // Configura la apariencia visual del borde y los elementos internos.
          decoration: InputDecoration(
            // Texto gris de ayuda dentro de la caja cuando está vacía.
            hintText: label,
            // Coloca el ícono izquierdo pintado con el rojo oficial del proyecto (#B50020).
            prefixIcon: Icon(prefixIcon, color: const Color(0xFFB50020)),
            // Coloca el ícono derecho opcional si se recibió uno.
            suffixIcon: suffixIcon,
            // Dibuja un contorno alrededor de toda la caja con esquinas suavemente redondeadas.
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}