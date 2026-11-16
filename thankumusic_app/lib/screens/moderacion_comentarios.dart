// Importa los componentes visuales básicos de Material Design en Flutter.
import 'package:flutter/material.dart';

// Importa la excepción 'SesionInvalida' para detectar si la sesión del usuario ya caducó.
import '../services/auth_service.dart';
// Importa el servicio encargado de consultar los comentarios al servidor.
import '../services/comentario_service.dart';
// Importa el contenedor que detecta actividad en pantalla para mantener viva la sesión.
import '../widgets/actividad_sesion.dart';

// Pantalla que permite a un administrador revisar y moderar los comentarios de una publicación específica.
class ModeracionComentariosPage extends StatefulWidget {
  // Constructor que recibe la publicación elegida, el token de sesión y las funciones para renovar actividad o volver al login.
  const ModeracionComentariosPage({
    super.key,
    required this.publicacion,
    required this.tokenSesion,
    required this.registrarActividad,
    required this.volverAlLogin,
  });

  // Diccionario con los datos de la publicación seleccionada (como su ID y título).
  final Map<String, dynamic> publicacion;
  // Token de autorización del administrador conectado.
  final String tokenSesion;
  // Función asíncrona que avisa al servidor que el usuario sigue interactuando con la aplicación.
  final Future<void> Function(BuildContext) registrarActividad;
  // Función que redirige a la pantalla de inicio de sesión con un aviso opcional si el token vence.
  final void Function(BuildContext, {String? aviso}) volverAlLogin;

  @override
  State<ModeracionComentariosPage> createState() =>
      _ModeracionComentariosPageState();
}

class _ModeracionComentariosPageState extends State<ModeracionComentariosPage> {
  // Color rojo institucional reutilizado en bordes, íconos y títulos de esta pantalla.
  static const rojo = Color(0xFFB50020);
  // Guarda la promesa con la lista de comentarios cargados al abrir la vista para no repetir peticiones al redibujar.
  late Future<ListaComentarios> _comentarios = cargarComentarios();
  bool _eliminando = false;

  // Carga los comentarios de la publicación seleccionada.
  Future<ListaComentarios> cargarComentarios() async {
    try {
      // Consulta en el servidor los comentarios asociados al ID de esta publicación.
      return await ComentarioService().obtenerComentarios(
        idPublicacion: widget.publicacion['id_publicacion'] as int,
        tokenSesion: widget.tokenSesion,
      );
    } on SesionInvalida {
      // Si la sesión caducó y la pantalla sigue abierta, regresa al usuario al login.
      if (mounted) {
        widget.volverAlLogin(context, aviso: 'La sesión terminó.');
      }
      // Vuelve a lanzar el error para que el FutureBuilder sepa que la carga falló.
      rethrow;
    }
  }

