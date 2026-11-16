// Importa los componentes visuales básicos de Material Design en Flutter.
import 'package:flutter/material.dart';

// Define una tarjeta reutilizable para mostrar la vista previa de una publicación o artículo.
class PostCard extends StatelessWidget {
  // Constructor que exige el título y el resumen, dejando como opcionales la imagen de portada y la acción al presionar el botón.
  const PostCard({
    super.key,
    required this.titulo,
    required this.resumen,
    this.portada,
    this.alLeer,
  });

  // Título principal de la publicación.
  final String titulo;
  // Texto breve con la descripción o extracto del contenido.
  final String resumen;
  // Widget opcional para mostrar una imagen superior; si no se envía, se muestra un recuadro con icono por defecto.
  final Widget? portada;
  // Función opcional que se ejecuta cuando el usuario toca 'Leer publicación'.
  final VoidCallback? alLeer;

  // Define el color rojo institucional reutilizable dentro de la tarjeta.
  static const rojo = Color(0xFFB50020);

  @override
  Widget build(BuildContext context) {
    // Construye el contenedor con sombra ligera, fondo rosado claro y esquinas redondeadas.
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFFFEDF2),
      elevation: 2,
      // Recorta cualquier contenido interno (como la imagen superior) para que respete los bordes redondeados de la tarjeta.
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      // Organiza la imagen arriba y los textos abajo en una columna que ocupa todo el ancho disponible.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reserva un espacio de altura fija para la portada.
          SizedBox(
            height: 150,
            // Si 'portada' tiene contenido la muestra; si es nula ('??'), dibuja un fondo rosado con un icono centrado de imagen.
            child: portada ??
                const ColoredBox(
                  color: Color(0xFFFBD7DF),
                  child: Center(
                    child: Icon(Icons.image_outlined, color: rojo, size: 36),
                  ),
                ),
          ),
          // Agrega margen interior alrededor de los textos y el botón de lectura.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Muestra el título destacado en negritas y color rojo institucional.
                Text(
                  titulo,
                  style: const TextStyle(
                    color: rojo,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Pequeña separación vertical entre el título y el resumen.
                const SizedBox(height: 4),
                // Muestra el resumen limitado a un máximo de 2 líneas, cortando el texto sobrante con puntos suspensivos ('...').
                Text(resumen, maxLines: 2, overflow: TextOverflow.ellipsis),
                // Botón con icono y texto que dispara la función 'alLeer' al ser presionado, sin margen horizontal extra para alinearse a la izquierda.
                TextButton.icon(
                  onPressed: alLeer,
                  style: TextButton.styleFrom(
                    foregroundColor: rojo,
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.article_outlined, size: 18),
                  label: const Text('Leer publicación'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}