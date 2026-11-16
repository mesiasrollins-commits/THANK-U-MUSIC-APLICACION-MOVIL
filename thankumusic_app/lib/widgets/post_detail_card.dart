// Importa los componentes visuales básicos de Material Design en Flutter.
import 'package:flutter/material.dart';

// Define una tarjeta con estado interno para mostrar el detalle completo de una publicación y permitir expandir o contraer su texto.
class PostDetailCard extends StatefulWidget {
  // Constructor que exige título, autor, fecha y contenido, dejando la URL de la imagen como opcional.
  const PostDetailCard({
    super.key,
    required this.titulo,
    required this.autor,
    required this.fecha,
    required this.contenido,
    this.imagenUrl,
  });

  // Datos principales de la publicación que recibirá el widget desde fuera.
  final String titulo;
  final String autor;
  final String fecha;
  final String contenido;
  final String? imagenUrl;

  @override
  State<PostDetailCard> createState() => _PostDetailCardState();
}

class _PostDetailCardState extends State<PostDetailCard> {
  // Define el color rojo institucional reutilizable dentro de toda la tarjeta.
  static const rojo = Color(0xFFB50020);

  // Controla si el contenido de la publicación se muestra completo (true) o recortado a 2 líneas (false).
  bool expandido = false;

  @override
  Widget build(BuildContext context) {
    // Guarda en variables locales la URL de la imagen y el estilo de texto heredado del tema actual para usarlos al medir el texto.
    final imagenUrl = widget.imagenUrl;
    final estiloContenido = DefaultTextStyle.of(context).style;

    // Contenedor principal en forma de tarjeta con sombra ligera, fondo rosado claro y esquinas redondeadas.
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFFFFEDF2),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Solo dibuja el bloque de la imagen si se recibió una URL válida y no vacía.
            if (imagenUrl != null && imagenUrl.isNotEmpty) ...[
              // Recorta las esquinas de la imagen para darle bordes redondeados.
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imagenUrl,
                  height: 180,
                  fit: BoxFit.cover,
                  // En Flutter Web, usa una etiqueta HTML nativo (<img>) para evitar bloqueos de seguridad (CORS) al cargar imágenes externas.
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  // Si la imagen falla al cargar, muestra un recuadro de la misma altura con un icono de imagen rota.
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 180,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            // Título de la publicación en tamaño grande, negritas y color rojo institucional.
            Text(
              widget.titulo,
              style: const TextStyle(
                color: rojo,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            // Acomoda el autor y la fecha uno al lado del otro, saltando a una segunda fila si la pantalla es muy estrecha.
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                dato(Icons.person_outline, widget.autor),
                dato(Icons.calendar_today_outlined, widget.fecha),
              ],
            ),
            const SizedBox(height: 10),
            // Obtiene el ancho exacto disponible en pantalla para calcular si el texto supera las 2 líneas.
            LayoutBuilder(
              builder: (context, espacio) {
                // Simula el dibujado del texto con un límite de 2 líneas dentro del ancho disponible sin mostrarlo aún en pantalla.
                final medidor = TextPainter(
                  text: TextSpan(
                    text: widget.contenido,
                    style: estiloContenido,
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  maxLines: 2,
                )..layout(maxWidth: espacio.maxWidth);

                // Guarda en un booleano si el texto rebasa las 2 líneas y libera de memoria el objeto medidor.
                final hayMasTexto = medidor.didExceedMaxLines;
                medidor.dispose();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Muestra el cuerpo de la publicación: sin límite de líneas si está expandido, o cortado con puntos suspensivos a 2 líneas si está contraído.
                    Text(
                      widget.contenido,
                      style: estiloContenido,
                      maxLines: expandido ? null : 2,
                      overflow: expandido
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    // Muestra el botón 'Ver más' / 'Ver menos' únicamente cuando el texto realmente es más largo de 2 líneas.
                    if (hayMasTexto)
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: rojo,
                            side: const BorderSide(color: rojo),
                          ),
                          // Alterna el estado entre expandido y contraído y redibuja el widget.
                          onPressed: () {
                            setState(() => expandido = !expandido);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(expandido ? 'Ver menos' : 'Ver más'),
                              const SizedBox(width: 4),
                              Icon(
                                expandido ? Icons.expand_less : Icons.expand_more,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Método auxiliar que construye una fila pequeña con un icono rojo y un texto al lado (usado para el autor y la fecha).
  Widget dato(IconData icono, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: rojo, size: 16),
        const SizedBox(width: 6),
        Text(texto),
      ],
    );
  }
}