  // Muestra una ventana de confirmación y, si el usuario acepta, elimina el comentario en el servidor y actualiza la lista.
  Future<void> confirmarEliminacion(int idComentario) async {
    // Evita ejecutar otra eliminación si ya hay una en curso.
    if (_eliminando) return;

    // Abre un cuadro de diálogo preguntando al administrador si desea confirmar o cancelar el borrado.
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('¿Eliminar comentario?'),
        content: const Text('El comentario se quitará de la publicación.'),
        actions: [
          // Botón que cierra el diálogo devolviendo 'false' para cancelar la operación.
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          // Botón rojo que cierra el diálogo devolviendo 'true' para proceder con el borrado.
          ElevatedButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: rojo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    // Si la pantalla se cerró, el usuario canceló o ya hay un proceso activo, detiene la función.
    if (!mounted || confirmado != true || _eliminando) return;

    // Activa la bandera '_eliminando' para bloquear botones repetidos mientras responde el servidor.
    setState(() {
      _eliminando = true;
    });

    try {
      // Envía la orden de borrado al servicio indicando la publicación, el comentario y el token de sesión.
      await ComentarioService().eliminarComentario(
        idPublicacion: widget.publicacion['id_publicacion'] as int,
        idComentario: idComentario,
        tokenSesion: widget.tokenSesion,
      );

      // Verifica que la pantalla siga activa antes de actualizar la vista.
      if (!mounted) return;

      // Recargamos la lista después de que FastAPI confirma el borrado.
      final comentariosActualizados = cargarComentarios();
      setState(() {
        _comentarios = comentariosActualizados;
      });

      // Muestra un aviso temporal en la parte inferior confirmando la eliminación.
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Comentario eliminado.')));
    } on SesionInvalida {
      // Si la sesión caducó durante la petición, regresa al usuario al login.
      if (mounted) {
        widget.volverAlLogin(context, aviso: 'La sesión terminó.');
      }
    } on StateError catch (error) {
      // Si el servidor devolvió un error controlado, muestra su mensaje en la barra inferior.
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      // Si ocurre un fallo inesperado (como pérdida de red), muestra un mensaje general de error.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo confirmar el borrado.')),
      );
    } finally {
      // Al terminar (con éxito o con error), desactiva la bandera '_eliminando' para volver a habilitar los controles.
      if (mounted) {
        setState(() {
          _eliminando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Envuelve toda la vista para detectar toques o desplazamientos y mantener activa la sesión.
    return ActividadSesion(
      onActividad: () => widget.registrarActividad(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF5F7),
        // Barra superior con el logotipo en blanco y sin flecha automática de regreso.
        appBar: AppBar(
          backgroundColor: rojo,
          automaticallyImplyLeading: false,
          title: Image.asset(
            'assets/logo.png',
            height: 34,
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
        // Centra el contenido y limita su ancho máximo a 1000 píxeles para que luzca ordenado en pantallas grandes.
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Fila superior con el botón de regreso y el título principal de la sección.
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Volver a tus publicaciones',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: rojo),
                    ),
                    const Expanded(
                      child: Text(
                        'Moderación de comentarios',
                        style: TextStyle(
                          color: rojo,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tarjeta blanca que agrupa el título de la publicación y la lista de comentarios debajo.
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Encabezado interno con una línea vertical roja y el título de la publicación elegida.
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 30,
                              decoration: BoxDecoration(
                                color: rojo,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Publicación',
                                    style: TextStyle(
                                      color: rojo,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.publicacion['titulo']?.toString() ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Escucha el estado de '_comentarios' y muestra carga, error o la lista de comentarios.
                        FutureBuilder<ListaComentarios>(
                          future: _comentarios,
                          builder: (context, snapshot) {
                            // Mientras el servidor responde, muestra un círculo giratorio centrado.
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            // Si la consulta falló, muestra un aviso de error.
                            if (snapshot.hasError) {
                              return const Text(
                                'No se pudieron cargar los comentarios.',
                              );
                            }

                            // Toma la lista de comentarios recibida o usa una lista vacía como respaldo.
                            final ListaComentarios comentarios =
                                snapshot.data ?? [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Muestra el total de comentarios entre paréntesis.
                                Text(
                                  'Comentarios (${comentarios.length})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Si no hay comentarios, muestra un aviso; si existen, dibuja una tarjeta por cada uno.
                                if (comentarios.isEmpty)
                                  const Text(
                                    'Esta publicación todavía no tiene comentarios.',
                                  ),
                                for (final comentario in comentarios)
                                  tarjetaComentario(comentario),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Muestra el autor, el texto y el botón de eliminación.
  Widget tarjetaComentario(Map<String, dynamic> comentario) {
    // Construye una tarjeta con borde suave que muestra el avatar, nombre del autor, mensaje y botón de eliminar deshabilitado.
    return Card(
      color: const Color(0xFFFFF5F7),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFF1DAE1)),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFBD7DF),
          child: Icon(Icons.person_outline, color: rojo),
        ),
        title: Text(
          comentario['autor']?.toString() ?? 'Autor no disponible',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(comentario['comentario']?.toString() ?? ''),
        // Botón de eliminar actualmente desactivado ('onPressed: null').
        trailing: OutlinedButton.icon(
          onPressed: _eliminando
              ? null
              : () => confirmarEliminacion(comentario['id_comentario'] as int),
          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Eliminar'),
        ),
      ),
    );
  }
}
