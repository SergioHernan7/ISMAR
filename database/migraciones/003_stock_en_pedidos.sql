-- =====================================================
--  El stock se descuenta al confirmar un pedido
--
--  Cuando el admin pasa un pedido a confirmado, enviado o entregado, sus
--  unidades se restan del inventario; si lo pasa a pendiente o cancelado (o
--  lo elimina), vuelven. pedidos.stock_descontado recuerda si ya se restaron,
--  para no hacerlo dos veces.
--
--  Solo hace falta en bases creadas antes de este cambio: ismar.sql ya trae
--  la columna. La app también la agrega sola al arrancar (asegurar_esquema()).
--  Los pedidos anteriores quedan con stock_descontado = 0: si alguno ya estaba
--  confirmado, el inventario no se toca (se asume que ya se ajustó a mano).
-- =====================================================

USE ismar;

ALTER TABLE pedidos
  ADD COLUMN stock_descontado TINYINT(1) NOT NULL DEFAULT 0
  COMMENT '1 = sus unidades ya se restaron del inventario' AFTER estado;
