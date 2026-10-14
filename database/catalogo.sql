-- =====================================================
--  Catálogo real de ISMAR
--  Importado del catálogo de Treinta (catalogo.treinta.co/ismar-productoselectricos)
--  139 productos. Las fotos están en static/catalogo/
--
--  Se puede importar sobre una base ya creada con ismar.sql:
--  REEMPLAZA las categorías, marcas y productos, pero NO toca
--  administradores, pedidos ni configuración.
-- =====================================================

USE ismar;

-- Al borrar productos se borran sus imágenes y especificaciones, y los pedidos
-- antiguos conservan el nombre y el precio (su producto_id queda en NULL)
DELETE FROM productos;
DELETE FROM categorias;
DELETE FROM marcas;
ALTER TABLE productos AUTO_INCREMENT = 1;
ALTER TABLE categorias AUTO_INCREMENT = 1;
ALTER TABLE marcas AUTO_INCREMENT = 1;

INSERT INTO categorias (id, categoria_padre_id, nombre, slug, descripcion, orden) VALUES
(1, NULL, 'Iluminación', 'iluminacion', 'Bombillos, paneles, framel, cintas LED, reflectores y sensores', 1),
(2, NULL, 'Tomas e interruptores', 'tomas-e-interruptores', 'Tomas, interruptores, clavijas, multitomas y extensiones', 2),
(3, NULL, 'Parte eléctrica', 'parte-electrica', 'Tubería, cajas, tableros, terminales, uniones y accesorios de instalación', 3),
(4, NULL, 'Duchas', 'duchas', 'Duchas eléctricas, mezcladores y niples', 4),
(5, NULL, 'Otros', 'otros', 'Herramientas, cerraduras, timbres y más', 5);

