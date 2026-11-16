import 'dart:typed_data';

// Importa los componentes visuales básicos de Material Design en Flutter.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Importa el detector de actividad para mantener activa la sesión del administrador mientras escribe.
import '../widgets/actividad_sesion.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';

// Pantalla con formulario para redactar y agregar una nueva publicación al blog.
class AddBlogPage extends StatefulWidget {
  // Constructor que recibe la función encargada de registrar la actividad del usuario.
  const AddBlogPage({
    super.key,
    required this.registrarActividad,
    required this.tokenSesion,
    required this.volverAlLogin,
    this.publicacion,
  });

  // Función asíncrona que avisa al servidor que el administrador sigue usando la pantalla.
  final Future<void> Function(BuildContext) registrarActividad;
  final String tokenSesion;
  final void Function(BuildContext, {String? aviso}) volverAlLogin;
  // Si recibimos una publicación, abrimos el formulario en modo edición.
  final Map<String, dynamic>? publicacion;

  @override
  State<AddBlogPage> createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  // Define el color rojo institucional reutilizable en los elementos de esta pantalla.
  static const rojo = Color(0xFFB50020);

  // Guardamos lo que escribe el administrador en cada campo.
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  // Guarda los datos crudos (bytes) de la imagen elegida para mostrarla en vista previa y enviarla al servidor.
  Uint8List? _portada;
  String? _etiqueta;
  // Bandera que indica si ya se está enviando la publicación al servidor, para evitar envíos repetidos.
  bool _publicando = false;

  // Muestra un mensaje corto en la parte inferior de la pantalla (SnackBar) solo si la vista sigue abierta.
  void mostrarAviso(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> confirmarCancelacion() async {
    final opcion = await showDialog<String>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('¿Qué quieres hacer con esta publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(),
            child: const Text('Continuar'),
          ),
          if (widget.publicacion == null)
            OutlinedButton(
              onPressed: () => Navigator.of(contextoDialogo).pop('borrador'),
              child: const Text('Guardar como borrador'),
            ),
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop('descartar'),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (opcion == 'borrador') {
      await publicar(estado: 'borrador');
    } else if (opcion == 'descartar') {
      Navigator.of(context).pop();
    }
  }

  // Revisa que todos los datos estén completos, envía la publicación al servidor y cierra la pantalla si todo salió bien.
  Future<void> publicar({String estado = 'publicada'}) async {
    // Si ya hay una publicación enviándose en este momento, detiene la función para evitar duplicados.
    if (_publicando) return;

    // Guarda en variables locales los valores actuales del formulario.
    final titulo = _tituloController.text.trim();
    final contenido = _contenidoController.text;
    final etiqueta = _etiqueta;
    final portada = _portada;
    final publicacion = widget.publicacion;

    if (titulo.isEmpty || contenido.trim().isEmpty || etiqueta == null) {
      mostrarAviso('Completa el título, el contenido y la etiqueta.');
      return;
    }

    // La portada es obligatoria al crear. En edición podemos usar la que ya está guardada.
    if (publicacion == null && portada == null) {
      mostrarAviso('Agrega una portada.');
      return;
    }

    // Activa la bandera '_publicando' y redibuja la pantalla (por ejemplo, para deshabilitar el botón mientras sube).
    setState(() {
      _publicando = true;
    });

    try {
      // Llama al servicio para subir los textos y la imagen al servidor FastAPI.
      final servicio = PostService();

      if (publicacion == null) {
        // Crea una entrada nueva con el estado elegido en el formulario.
        await servicio.crearPublicacion(
          tokenSesion: widget.tokenSesion,
          titulo: titulo,
          contenido: contenido,
          etiqueta: etiqueta,
          portada: portada!,
          estado: estado,
        );
      } else {
        // Actualiza la entrada existente. Si era borrador, la publica.
        await servicio.editarPublicacion(
          idPublicacion: publicacion['id_publicacion'] as int,
          tokenSesion: widget.tokenSesion,
          titulo: titulo,
          contenido: contenido,
          etiqueta: etiqueta,
          publicar: publicacion['estado'] == 'borrador',
          portada: portada,
        );
      }
    } on SesionInvalida {
      // Si el servidor avisa que la sesión caducó, regresa al usuario al inicio de sesión y detiene la función.
      if (mounted) {
        widget.volverAlLogin(context, aviso: 'La sesión terminó.');
      }
      return;
    } on StateError catch (error) {
      // Si el servidor devolvió un error específico (como formato inválido o falta de permisos), muestra ese mensaje y detiene el proceso.
      mostrarAviso(error.message);
      return;
    } catch (_) {
      // Si ocurre un fallo inesperado (como corte de red o tiempo agotado), advierte al usuario que revise antes de volver a intentarlo.
      mostrarAviso(
        'No se pudo confirmar la publicación. Revisa el blog antes de reintentar.',
      );
      return;
    } finally {
      // Sin importar si tuvo éxito o falló, al terminar apaga la bandera '_publicando' para reactivar la pantalla.
      if (mounted) {
        setState(() {
          _publicando = false;
        });
      }
    }

    // Si todo se guardó correctamente y la pantalla sigue abierta, la cierra devolviendo 'true' para que el blog recargue la lista.
    if (!mounted) return;
    Navigator.of(context).pop(estado);
  }

  // Abre la galería del dispositivo o explorador de archivos para que el usuario elija una imagen de portada.
  Future<void> elegirPortada() async {
    try {
      // Llama al selector de imágenes indicando que busque en la galería.
      final archivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      // Si se cancela el selector, conservamos la portada anterior.
      if (archivo == null) return;

      // Lee todo el contenido de la imagen seleccionada en forma de bytes en memoria (compatible tanto con celular como con web).
      final bytes = await archivo.readAsBytes();

      // Verifica que la pantalla siga abierta antes de actualizar la vista.
      if (!mounted) return;
      // Guarda los bytes en '_portada' y redibuja la pantalla para mostrar la vista previa de la foto.
      setState(() {
        _portada = bytes;
      });
    } catch (error) {
      debugPrint('Error al elegir portada: $error');

      // Si ocurre algún fallo al abrir o leer el archivo, muestra un aviso rápido en la parte inferior de la pantalla.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la imagen.')),
      );
    }
  }

