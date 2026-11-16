import 'package:flutter/material.dart';

/// Envuelve una vista completa para detectar cualquier interacción del usuario
/// (toques, arrastres, rueda del ratón o gestos) sin bloquear los widgets internos.
class ActividadSesion extends StatelessWidget {
  const ActividadSesion({
    super.key,
    required this.onActividad,
    required this.child,
  });

  /// Acción que se dispara en cada interacción (por ejemplo, reiniciar el tiempo de inactividad).
  final VoidCallback onActividad;

  /// Pantalla o contenido hijo que será monitoreado.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Permite capturar el evento incluso en espacios vacíos y deja que siga su curso hacia los botones.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onActividad(), // Al tocar o hacer clic
      onPointerMove: (_) => onActividad(), // Al deslizar el dedo o mover el cursor
      onPointerSignal: (_) => onActividad(), // Al usar la rueda del ratón
      onPointerPanZoomUpdate: (_) => onActividad(), // Al hacer zoom o desplazar con dos dedos
      child: child,
    );
  }
}