INSERT INTO productos (id, categoria_id, sku, nombre, slug, descripcion, precio, stock, imagen_principal) VALUES
(1, 1, 'ISM-001', 'Antipolvo 52w', 'antipolvo-52w', NULL, 17000, 5, 'catalogo/antipolvo-52w.jpg'),
(2, 1, 'ISM-002', 'Aplique 2 ojos', 'aplique-2-ojos', NULL, 25000, 2, 'catalogo/aplique-2-ojos.jpg'),
(3, 1, 'ISM-003', 'Aplique de 3 ojos', 'aplique-de-3-ojos', NULL, 30000, 5, 'catalogo/aplique-de-3-ojos.jpg'),
(4, 1, 'ISM-004', 'Bombillo 20w', 'bombillo-20w', NULL, 6000, 62, 'catalogo/bombillo-20w.jpg'),
(5, 1, 'ISM-005', 'Bombillo 3w L/C L/B', 'bombillo-3w-l-c-l-b', NULL, 3000, 20, 'catalogo/bombillo-3w-l-c-l-b.webp'),
(6, 1, 'ISM-006', 'Bombillo 5W GU10 L/C L/B', 'bombillo-5w-gu10-l-c-l-b', NULL, 5000, 18, 'catalogo/bombillo-5w-gu10-l-c-l-b.jpg'),
(7, 1, 'ISM-007', 'Bombillo aspas 40w', 'bombillo-aspas-40w', NULL, 25000, 2, 'catalogo/bombillo-aspas-40w.jpg'),
(8, 1, 'ISM-008', 'Bombillo E14 L/C L/B', 'bombillo-e14-l-c-l-b', NULL, 4000, 15, 'catalogo/bombillo-e14-l-c-l-b.jpg'),
(9, 1, 'ISM-009', 'Bombillo infrarrojo', 'bombillo-infrarrojo', NULL, 17000, 10, 'catalogo/bombillo-infrarrojo.jpg'),
(10, 1, 'ISM-010', 'Bombillo sensor', 'bombillo-sensor', NULL, 13000, 2, 'catalogo/bombillo-sensor.jpg'),
(11, 1, 'ISM-011', 'Bombillo torpedo 9W L/C L/B', 'bombillo-torpedo-9w-l-c-l-b', NULL, 6000, 16, 'catalogo/bombillo-torpedo-9w-l-c-l-b.jpg'),
(12, 1, 'ISM-012', 'Bombillo vela 5w l/c l/b', 'bombillo-vela-5w-l-c-l-b', NULL, 4000, 17, 'catalogo/bombillo-vela-5w-l-c-l-b.jpg'),
(13, 1, 'ISM-013', 'Bombillo ventilado', 'bombillo-ventilado', NULL, 35000, 2, 'catalogo/bombillo-ventilado.jpg'),
(14, 1, 'ISM-014', 'Bombillos 50w', 'bombillos-50w', NULL, 15000, 40, 'catalogo/bombillos-50w.jpg'),
(15, 1, 'ISM-015', 'Cinta cob 10mt calida', 'cinta-cob-10mt-calida', NULL, 50000, 4, 'catalogo/cinta-cob-10mt-calida.jpg'),
(16, 1, 'ISM-016', 'Cinta led cob 10mt blanca', 'cinta-led-cob-10mt-blanca', NULL, 50000, 9, 'catalogo/cinta-led-cob-10mt-blanca.jpg'),
(17, 1, 'ISM-017', 'Cinta neon flex blanca', 'cinta-neon-flex-blanca', NULL, 5500, 100, 'catalogo/cinta-neon-flex-blanca.jpg'),
(18, 1, 'ISM-018', 'Cinta RGB 5mt', 'cinta-rgb-5mt', NULL, 35000, 3, 'catalogo/cinta-rgb-5mt.jpg'),
(19, 1, 'ISM-019', 'Cinta running cob RGB', 'cinta-running-cob-rgb', '🌈 Iluminación RGB Full Color
📏 Longitud: 5 metros
📱 Control Bluetooth
🎮 Incluye control remoto
🎵 Sincronización con música
💡 Atenuable para regular la intensidad
⏰ Temporizador
🔄 Efecto de iluminación Running
🎨 Amplia variedad de colores y efectos', 65000, 1, 'catalogo/cinta-running-cob-rgb.jpg'),
(20, 1, 'ISM-020', 'Framel 18w de sobreponer', 'framel-18w-de-sobreponer', NULL, 8000, 45, NULL),
(21, 1, 'ISM-021', 'Framel 18w incrustar', 'framel-18w-incrustar', NULL, 7000, 27, NULL),
(22, 1, 'ISM-022', 'Framel 24w cuadrado de sobreponer', 'framel-24w-cuadrado-de-sobreponer', NULL, 13000, 19, NULL),
(23, 1, 'ISM-023', 'Framel 24w de sobreponer', 'framel-24w-de-sobreponer', NULL, 11000, 22, NULL),
(24, 1, 'ISM-024', 'Framel 24w incrustar', 'framel-24w-incrustar', NULL, 9000, 16, NULL),
(25, 1, 'ISM-025', 'Framel 24w incrustar 3 tonos', 'framel-24w-incrustar-3-tonos', NULL, 14000, 3, NULL),
(26, 1, 'ISM-026', 'Framel 24w sobreponer L/C', 'framel-24w-sobreponer-l-c', NULL, 13000, 15000, 'catalogo/framel-24w-sobreponer-l-c.jpg'),
(27, 1, 'ISM-027', 'Framel 36w de sobreponer', 'framel-36w-de-sobreponer', NULL, 14000, 7, 'catalogo/framel-36w-de-sobreponer.jpg'),
(28, 1, 'ISM-028', 'Framel 36w incrustar', 'framel-36w-incrustar', NULL, 12000, 40, 'catalogo/framel-36w-incrustar.avif'),
(29, 1, 'ISM-029', 'Framel 36w incrustar 3 tonos', 'framel-36w-incrustar-3-tonos', NULL, 17000, 15, NULL),
(30, 1, 'ISM-030', 'Framel 36w sobreponer 3 tonos', 'framel-36w-sobreponer-3-tonos', NULL, 18000, 14, 'catalogo/framel-36w-sobreponer-3-tonos.webp'),
(31, 1, 'ISM-031', 'Framel s/p 36w borde negro', 'framel-s-p-36w-borde-negro', NULL, 25000, 5, 'catalogo/framel-s-p-36w-borde-negro.jpg'),
(32, 1, 'ISM-032', 'Lampara de lujo 28w 3 tonos', 'lampara-de-lujo-28w-3-tonos', NULL, 55000, 15, 'catalogo/lampara-de-lujo-28w-3-tonos.jpg'),
(33, 1, 'ISM-033', 'Lampara de pinza', 'lampara-de-pinza', NULL, 18000, 2, 'catalogo/lampara-de-pinza.jpg'),
(34, 1, 'ISM-034', 'Lampara decorativa 35w 3 tonos', 'lampara-decorativa-35w-3-tonos', NULL, 60000, 9, 'catalogo/lampara-decorativa-35w-3-tonos.jpg'),
(35, 1, 'ISM-035', 'Panel 12w incrustar', 'panel-12w-incrustar', '✅ Potencia: 12W
✅ Incluye driver
✅ Diseño delgado y moderno
✅ Bajo consumo de energía
✅ Iluminación uniforme
✅ Ideal para diferentes espacios', 7000, 40, 'catalogo/panel-12w-incrustar.webp'),
(36, 1, 'ISM-036', 'Panel 12w sobreponer', 'panel-12w-sobreponer', NULL, 7500, 64, NULL),
(37, 1, 'ISM-037', 'Panel 18w incrustar', 'panel-18w-incrustar', 'las medidas son 20cm y trae draiber', 8000, 26, 'catalogo/panel-18w-incrustar.jpg'),
(38, 1, 'ISM-038', 'Panel 18w sobreponer', 'panel-18w-sobreponer', 'las medidas son 2.4cm de ancho y de largo 20.4cm', 9000, 71, 'catalogo/panel-18w-sobreponer.jpg'),
(39, 1, 'ISM-039', 'Panel 9w', 'panel-9w', NULL, 6000, 32, NULL),
(40, 1, 'ISM-040', 'Ramal 10 MT 20 bombillo', 'ramal-10-mt-20-bombillo', NULL, 30000, 1, 'catalogo/ramal-10-mt-20-bombillo.jpg'),
(41, 1, 'ISM-041', 'Reflector 100w solar', 'reflector-100w-solar', '✅ Potencia: 100W
☀️ Energía solar: no necesita conexión eléctrica
💡 Iluminación LED de alta potencia
🌧️ Resistente al agua y al exterior
🔋 Panel solar + batería recargable
🌙 Encendido automático durante la noche
📦 Ideal para hogares, negocios y espacios exteriores.', 100000, 1, 'catalogo/reflector-100w-solar.jpg'),
(42, 1, 'ISM-042', 'Reflector de 200w solar', 'reflector-de-200w-solar', NULL, 125000, 2, 'catalogo/reflector-de-200w-solar.webp'),
(43, 1, 'ISM-043', 'Sensor de techo levitón', 'sensor-de-techo-leviton', 'El sensor de techo Levitón detecta el movimiento y controla automáticamente la iluminación, ofreciéndote comodidad, seguridad y ahorro de energía.', 80000, 10, 'catalogo/sensor-de-techo-leviton.jpg'),
(44, 1, 'ISM-044', 'Sensor de toque con reloj', 'sensor-de-toque-con-reloj', NULL, 35000, 1, 'catalogo/sensor-de-toque-con-reloj.jpg'),
(45, 1, 'ISM-045', 'Sensor roseta', 'sensor-roseta', '✅ Sensor de movimiento
💡 Encendido y apagado automático
🏠 Ideal para pasillos, baños, entradas, escaleras y garajes
⚡ Fácil instalación
💰 Ayuda a ahorrar energía
🔌 Compatible con diferentes tipos de bombillos', 18000, 37, 'catalogo/sensor-roseta.jpg'),
(46, 1, 'ISM-046', 'Tous de madera', 'tous-de-madera', NULL, 35000, 3, 'catalogo/tous-de-madera.jpg'),
(47, 1, 'ISM-047', 'Tous para espejo', 'tous-para-espejo', NULL, 20000, 7, 'catalogo/tous-para-espejo.jpg'),
(48, 2, 'ISM-048', '2 toma doble + interruptor bocherine', '2-toma-doble-interruptor-bocherine', NULL, 15000, 20, 'catalogo/2-toma-doble-interruptor-bocherine.jpg'),
(49, 2, 'ISM-049', 'Clavija domestica codelca', 'clavija-domestica-codelca', NULL, 3500, 3, 'catalogo/clavija-domestica-codelca.jpg'),
(50, 2, 'ISM-050', 'Clavija industrial codelca', 'clavija-industrial-codelca', NULL, 4500, 4, 'catalogo/clavija-industrial-codelca.webp'),
(51, 2, 'ISM-051', 'Clavija plástica AVE', 'clavija-plastica-ave', NULL, 2500, 22, 'catalogo/clavija-plastica-ave.jpg'),
(52, 2, 'ISM-052', 'Extencion 2MT', 'extencion-2mt', NULL, 12000, 2, 'catalogo/extencion-2mt.webp'),
(53, 2, 'ISM-053', 'Interruptor + toma s/p', 'interruptor-toma-s-p', NULL, 4000, 19, 'catalogo/interruptor-toma-s-p.jpg'),
(54, 2, 'ISM-054', 'Interruptor de paso', 'interruptor-de-paso', NULL, 1500, 20, 'catalogo/interruptor-de-paso.jpg'),
(55, 2, 'ISM-055', 'Interruptor de s/p', 'interruptor-de-s-p', NULL, 2500, 26, 'catalogo/interruptor-de-s-p.webp'),
(56, 2, 'ISM-056', 'Interruptor doble conmutable galica2', 'interruptor-doble-conmutable-galica2', NULL, 17000, 14, 'catalogo/interruptor-doble-conmutable-galica2.jpg'),
(57, 2, 'ISM-057', 'Interruptor doble s/p', 'interruptor-doble-s-p', NULL, 4000, 16, 'catalogo/interruptor-doble-s-p.jpg'),
(58, 2, 'ISM-058', 'Interruptor plus negro', 'interruptor-plus-negro', NULL, 4800, 10, 'catalogo/interruptor-plus-negro.jpg'),
(59, 2, 'ISM-059', 'Interruptor sencillo gálica 2', 'interruptor-sencillo-galica-2', NULL, 8500, 13, 'catalogo/interruptor-sencillo-galica-2.jpg'),
(60, 2, 'ISM-060', 'Multitoma 3 salidas', 'multitoma-3-salidas', NULL, 8000, 2, 'catalogo/multitoma-3-salidas.jpg'),
(61, 2, 'ISM-061', 'Multitoma de 3MT', 'multitoma-de-3mt', NULL, 15000, 3, 'catalogo/multitoma-de-3mt.jpg'),
(62, 2, 'ISM-062', 'Protector de voltaje 20AMP', 'protector-de-voltaje-20amp', NULL, 45000, 1, 'catalogo/protector-de-voltaje-20amp.jpg'),
(63, 2, 'ISM-063', 'Toma 15 AMP leviton', 'toma-15-amp-leviton', NULL, 6500, 10, 'catalogo/toma-15-amp-leviton.jpg'),
(64, 2, 'ISM-064', 'Toma 20AMP', 'toma-20amp', NULL, 13000, 6, 'catalogo/toma-20amp.jpg'),
(65, 2, 'ISM-065', 'Toma de sobreponer eco', 'toma-de-sobreponer-eco', NULL, 2800, 10, 'catalogo/toma-de-sobreponer-eco.jpg'),
(66, 2, 'ISM-066', 'Toma plus negra', 'toma-plus-negra', NULL, 5000, 1, 'catalogo/toma-plus-negra.jpg'),
(67, 2, 'ISM-067', 'Toma plástica AVE', 'toma-plastica-ave', NULL, 3500, 16, 'catalogo/toma-plastica-ave.jpg'),
(68, 2, 'ISM-068', 'Toma s/p', 'toma-s-p', NULL, 3500, 10, 'catalogo/toma-s-p.jpg'),
(69, 2, 'ISM-069', 'Toma s/p lujo', 'toma-s-p-lujo', NULL, 4500, 10, 'catalogo/toma-s-p-lujo.jpg'),
(70, 2, 'ISM-070', 'Toma triple bocherini', 'toma-triple-bocherini', NULL, 15000, 20, NULL),
(71, 3, 'ISM-071', 'Boquilla 1"', 'boquilla-1', NULL, 3500, 2, 'catalogo/boquilla-1.jpg'),
(72, 3, 'ISM-072', 'Caja 2400 pvc 10x10', 'caja-2400-pvc-10x10', NULL, 3000, 6, 'catalogo/caja-2400-pvc-10x10.jpg'),
(73, 3, 'ISM-073', 'Caja 2400 rawuel 3/4', 'caja-2400-rawuel-3-4', NULL, 18000, 4, 'catalogo/caja-2400-rawuel-3-4.jpg'),
(74, 3, 'ISM-074', 'Caja 2400 rawuel 3/4 doble fondo', 'caja-2400-rawuel-3-4-doble-fondo', NULL, 24500, 4, 'catalogo/caja-2400-rawuel-3-4-doble-fondo.jpg'),
(75, 3, 'ISM-075', 'Caja 5800 metálica', 'caja-5800-metalica', NULL, 2500, 16, 'catalogo/caja-5800-metalica.jpg'),
(76, 3, 'ISM-076', 'Caja 5800 rawuel 3/4', 'caja-5800-rawuel-3-4', NULL, 11000, 8, 'catalogo/caja-5800-rawuel-3-4.jpg'),
(77, 3, 'ISM-077', 'Caja octagonal rawuel 3/4', 'caja-octagonal-rawuel-3-4', NULL, 12500, 15, 'catalogo/caja-octagonal-rawuel-3-4.jpg'),
(78, 3, 'ISM-078', 'Capacete 1"', 'capacete-1', NULL, 4000, 3, 'catalogo/capacete-1.jpg'),
(79, 3, 'ISM-079', 'Cinta aislante', 'cinta-aislante', NULL, 3000, 69, 'catalogo/cinta-aislante.jpg'),
(80, 3, 'ISM-080', 'Conduleta 3/4 LR lisa', 'conduleta-3-4-lr-lisa', NULL, 10000, 6, 'catalogo/conduleta-3-4-lr-lisa.jpg'),
(81, 3, 'ISM-081', 'Conector dentado grande', 'conector-dentado-grande', NULL, 12000, 4, 'catalogo/conector-dentado-grande.jpg'),
(82, 3, 'ISM-082', 'Contadores internos', 'contadores-internos', NULL, 38000, 3, 'catalogo/contadores-internos.jpg'),
(83, 3, 'ISM-083', 'Curva 1 1/2 EMT', 'curva-1-1-2-emt', NULL, 10500, 4, 'catalogo/curva-1-1-2-emt.jpg'),
(84, 3, 'ISM-084', 'Curva 1" EMT', 'curva-1-emt', NULL, 5500, 8, 'catalogo/curva-1-emt.jpg'),
(85, 3, 'ISM-085', 'Curva galvanizada 1 1/4', 'curva-galvanizada-1-1-4', NULL, 12500, 3, 'catalogo/curva-galvanizada-1-1-4.jpg'),
(86, 3, 'ISM-086', 'Curva galvanizada 1"', 'curva-galvanizada-1', NULL, 12000, 4, 'catalogo/curva-galvanizada-1.jpg'),
(87, 3, 'ISM-087', 'Grapa 1 1/4 EMT doble ala', 'grapa-1-1-4-emt-doble-ala', NULL, 800, 3, 'catalogo/grapa-1-1-4-emt-doble-ala.jpg'),
(88, 3, 'ISM-088', 'Grapa 1/2 EMT doble ala', 'grapa-1-2-emt-doble-ala', NULL, 300, 18, 'catalogo/grapa-1-2-emt-doble-ala.jpg'),
(89, 3, 'ISM-089', 'Grapa 3/4 EMT 1 ala', 'grapa-3-4-emt-1-ala', NULL, 400, 42, 'catalogo/grapa-3-4-emt-1-ala.jpg'),
(90, 3, 'ISM-090', 'Grapa 3/4 EMT doble ala', 'grapa-3-4-emt-doble-ala', NULL, 400, 10, 'catalogo/grapa-3-4-emt-doble-ala.jpg'),
(91, 3, 'ISM-091', 'Porta tensor', 'porta-tensor', NULL, 3500, 2, 'catalogo/porta-tensor.jpg'),
(92, 3, 'ISM-092', 'Suplemento pvc', 'suplemento-pvc', NULL, 800, 1, 'catalogo/suplemento-pvc.jpg'),
(93, 3, 'ISM-093', 'Tablero 2 circuitos fem', 'tablero-2-circuitos-fem', NULL, 22000, 1, 'catalogo/tablero-2-circuitos-fem.jpg'),
(94, 3, 'ISM-094', 'Tablero 4 circuitos tercol barraje en cobre', 'tablero-4-circuitos-tercol-barraje-en-cobre', NULL, 54000, 1, NULL),
(95, 3, 'ISM-095', 'Tablero 6 circuitos con tapa fem', 'tablero-6-circuitos-con-tapa-fem', NULL, 45000, 1, 'catalogo/tablero-6-circuitos-con-tapa-fem.jpg'),
(96, 3, 'ISM-096', 'Tablero 6 circuitos fem', 'tablero-6-circuitos-fem', NULL, 37000, 2, 'catalogo/tablero-6-circuitos-fem.jpg'),
(97, 3, 'ISM-097', 'Tablero 6 circuitos tercol barraje en cobre', 'tablero-6-circuitos-tercol-barraje-en-cobre', NULL, 68000, 1, NULL),
(98, 3, 'ISM-098', 'Tablero de 3 circuitos fem', 'tablero-de-3-circuitos-fem', NULL, 25000, 2, NULL),
(99, 3, 'ISM-099', 'Taco luminex', 'taco-luminex', 'producto original', 17000, 33, 'catalogo/taco-luminex.jpg'),
(100, 3, 'ISM-100', 'Tapa ciega 2400 EMT', 'tapa-ciega-2400-emt', NULL, 1500, 0, 'catalogo/tapa-ciega-2400-emt.jpg'),
(101, 3, 'ISM-101', 'Tapa ciega 5800 EMT', 'tapa-ciega-5800-emt', NULL, 1500, 23, 'catalogo/tapa-ciega-5800-emt.jpg'),
(102, 3, 'ISM-102', 'Tapa ciega octagonal EMT', 'tapa-ciega-octagonal-emt', NULL, 1800, 21, 'catalogo/tapa-ciega-octagonal-emt.jpg'),
(103, 3, 'ISM-103', 'Tapa ciega pvc 2400', 'tapa-ciega-pvc-2400', NULL, 800, 16, 'catalogo/tapa-ciega-pvc-2400.jpg'),
(104, 3, 'ISM-104', 'Tapa ciega pvc 5800', 'tapa-ciega-pvc-5800', NULL, 600, 11, 'catalogo/tapa-ciega-pvc-5800.jpg'),
(105, 3, 'ISM-105', 'Tapa interperie', 'tapa-interperie', NULL, 3500, 6, 'catalogo/tapa-interperie.jpg'),
(106, 3, 'ISM-106', 'Tensor grande', 'tensor-grande', NULL, 6000, 2, 'catalogo/tensor-grande.jpg'),
(107, 3, 'ISM-107', 'Terminal 1 1/2 EMT', 'terminal-1-1-2-emt', NULL, 3000, 2, NULL),
(108, 3, 'ISM-108', 'Terminal 1 1/4 EMT', 'terminal-1-1-4-emt', NULL, 2500, 13, NULL),
(109, 3, 'ISM-109', 'Terminal 1" EMT', 'terminal-1-emt', NULL, 1800, 19, 'catalogo/terminal-1-emt.jpg'),
(110, 3, 'ISM-110', 'Terminal 1/2 EMT', 'terminal-1-2-emt', NULL, 1000, 2, 'catalogo/terminal-1-2-emt.jpg'),
(111, 3, 'ISM-111', 'Terminal 3/4 EMT', 'terminal-3-4-emt', NULL, 1100, 58, 'catalogo/terminal-3-4-emt.jpg'),
(112, 3, 'ISM-112', 'Tubo 1 1/2 pvc', 'tubo-1-1-2-pvc', NULL, 19000, 3, 'catalogo/tubo-1-1-2-pvc.jpg'),
(113, 3, 'ISM-113', 'Tubo 1 1/4 pvc pesado', 'tubo-1-1-4-pvc-pesado', NULL, 14000, 3, NULL),
(114, 3, 'ISM-114', 'Tubo 1/2 EMT semi', 'tubo-1-2-emt-semi', NULL, 11000, 7, NULL),
(115, 3, 'ISM-115', 'Tubo 1/2 pvc semi', 'tubo-1-2-pvc-semi', NULL, 2200, 16, NULL),
(116, 3, 'ISM-116', 'Tubo 3/4 EMT semi', 'tubo-3-4-emt-semi', NULL, 15000, 0, 'catalogo/tubo-3-4-emt-semi.jpg'),
(117, 3, 'ISM-117', 'Tubos 1/2 pvc pesado', 'tubos-1-2-pvc-pesado', NULL, 4500, 77, NULL),
(118, 3, 'ISM-118', 'Union 1 1/4 EMT', 'union-1-1-4-emt', NULL, 2200, 4, 'catalogo/union-1-1-4-emt.jpg'),
(119, 3, 'ISM-119', 'Union 1" EMT', 'union-1-emt', NULL, 1800, 7, 'catalogo/union-1-emt.jpg'),
(120, 3, 'ISM-120', 'Unión 1 1/2 EMT', 'union-1-1-2-emt', NULL, 3000, 6, NULL),
(121, 3, 'ISM-121', 'Unión 1" galvanizada', 'union-1-galvanizada', NULL, 4000, 4, 'catalogo/union-1-galvanizada.jpg'),
(122, 3, 'ISM-122', 'Unión 1/2 EMT', 'union-1-2-emt', NULL, 1000, 17, 'catalogo/union-1-2-emt.jpg'),
(123, 3, 'ISM-123', 'Unión 3/4 EMT', 'union-3-4-emt', NULL, 1100, 39, 'catalogo/union-3-4-emt.jpg'),
(124, 3, 'ISM-124', 'Varilla enchaquetada 1.50 + conector', 'varilla-enchaquetada-1-50-conector', NULL, 26000, 1, 'catalogo/varilla-enchaquetada-1-50-conector.jpg'),
(125, 4, 'ISM-125', 'Ducha bocherini maxi', 'ducha-bocherini-maxi', NULL, 75000, 1, 'catalogo/ducha-bocherini-maxi.jpg'),
(126, 4, 'ISM-126', 'Ducha con plato cuadrado negra', 'ducha-con-plato-cuadrado-negra', NULL, 95000, 3, 'catalogo/ducha-con-plato-cuadrado-negra.jpg'),
(127, 4, 'ISM-127', 'Duchas con plato', 'duchas-con-plato', NULL, 85000, 5, 'catalogo/duchas-con-plato.jpg'),
(128, 4, 'ISM-128', 'Duchas con plato con selectot', 'duchas-con-plato-con-selectot', NULL, 95000, 3, 'catalogo/duchas-con-plato-con-selectot.jpg'),
(129, 4, 'ISM-129', 'Duchas economicas', 'duchas-economicas', NULL, 65000, 6, 'catalogo/duchas-economicas.jpg'),
(130, 4, 'ISM-130', 'Mezclador doble', 'mezclador-doble', NULL, 35000, 7, 'catalogo/mezclador-doble.jpg'),
(131, 4, 'ISM-131', 'Mezclador sencillo', 'mezclador-sencillo', NULL, 25000, 5, 'catalogo/mezclador-sencillo.webp'),
(132, 4, 'ISM-132', 'Niple para ducha metalico', 'niple-para-ducha-metalico', NULL, 10000, 4, 'catalogo/niple-para-ducha-metalico.jpg'),
(133, 4, 'ISM-133', 'Niple para ducha plastico', 'niple-para-ducha-plastico', NULL, 12000, 5, 'catalogo/niple-para-ducha-plastico.jpg'),
(134, 5, 'ISM-134', 'Amarres dexon 20cm', 'amarres-dexon-20cm', NULL, 8000, 10, 'catalogo/amarres-dexon-20cm.jpg'),
(135, 5, 'ISM-135', 'Candado de 60mm', 'candado-de-60mm', NULL, 60000, 5, 'catalogo/candado-de-60mm.jpg'),
(136, 5, 'ISM-136', 'Chapa de alcoba', 'chapa-de-alcoba', NULL, 20000, 2, 'catalogo/chapa-de-alcoba.jpg'),
(137, 5, 'ISM-137', 'Pela cable', 'pela-cable', NULL, 10000, 6, 'catalogo/pela-cable.jpg'),
(138, 5, 'ISM-138', 'Pulsador timbre s/p', 'pulsador-timbre-s-p', NULL, 2800, 5, NULL),
(139, 5, 'ISM-139', 'Timbre inalámbrico', 'timbre-inalambrico', NULL, 20000, 7, 'catalogo/timbre-inalambrico.jpg');