  // Se ejecuta una sola vez al abrir la pantalla para rellenar los campos si se está editando una publicación existente.
  @override
  void initState() {
    super.initState();

    // Revisa si la pantalla recibió una publicación; si es nula (modo crear nuevo), deja los campos vacíos y sale.
    final publicacion = widget.publicacion;
    if (publicacion == null) return;

    // Carga el título y el contenido actuales dentro de los cuadros de texto del formulario.
    _tituloController.text = publicacion['titulo']?.toString() ?? '';
    _contenidoController.text = publicacion['contenido']?.toString() ?? '';

    // El selector solo puede mostrar valores que estén entre sus opciones.
    const etiquetas = [
      'analisis',
      'resena',
      'recomendacion',
      'Aviso',
      'Conciertos',
    ];
    final etiqueta = publicacion['tags']?.toString();
    // Si la etiqueta guardada coincide con una de las opciones válidas, la deja preseleccionada en el menú desplegable.
    if (etiquetas.contains(etiqueta)) {
      _etiqueta = etiqueta;
    }
  }

  @override
  // Se ejecuta al cerrar esta pantalla para liberar de memoria los controladores de texto.
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verifica si se recibió una publicación previa para saber si la pantalla está en modo edición (true) o creación nueva (false).
    final esEdicion = widget.publicacion != null;
    final esBorrador = widget.publicacion?['estado'] == 'borrador';
    final textoGuardar = esEdicion && !esBorrador
        ? 'Guardar cambios'
        : 'Publicar';
    // Obtiene la dirección web (URL) de la imagen que ya tenía guardada la publicación, si es que existe.
    final imagenActualUrl = widget.publicacion?['imagen_url']?.toString();
    // Comprueba si hay una imagen para mostrar, ya sea una foto recién elegida desde el dispositivo ('_portada') o la que ya estaba subida en el servidor ('imagenActualUrl').
    final hayPortada =
        _portada != null || (imagenActualUrl?.isNotEmpty ?? false);
    // Envuelve toda la vista para detectar interacciones (toques o desplazamientos) y renovar la sesión.
    return ActividadSesion(
      onActividad: () => widget.registrarActividad(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF5F7),
        // Barra superior institucional sin flecha automática de regreso.
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
        // Centra el contenido y limita su ancho máximo a 760 píxeles para que se vea ordenado en pantallas grandes o web.
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            // Lista desplazable que contiene el encabezado y la tarjeta con el formulario.
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Fila superior con el botón para regresar al listado del blog y el título de la pantalla.
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Volver al blog',
                      icon: const Icon(Icons.arrow_back, color: rojo),
                    ),
                    Expanded(
                      child: Text(
                        'Agregar publicación',
                        style: TextStyle(
                          color: rojo,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Tarjeta blanca que agrupa los campos de entrada del formulario.
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Recorta todo el recuadro de la portada para darle esquinas redondeadas.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          // Fija una altura de 170 píxeles para el área de vista previa de la imagen.
                          child: SizedBox(
                            height: 170,
                            // Permite apilar elementos uno encima del otro (la imagen de fondo y el botón flotante encima).
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Si todavía no se ha elegido ninguna imagen, muestra un recuadro rosado tocable para seleccionarla.
                                if (!hayPortada)
                                  Material(
                                    color: const Color(0xFFFBD7DF),
                                    // Detecta el toque sobre todo el recuadro y abre la galería de imágenes.
                                    child: InkWell(
                                      onTap: elegirPortada,
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            color: rojo,
                                            size: 48,
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'Agregar portada',
                                            style: TextStyle(
                                              color: rojo,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                // Si ya hay una imagen seleccionada, la dibuja directamente desde memoria cubriendo todo el recuadro sin deformarse.
                                // Si el usuario eligió una imagen nueva desde su dispositivo, la dibuja directamente desde memoria cubriendo el recuadro.
                                else if (_portada != null)
                                  Image.memory(_portada!, fit: BoxFit.cover)
                                // Si no eligió una foto nueva (modo edición), descarga y muestra la imagen que ya estaba guardada en el servidor.
                                else
                                  Image.network(
                                    imagenActualUrl!,
                                    fit: BoxFit.cover,
                                    // Usa la etiqueta HTML nativa en navegadores web para evitar bloqueos al cargar imágenes desde el servidor.
                                    webHtmlElementStrategy:
                                        WebHtmlElementStrategy.prefer,
                                    // Si la imagen no se puede descargar o el enlace falla, muestra el ícono de imagen rota centrado.
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                                // Si existe alguna portada visible (nueva o anterior), permite mostrar encima el botón para cambiarla.
                                if (hayPortada)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: OutlinedButton.icon(
                                      onPressed: elegirPortada,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: rojo,
                                        backgroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('Editar portada'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Agrega una separación vertical debajo del recuadro de la portada.
                        const SizedBox(height: 16),
                        // Etiqueta y cuadro de texto para el título, con límite máximo de 200 caracteres.
                        const Text('Editar título'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _tituloController,
                          maxLength: 200,
                          // Cada vez que se escribe una letra, renueva la actividad de la sesión.
                          onChanged: (_) => widget.registrarActividad(context),
                          decoration: const InputDecoration(
                            hintText: 'Ingresa un título',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        // Línea horizontal que separa visualmente el campo del título y el del contenido.
                        const Divider(),
                        // Etiqueta y área de texto multilínea para el cuerpo de la publicación, con límite de 15,000 caracteres.
                        const Text('Editar contenido'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _contenidoController,
                          minLines: 4,
                          maxLines: 8,
                          maxLength: 15000,
                          // Renueva la actividad de la sesión mientras el administrador redacta.
                          onChanged: (_) => widget.registrarActividad(context),
                          decoration: const InputDecoration(
                            hintText:
                                'Escribe el contenido de la publicación...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        // Línea horizontal que separa el campo de contenido de la sección de etiquetas.
                        const Divider(),
                        // Título de la sección del selector de categoría.
                        const Text('Etiquetas'),
                        const SizedBox(height: 6),
                        // Menú desplegable integrado en el formulario para elegir una etiqueta de tipo texto.
                        DropdownButtonFormField<String>(
                          // Muestra como opción elegida el valor que esté guardado actualmente en la variable '_etiqueta'.
                          initialValue: _etiqueta,
                          // Hace que el menú ocupe todo el ancho disponible de la tarjeta.
                          isExpanded: true,
                          // Configura el texto de ayuda cuando no hay nada elegido y le pone un borde rectangular.
                          decoration: const InputDecoration(
                            hintText: 'Selecciona una etiqueta',
                            border: OutlineInputBorder(),
                          ),
                          // Lista de opciones disponibles: 'value' es el dato exacto que se enviará al servidor y 'child' es el texto bonito que ve el usuario.
                          items: const [
                            DropdownMenuItem(
                              value: 'analisis',
                              child: Text('Análisis'),
                            ),
                            DropdownMenuItem(
                              value: 'resena',
                              child: Text('Reseña'),
                            ),
                            DropdownMenuItem(
                              value: 'recomendacion',
                              child: Text('Recomendación'),
                            ),
                            DropdownMenuItem(
                              value: 'Aviso',
                              child: Text('Aviso'),
                            ),
                            DropdownMenuItem(
                              value: 'Conciertos',
                              child: Text('Conciertos'),
                            ),
                          ],
                          // Se ejecuta cada vez que el usuario elige una opción diferente en la lista.
                          onChanged: (valor) {
                            // Actualiza la variable '_etiqueta' con la nueva selección y redibuja el selector.
                            setState(() {
                              _etiqueta = valor;
                            });
                            // Avisa al servidor que el administrador sigue activo en la pantalla.
                            widget.registrarActividad(context);
                          },
                        ),
                        // Inserta un espacio vertical entre el selector de etiquetas y la fila de botones inferiores.
                        const SizedBox(height: 16),
                        // Alinea los botones a la derecha y, si la pantalla es muy estrecha, los acomoda uno debajo del otro automáticamente para evitar desbordamientos.
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            // Botón con borde rojo para cancelar y regresar a la pantalla anterior; se deshabilita ('null') si ya se está enviando la publicación.
                            OutlinedButton(
                              onPressed: _publicando
                                  ? null
                                  : confirmarCancelacion,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: rojo,
                                side: const BorderSide(color: rojo),
                              ),
                              child: const Text('Cancelar'),
                            ),

                            // Botón principal relleno de rojo para guardar y publicar; se bloquea mientras se envía y cambia su texto a 'Publicando…' para dar aviso visual.
                            ElevatedButton(
                              onPressed: _publicando ? null : publicar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: rojo,
                                foregroundColor: Colors.white,
                              ),
                              // Muestra 'Guardando…' mientras los datos se están enviando al servidor; cuando no está guardando, muestra el texto definido en 'textoGuardar'.
                              child: Text(
                                _publicando ? 'Guardando…' : textoGuardar,
                              ),
                            ),
                          ],
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
}
