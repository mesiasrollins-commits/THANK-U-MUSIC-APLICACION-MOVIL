// Importa los componentes visuales básicos de Material Design en Flutter.
import 'package:flutter/material.dart';

// Importa la excepción 'SesionInvalida' para detectar si la sesión del usuario ya venció.
import '../services/auth_service.dart';
// Importa el servicio encargado de pedir las publicaciones al servidor.
import '../services/post_service.dart';
// Importa el widget que detecta actividad en la pantalla para mantener activa la sesión.
import '../widgets/actividad_sesion.dart';
import '../widgets/post_card.dart';
import 'add_blog_page.dart';
import 'moderacion_comentarios.dart';

// Define un nombre corto para la lista de publicaciones. Cada publicación es un mapa con sus datos.
typedef ListaPublicaciones = List<Map<String, dynamic>>;

// Pantalla que muestra la lista de publicaciones creadas por el usuario conectado.
class MisPublicacionesPage extends StatefulWidget {
  // Constructor que recibe el token de sesión y las funciones para registrar actividad o regresar al login.
  const MisPublicacionesPage({
    super.key,
    required this.tokenSesion,
    required this.registrarActividad,
    required this.volverAlLogin,
  });

  // Token de autorización del usuario actual.
  final String tokenSesion;

  // Función que avisa al servidor que el usuario sigue usando la pantalla.
  final Future<void> Function(BuildContext) registrarActividad;

  // Función que redirige al inicio de sesión y puede mostrar un aviso si la sesión caduca.
  final void Function(BuildContext, {String? aviso}) volverAlLogin;

  @override
  State<MisPublicacionesPage> createState() => _MisPublicacionesPageState();
}

class _MisPublicacionesPageState extends State<MisPublicacionesPage> {
  // Guarda la consulta para evitar pedir las publicaciones en cada redibujo.
  // Guardamos la consulta para poder recargar la lista después de editar.
  late Future<ListaPublicaciones> _publicaciones;

  @override
  void initState() {
    super.initState();

    // Inicia la carga de las publicaciones una sola vez al abrir la pantalla.
    _publicaciones = cargarPublicaciones();
  }

  // Pide al servicio las publicaciones propias y redirige al login si la sesión terminó.
  Future<ListaPublicaciones> cargarPublicaciones() async {
    try {
      // Activa 'soloMias' para consultar las publicaciones de la cuenta actual.
      return await PostService().obtenerPublicaciones(
        widget.tokenSesion,
        soloMias: true,
      );
    } on SesionInvalida {
      // Verifica que la pantalla siga abierta antes de regresar al login.
      if (mounted) {
        widget.volverAlLogin(context, aviso: 'La sesión terminó.');
      }

      // Vuelve a lanzar el error para que FutureBuilder detecte que la carga falló.
      rethrow;
    }
  }

  // Abre la pantalla de edición con los datos de una publicación existente y actualiza la lista cuando se guardan los cambios.
  Future<void> abrirEditor(Map<String, dynamic> publicacion) async {
    // Guarda si la publicación estaba en borrador antes de abrir el editor, para saber si después cambió a publicada.
    final eraBorrador = publicacion['estado'] == 'borrador';

    // Abrimos el mismo formulario con los datos de la entrada seleccionada.
    final estadoGuardado = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => AddBlogPage(
          registrarActividad: widget.registrarActividad,
          tokenSesion: widget.tokenSesion,
          volverAlLogin: widget.volverAlLogin,
          publicacion: publicacion,
        ),
      ),
    );

    // Si la pantalla se cerró o el usuario regresó sin guardar cambios ('estadoGuardado' es nulo), detiene la función.
    if (!mounted || estadoGuardado == null) return;

    // Pedimos la lista actualizada después de que FastAPI confirma el guardado.
    final publicacionesActualizadas = cargarPublicaciones();
    setState(() {
      _publicaciones = publicacionesActualizadas;
    });

    // Elige el texto del aviso: si era borrador y ahora quedó publicada dice 'Borrador publicado.', de lo contrario 'Cambios guardados.'.
    final mensaje = eraBorrador && estadoGuardado == 'publicada'
        ? 'Borrador publicado.'
        : 'Cambios guardados.';

    // Muestra una notificación breve en la parte inferior de la pantalla con el mensaje elegido.
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    // Detecta interacciones en la pantalla para mantener activa la sesión.
    return ActividadSesion(
      onActividad: () => widget.registrarActividad(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF5F7),

        // Barra superior con el título de la pantalla y los colores institucionales.
        appBar: AppBar(
          title: const Text('Tus publicaciones'),
          backgroundColor: const Color(0xFFB50020),
          foregroundColor: Colors.white,
        ),

        // Usa ListaPublicaciones para que Dart reconozca el tipo de snapshot.data.
        body: FutureBuilder<ListaPublicaciones>(
          future: _publicaciones,
          builder: (context, snapshot) {
            // Mientras el servidor responde, muestra un indicador de carga centrado.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Si falla la consulta, muestra un aviso centrado.
            if (snapshot.hasError) {
              return const Center(
                child: Text('No se pudieron cargar tus publicaciones.'),
              );
            }

            // Obtiene la lista recibida o usa una lista vacía si llegó nula.
            final ListaPublicaciones publicaciones = snapshot.data ?? [];

            // Si la lista está vacía, muestra un aviso en lugar de las tarjetas.
            if (publicaciones.isEmpty) {
              return const Center(
                child: Text('Todavía no tienes publicaciones.'),
              );
            }

            // Construye las tarjetas conforme se necesitan al desplazar la lista.
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: publicaciones.length,
              itemBuilder: (context, indice) {
                final publicacion = publicaciones[indice];

                final imagenUrl = publicacion['imagen_url']?.toString() ?? '';

                return PostCard(
                  titulo: publicacion['titulo']?.toString() ?? '',
                  resumen: publicacion['contenido']?.toString() ?? '',
                  portada: imagenUrl.isEmpty
                      ? null
                      : Image.network(
                          imagenUrl,
                          fit: BoxFit.cover,
                          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                  alEditar: () => abrirEditor(publicacion),
                  // Acción que se ejecuta cuando se selecciona la opción para moderar los comentarios de una publicación.
                  alModerar: () {
                    // Abre la pantalla 'ModeracionComentariosPage' enviándole los datos de la publicación elegida, el token de sesión y las funciones para mantener activa la sesión o regresar al login.
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ModeracionComentariosPage(
                          publicacion: publicacion,
                          tokenSesion: widget.tokenSesion,
                          registrarActividad: widget.registrarActividad,
                          volverAlLogin: widget.volverAlLogin,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
