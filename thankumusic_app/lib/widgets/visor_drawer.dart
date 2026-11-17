import 'package:flutter/material.dart';

import 'avatar_perfil.dart';

class VisorDrawer extends StatelessWidget {
  const VisorDrawer({
    super.key,
    required this.onMiPerfil,
    required this.onCerrarSesion,
    required this.nombre,
    this.fotoUrl,
  });

  final VoidCallback onMiPerfil;
  final VoidCallback onCerrarSesion;
  final String? fotoUrl;
  final String nombre;

  static const rojo = Color(0xFFB50020);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFFF5F7),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 12),
            leading: AvatarPerfil(fotoUrl: fotoUrl),
            title: Text(
              nombre,
              style: const TextStyle(color: rojo, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: rojo),
            title: const Text('Inicio'),
            onTap: () => Navigator.of(context).pop(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_outline, color: rojo),
            title: const Text('Mi perfil'),
            onTap: onMiPerfil,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: rojo),
            title: const Text('Cerrar sesión'),
            onTap: onCerrarSesion,
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
