-- =====================================================
--  Estados de pedido más simples: pendiente / vendido / cancelado
--
--  Confirmado, enviado y entregado se unen en "vendido" (es un negocio
--  familiar que entrega por su cuenta; tantos pasos eran mucho trabajo).
--  Al marcar un pedido como vendido se descuenta del inventario.
--
--  Solo hace falta en bases creadas antes de este cambio: ismar.sql ya lo trae.
--  La app también lo aplica sola al arrancar (asegurar_esquema() en app.py).
-- =====================================================

USE ismar;

ALTER TABLE pedidos MODIFY estado
  ENUM('pendiente','confirmado','enviado','entregado','vendido','cancelado') NOT NULL DEFAULT 'pendiente';

UPDATE pedidos SET estado = 'vendido' WHERE estado IN ('confirmado', 'enviado', 'entregado');

ALTER TABLE pedidos MODIFY estado
  ENUM('pendiente','vendido','cancelado') NOT NULL DEFAULT 'pendiente';
