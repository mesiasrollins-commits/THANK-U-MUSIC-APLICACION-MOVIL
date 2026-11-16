// Importa los componentes visuales básicos de Material Design en Flutter.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Importa la excepción 'SesionInvalida' para detectar si la sesión del usuario ya caducó.
import '../services/auth_service.dart';
// Importa el servicio encargado de pedir los datos del perfil al servidor.
import '../services/perfil_service.dart';
// Importa el contenedor que detecta actividad en la pantalla para mantener viva la sesión.
import '../widgets/actividad_sesion.dart';

// Pantalla que muestra los datos personales de la cuenta que tiene la sesión iniciada.
class PerfilPage extends StatefulWidget {
  // Constructor que recibe el token de sesión y las funciones para renovar actividad o regresar al login.
  const PerfilPage({
    super.key,
    required this.tokenSesion,
    required this.registrarActividad,
    required this.volverAlLogin,
  });

  // Token de autorización del usuario conectado.
  final String tokenSesion;
  // Función asíncrona que avisa al servidor que el usuario sigue interactuando con la pantalla.
  final Future<void> Function(BuildContext) registrarActividad;
  // Función que redirige a la pantalla de inicio de sesión con un aviso opcional si el token vence.
  final void Function(BuildContext, {String? aviso}) volverAlLogin;

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  // Color rojo institucional reutilizado en la barra superior, el avatar y los íconos.
  static const rojo = Color(0xFFB50020);

  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _direccionController = TextEditingController();
  bool _guardando = false;
  bool _subiendoFoto = false;
  String? _fotoActualizadaUrl;
  // Guarda la promesa con los datos del perfil cargados al abrir la vista para no repetir peticiones al redibujar.
  late final Future<Map<String, dynamic>> _perfil = cargarPerfil();

