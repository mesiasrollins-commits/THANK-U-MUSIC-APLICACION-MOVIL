import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../widgets/actividad_sesion.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/post_card.dart';
import 'login_user_page.dart';

class InicioPantalla extends StatefulWidget {
  const InicioPantalla({
    super.key,
    required this.nombre,
    required this.rol,
    required this.correo,
    required this.tokenSesion,
    required this.authService,
  });

  final String nombre;
  final String rol;
  final String correo;
  final String tokenSesion;
  final AuthService authService;

  @override
  State<InicioPantalla> createState() => _InicioPantallaState();
}

class _InicioPantallaState extends State<InicioPantalla> {
  // Permite abrir y cerrar el menú del Scaffold que está debajo de la barra roja.
  final _panelKey = GlobalKey<ScaffoldState>();

  // Guarda la promesa (Future) con la lista de publicaciones para evitar que se vuelvan a descargar cada vez que se redibuja la pantalla.
  // Se marca como 'late final' porque se inicializará una única vez dentro de 'initState'.
  late final Future<List<Map<String, dynamic>>> _publicaciones;

  @override
  void initState() {
    super.initState();
    // Inicia la descarga de las publicaciones una sola vez en el momento en que se crea esta pantalla.
    _publicaciones = cargarPublicaciones();
  }

  // Solicita las publicaciones al servicio y redirige al login si el servidor indica que el token ya venció.
  Future<List<Map<String, dynamic>>> cargarPublicaciones() async {
    try {
      // Llama al servicio enviando el token actual de la sesión para traer los datos desde FastAPI.
      return await PostService().obtenerPublicaciones(widget.tokenSesion);
    } on SesionInvalida {
      // Verifica que la pantalla siga montada en pantalla antes de ejecutar la navegación.
      if (mounted) {
        volverAlLogin(
          context,
          aviso: 'La sesión terminó. Inicia sesión de nuevo.',
        );
      }
      // Vuelve a lanzar el error ('rethrow') para que un posible FutureBuilder sepa que la petición falló y no quede esperando indefinidamente.
      rethrow;
    }
  }

  // Conecta la detección de actividad de la pantalla con el servicio de autenticación y maneja el cierre automático si la sesión ya venció.
  Future<void> registrarActividad(BuildContext context) async {
    try {
      // Llama al servicio para renovar el tiempo de vida de la sesión en FastAPI (respetando el límite de 1 consulta por minuto).
      await widget.authService.registrarActividad(widget.tokenSesion);
    } on SesionInvalida {
      // Si el servidor responde que el token ya caducó o no es válido, redirige al usuario de inmediato a la pantalla de inicio de sesión con un aviso.
      volverAlLogin(
        context,
        aviso: 'La sesión terminó. Inicia sesión de nuevo.',
      );
    } catch (_) {
      // Ignora cualquier otro error temporal (como una caída momentánea de internet) sin sacar al usuario, permitiendo que el próximo movimiento vuelva a intentarlo.
    }
  }

  // Cierra la sesión en el servidor si hay conexión, pero siempre limpia la sesión local y redirige al login.
  Future<void> cerrarSesion(BuildContext context) async {
    try {
      // Intenta avisarle a FastAPI para que invalide el token activo en el servidor.
      await widget.authService.cerrarSesion(widget.tokenSesion);
    } catch (_) {
      // Si no hay internet o el servidor falla, no bloquea al usuario; el token expirará solo por inactividad en el backend.
    } finally {
      // Este bloque se ejecuta siempre (haya funcionado o fallado el servidor), garantizando que el usuario pueda volver al login.
      if (context.mounted) {
        volverAlLogin(context);
      }
    }
  }

