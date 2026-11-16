import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/comentario_service.dart';
import '../widgets/actividad_sesion.dart';

class ModeracionComentariosPage extends StatefulWidget {
  const ModeracionComentariosPage({
    super.key,
    required this.publicacion,
    required this.tokenSesion,
    required this.registrarActividad,
    required this.volverAlLogin,
  });

  final Map<String, dynamic> publicacion;
  final String tokenSesion;
  final Future<void> Function(BuildContext) registrarActividad;
  final void Function(BuildContext, {String? aviso}) volverAlLogin;

  @override
  State<ModeracionComentariosPage> createState() =>
      _ModeracionComentariosPageState();
}

class _ModeracionComentariosPageState
    extends State<ModeracionComentariosPage> {
  late final Future<ListaComentarios> _comentarios = cargarComentarios();

  // Cargamos los comentarios de la entrada seleccionada.
  Future<ListaComentarios> cargarComentarios() async {
    try {
      return await ComentarioService().obtenerComentarios(
        idPublicacion: widget.publicacion['id_publicacion'] as int,
        tokenSesion: widget.tokenSesion,
      );
    } on SesionInvalida {
      if (mounted) {
        widget.volverAlLogin(context, aviso: 'La sesión terminó.');
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActividadSesion(
      onActividad: () => widget.registrarActividad(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF5F7),
        appBar: AppBar(
          title: const Text('Moderación de comentarios'),
          backgroundColor: const Color(0xFFB50020),
          foregroundColor: Colors.white,
        ),
        body: FutureBuilder<ListaComentarios>(
          future: _comentarios,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('No se pudieron cargar los comentarios.'),
              );
            }

            final ListaComentarios comentarios = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.publicacion['titulo']?.toString() ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (comentarios.isEmpty)
                  const Text('Esta publicación todavía no tiene comentarios.'),
                for (final comentario in comentarios)
                  Card(
                    child: ListTile(
                      title: Text(comentario['autor']?.toString() ?? ''),
                      subtitle: Text(
                        comentario['comentario']?.toString() ?? '',
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}