// Importa los componentes visuales básicos de Material Design en Flutter.
import 'package:flutter/material.dart';

// Importa el detector de actividad para mantener viva la sesión y la tarjeta que muestra el detalle de la publicación.
import '../widgets/actividad_sesion.dart';
import '../widgets/post_detail_card.dart';

import '../services/auth_service.dart';
import '../services/comentario_service.dart';

// Pantalla que muestra el contenido completo de una publicación seleccionada desde el blog.
// Pantalla con estado interno para mostrar el detalle de una publicación junto con su lista de comentarios.
class PostDetailPage extends StatefulWidget {
  // Constructor que exige los datos de la publicación, las funciones de sesión y el token activo.
  const PostDetailPage({
    super.key,
    required this.publicacion,
    required this.registrarActividad,
    required this.tokenSesion,
    required this.volverAlLogin,
  });

  // Mapa clave-valor con los datos de la publicación seleccionada.
  final Map<String, dynamic> publicacion;
  // Función asíncrona que avisa al servidor que el usuario sigue activo.
  final Future<void> Function(BuildContext) registrarActividad;
  // Token de autorización del usuario para consultar los comentarios en la API.
  final String tokenSesion;
  // Función que redirige al inicio de sesión mostrando un aviso opcional si la sesión caduca.
  final void Function(BuildContext, {String? aviso}) volverAlLogin;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  // Define el color rojo institucional reutilizable dentro de esta pantalla.
  static const rojo = Color(0xFFB50020);

  // Guarda la promesa (Future) con la lista de comentarios para evitar descargarlos de nuevo cada vez que se redibuje la interfaz.
  late Future<ListaComentarios> _comentarios;

  @override
  void initState() {
    super.initState();
    // Inicia la descarga de los comentarios una única vez al entrar a la pantalla de detalle.
    _comentarios = cargarComentarios();
  }

  // Solicita los comentarios de la publicación actual al servicio y redirige al login si el token ya venció.
  Future<ListaComentarios> cargarComentarios() async {
    try {
      // Llama al servicio enviando el ID numérico de la publicación y el token de sesión.
      return await ComentarioService().obtenerComentarios(
        idPublicacion: widget.publicacion['id_publicacion'] as int,
        tokenSesion: widget.tokenSesion,
      );
    } on SesionInvalida {
      // Verifica que la pantalla siga visible antes de ejecutar la navegación hacia el login.
      if (mounted) {
        widget.volverAlLogin(
          context,
          aviso: 'La sesión terminó. Inicia sesión de nuevo.',
        );
      }
      // Vuelve a lanzar el error ('rethrow') para que el FutureBuilder detecte que la carga falló.
      rethrow;
    }
  }

  // Convierte una fecha en texto estándar (por ejemplo '2026-11-16') a un formato corto legible ('16 nov 2026').
  String formatearFecha(String? valor) {
    // Intenta interpretar el texto como fecha; si viene nulo o con formato inválido, devuelve un texto de respaldo.
    final fecha = DateTime.tryParse(valor ?? '');
    if (fecha == null) return 'Fecha sin registrar';

    // Lista con las abreviaturas de los meses en español.
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    // Asegura que el día siempre tenga dos dígitos agregando un cero a la izquierda si es menor a 10.
    final dia = fecha.day.toString().padLeft(2, '0');
    return '$dia ${meses[fecha.month - 1]} ${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final publicacion = widget.publicacion;
    // Envuelve toda la pantalla en 'ActividadSesion' para detectar toques o desplazamientos y renovar la sesión.
    return ActividadSesion(
      onActividad: () => widget.registrarActividad(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF5F7),
        // Barra superior institucional sin flecha automática de regreso (porque el botón de volver está dentro del cuerpo).
        appBar: AppBar(
          backgroundColor: rojo,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Image.asset(
            'assets/logo.png',
            height: 34,
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
        // Cuerpo desplazable verticalmente con márgenes laterales e inferior.
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            // Alinea a la izquierda el botón que cierra esta pantalla y regresa al listado del blog.
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: rojo),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver al blog'),
              ),
            ),
            const SizedBox(height: 8),
            // Muestra la tarjeta de detalle extrayendo cada campo del mapa 'publicacion' y aplicando valores por defecto si alguno falta.
            PostDetailCard(
              titulo: publicacion['titulo']?.toString() ?? '',
              autor: publicacion['autor']?.toString() ?? 'Autor no disponible',
              fecha: formatearFecha(
                publicacion['fecha_publicacion']?.toString(),
              ),
              contenido: publicacion['contenido']?.toString() ?? '',
              imagenUrl: publicacion['imagen_url']?.toString(),
            ),
            // Inserta una separación vertical entre la tarjeta de la publicación y la sección de comentarios.
            const SizedBox(height: 16),
            // Escucha el estado de la promesa '_comentarios' y dibuja la interfaz correspondiente según el avance de la consulta.
            FutureBuilder<ListaComentarios>(
              future: _comentarios,
              builder: (context, snapshot) {
                // Mientras la petición al servidor sigue en curso, muestra una rueda giratoria de carga centrada.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Si ocurrió un error al obtener los comentarios, muestra un mensaje informativo en texto plano.
                if (snapshot.hasError) {
                  return const Text('No se pudieron cargar los comentarios.');
                }

                // Extrae la lista de comentarios recibida, o usa una lista vacía ('[]') como respaldo si el dato llega nulo.
                final comentarios = snapshot.data ?? [];

                // Organiza en columna el encabezado de la sección y el listado de tarjetas de comentarios.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado que muestra la palabra 'Comentarios' junto con el total de elementos recibidos entre paréntesis.
                    Text(
                      'Comentarios (${comentarios.length})',
                      style: const TextStyle(
                        color: rojo,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Si la lista está vacía, muestra un aviso indicando que aún nadie ha comentado.
                    if (comentarios.isEmpty)
                      const Text('Todavía no hay comentarios.'),
                    // Recorre cada comentario de la lista para construir una tarjeta individual por cada uno.
                    for (final comentario in comentarios)
                      Card(
                        color: const Color(0xFFFFEDF2),
                        child: ListTile(
                          // Círculo rosado con el icono de persona en el lado izquierdo de la tarjeta.
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFBD7DF),
                            child: Icon(Icons.person_outline, color: rojo),
                          ),
                          // Muestra el nombre del autor en negritas, o un texto de respaldo si el dato viene nulo.
                          title: Text(
                            comentario['autor']?.toString() ??
                                'Autor no disponible',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // Apila verticalmente el texto del comentario y su fecha formateada debajo del nombre del autor.
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comentario['comentario']?.toString() ?? ''),
                              Text(
                                formatearFecha(
                                  comentario['fecha_comentario']?.toString(),
                                ),
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
}
