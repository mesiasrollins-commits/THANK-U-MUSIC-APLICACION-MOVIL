import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/actividad_sesion.dart';
import 'login_user_page.dart';

class InicioPantalla extends StatelessWidget {
  const InicioPantalla({
    super.key,
    required this.nombre,
    required this.tokenSesion,
    required this.authService,
  });

  final String nombre;
  final String tokenSesion;
  final AuthService authService;

// Conecta la detección de actividad de la pantalla con el servicio de autenticación y maneja el cierre automático si la sesión ya venció.
  Future<void> registrarActividad(BuildContext context) async {
    try {
      // Llama al servicio para renovar el tiempo de vida de la sesión en FastAPI (respetando el límite de 1 consulta por minuto).
      await authService.registrarActividad(tokenSesion);
    } on SesionInvalida {
      // Si el servidor responde que el token ya caducó o no es válido, redirige al usuario de inmediato a la pantalla de inicio de sesión con un aviso.
      volverAlLogin(context, aviso: 'La sesión terminó. Inicia sesión de nuevo.');
    } catch (_) {
      // Ignora cualquier otro error temporal (como una caída momentánea de internet) sin sacar al usuario, permitiendo que el próximo movimiento vuelva a intentarlo.
    }
  }

// Cierra la sesión en el servidor si hay conexión, pero siempre limpia la sesión local y redirige al login.
  Future<void> cerrarSesion(BuildContext context) async {
    try {
      // Intenta avisarle a FastAPI para que invalide el token activo en el servidor.
      await authService.cerrarSesion(tokenSesion);
    } catch (_) {
      // Si no hay internet o el servidor falla, no bloquea al usuario; el token expirará solo por inactividad en el backend.
    } finally {
      // Este bloque se ejecuta siempre (haya funcionado o fallado el servidor), garantizando que el usuario pueda salir de la app.
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(aviso)),
      );
    }

    // Reemplaza la pantalla actual por 'LoginPage' para que el usuario no pueda regresar a la vista privada presionando el botón "Atrás" del dispositivo.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false, //elimina todas las pantallas anteriores del historial
    );
  }

  @override
  Widget build(BuildContext context) {
    return ActividadSesion(
      onActividad: () => registrarActividad(context),
      child: Scaffold(
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
      ),
    );
  }
}