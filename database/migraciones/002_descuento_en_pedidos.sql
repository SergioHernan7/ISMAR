-- =====================================================
--  Los pedidos recuerdan si se vendieron con descuento
--
--  pedido_detalle guarda, además del precio cobrado (precio_unitario),
--  el precio normal de ese día (precio_lista) y el % de oferta (descuento).
--  Así, aunque después el producto cambie de precio o salga de Ofertas,
--  el pedido sigue mostrando que se vendió con descuento.
--
--  Solo hace falta en bases creadas antes de este cambio: ismar.sql ya trae
--  las columnas. La app también lo aplica sola al arrancar
--  (ver asegurar_esquema() en app.py).
-- =====================================================

USE ismar;

ALTER TABLE pedido_detalle
  ADD COLUMN precio_lista DECIMAL(12,2) NULL COMMENT 'Precio normal el día de la compra' AFTER precio_unitario,
  ADD COLUMN descuento TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '% de oferta el día de la compra' AFTER precio_lista;

-- Pedidos anteriores: si el producto se cobró por debajo de su precio actual,
-- se toma ese precio como el normal y se deduce el porcentaje
UPDATE pedido_detalle d
  JOIN productos p ON p.id = d.producto_id
   SET d.precio_lista = p.precio,
       d.descuento = LEAST(90, ROUND((1 - d.precio_unitario / p.precio) * 100))
 WHERE d.precio_unitario < p.precio AND p.precio > 0;

UPDATE pedido_detalle SET precio_lista = precio_unitario WHERE precio_lista IS NULL;
