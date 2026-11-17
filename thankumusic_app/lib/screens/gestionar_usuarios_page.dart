import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/usuario_service.dart';
import '../widgets/actividad_sesion.dart';

// Pantalla que muestra las cuentas que puede gestionar el administrador.
class GestionarUsuariosPage extends StatefulWidget {
  const GestionarUsuariosPage({
    super.key,
    required this.tokenSesion,
    required this.registrarActividad,
    required this.volverAlLogin,
  });

  final String tokenSesion;

  // Recibe la misma función que mantiene activa la sesión en Inicio.
  final Future<void> Function(BuildContext) registrarActividad;
  final void Function(BuildContext, {String? aviso}) volverAlLogin;

  @override
  State<GestionarUsuariosPage> createState() => _GestionarUsuariosPageState();
}

class _GestionarUsuariosPageState extends State<GestionarUsuariosPage> {
  static const rojo = Color(0xFFB50020);

  // Guarda la consulta para que Flutter no vuelva a pedir la lista en cada redibujo.
  late Future<List<Map<String, dynamic>>> _usuarios;
  bool _guardandoUsuario = false;

  @override
  void initState() {
    super.initState();
    _usuarios = cargarUsuarios();
  }

  Future<List<Map<String, dynamic>>> cargarUsuarios() async {
    try {
      return await UsuarioService().obtenerUsuarios(widget.tokenSesion);
    } on SesionInvalida {
      // Si la sesión venció, vuelve al login mientras esta pantalla siga abierta.
      if (mounted) {
        widget.volverAlLogin(context, aviso: 'La sesión terminó.');
      }
      rethrow;
    }
  }

