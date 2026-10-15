-- =====================================================
--  Tratamiento de datos personales (Ley 1581 de 2012)
--
--  * Datos de la tienda para la política de privacidad (/privacidad), que la
--    cliente completa en el panel > Configuración: correo, NIT/cédula y dirección.
--  * pedidos.datos_autorizados_en: fecha y hora en que el cliente marcó la casilla
--    "Autorizo el tratamiento de mis datos" al enviar el pedido. Es la prueba de
--    la autorización que pide el Decreto 1377 de 2013 (art. 8).
--
--  Solo hace falta en bases creadas antes de este cambio: ismar.sql ya lo trae.
--  La app también lo aplica sola al arrancar (asegurar_esquema() en app.py).
-- =====================================================

USE ismar;

INSERT IGNORE INTO configuracion (clave, valor, descripcion) VALUES
('correo_contacto',  '', 'Correo para dudas y solicitudes sobre datos personales (sale en la política de privacidad)'),
('nit',              '', 'NIT o cédula del responsable de la tienda (sale en la política de privacidad)'),
('direccion_tienda', '', 'Dirección física de la tienda (opcional; sale en la política de privacidad)');

ALTER TABLE pedidos
  ADD COLUMN datos_autorizados_en DATETIME NULL
  COMMENT 'Cuándo el cliente autorizó el tratamiento de sus datos' AFTER notas;
