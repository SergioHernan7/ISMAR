-- =====================================================
--  Ofertas con porcentaje de descuento (como en UrbanStyle)
--
--  Cambia productos.precio_oferta (un precio fijo) por productos.descuento
--  (porcentaje, 0 = sin oferta). El administrador lo asigna en el panel
--  (Ofertas, o al editar cada producto) y el precio final se calcula solo:
--  precio * (100 - descuento) / 100.
--
--  Solo hace falta en bases creadas antes de este cambio: ismar.sql ya trae
--  la columna nueva. La app también la aplica sola al arrancar si no existe
--  (ver asegurar_columna_descuento() en app.py).
-- =====================================================

USE ismar;

ALTER TABLE productos
  ADD COLUMN descuento TINYINT UNSIGNED NOT NULL DEFAULT 0
  COMMENT '% de descuento (0 = sin oferta)' AFTER precio;

-- Las ofertas que ya hubiera se convierten a porcentaje (redondeado, máximo 90 %)
UPDATE productos
   SET descuento = LEAST(90, GREATEST(0, ROUND((1 - precio_oferta / precio) * 100)))
 WHERE precio_oferta IS NOT NULL AND precio > 0 AND precio_oferta < precio;

ALTER TABLE productos DROP COLUMN precio_oferta;
