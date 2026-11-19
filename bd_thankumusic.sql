CREATE DATABASE IF NOT EXISTS `bd_thankumusic`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `bd_thankumusic`;

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `correo` varchar(150) NOT NULL,
  `direccion` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `rol` enum('administrador','visor') NOT NULL DEFAULT 'visor',
  `estado` enum('activo','baneado') NOT NULL DEFAULT 'activo',
  `fecha_registro` timestamp NOT NULL DEFAULT current_timestamp(),
  `foto` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `correo` (`correo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `publicaciones` (
  `id_publicacion` int(11) NOT NULL AUTO_INCREMENT,
  `titulo` varchar(200) NOT NULL,
  `contenido` text NOT NULL,
  `imagen` varchar(255) DEFAULT NULL,
  `estado` enum('borrador','publicada','eliminada') NOT NULL DEFAULT 'publicada',
  `id_autor` int(11) NOT NULL,
  `fecha_publicacion` timestamp NOT NULL DEFAULT current_timestamp(),
  `tags` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_publicacion`),
  KEY `fk_publicacion_usuario` (`id_autor`),
  CONSTRAINT `fk_publicacion_usuario`
    FOREIGN KEY (`id_autor`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `comentarios` (
  `id_comentario` int(11) NOT NULL AUTO_INCREMENT,
  `comentario` text NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `id_publicacion` int(11) NOT NULL,
  `fecha_comentario` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_comentario`),
  KEY `fk_comentario_usuario` (`id_usuario`),
  KEY `fk_comentario_publicacion` (`id_publicacion`),
  CONSTRAINT `fk_comentario_publicacion`
    FOREIGN KEY (`id_publicacion`) REFERENCES `publicaciones` (`id_publicacion`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_comentario_usuario`
    FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `usuarios` (
  `nombre`,
  `correo`,
  `direccion`,
  `password`,
  `rol`,
  `estado`,
  `foto`
) VALUES (
  'Administrador',
  'admin@gmail.com',
  'Sin especificar',
  '$2b$12$tbiPSS7sDvR1HUxqWyqil.BhCygJyopZtL1ubeZtp./IicsvvQJLy',
  'administrador',
  'activo',
  NULL
);
