// Importa los componentes visuales básicos de Material Design en Flutter.
import 'package:flutter/material.dart';

// Importa el contenedor que detecta actividad en la pantalla para mantener viva la sesión.
import '../widgets/actividad_sesion.dart';

// Pantalla que muestra las cuentas que puede gestionar el administrador.
class GestionarUsuariosPage extends StatelessWidget {
  // Constructor que solicita la función para registrar actividad del usuario en la vista.
  const GestionarUsuariosPage({
    super.key,
    required this.registrarActividad,
  });

  // Recibe la misma función que mantiene activa la sesión en Inicio.
  final Future<void> Function(BuildContext) registrarActividad;

  // Color rojo institucional reutilizado en barra superior, íconos y títulos.
  static const rojo = Color(0xFFB50020);

  @override
  Widget build(BuildContext context) {
    // Envuelve toda la pantalla para detectar interacciones y mantener activa la sesión.
    return ActividadSesion(
      onActividad: () => registrarActividad(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF5F7),

        // Mantiene la barra roja con el logo blanco y sin flecha automática de regreso.
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

        // Protege el contenido de los bordes físicos de la pantalla (como muescas o barras del sistema).
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

                // Muestra una tarjeta de ejemplo para revisar el diseño y oculta las barras de desplazamiento visuales.
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      scrollbars: false,
                    ),
                    child: ListView(
                      children: [
                        // Tarjeta blanca que representa a un usuario con su avatar, nombre, correo y menú de opciones.
                        Card(
                          color: Colors.white,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFBD7DF),
                              child: Icon(Icons.person_outline, color: rojo),
                            ),
                            title: const Text(
                              'Adriana Contreras',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text('adriana@ejemplo.com'),

                            // Abre las acciones de la cuenta desde los tres puntos.
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Opciones del usuario',
                              icon: const Icon(Icons.more_vert, color: rojo),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'rol',
                                  child: Text('Editar rol'),
                                ),
                                PopupMenuItem(
                                  value: 'estado',
                                  child: Text('Banear usuario'),
                                ),
                              ],
                            ),
                          ),
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