  // Abre el mismo diálogo para cambiar el rol o el estado de una cuenta.
  Future<void> editarUsuario(
    Map<String, dynamic> usuario, {
    required String campo,
  }) async {
    // Evita abrir otro diálogo mientras se guarda un cambio.
    if (_guardandoUsuario) return;

    // Determina si se editará el rol o el estado, guarda el valor actual del usuario y prepara la variable temporal para el nuevo valor.
    final editandoRol = campo == 'rol';
    final valorActual = usuario[campo] as String;
    var valorElegido = valorActual;

    // Define el título de la ventana según si se cambia el rol o si se va a banear/desbanear la cuenta.
    final titulo = editandoRol
        ? 'Editar usuario'
        : (valorActual == 'baneado' ? 'Desbanear usuario' : 'Banear usuario');

    // Abre el diálogo con el valor actual seleccionado.
    final nuevoValor = await showDialog<String>(
      context: context,
      builder: (contextoDialogo) {
        // Permite redibujar únicamente el interior de la ventana emergente cuando el administrador cambia una selección.
        return StatefulBuilder(
          builder: (context, actualizarDialogo) {
            // Aplica el mismo estilo a los dos botones de rol.
            Widget opcionRol(String valor, String etiqueta, IconData icono) {
              final seleccionado = valorElegido == valor;
              final color = seleccionado ? Colors.white : rojo;

              return ChoiceChip(
                label: Text(etiqueta),
                avatar: Icon(icono, color: color),
                selected: seleccionado,
                showCheckmark: false,
                selectedColor: rojo,
                backgroundColor: const Color(0xFFFFF5F7),
                labelStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                side: const BorderSide(color: rojo),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                onSelected: (_) {
                  actualizarDialogo(() {
                    valorElegido = valor;
                  });
                },
              );
            }

            // Construye la ventana emergente con fondo blanco, esquinas redondeadas e identidad visual en rojo.
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    editandoRol ? Icons.manage_accounts_outlined : Icons.block,
                    color: rojo,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        color: rojo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(contextoDialogo).pop(),
                    icon: const Icon(Icons.close, color: rojo),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Muestra el nombre del usuario seleccionado.
                    Text(
                      usuario['nombre']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 28),
                    // Muestra el subtítulo correspondiente según si se modifica el rol o el estado de la cuenta.
                    Text(
                      editandoRol ? 'Rol del usuario' : 'Estado del usuario',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    // Si se edita el rol, muestra los dos botones en forma de píldora; si se edita el estado, muestra el interruptor.
                    if (editandoRol)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          opcionRol('visor', 'Normal', Icons.person_outline),
                          opcionRol(
                            'administrador',
                            'Administrador',
                            Icons.admin_panel_settings_outlined,
                          ),
                        ],
                      )
                    else
                      // Encendido significa baneado y apagado significa activo.
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          valorElegido == 'baneado' ? 'Baneado' : 'Activo',
                        ),
                        value: valorElegido == 'baneado',
                        activeTrackColor: rojo,
                        onChanged: (banear) {
                          actualizarDialogo(() {
                            valorElegido = banear ? 'baneado' : 'activo';
                          });
                        },
                      ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                // Cierra la ventana sin guardar cambios.
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: rojo,
                    side: const BorderSide(color: rojo),
                  ),
                  onPressed: () => Navigator.of(contextoDialogo).pop(),
                  child: const Text('Cancelar'),
                ),
                // Desactiva el botón si el valor elegido es igual al original; al pulsar, cierra la ventana devolviendo el nuevo valor.
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: rojo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: valorElegido == valorActual
                      ? null
                      : () => Navigator.of(contextoDialogo).pop(valorElegido),
                  child: const Text('Guardar cambios'),
                ),
              ],
            );
          },
        );
      },
    );

    // Si la pantalla se cerró, el usuario canceló el diálogo o ya hay un guardado en curso, detiene la función.
    if (!mounted || nuevoValor == null || _guardandoUsuario) return;

    // Activa la bandera '_guardandoUsuario' para evitar envíos duplicados mientras responde el servidor.
    setState(() => _guardandoUsuario = true);

    try {
      // Envía al servidor el cambio de rol o estado mediante 'UsuarioService'.
      await UsuarioService().actualizarUsuario(
        widget.tokenSesion,
        usuario['id_usuario'] as int,
        campo: campo,
        valor: nuevoValor,
      );

      // Verifica que la pantalla siga visible antes de actualizar la interfaz.
      if (!mounted) return;

      // Inicia la consulta fuera de setState y actualiza la lista.
      final consultaUsuarios = cargarUsuarios();
      setState(() {
        _usuarios = consultaUsuarios;
      });

      // Elige el texto de confirmación según la acción realizada y lo muestra en una barra inferior.
      final mensaje = editandoRol
          ? 'Rol actualizado correctamente.'
          : (nuevoValor == 'baneado'
                ? 'Usuario baneado.'
                : 'Usuario desbaneado.');

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
    } on SesionInvalida {
      // Si la sesión caducó durante la operación, redirige al usuario al inicio de sesión.
      if (mounted) {
        widget.volverAlLogin(context, aviso: 'La sesión terminó.');
      }
    } catch (error) {
      // Si ocurre un fallo, muestra el mensaje exacto del servidor (si es StateError) o un aviso general de error.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message
                : 'No se pudo guardar el cambio.',
          ),
        ),
      );
    } finally {
      // Al finalizar (con éxito o con error), desactiva la bandera '_guardandoUsuario'.
      if (mounted) {
        setState(() => _guardandoUsuario = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActividadSesion(
      onActividad: () => widget.registrarActividad(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF5F7),

        // Mantiene la barra roja con el logo blanco.
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

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // La flecha queda debajo de la barra roja, igual que en Registro.
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Volver al inicio',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: rojo),
                    ),
                    const Expanded(
                      child: Text(
                        'Gestión de usuarios',
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

                // Escucha la consulta y muestra una tarjeta por cada usuario recibido.
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _usuarios,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        final error = snapshot.error;
                        final mensaje = error is StateError
                            ? error.message
                            : 'No se pudieron cargar los usuarios.';
                        return Center(child: Text(mensaje));
                      }

                      final usuarios = snapshot.data ?? [];
                      if (usuarios.isEmpty) {
                        return const Center(
                          child: Text('Todavía no hay usuarios registrados.'),
                        );
                      }

                      return ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: ListView.builder(
                          itemCount: usuarios.length,
                          itemBuilder: (context, indice) {
                            final usuario = usuarios[indice];
                            final esAdministrador =
                                usuario['rol'] == 'administrador';
                            final fotoUrl =
                                usuario['foto_url']?.toString() ?? '';
                            const iconoPerfil = Icon(
                              Icons.person_outline,
                              color: rojo,
                            );
                            final estaBaneado = usuario['estado'] == 'baneado';

                            return Card(
                              color: Colors.white,
                              child: ListTile(
                                // Coloca a la izquierda del elemento un avatar circular de 20 píxeles de radio (40 px de diámetro) con fondo rosa claro.
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFFFBD7DF),
                                  // Si el usuario no tiene foto guardada ('fotoUrl.isEmpty'), muestra el ícono genérico de perfil.
                                  child: fotoUrl.isEmpty
                                      ? iconoPerfil
                                      // Si tiene URL de foto, recorta la imagen en forma ovalada/circular para que encaje en el avatar.
                                      : ClipOval(
                                          child: Image.network(
                                            fotoUrl,
                                            width: 40,
                                            height: 40,
                                            // Ajusta la imagen para llenar todo el círculo sin deformarla, recortando los bordes sobrantes.
                                            fit: BoxFit.cover,
                                            // Permite que en Flutter Web use un elemento HTML alternativo si falla la carga directa por permisos de red (CORS).
                                            webHtmlElementStrategy:
                                                WebHtmlElementStrategy.fallback,
                                            // Si la imagen no logra descargarse o el enlace está roto, muestra el ícono de perfil centrado como respaldo.
                                            errorBuilder: (_, __, ___) =>
                                                const Center(
                                                  child: iconoPerfil,
                                                ),
                                          ),
                                        ),
                                ),
                                title: Text(
                                  usuario['nombre']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Amplía el espacio vertical de la fila (ListTile) para acomodar cómodamente tres líneas de información (título + dos líneas de subtítulo).
                                isThreeLine: true,
                                // Coloca debajo del nombre del usuario una columna vertical alineada a la izquierda con su correo y su rol.
                                subtitle: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Muestra el correo electrónico del usuario (o texto vacío si llega nulo).
                                    Text(usuario['correo']?.toString() ?? ''),
                                    // Muestra en negritas el tipo de cuenta: 'Administrador' en rojo institucional o 'Normal' en gris oscuro.
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          esAdministrador
                                              ? 'Administrador'
                                              : 'Normal',
                                          style: TextStyle(
                                            color: esAdministrador
                                                ? rojo
                                                : Colors.black54,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (estaBaneado)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFBD7DF),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.block,
                                                  size: 14,
                                                  color: rojo,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Baneado',
                                                  style: TextStyle(
                                                    color: rojo,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),

                                // Abre las acciones de la cuenta desde los tres puntos.
                                trailing: PopupMenuButton<String>(
                                  tooltip: 'Opciones del usuario',
                                  onSelected: (opcion) {
                                    editarUsuario(usuario, campo: opcion);
                                  },
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: rojo,
                                  ),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'rol',
                                      child: Text('Editar rol'),
                                    ),
                                    PopupMenuItem(
                                      value: 'estado',
                                      child: Text(
                                        estaBaneado
                                            ? 'Desbanear usuario'
                                            : 'Banear usuario',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
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
