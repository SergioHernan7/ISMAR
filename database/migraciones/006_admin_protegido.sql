-- =====================================================
--  Cuenta de soporte protegida ("llave maestra")
--
--  Una cuenta con protegido = 1 solo la puede modificar ella misma: ningún
--  otro administrador la puede editar, cambiarle la contraseña, desactivar ni
--  borrar. Es la cuenta del soporte técnico: si la cliente olvida su
--  contraseña, se entra con ella y se le pone una nueva.
--
--  La protección se pone desde la consola, no desde el panel:
--    flask --app app proteger-admin USUARIO
--
--  Solo hace falta en bases creadas antes de este cambio: ismar.sql ya la trae.
--  La app también la agrega sola al arrancar (asegurar_esquema() en app.py).
-- =====================================================

USE ismar;

ALTER TABLE administradores
  ADD COLUMN protegido TINYINT(1) NOT NULL DEFAULT 0
  COMMENT '1 = solo esta misma cuenta puede editarse' AFTER activo;
