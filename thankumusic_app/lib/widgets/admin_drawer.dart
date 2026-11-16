import 'package:flutter/material.dart';

// Define el menú lateral desplegable (Drawer) exclusivo para el panel del administrador.
class AdminDrawer extends StatelessWidget {
  // Constructor que exige el correo del usuario conectado y la función que se ejecutará al cerrar sesión.
  const AdminDrawer({
    super.key,
    required this.correo,
    required this.onAgregarPublicacion,
    required this.onCerrarSesion,
    required this.onEditarPublicaciones,
  });

  // Guarda el correo electrónico que se mostrará en la cabecera del menú.
  final String correo;
  final VoidCallback onAgregarPublicacion;
  // Función sin retorno que dispara el proceso de cierre de sesión al tocar la última opción.
  final VoidCallback onCerrarSesion;
  final VoidCallback onEditarPublicaciones;


  // Define el color rojo institucional reutilizable para iconos, bordes y textos destacados dentro de este menú.
  static const rojo = Color(0xFFB50020);

  @override
  Widget build(BuildContext context) {
    // Construye el panel deslizable lateral con un fondo rosado muy claro.
    return Drawer(
      backgroundColor: const Color(0xFFFFF5F7),
      // Organiza los elementos del menú en una lista desplazable verticalmente con margen interior.
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabecera del menú que muestra el avatar, el rol y el correo del administrador.
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            // Círculo rosado con el icono de perfil en el lado izquierdo.
            leading: const CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFFFBD7DF),
              child: Icon(Icons.person_outline, color: rojo, size: 32),
            ),
            // Título en negritas y color rojo institucional.
            title: const Text(
              'Administrador',
              style: TextStyle(color: rojo, fontWeight: FontWeight.bold),
            ),
            // Muestra debajo el correo recibido por parámetro.
            subtitle: Text(correo),
          ),
          // Línea horizontal que separa la cabecera de las opciones de navegación.
          const Divider(),
          // Opción principal marcada como seleccionada actualmente ('Inicio') con fondo resaltado y esquinas redondeadas.
          ListTile(
            leading: const Icon(Icons.home_outlined, color: rojo),
            title: const Text('Inicio'),
            selected: true,
            selectedColor: rojo,
            selectedTileColor: const Color(0xFFFBD7DF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // Al tocar 'Inicio', simplemente cierra el menú lateral regresando a la pantalla que ya está abierta.
            onTap: () => Navigator.of(context).pop(),
          ),
          // Lista de opciones del menú generadas con el método auxiliar 'opcion' (aún sin acción asignada excepto la última).
          opcion(Icons.person_outline, 'Mi perfil'),
          opcion(Icons.person_add_alt_1, 'Registrar usuario'),
          opcion(Icons.groups_outlined, 'Gestionar usuarios'),
          opcion(
            Icons.post_add,
            'Agregar publicación',
            onTap: onAgregarPublicacion,
          ),
          opcion(Icons.edit_outlined, 'Editar publicaciones',onTap: onEditarPublicaciones),
          // Última opción que ejecuta la función 'onCerrarSesion' al ser presionada.
          opcion(Icons.logout, 'Cerrar sesión', onTap: onCerrarSesion),
        ],
      ),
    );
  }

  // Método auxiliar que construye cada fila del menú con su icono, texto, acción opcional y una línea divisoria inferior.
  Widget opcion(IconData icono, String titulo, {VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icono, color: rojo),
          title: Text(titulo),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