  // Consulta los datos de la cuenta una sola vez al abrir la pantalla.
  Future<Map<String, dynamic>> cargarPerfil() async {
    try {
      // Pide al servicio la información del perfil usando el token actual.
      final perfil = await PerfilService().obtenerPerfil(widget.tokenSesion);

      if (mounted) {
        _nombreController.text = perfil['nombre']?.toString() ?? '';
        _correoController.text = perfil['correo']?.toString() ?? '';
        _direccionController.text = perfil['direccion']?.toString() ?? '';
      }

      return perfil;
    } on SesionInvalida {
      // Si la sesión caducó y la pantalla sigue abierta, regresa al usuario al login.
      if (mounted) {
        widget.volverAlLogin(context, aviso: 'La sesión terminó.');
      }
      // Vuelve a lanzar el error para que el FutureBuilder sepa que la carga falló.
      rethrow;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> guardarPerfil() async {
    if (_guardando) return;

    setState(() {
      _guardando = true;
    });

    try {
      final perfil = await PerfilService().actualizarPerfil(
        tokenSesion: widget.tokenSesion,
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
        direccion: _direccionController.text.trim(),
      );

      if (!mounted) return;

      _nombreController.text = perfil['nombre'] as String;
      _correoController.text = perfil['correo'] as String;
      _direccionController.text = perfil['direccion'] as String;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Cambios guardados.')));
    } on SesionInvalida {
      if (mounted) {
        widget.volverAlLogin(context, aviso: 'La sesión terminó.');
      }
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo confirmar el guardado.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  // Abre la galería para elegir una imagen, la sube al servidor y actualiza la foto de perfil en pantalla.
  Future<void> editarFotoPerfil() async {
    // Evita iniciar una nueva subida si ya hay otra en curso.
    if (_subiendoFoto) return;

    // Activa la bandera '_subiendoFoto' para deshabilitar el botón o mostrar carga mientras se procesa la imagen.
    setState(() {
      _subiendoFoto = true;
    });

    try {
      // Abre el selector de imágenes del dispositivo para que el usuario elija una foto de su galería.
      final archivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      // Si el usuario cerró la galería sin elegir imagen o la pantalla ya no está activa, detiene la función.
      if (archivo == null || !mounted) return;

      // Lee el contenido binario (bytes) de la imagen elegida para poder enviarla por red.
      final bytes = await archivo.readAsBytes();
      if (!mounted) return;

      // Envía la imagen al servidor mediante 'PerfilService' y recibe la nueva dirección web (URL) donde quedó guardada.
      final fotoUrl = await PerfilService().actualizarFoto(
        tokenSesion: widget.tokenSesion,
        bytes: bytes,
        nombreArchivo: archivo.name,
      );

      // Verifica que la pantalla siga visible antes de modificar la interfaz.
      if (!mounted) return;

      // Actualizamos el avatar con la URL que devuelve FastAPI.
      setState(() {
        _fotoActualizadaUrl = fotoUrl;
      });

      // Muestra un aviso breve en la parte inferior confirmando que la foto se guardó.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada.')),
      );
    } on SesionInvalida {
      // Si la sesión caducó durante el proceso, redirige al usuario a la pantalla de inicio de sesión.
      if (mounted) {
        widget.volverAlLogin(context, aviso: 'La sesión terminó.');
      }
    } on StateError catch (error) {
      // Si el servidor rechazó la imagen con un mensaje específico, lo muestra en la barra inferior.
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      // Si ocurre cualquier otro fallo (como pérdida de conexión), muestra un aviso general de error.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo confirmar el guardado de la foto.'),
        ),
      );
    } finally {
      // Al terminar (con éxito o con error), desactiva la bandera '_subiendoFoto' para volver a habilitar el control.
      if (mounted) {
        setState(() {
          _subiendoFoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Envuelve toda la pantalla para detectar interacciones y mantener activa la sesión.
    return ActividadSesion(
      onActividad: () => widget.registrarActividad(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF5F7),
        // Barra superior con el título 'Mi perfil' en letras blancas sobre fondo rojo.
        appBar: AppBar(
          title: const Text('Mi perfil'),
          backgroundColor: rojo,
          foregroundColor: Colors.white,
        ),
        // Escucha el estado de '_perfil' y dibuja la carga, un aviso de error o la tarjeta con los datos.
        body: FutureBuilder<Map<String, dynamic>>(
          future: _perfil,
          builder: (context, snapshot) {
            // Mientras el servidor responde, muestra un círculo giratorio centrado.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Si ocurrió un error o no llegaron datos, muestra un mensaje informativo centrado.
            final perfil = snapshot.data;
            if (snapshot.hasError || perfil == null) {
              return const Center(child: Text('No se pudo cargar tu perfil.'));
            }

            final fotoUrl =
                _fotoActualizadaUrl ?? perfil['foto_url']?.toString() ?? '';
            const iconoPerfil = Icon(
              Icons.person_outline,
              size: 48,
              color: rojo,
            );

            // Centra el contenido y limita su ancho máximo a 560 píxeles para que luzca ordenado en pantallas anchas.
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Tarjeta blanca que contiene el avatar circular y los campos informativos del usuario.
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Muestra la misma foto que el perfil web o el ícono si no hay foto.
                            Center(
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: const Color(0xFFFBD7DF),
                                child: fotoUrl.isEmpty
                                    ? iconoPerfil
                                    : ClipOval(
                                        child: Image.network(
                                          fotoUrl,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                          webHtmlElementStrategy:
                                              WebHtmlElementStrategy.prefer,
                                          errorBuilder: (_, __, ___) =>
                                              iconoPerfil,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: TextButton.icon(
                                onPressed: _subiendoFoto
                                    ? null
                                    : editarFotoPerfil,
                                style: TextButton.styleFrom(
                                  foregroundColor: rojo,
                                ),
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: Text(
                                  _subiendoFoto
                                      ? 'Subiendo foto…'
                                      : 'Editar foto de perfil',
                                ),
                              ),
                            ),
                            
                            // Muestra el nombre completo recibido del servidor en modo solo lectura.
                            campoPerfil(
                              'Nombre completo',
                              _nombreController,
                              Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            // Muestra el correo electrónico recibido del servidor en modo solo lectura.
                            campoPerfil(
                              'Correo electrónico',
                              _correoController,
                              Icons.mail_outline,
                            ),
                            const SizedBox(height: 16),
                            // Muestra la dirección recibida del servidor en modo solo lectura.
                            campoPerfil(
                              'Dirección',
                              _direccionController,
                              Icons.location_on_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _guardando ? null : guardarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rojo,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _guardando ? 'Guardando…' : 'Guardar cambios',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Muestra un campo editable y registra actividad mientras el usuario escribe.
  Widget campoPerfil(
    String etiqueta,
    TextEditingController controlador,
    IconData icono,
  ) {
    // Crea un cuadro de texto conectado a un controlador para capturar lo que escribe el usuario.
    return TextFormField(
      controller: controlador,
      // Bloquea la edición del campo mientras los datos se están enviando al servidor ('_guardando').
      enabled: !_guardando,
      // Cada vez que el usuario teclea o borra una letra, avisa que sigue activo para evitar que caduque la sesión.
      onChanged: (_) => widget.registrarActividad(context),
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, color: rojo),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
