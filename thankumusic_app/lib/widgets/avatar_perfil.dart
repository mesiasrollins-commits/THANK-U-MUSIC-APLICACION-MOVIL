import 'package:flutter/material.dart';

class AvatarPerfil extends StatelessWidget {
  const AvatarPerfil({super.key, this.fotoUrl});

  final String? fotoUrl;

  @override
  Widget build(BuildContext context) {
    final url = fotoUrl?.trim() ?? '';
    const icono = Icon(
      Icons.person_outline,
      color: Color(0xFFB50020),
      size: 32,
    );

    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFFFBD7DF),
      child: url.isEmpty
          ? icono
          : ClipOval(
              child: Image.network(
                url,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, __, ___) => icono,
              ),
            ),
    );
  }
}