  // Redirige al usuario a la pantalla de inicio de sesión reemplazando la vista actual y muestra un mensaje opcional (por ejemplo, si la sesión expiró).
  void volverAlLogin(BuildContext context, {String? aviso}) {
    // Verifica dos cosas: que la pantalla siga activa en memoria ('mounted') y que sea la ruta visible actual ('isCurrent').
    // Esto evita que se dispare una navegación duplicada si dos peticiones detectan la sesión vencida al mismo tiempo.
    if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;

    // Si se recibió un texto de aviso (como "La sesión terminó..."), muestra una barra emergente inferior antes de cambiar de pantalla.
    if (aviso != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(aviso)));
    }

    // Reemplaza la pantalla actual por 'LoginPage' para que el usuario no pueda regresar a la vista privada presionando el botón "Atrás" del dispositivo.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false, //elimina todas las pantallas anteriores del historial
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extrae únicamente el primer nombre de la cadena completa ('widget.nombre').
    // Primero quita espacios sobrantes al inicio y al final con 'trim()', luego corta el texto usando cualquier cantidad de espacios en blanco ('RegExp(r'\s+')') como separador y finalmente toma el primer elemento resultante ('first').
    final primerNombre = widget.nombre.trim().split(RegExp(r'\s+')).first;
    final esAdmin = widget.rol == 'administrador';

    return ActividadSesion(
      onActividad: () => registrarActividad(context),
      child: Scaffold(
        // Configura la barra superior de la aplicación (AppBar) con el estilo visual institucional.
        appBar: AppBar(
          // Pinta el fondo de la barra en un tono rojo oscuro.
          backgroundColor: const Color(0xFFB50020),
          // Define el color blanco como predeterminado para todos los iconos y textos dentro de la barra.
          foregroundColor: Colors.white,
          // Quita el margen horizontal entre el icono izquierdo ('leading') y el inicio del título ('title').
          titleSpacing: 0,
          // La hamburguesa abre el menú del administrador. Para el visor, por ahora solo se muestra el icono.
          leading: esAdmin
              ? IconButton(
                  icon: const Icon(Icons.menu, size: 28),
                  tooltip: 'Abrir menú',
                  onPressed: () => _panelKey.currentState?.openDrawer(),
                )
              : const Icon(Icons.menu, size: 28),
          // Alinea horizontalmente el separador y el logotipo dentro del espacio del título.
          title: Row(
            children: [
              // Crea una línea vertical delgada en blanco translúcido para dividir el menú del logo.
              Container(width: 1, height: 28, color: Colors.white70),
              // Inserta una separación horizontal entre la línea divisoria y la imagen.
              const SizedBox(width: 12),
              // Muestra la imagen del logotipo ubicada en 'assets/logo.png' con una altura fija.
              Image.asset(
                'assets/logo.png',
                height: 34,
                // Tiñe por completo la forma visible del archivo PNG en color blanco usando el modo de mezcla 'srcIn'.
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ],
          ),
        ),
        // El menú pertenece al cuerpo para que la barra roja siga visible al abrirlo.
        body: Scaffold(
          key: _panelKey,
          drawer: esAdmin
              ? AdminDrawer(
                  correo: widget.correo,
                  onCerrarSesion: () {
                    _panelKey.currentState?.closeDrawer();
                    cerrarSesion(context);
                  },
                )
              : null,
          // Define el color de fondo general de la pantalla en un tono rosado muy claro.
          backgroundColor: const Color(0xFFFFF5F7),
          // Agrega un margen interior alrededor de todo el contenido principal (izquierda, arriba, derecha y abajo).
          body: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            // Apila los elementos visuales de forma vertical, de arriba hacia abajo.
            child: Column(
              // Alinea los elementos hijos al inicio (borde izquierdo) de la columna.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Muestra el mensaje de bienvenida personalizado con el nombre recibido en el widget.
                Text(
                  'Bienvenido, $primerNombre',
                  style: const TextStyle(
                    color: Color(0xFFB50020),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Inserta una separación vertical vacía entre el saludo y el botón.
                const SizedBox(height: 16),

                // Hace que el bloque ocupe todo el espacio vertical restante dentro de la columna para que la lista pueda desplazarse sin desbordarse.
                Expanded(
                  // Escucha el estado de '_publicaciones' y reconstruye la interfaz automáticamente según vaya cambiando (cargando, error o listo).
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _publicaciones,
                    builder: (context, snapshot) {
                      // Mientras la petición HTTP sigue en curso, muestra una rueda giratoria centrada en la pantalla.
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Si ocurrió algún fallo al pedir o procesar los datos, muestra un mensaje de error centrado.
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'No se pudieron cargar las publicaciones.',
                          ),
                        );
                      }

                      // Extrae la lista de publicaciones recibida desde el servidor.
                      final publicaciones = snapshot.data;

                      // Si la lista llegó nula o vacía, informa al usuario que aún no hay contenido registrado.
                      if (publicaciones == null || publicaciones.isEmpty) {
                        return const Center(
                          child: Text('Todavía no hay publicaciones.'),
                        );
                      }

                      // Construye una lista desplazable que dibuja las tarjetas bajo demanda conforme el usuario baja por la pantalla.
                      return ListView.builder(
                        itemCount: publicaciones.length,
                        itemBuilder: (context, indice) {
                          // Obtiene el mapa de datos correspondiente a la publicación en la posición actual.
                          final publicacion = publicaciones[indice];

                          // Crea una tarjeta 'PostCard' pasando el título y el contenido, usando texto vacío ('') como respaldo si algún campo viene nulo.
                          return PostCard(
                            titulo: publicacion['titulo']?.toString() ?? '',
                            resumen: publicacion['contenido']?.toString() ?? '',
                          );
                        },
                      );
                    },
                  ),
                ),

                // Centra horizontalmente el botón dentro del ancho disponible de la pantalla.
                Center(
                  child: ElevatedButton(
                    // Al presionar el botón, llama a la función 'cerrarSesion' pasándole el contexto actual.
                    onPressed: () => cerrarSesion(context),
                    child: const Text('Cerrar sesión'),
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
