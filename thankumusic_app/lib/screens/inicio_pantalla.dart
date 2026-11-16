import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_user_page.dart';

class InicioPantalla extends StatelessWidget {
  // Constructor constante de la pantalla que exige ('required') recibir el nombre del usuario y su token de sesión cada vez que se abra esta vista.
  const InicioPantalla({
    super.key,
    required this.nombre,
    required this.tokenSesion,
  });

  // Variable inmutable ('final') que guarda el nombre del usuario para mostrarlo en la interfaz (por ejemplo, en el saludo).
  final String nombre;
  // Variable inmutable ('final') que conserva el pase de sesión activo para enviarlo al servidor cuando el usuario presione cerrar sesión.
  final String tokenSesion;

  Future<void> cerrarSesion(BuildContext context) async {
    try {
      // Pedimos a FastAPI que elimine la sesión de este token.
      await AuthService().cerrarSesion(tokenSesion);
    } catch (_) {
      // Si falla la red, el servidor está apagado o el token ya venció,
      // ignoramos el error para permitir que el usuario salga de todas formas.
    }

    // Verifica que el 'context' siga conectado a una pantalla activa antes de navegar.
    if (!context.mounted) return;

    // Volvemos al login y quitamos Inicio del historial.
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bienvenido, $nombre'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => cerrarSesion(context),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
