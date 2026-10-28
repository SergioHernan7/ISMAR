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
(2, NULL, 'Tomas e interruptores', 'tomas-e-interruptores', 'Tomas, interruptores, clavijas, multitomas, extensiones y timbres', 2),
(3, NULL, 'Parte eléctrica', 'parte-electrica', 'Tubería, cajas, tableros, terminales, uniones y accesorios de instalación', 3),
(4, NULL, 'Duchas', 'duchas', 'Duchas eléctricas, mezcladores y niples', 4),
(5, NULL, 'Herramientas y ferretería', 'herramientas-y-ferreteria', 'Pelacables, candados y chapas', 5);

INSERT INTO productos (id, categoria_id, sku, nombre, slug, descripcion, precio, stock, imagen_principal) VALUES
(1, 1, 'ISM-001', 'Lámpara antipolvo LED 52W', 'lampara-antipolvo-led-52w', 'Luminaria LED tipo regleta de 52W con cubierta antipolvo. Da una luz amplia y uniforme, ideal para garajes, bodegas, locales, cocinas y zonas de trabajo.

✅ Potencia: 52W
💡 Luminaria LED tipo regleta
🛡️ Cubierta antipolvo
🔆 Luz amplia y uniforme
🏭 Ideal para garajes, bodegas, locales y cocinas', 17000, 5, 'catalogo/antipolvo-52w.jpg'),
(2, 1, 'ISM-002', 'Aplique de pared LED 2 luces', 'aplique-de-pared-led-2-luces', 'Aplique LED de pared con dos haces de luz, uno hacia arriba y otro hacia abajo. Crea un efecto decorativo sobre el muro, ideal para fachadas, pasillos, escaleras y salas.

💡 Aplique LED de pared
↕️ 2 haces de luz: hacia arriba y hacia abajo
✨ Efecto decorativo sobre el muro
🏠 Ideal para fachadas, pasillos, escaleras y salas', 25000, 2, 'catalogo/aplique-2-ojos.jpg'),
(3, 1, 'ISM-003', 'Aplique de pared LED 3 luces', 'aplique-de-pared-led-3-luces', 'Aplique LED de pared con tres haces de luz hacia arriba y hacia abajo. Da un efecto decorativo llamativo sobre el muro, ideal para fachadas, entradas, pasillos y salas.

💡 Aplique LED de pared
↕️ 3 haces de luz hacia arriba y hacia abajo
✨ Efecto decorativo llamativo
🏠 Ideal para fachadas, entradas, pasillos y salas', 30000, 5, 'catalogo/aplique-de-3-ojos.jpg'),
(4, 1, 'ISM-004', 'Bombillo LED 20W', 'bombillo-led-20w', 'Bombillo LED de 20W de alta potencia. Ilumina espacios amplios con bajo consumo de energía; ideal para locales, garajes, patios y bodegas.

✅ Potencia: 20W
💡 Tecnología LED
🔆 Alta potencia para espacios amplios
💰 Bajo consumo de energía
🏭 Ideal para locales, garajes, patios y bodegas', 6000, 62, 'catalogo/bombillo-20w.jpg'),
(5, 1, 'ISM-005', 'Bombillo LED 3W luz cálida o blanca', 'bombillo-led-3w-luz-calida-o-blanca', 'Bombillo LED de 3W de bajo consumo, ideal para lámparas pequeñas, mesas de noche y luz de ambiente. Disponible en luz cálida o luz blanca (L/C - L/B): indícanos cuál prefieres al enviar tu pedido.

✅ Potencia: 3W
💡 Tecnología LED
🎨 Disponible en luz cálida o luz blanca
💰 Bajo consumo de energía
🛏️ Ideal para lámparas pequeñas, mesas de noche y luz de ambiente', 3000, 20, 'catalogo/bombillo-3w-l-c-l-b.webp'),
(6, 1, 'ISM-006', 'Bombillo LED GU10 5W luz cálida o blanca', 'bombillo-led-gu10-5w-luz-calida-o-blanca', 'Bombillo LED dicroico de 5W con base GU10, para lámparas de techo dirigibles, rieles y spots empotrados. Disponible en luz cálida o luz blanca (L/C - L/B): indícanos cuál prefieres al enviar tu pedido.

✅ Potencia: 5W
💡 Tecnología LED
🔩 Base GU10
🎯 Luz dirigida tipo dicroico
🎨 Disponible en luz cálida o luz blanca
💰 Bajo consumo de energía
🏠 Ideal para spots, rieles y lámparas dirigibles', 5000, 18, 'catalogo/bombillo-5w-gu10-l-c-l-b.jpg'),
(7, 1, 'ISM-007', 'Bombillo LED de aspas 40W', 'bombillo-led-de-aspas-40w', 'Bombillo LED de 40W con aspas plegables que se ajustan para dirigir la luz. Ilumina áreas grandes como garajes, talleres, bodegas y locales.

✅ Potencia: 40W
💡 Tecnología LED
🔄 Aspas plegables para dirigir la luz
🔆 Ilumina áreas grandes
🏭 Ideal para garajes, talleres, bodegas y locales', 25000, 2, 'catalogo/bombillo-aspas-40w.jpg'),
(8, 1, 'ISM-008', 'Bombillo LED E14 luz cálida o blanca', 'bombillo-led-e14-luz-calida-o-blanca', 'Bombillo LED con base E14 (rosca pequeña), para lámparas decorativas, apliques y candelabros. Disponible en luz cálida o luz blanca (L/C - L/B): indícanos cuál prefieres al enviar tu pedido.

💡 Tecnología LED
🔩 Base E14 (rosca pequeña)
🎨 Disponible en luz cálida o luz blanca
💰 Bajo consumo de energía
🕯️ Ideal para lámparas decorativas, apliques y candelabros', 4000, 15, 'catalogo/bombillo-e14-l-c-l-b.jpg'),
(9, 1, 'ISM-009', 'Bombillo infrarrojo', 'bombillo-infrarrojo', 'Bombillo infrarrojo que emite calor. Se usa en terapias de calor, criaderos de animales y para mantener la temperatura en espacios pequeños.

🔥 Emite calor infrarrojo
🐣 Usado en criaderos de animales
💆 Útil en terapias de calor
🌡️ Mantiene la temperatura en espacios pequeños', 17000, 10, 'catalogo/bombillo-infrarrojo.jpg'),
(10, 1, 'ISM-010', 'Bombillo LED con sensor', 'bombillo-led-con-sensor', 'Bombillo LED con sensor de movimiento: se enciende solo al detectar a una persona y se apaga después de un tiempo. Ideal para pasillos, escaleras, entradas y garajes; ahorra energía.

💡 Bombillo LED
👋 Sensor de movimiento integrado
🔄 Encendido y apagado automático
💰 Bajo consumo de energía
🏠 Ideal para pasillos, escaleras, entradas y garajes', 13000, 2, 'catalogo/bombillo-sensor.jpg'),
(11, 1, 'ISM-011', 'Bombillo LED torpedo 9W luz cálida o blanca', 'bombillo-led-torpedo-9w-luz-calida-o-blanca', 'Bombillo LED tipo torpedo de 9W con forma alargada, para lámparas decorativas y apliques. Disponible en luz cálida o luz blanca (L/C - L/B): indícanos cuál prefieres al enviar tu pedido.

✅ Potencia: 9W
💡 Tecnología LED
📐 Forma alargada tipo torpedo
🎨 Disponible en luz cálida o luz blanca
💰 Bajo consumo de energía
🏠 Ideal para lámparas decorativas y apliques', 6000, 16, 'catalogo/bombillo-torpedo-9w-l-c-l-b.jpg'),
(12, 1, 'ISM-012', 'Bombillo LED vela 5W luz cálida o blanca', 'bombillo-led-vela-5w-luz-calida-o-blanca', 'Bombillo LED tipo vela de 5W, ideal para candelabros, lámparas colgantes y apliques decorativos. Disponible en luz cálida o luz blanca (L/C - L/B): indícanos cuál prefieres al enviar tu pedido.

✅ Potencia: 5W
💡 Tecnología LED
🕯️ Forma de vela
🎨 Disponible en luz cálida o luz blanca
💰 Bajo consumo de energía
✨ Ideal para candelabros, lámparas colgantes y apliques', 4000, 17, 'catalogo/bombillo-vela-5w-l-c-l-b.jpg'),
(13, 1, 'ISM-013', 'Bombillo con ventilador y control remoto', 'bombillo-con-ventilador-y-control-remoto', 'Bombillo con ventilador integrado y control remoto: ilumina y refresca al mismo tiempo. Se instala en un portabombillo de techo, sin obra adicional.

💡 Luz LED + ventilador en un solo equipo
🎮 Incluye control remoto
🌬️ Ilumina y refresca al mismo tiempo
🔧 Se instala en un portabombillo de techo
🏠 Ideal para habitaciones, salas y cocinas', 35000, 2, 'catalogo/bombillo-ventilado.jpg'),
(14, 1, 'ISM-014', 'Bombillo LED 50W', 'bombillo-led-50w', 'Bombillo LED de 50W de alta potencia para espacios grandes: locales, bodegas, talleres, parqueaderos y patios.

✅ Potencia: 50W
💡 Tecnología LED
🔆 Alta potencia para espacios grandes
💰 Bajo consumo de energía
🏭 Ideal para locales, bodegas, talleres, parqueaderos y patios', 15000, 40, 'catalogo/bombillos-50w.jpg'),
(15, 1, 'ISM-015', 'Cinta LED COB 10 m luz cálida', 'cinta-led-cob-10-m-luz-calida', 'Cinta LED COB de 10 metros en luz cálida. La tecnología COB da una línea de luz continua, sin puntos visibles; ideal para cielos rasos, muebles, repisas y nichos.

📏 Longitud: 10 metros
💡 Tecnología COB: línea de luz continua, sin puntos
🌅 Luz cálida
🏠 Ideal para cielos rasos, muebles, repisas y nichos', 50000, 4, 'catalogo/cinta-cob-10mt-calida.jpg'),
(16, 1, 'ISM-016', 'Cinta LED COB 10 m luz blanca', 'cinta-led-cob-10-m-luz-blanca', 'Cinta LED COB de 10 metros en luz blanca. La tecnología COB da una línea de luz continua, sin puntos visibles; ideal para cielos rasos, cocinas, muebles y vitrinas.

📏 Longitud: 10 metros
💡 Tecnología COB: línea de luz continua, sin puntos
⚪ Luz blanca
🏠 Ideal para cielos rasos, cocinas, muebles y vitrinas', 50000, 9, 'catalogo/cinta-led-cob-10mt-blanca.jpg'),
(17, 1, 'ISM-017', 'Cinta neón flex luz blanca', 'cinta-neon-flex-luz-blanca', 'Cinta de neón flexible en luz blanca. Se puede curvar para formar líneas y figuras; ideal para decoración, avisos, fachadas y contornos.

💡 Neón flexible
⚪ Luz blanca
〰️ Se curva para formar líneas y figuras
✨ Ideal para decoración, avisos, fachadas y contornos', 5500, 100, 'catalogo/cinta-neon-flex-blanca.jpg'),
(18, 1, 'ISM-018', 'Cinta LED RGB 5 m', 'cinta-led-rgb-5-m', 'Cinta LED RGB de 5 metros que cambia de color. Ideal para decorar habitaciones, salas, televisores, muebles y fiestas.

📏 Longitud: 5 metros
🌈 Luz RGB que cambia de color
💡 Tecnología LED
🎉 Ideal para habitaciones, salas, televisores, muebles y fiestas', 35000, 3, 'catalogo/cinta-rgb-5mt.jpg'),
(19, 1, 'ISM-019', 'Cinta LED COB RGB running 5 m', 'cinta-led-cob-rgb-running-5-m', '🌈 Iluminación RGB Full Color
📏 Longitud: 5 metros
📱 Control Bluetooth
🎮 Incluye control remoto
🎵 Sincronización con música
💡 Atenuable para regular la intensidad
⏰ Temporizador
🔄 Efecto de iluminación Running
🎨 Amplia variedad de colores y efectos', 65000, 1, 'catalogo/cinta-running-cob-rgb.jpg'),
(20, 1, 'ISM-020', 'Framel LED 18W de sobreponer', 'framel-led-18w-de-sobreponer', 'Panel LED (framel) de 18W para instalar sobre el techo, sin necesidad de hacer corte en el cielo raso. Luz uniforme y bajo consumo.

✅ Potencia: 18W
💡 Panel LED de luz uniforme
🔧 De sobreponer: se instala sobre el techo, sin cortar el cielo raso
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 8000, 45, NULL),
(21, 1, 'ISM-021', 'Framel LED 18W de incrustar', 'framel-led-18w-de-incrustar', 'Panel LED (framel) de 18W para incrustar en el cielo raso. Acabado delgado y moderno, luz uniforme y bajo consumo.

✅ Potencia: 18W
💡 Panel LED de luz uniforme
🔧 De incrustar: va empotrado en el cielo raso
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 7000, 27, NULL),
(22, 1, 'ISM-022', 'Framel LED 24W cuadrado de sobreponer', 'framel-led-24w-cuadrado-de-sobreponer', 'Panel LED (framel) cuadrado de 24W para instalar sobre el techo. Diseño moderno, luz uniforme y bajo consumo.

✅ Potencia: 24W
💡 Panel LED de luz uniforme
🔧 De sobreponer: se instala sobre el techo, sin cortar el cielo raso
⬛ Forma cuadrada
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 13000, 19, NULL),
(23, 1, 'ISM-023', 'Framel LED 24W de sobreponer', 'framel-led-24w-de-sobreponer', 'Panel LED (framel) de 24W para instalar sobre el techo, sin cortar el cielo raso. Luz uniforme y bajo consumo.

✅ Potencia: 24W
💡 Panel LED de luz uniforme
🔧 De sobreponer: se instala sobre el techo, sin cortar el cielo raso
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 11000, 22, NULL),
(24, 1, 'ISM-024', 'Framel LED 24W de incrustar', 'framel-led-24w-de-incrustar', 'Panel LED (framel) de 24W para incrustar en el cielo raso. Acabado delgado y moderno, luz uniforme y bajo consumo.

✅ Potencia: 24W
💡 Panel LED de luz uniforme
🔧 De incrustar: va empotrado en el cielo raso
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 9000, 16, NULL),
(25, 1, 'ISM-025', 'Framel LED 24W de incrustar 3 tonos', 'framel-led-24w-de-incrustar-3-tonos', 'Panel LED (framel) de 24W para incrustar en el cielo raso. Permite cambiar entre tres tonos de luz (blanca, neutra y cálida) según el ambiente que quieras.

✅ Potencia: 24W
💡 Panel LED de luz uniforme
🔧 De incrustar: va empotrado en el cielo raso
🎨 3 tonos de luz: blanca, neutra y cálida
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 14000, 3, NULL),
(26, 1, 'ISM-026', 'Framel LED 24W de sobreponer luz cálida', 'framel-led-24w-de-sobreponer-luz-calida', 'Panel LED (framel) de 24W para instalar sobre el techo, en luz cálida (L/C). Luz acogedora, ideal para habitaciones y salas.

✅ Potencia: 24W
💡 Panel LED de luz uniforme
🔧 De sobreponer: se instala sobre el techo, sin cortar el cielo raso
🌅 Luz cálida (L/C)
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 13000, 15, 'catalogo/framel-24w-sobreponer-l-c.jpg'),
(27, 1, 'ISM-027', 'Framel LED 36W de sobreponer', 'framel-led-36w-de-sobreponer', 'Panel LED (framel) de 36W para instalar sobre el techo. Alta luminosidad para salas, cocinas, oficinas y locales.

✅ Potencia: 36W
💡 Panel LED de luz uniforme
🔧 De sobreponer: se instala sobre el techo, sin cortar el cielo raso
🔆 Alta luminosidad
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 14000, 7, 'catalogo/framel-36w-de-sobreponer.jpg'),
(28, 1, 'ISM-028', 'Framel LED 36W de incrustar', 'framel-led-36w-de-incrustar', 'Panel LED (framel) de 36W para incrustar en el cielo raso. Alta luminosidad para salas, cocinas, oficinas y locales.

✅ Potencia: 36W
💡 Panel LED de luz uniforme
🔧 De incrustar: va empotrado en el cielo raso
🔆 Alta luminosidad
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 12000, 40, 'catalogo/framel-36w-incrustar.avif'),
(29, 1, 'ISM-029', 'Framel LED 36W de incrustar 3 tonos', 'framel-led-36w-de-incrustar-3-tonos', 'Panel LED (framel) de 36W para incrustar en el cielo raso. Permite cambiar entre tres tonos de luz (blanca, neutra y cálida) según el ambiente que quieras.

✅ Potencia: 36W
💡 Panel LED de luz uniforme
🔧 De incrustar: va empotrado en el cielo raso
🎨 3 tonos de luz: blanca, neutra y cálida
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 17000, 15, NULL),
(30, 1, 'ISM-030', 'Framel LED 36W de sobreponer 3 tonos', 'framel-led-36w-de-sobreponer-3-tonos', 'Panel LED (framel) de 36W para instalar sobre el techo. Permite cambiar entre tres tonos de luz (blanca, neutra y cálida) según el ambiente que quieras.

✅ Potencia: 36W
💡 Panel LED de luz uniforme
🔧 De sobreponer: se instala sobre el techo, sin cortar el cielo raso
🎨 3 tonos de luz: blanca, neutra y cálida
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 18000, 14, 'catalogo/framel-36w-sobreponer-3-tonos.webp'),
(31, 1, 'ISM-031', 'Framel LED 36W de sobreponer borde negro', 'framel-led-36w-de-sobreponer-borde-negro', 'Panel LED (framel) de 36W para instalar sobre el techo, con borde negro que le da un acabado moderno y elegante.

✅ Potencia: 36W
💡 Panel LED de luz uniforme
🔧 De sobreponer: se instala sobre el techo, sin cortar el cielo raso
⬛ Borde negro elegante
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 25000, 5, 'catalogo/framel-s-p-36w-borde-negro.jpg'),
(32, 1, 'ISM-032', 'Lámpara de lujo LED 28W 3 tonos', 'lampara-de-lujo-led-28w-3-tonos', 'Lámpara LED de lujo de 28W con diseño decorativo para techo. Permite cambiar entre tres tonos de luz (blanca, neutra y cálida) según el ambiente que quieras. Ideal para salas, comedores y habitaciones.

✅ Potencia: 28W
💎 Diseño de lujo para techo
🎨 3 tonos de luz: blanca, neutra y cálida
💡 Tecnología LED
🏠 Ideal para salas, comedores y habitaciones', 55000, 15, 'catalogo/lampara-de-lujo-28w-3-tonos.jpg'),
(33, 1, 'ISM-033', 'Lámpara de pinza', 'lampara-de-pinza', 'Lámpara de pinza que se sujeta a mesas, repisas o escritorios. Práctica para leer, estudiar o trabajar con luz dirigida.

🗜️ Se sujeta con pinza a mesas, repisas o escritorios
🎯 Luz dirigida
📚 Ideal para leer, estudiar o trabajar', 18000, 2, 'catalogo/lampara-de-pinza.jpg'),
(34, 1, 'ISM-034', 'Lámpara decorativa LED 35W 3 tonos', 'lampara-decorativa-led-35w-3-tonos', 'Lámpara LED decorativa de 35W para techo. Permite cambiar entre tres tonos de luz (blanca, neutra y cálida) según el ambiente que quieras. Ideal para salas, comedores y habitaciones.

✅ Potencia: 35W
✨ Diseño decorativo para techo
🎨 3 tonos de luz: blanca, neutra y cálida
💡 Tecnología LED
🏠 Ideal para salas, comedores y habitaciones', 60000, 9, 'catalogo/lampara-decorativa-35w-3-tonos.jpg'),
(35, 1, 'ISM-035', 'Panel LED 12W de incrustar', 'panel-led-12w-de-incrustar', '✅ Potencia: 12W
✅ Incluye driver
✅ Diseño delgado y moderno
✅ Bajo consumo de energía
✅ Iluminación uniforme
✅ Ideal para diferentes espacios', 7000, 40, 'catalogo/panel-12w-incrustar.webp'),
(36, 1, 'ISM-036', 'Panel LED 12W de sobreponer', 'panel-led-12w-de-sobreponer', 'Panel LED de 12W para instalar sobre el techo, sin cortar el cielo raso. Luz uniforme y bajo consumo; ideal para baños, pasillos y habitaciones.

✅ Potencia: 12W
💡 Panel LED de luz uniforme
🔧 De sobreponer: se instala sobre el techo, sin cortar el cielo raso
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 7500, 64, NULL),
(37, 1, 'ISM-037', 'Panel LED 18W de incrustar', 'panel-led-18w-de-incrustar', 'las medidas son 20cm y trae driver

✅ Potencia: 18W
📏 Medida: 20 cm
✅ Incluye driver
🔧 De incrustar: va empotrado en el cielo raso
💡 Luz LED uniforme
💰 Bajo consumo de energía', 8000, 26, 'catalogo/panel-18w-incrustar.jpg'),
(38, 1, 'ISM-038', 'Panel LED 18W de sobreponer', 'panel-led-18w-de-sobreponer', 'las medidas son 2.4cm de ancho y de largo 20.4cm

✅ Potencia: 18W
🔧 De sobreponer: se instala sobre el techo, sin cortar el cielo raso
💡 Luz LED uniforme
✨ Diseño delgado y moderno
💰 Bajo consumo de energía', 9000, 71, 'catalogo/panel-18w-sobreponer.jpg'),
(39, 1, 'ISM-039', 'Panel LED 9W', 'panel-led-9w', 'Panel LED de 9W, compacto y de bajo consumo. Ideal para baños, pasillos, closets y espacios pequeños.

✅ Potencia: 9W
💡 Panel LED compacto
💰 Bajo consumo de energía
🚿 Ideal para baños, pasillos, closets y espacios pequeños', 6000, 32, NULL),
(40, 1, 'ISM-040', 'Ramal de 10 m para 20 bombillos', 'ramal-de-10-m-para-20-bombillos', 'Ramal (guirnalda) de 10 metros con 20 portabombillos. Ideal para decorar patios, terrazas, jardines, eventos y negocios. Los bombillos se venden por separado.

📏 Longitud: 10 metros
💡 20 portabombillos
🎉 Ideal para patios, terrazas, jardines, eventos y negocios
ℹ️ Bombillos no incluidos', 30000, 1, 'catalogo/ramal-10-mt-20-bombillo.jpg'),
(41, 1, 'ISM-041', 'Reflector solar LED 100W', 'reflector-solar-led-100w', '✅ Potencia: 100W
☀️ Energía solar: no necesita conexión eléctrica
💡 Iluminación LED de alta potencia
🌧️ Resistente al agua y al exterior
🔋 Panel solar + batería recargable
🌙 Encendido automático durante la noche
📦 Ideal para hogares, negocios y espacios exteriores.', 100000, 1, 'catalogo/reflector-100w-solar.jpg'),
(42, 1, 'ISM-042', 'Reflector solar LED 200W', 'reflector-solar-led-200w', 'Reflector LED solar de 200W con panel solar: no necesita conexión eléctrica. Ideal para iluminar patios, fachadas, parqueaderos, fincas y espacios exteriores.

✅ Potencia: 200W
☀️ Energía solar: no necesita conexión eléctrica
💡 Iluminación LED de alta potencia
🏡 Ideal para patios, fachadas, parqueaderos y fincas', 125000, 2, 'catalogo/reflector-de-200w-solar.webp'),
(43, 1, 'ISM-043', 'Sensor de movimiento de techo Leviton', 'sensor-de-movimiento-de-techo-leviton', 'El sensor de techo Leviton detecta el movimiento y controla automáticamente la iluminación, ofreciéndote comodidad, seguridad y ahorro de energía.', 80000, 10, 'catalogo/sensor-de-techo-leviton.jpg'),
(44, 1, 'ISM-044', 'Sensor de toque con reloj', 'sensor-de-toque-con-reloj', 'Sensor de toque con reloj digital para espejos con luz LED: enciende y apaga la iluminación con solo tocarlo y muestra la hora. Ideal para baños y tocadores.

👆 Encendido y apagado con solo tocarlo
⏰ Reloj digital integrado
🪞 Para espejos con luz LED
🚿 Ideal para baños y tocadores', 35000, 1, 'catalogo/sensor-de-toque-con-reloj.jpg'),
(45, 1, 'ISM-045', 'Roseta con sensor de movimiento', 'roseta-con-sensor-de-movimiento', '✅ Sensor de movimiento
💡 Encendido y apagado automático
🏠 Ideal para pasillos, baños, entradas, escaleras y garajes
⚡ Fácil instalación
💰 Ayuda a ahorrar energía
🔌 Compatible con diferentes tipos de bombillos', 18000, 37, 'catalogo/sensor-roseta.jpg'),
(46, 1, 'ISM-046', 'Sensor touch para madera', 'sensor-touch-para-madera', 'Interruptor touch (táctil) en madera: enciende y apaga la luz con solo tocarlo o acercar la mano. Diseño decorativo para muebles, closets, cabeceros y espejos.

👆 Interruptor táctil (touch)
✋ Funciona al tocarlo o acercar la mano
🪵 Acabado en madera
🏠 Ideal para muebles, closets, cabeceros y espejos', 35000, 3, 'catalogo/tous-de-madera.jpg'),
(47, 1, 'ISM-047', 'Sensor touch para espejo', 'sensor-touch-para-espejo', 'Interruptor touch (táctil) para espejo: se instala detrás del vidrio y enciende o apaga la luz del espejo con solo tocarlo. Ideal para baños y tocadores.

👆 Interruptor táctil (touch)
🪞 Se instala detrás del vidrio del espejo
💡 Enciende y apaga la luz del espejo
🚿 Ideal para baños y tocadores', 20000, 7, 'catalogo/tous-para-espejo.jpg'),
(48, 2, 'ISM-048', '2 tomas dobles + interruptor Boccherini', '2-tomas-dobles-interruptor-boccherini', 'Placa Boccherini con toma doble e interruptor en una sola pieza. Ideal para cocinas, habitaciones y salas donde necesitas enchufe y control de luz en el mismo punto.

🔌 2 tomas + 1 interruptor en una sola placa
🏷️ Marca Boccherini
⚡ Enchufe y control de luz en el mismo punto
🏠 Ideal para cocinas, habitaciones y salas', 15000, 20, 'catalogo/2-toma-doble-interruptor-bocherine.jpg'),
(49, 2, 'ISM-049', 'Clavija doméstica Codelca', 'clavija-domestica-codelca', 'Clavija doméstica Codelca para armar o reparar extensiones y cables de electrodomésticos.

🔌 Clavija de uso doméstico
🏷️ Marca Codelca
🔧 Para armar o reparar extensiones y cables', 3500, 3, 'catalogo/clavija-domestica-codelca.jpg'),
(50, 2, 'ISM-050', 'Clavija industrial Codelca', 'clavija-industrial-codelca', 'Clavija industrial Codelca de construcción reforzada, para herramientas y equipos de uso intensivo.

🔌 Clavija de uso industrial
🏷️ Marca Codelca
💪 Construcción reforzada
🛠️ Para herramientas y equipos de uso intensivo', 4500, 4, 'catalogo/clavija-industrial-codelca.webp'),
(51, 2, 'ISM-051', 'Clavija plástica AVE', 'clavija-plastica-ave', 'Clavija plástica AVE para armar o reparar cables de lámparas, electrodomésticos y extensiones.

🔌 Clavija plástica
🏷️ Marca AVE
🔧 Para cables de lámparas, electrodomésticos y extensiones', 2500, 22, 'catalogo/clavija-plastica-ave.jpg'),
(52, 2, 'ISM-052', 'Extensión eléctrica 2 m', 'extension-electrica-2-m', 'Extensión eléctrica de 2 metros para conectar equipos lejos del tomacorriente.

📏 Longitud: 2 metros
🔌 Extensión eléctrica
🏠 Conecta equipos lejos del tomacorriente', 12000, 2, 'catalogo/extencion-2mt.webp'),
(53, 2, 'ISM-053', 'Interruptor + toma de sobreponer', 'interruptor-toma-de-sobreponer', 'Interruptor y toma en una sola pieza para instalar sobre el muro (de sobreponer), sin necesidad de caja empotrada.

🔌 Interruptor + toma en una sola pieza
🔧 De sobreponer: va sobre el muro
📦 No necesita caja empotrada', 4000, 19, 'catalogo/interruptor-toma-s-p.jpg'),
(54, 2, 'ISM-054', 'Interruptor de paso', 'interruptor-de-paso', 'Interruptor de paso que se instala sobre el cable, para encender y apagar lámparas de mesa, de pie o equipos.

🔘 Interruptor de paso
🔧 Se instala sobre el cable
💡 Para lámparas de mesa, de pie y equipos', 1500, 20, 'catalogo/interruptor-de-paso.jpg'),
(55, 2, 'ISM-055', 'Interruptor de sobreponer', 'interruptor-de-sobreponer', 'Interruptor sencillo para instalar sobre el muro (de sobreponer), sin necesidad de caja empotrada.

🔘 Interruptor sencillo
🔧 De sobreponer: va sobre el muro
📦 No necesita caja empotrada', 2500, 26, 'catalogo/interruptor-de-s-p.webp'),
(56, 2, 'ISM-056', 'Interruptor doble conmutable Gálica 2', 'interruptor-doble-conmutable-galica-2', 'Interruptor doble conmutable línea Gálica 2: controla dos luces independientes y permite encender o apagar desde dos puntos distintos, como al inicio y al final de una escalera o pasillo.

🔘 Interruptor doble conmutable
🏷️ Línea Gálica 2
💡 Controla dos luces independientes
↔️ Enciende y apaga desde dos puntos distintos
🏠 Ideal para escaleras y pasillos', 17000, 14, 'catalogo/interruptor-doble-conmutable-galica2.jpg'),
(57, 2, 'ISM-057', 'Interruptor doble de sobreponer', 'interruptor-doble-de-sobreponer', 'Interruptor doble para instalar sobre el muro (de sobreponer): controla dos luces de forma independiente, sin necesidad de caja empotrada.

🔘 Interruptor doble
💡 Controla dos luces de forma independiente
🔧 De sobreponer: va sobre el muro
📦 No necesita caja empotrada', 4000, 16, 'catalogo/interruptor-doble-s-p.jpg'),
(58, 2, 'ISM-058', 'Interruptor Plus negro', 'interruptor-plus-negro', 'Interruptor de la línea Plus en color negro, con diseño moderno que combina con decoraciones contemporáneas.

🔘 Interruptor
🏷️ Línea Plus
⚫ Color negro
✨ Diseño moderno', 4800, 10, 'catalogo/interruptor-plus-negro.jpg'),
(59, 2, 'ISM-059', 'Interruptor sencillo Gálica 2', 'interruptor-sencillo-galica-2', 'Interruptor sencillo línea Gálica 2, de acabado limpio y moderno para instalaciones de hogar y oficina.

🔘 Interruptor sencillo
🏷️ Línea Gálica 2
✨ Acabado limpio y moderno
🏠 Para hogar y oficina', 8500, 13, 'catalogo/interruptor-sencillo-galica-2.jpg'),
(60, 2, 'ISM-060', 'Multitoma 3 salidas', 'multitoma-3-salidas', 'Multitoma de 3 salidas para conectar varios equipos desde un solo tomacorriente.

🔌 3 salidas
⚡ Conecta varios equipos desde un solo tomacorriente
🏠 Ideal para el hogar y la oficina', 8000, 2, 'catalogo/multitoma-3-salidas.jpg'),
(61, 2, 'ISM-061', 'Multitoma con cable de 3 m', 'multitoma-con-cable-de-3-m', 'Multitoma con cable de 3 metros para conectar varios equipos lejos del tomacorriente.

📏 Cable de 3 metros
🔌 Varias salidas
⚡ Conecta varios equipos lejos del tomacorriente', 15000, 3, 'catalogo/multitoma-de-3mt.jpg'),
(62, 2, 'ISM-062', 'Protector de voltaje 20 A', 'protector-de-voltaje-20-a', 'Protector de voltaje de 20 amperios que resguarda tus equipos y electrodomésticos de subidas y bajadas de tensión.

⚡ Capacidad: 20 amperios
🛡️ Protege contra subidas y bajadas de voltaje
📺 Ideal para electrodomésticos y equipos electrónicos', 45000, 1, 'catalogo/protector-de-voltaje-20amp.jpg'),
(63, 2, 'ISM-063', 'Toma 15 A Leviton', 'toma-15-a-leviton', 'Toma de 15 amperios marca Leviton, de buena calidad para instalaciones residenciales.

🔌 Toma de 15 amperios
🏷️ Marca Leviton
🏠 Para instalaciones residenciales', 6500, 10, 'catalogo/toma-15-amp-leviton.jpg'),
(64, 2, 'ISM-064', 'Toma 20 A', 'toma-20-a', 'Toma de 20 amperios para equipos de mayor consumo, como electrodomésticos y herramientas.

🔌 Toma de 20 amperios
⚡ Para equipos de mayor consumo
🛠️ Ideal para electrodomésticos y herramientas', 13000, 6, 'catalogo/toma-20amp.jpg'),
(65, 2, 'ISM-065', 'Toma doble de sobreponer Eco', 'toma-doble-de-sobreponer-eco', 'Toma de sobreponer línea económica, para instalar sobre el muro sin necesidad de caja empotrada.

🔌 Toma de sobreponer
💰 Línea económica
🔧 Va sobre el muro, sin caja empotrada', 2800, 10, 'catalogo/toma-de-sobreponer-eco.jpg'),
(66, 2, 'ISM-066', 'Toma Plus negra', 'toma-plus-negra', 'Toma de la línea Plus en color negro, con diseño moderno que combina con decoraciones contemporáneas.

🔌 Toma
🏷️ Línea Plus
⚫ Color negro
✨ Diseño moderno', 5000, 1, 'catalogo/toma-plus-negra.jpg'),
(67, 2, 'ISM-067', 'Toma plástica AVE', 'toma-plastica-ave', 'Toma plástica AVE de buena calidad para instalaciones residenciales.

🔌 Toma plástica
🏷️ Marca AVE
🏠 Para instalaciones residenciales', 3500, 16, 'catalogo/toma-plastica-ave.jpg'),
(68, 2, 'ISM-068', 'Toma de sobreponer', 'toma-de-sobreponer', 'Toma para instalar sobre el muro (de sobreponer), sin necesidad de caja empotrada.

🔌 Toma de sobreponer
🔧 Va sobre el muro
📦 No necesita caja empotrada', 3500, 10, 'catalogo/toma-s-p.jpg'),
(69, 2, 'ISM-069', 'Toma de sobreponer de lujo', 'toma-de-sobreponer-de-lujo', 'Toma de sobreponer línea de lujo, con mejor acabado, para instalar sobre el muro sin caja empotrada.

🔌 Toma de sobreponer
💎 Línea de lujo, mejor acabado
🔧 Va sobre el muro, sin caja empotrada', 4500, 10, 'catalogo/toma-s-p-lujo.jpg'),
(70, 2, 'ISM-070', 'Toma triple Boccherini', 'toma-triple-boccherini', 'Toma triple Boccherini: tres conexiones en un solo punto, ideal para cocinas, escritorios y zonas con varios equipos.

🔌 3 conexiones en un solo punto
🏷️ Marca Boccherini
🏠 Ideal para cocinas, escritorios y zonas con varios equipos', 15000, 20, NULL),
(71, 3, 'ISM-071', 'Boquilla 1"', 'boquilla-1', 'Boquilla metálica de 1" que se coloca en la salida del tubo para proteger el aislamiento de los cables contra cortes y roces.

📏 Medida: 1"
🔩 Boquilla metálica
🛡️ Protege el aislamiento de los cables en la salida del tubo', 3500, 2, 'catalogo/boquilla-1.jpg'),
(72, 3, 'ISM-072', 'Caja 2400 PVC 10x10', 'caja-2400-pvc-10x10', 'Caja 2400 de PVC de 10x10 cm para empotrar tomas e interruptores en instalaciones con tubería PVC.

📦 Caja 2400 de PVC
📏 Medida: 10x10 cm
🔧 Para empotrar tomas e interruptores
🏗️ Para instalaciones con tubería PVC', 3000, 6, 'catalogo/caja-2400-pvc-10x10.jpg'),
(73, 3, 'ISM-073', 'Caja 2400 Rawelt 3/4"', 'caja-2400-rawelt-3-4', 'Caja 2400 metálica rawuel para tubo de 3/4", para alojar tomas e interruptores en instalaciones con tubería metálica.

📦 Caja 2400 metálica
🏷️ Rawuel
📏 Para tubo de 3/4"
🔧 Aloja tomas e interruptores', 18000, 4, 'catalogo/caja-2400-rawuel-3-4.jpg'),
(74, 3, 'ISM-074', 'Caja 2400 Rawelt 3/4" doble fondo', 'caja-2400-rawelt-3-4-doble-fondo', 'Caja 2400 metálica rawuel de doble fondo para tubo de 3/4": más espacio interno para cables y empalmes.

📦 Caja 2400 metálica de doble fondo
🏷️ Rawuel
📏 Para tubo de 3/4"
➕ Más espacio para cables y empalmes', 24500, 4, 'catalogo/caja-2400-rawuel-3-4-doble-fondo.jpg'),
(75, 3, 'ISM-075', 'Caja 5800 metálica', 'caja-5800-metalica', 'Caja 5800 metálica para instalaciones eléctricas empotradas, con mayor espacio para conexiones.

📦 Caja 5800 metálica
🔧 Para instalaciones empotradas
➕ Mayor espacio para conexiones', 2500, 16, 'catalogo/caja-5800-metalica.jpg'),
(76, 3, 'ISM-076', 'Caja 5800 Rawelt 3/4"', 'caja-5800-rawelt-3-4', 'Caja 5800 metálica rawuel para tubo de 3/4", para alojar conexiones, tomas e interruptores.

📦 Caja 5800 metálica
🏷️ Rawuel
📏 Para tubo de 3/4"
🔧 Aloja conexiones, tomas e interruptores', 11000, 8, 'catalogo/caja-5800-rawuel-3-4.jpg'),
(77, 3, 'ISM-077', 'Caja octagonal Rawelt 3/4"', 'caja-octagonal-rawelt-3-4', 'Caja octagonal metálica rawuel para tubo de 3/4", usada como salida de lámparas en el techo y para empalmes.

📦 Caja octagonal metálica
🏷️ Rawuel
📏 Para tubo de 3/4"
💡 Salida de lámparas en el techo y empalmes', 12500, 15, 'catalogo/caja-octagonal-rawuel-3-4.jpg'),
(78, 3, 'ISM-078', 'Capacete 1"', 'capacete-1', 'Capacete de 1" que se instala en el extremo superior del tubo de la acometida para impedir la entrada del agua de lluvia.

📏 Medida: 1"
🌧️ Impide la entrada del agua de lluvia
🔧 Va en el extremo superior del tubo de la acometida', 4000, 3, 'catalogo/capacete-1.jpg'),
(79, 3, 'ISM-079', 'Cinta aislante', 'cinta-aislante', 'Cinta aislante para aislar y proteger empalmes y conexiones eléctricas.

🛡️ Aísla y protege empalmes
⚡ Para conexiones eléctricas
🔧 Fácil de aplicar', 3000, 69, 'catalogo/cinta-aislante.jpg'),
(80, 3, 'ISM-080', 'Conduleta LR 3/4" lisa', 'conduleta-lr-3-4-lisa', 'Conduleta 3/4" tipo LR lisa para cambiar la dirección de la tubería y facilitar el paso del cableado.

📏 Medida: 3/4"
🔩 Conduleta tipo LR lisa
↪️ Cambia la dirección de la tubería
🔧 Facilita el paso del cableado', 10000, 6, 'catalogo/conduleta-3-4-lr-lisa.jpg'),
(81, 3, 'ISM-081', 'Conector dentado grande', 'conector-dentado-grande', 'Conector dentado (de perforación) grande para derivar conexiones en cables de acometida sin necesidad de pelarlos.

🔩 Conector dentado (de perforación)
📏 Tamaño grande
⚡ Deriva conexiones sin pelar el cable
🏠 Para cables de acometida', 12000, 4, 'catalogo/conector-dentado-grande.jpg'),
(82, 3, 'ISM-082', 'Contador de energía interno', 'contador-de-energia-interno', 'Contador (medidor) de energía para medir el consumo eléctrico de un apartamento, local o habitación por separado.

📊 Medidor de energía
⚡ Mide el consumo eléctrico por separado
🏢 Ideal para apartamentos, locales y habitaciones', 38000, 3, 'catalogo/contadores-internos.jpg'),
(83, 3, 'ISM-083', 'Curva EMT 1 1/2"', 'curva-emt-1-1-2', 'Curva EMT de 1 1/2" para cambiar la dirección de la tubería metálica.

✅ Curva EMT de 1 1/2"
🔩 Para tubería metálica EMT
🔧 Cambia la dirección de la tubería
🏗️ Para instalaciones residenciales y comerciales', 10500, 4, 'catalogo/curva-1-1-2-emt.jpg'),
(84, 3, 'ISM-084', 'Curva EMT 1"', 'curva-emt-1', 'Curva EMT de 1" para cambiar la dirección de la tubería metálica.

✅ Curva EMT de 1"
🔩 Para tubería metálica EMT
🔧 Cambia la dirección de la tubería
🏗️ Para instalaciones residenciales y comerciales', 5500, 8, 'catalogo/curva-1-emt.jpg'),
(85, 3, 'ISM-085', 'Curva galvanizada 1 1/4"', 'curva-galvanizada-1-1-4', 'Curva galvanizada de 1 1/4" para cambiar la dirección de la tubería galvanizada, ideal para acometidas.

✅ Curva galvanizada de 1 1/4"
🔩 Para tubería galvanizada
↪️ Cambia la dirección de la tubería
🏠 Ideal para acometidas', 12500, 3, 'catalogo/curva-galvanizada-1-1-4.jpg'),
(86, 3, 'ISM-086', 'Curva galvanizada 1"', 'curva-galvanizada-1', 'Curva galvanizada de 1" para cambiar la dirección de la tubería galvanizada, ideal para acometidas.

✅ Curva galvanizada de 1"
🔩 Para tubería galvanizada
↪️ Cambia la dirección de la tubería
🏠 Ideal para acometidas', 12000, 4, 'catalogo/curva-galvanizada-1.jpg'),
(87, 3, 'ISM-087', 'Grapa EMT 1 1/4" doble ala', 'grapa-emt-1-1-4-doble-ala', 'Grapa de doble ala para tubo EMT de 1 1/4": fija la tubería a muros y techos.

✅ Grapa doble ala EMT de 1 1/4"
🔩 Para tubería metálica EMT
🔧 Fija la tubería a muros y techos
🏗️ Para instalaciones residenciales y comerciales', 800, 3, 'catalogo/grapa-1-1-4-emt-doble-ala.jpg'),
(88, 3, 'ISM-088', 'Grapa EMT 1/2" doble ala', 'grapa-emt-1-2-doble-ala', 'Grapa de doble ala para tubo EMT de 1/2": fija la tubería a muros y techos.

✅ Grapa doble ala EMT de 1/2"
🔩 Para tubería metálica EMT
🔧 Fija la tubería a muros y techos
🏗️ Para instalaciones residenciales y comerciales', 300, 18, 'catalogo/grapa-1-2-emt-doble-ala.jpg'),
(89, 3, 'ISM-089', 'Grapa EMT 3/4" 1 ala', 'grapa-emt-3-4-1-ala', 'Grapa de un ala para tubo EMT de 3/4": fija la tubería a muros y techos.

✅ Grapa de un ala EMT de 3/4"
🔩 Para tubería metálica EMT
🔧 Fija la tubería a muros y techos
🏗️ Para instalaciones residenciales y comerciales', 400, 42, 'catalogo/grapa-3-4-emt-1-ala.jpg'),
(90, 3, 'ISM-090', 'Grapa EMT 3/4" doble ala', 'grapa-emt-3-4-doble-ala', 'Grapa de doble ala para tubo EMT de 3/4": fija la tubería a muros y techos.

✅ Grapa doble ala EMT de 3/4"
🔩 Para tubería metálica EMT
🔧 Fija la tubería a muros y techos
🏗️ Para instalaciones residenciales y comerciales', 400, 10, 'catalogo/grapa-3-4-emt-doble-ala.jpg'),
(91, 3, 'ISM-091', 'Portatensor', 'portatensor', 'Porta tensor metálico que se ajusta al tubo de la acometida para sujetar el tensor del cable.

🔩 Porta tensor metálico
🔧 Se ajusta al tubo de la acometida
🔗 Sujeta el tensor del cable', 3500, 2, 'catalogo/porta-tensor.jpg'),
(92, 3, 'ISM-092', 'Suplemento PVC', 'suplemento-pvc', 'Suplemento de PVC para cajas eléctricas: nivela la caja con el acabado final del muro.

📦 Suplemento de PVC para cajas
📐 Nivela la caja con el acabado del muro
🔧 Fácil instalación', 800, 1, 'catalogo/suplemento-pvc.jpg'),
(93, 3, 'ISM-093', 'Tablero de 2 circuitos FEM', 'tablero-de-2-circuitos-fem', 'Tablero eléctrico FEM de 2 circuitos para instalar los breakers (tacos) de la vivienda o local.

✅ Tablero de 2 circuitos
🏷️ Marca FEM
⚡ Aloja los breakers (tacos) de la instalación
🏠 Para viviendas, apartamentos y locales', 22000, 1, 'catalogo/tablero-2-circuitos-fem.jpg'),
(94, 3, 'ISM-094', 'Tablero de 4 circuitos Tercol barraje en cobre', 'tablero-de-4-circuitos-tercol-barraje-en-cobre', 'Tablero eléctrico Tercol de 4 circuitos con barraje en cobre, para instalar los breakers (tacos) de la vivienda o local.

✅ Tablero de 4 circuitos
🏷️ Marca Tercol
🟠 Barraje en cobre
⚡ Aloja los breakers (tacos) de la instalación
🏠 Para viviendas, apartamentos y locales', 54000, 1, NULL),
(95, 3, 'ISM-095', 'Tablero de 6 circuitos con tapa FEM', 'tablero-de-6-circuitos-con-tapa-fem', 'Tablero eléctrico FEM de 6 circuitos con tapa, para instalar los breakers (tacos) de la vivienda o local.

✅ Tablero de 6 circuitos
🏷️ Marca FEM
🚪 Con tapa
⚡ Aloja los breakers (tacos) de la instalación
🏠 Para viviendas, apartamentos y locales', 45000, 1, 'catalogo/tablero-6-circuitos-con-tapa-fem.jpg'),
(96, 3, 'ISM-096', 'Tablero de 6 circuitos FEM', 'tablero-de-6-circuitos-fem', 'Tablero eléctrico FEM de 6 circuitos para instalar los breakers (tacos) de la vivienda o local.

✅ Tablero de 6 circuitos
🏷️ Marca FEM
⚡ Aloja los breakers (tacos) de la instalación
🏠 Para viviendas, apartamentos y locales', 37000, 2, 'catalogo/tablero-6-circuitos-fem.jpg'),
(97, 3, 'ISM-097', 'Tablero de 6 circuitos Tercol barraje en cobre', 'tablero-de-6-circuitos-tercol-barraje-en-cobre', 'Tablero eléctrico Tercol de 6 circuitos con barraje en cobre, para instalar los breakers (tacos) de la vivienda o local.

✅ Tablero de 6 circuitos
🏷️ Marca Tercol
🟠 Barraje en cobre
⚡ Aloja los breakers (tacos) de la instalación
🏠 Para viviendas, apartamentos y locales', 68000, 1, NULL),
(98, 3, 'ISM-098', 'Tablero de 3 circuitos FEM', 'tablero-de-3-circuitos-fem', 'Tablero eléctrico FEM de 3 circuitos para instalar los breakers (tacos) de la vivienda o local.

✅ Tablero de 3 circuitos
🏷️ Marca FEM
⚡ Aloja los breakers (tacos) de la instalación
🏠 Para viviendas, apartamentos y locales', 25000, 2, NULL),
(99, 3, 'ISM-099', 'Taco Luminex', 'taco-luminex', 'producto original

⚡ Taco (breaker) marca Luminex
🔌 Cortacircuito termomagnético de 1 polo
🛡️ Protege los circuitos de la instalación
🏠 Para tableros de viviendas y locales', 17000, 33, 'catalogo/taco-luminex.jpg'),
(100, 3, 'ISM-100', 'Tapa ciega 2400 EMT', 'tapa-ciega-2400-emt', 'Tapa ciega metálica para caja 2400: cubre las cajas que no llevan toma ni interruptor.

✅ Tapa ciega metálica
📦 Para caja 2400
🔒 Cubre y protege las cajas sin uso
✨ Deja un acabado limpio en el muro', 1500, 0, 'catalogo/tapa-ciega-2400-emt.jpg'),
(101, 3, 'ISM-101', 'Tapa ciega 5800 EMT', 'tapa-ciega-5800-emt', 'Tapa ciega metálica para caja 5800: cubre las cajas que no llevan toma ni interruptor.

✅ Tapa ciega metálica
📦 Para caja 5800
🔒 Cubre y protege las cajas sin uso
✨ Deja un acabado limpio en el muro', 1500, 23, 'catalogo/tapa-ciega-5800-emt.jpg'),
(102, 3, 'ISM-102', 'Tapa ciega octagonal EMT', 'tapa-ciega-octagonal-emt', 'Tapa ciega metálica para caja octagonal: cubre las cajas que no llevan lámpara.

✅ Tapa ciega metálica
📦 Para caja octagonal
🔒 Cubre y protege las cajas sin uso
✨ Deja un acabado limpio en el muro', 1800, 21, 'catalogo/tapa-ciega-octagonal-emt.jpg'),
(103, 3, 'ISM-103', 'Tapa ciega 2400 PVC', 'tapa-ciega-2400-pvc', 'Tapa ciega plástica para caja 2400: cubre las cajas que no llevan toma ni interruptor.

✅ Tapa ciega plástica
📦 Para caja 2400
🔒 Cubre y protege las cajas sin uso
✨ Deja un acabado limpio en el muro', 800, 16, 'catalogo/tapa-ciega-pvc-2400.jpg'),
(104, 3, 'ISM-104', 'Tapa ciega 5800 PVC', 'tapa-ciega-5800-pvc', 'Tapa ciega plástica para caja 5800: cubre las cajas que no llevan toma ni interruptor.

✅ Tapa ciega plástica
📦 Para caja 5800
🔒 Cubre y protege las cajas sin uso
✨ Deja un acabado limpio en el muro', 600, 11, 'catalogo/tapa-ciega-pvc-5800.jpg'),
(105, 3, 'ISM-105', 'Tapa de intemperie para toma', 'tapa-de-intemperie-para-toma', 'Tapa para intemperie que protege tomas e interruptores instalados al aire libre de la lluvia y el polvo.

🌧️ Para intemperie
🛡️ Protege tomas e interruptores de la lluvia y el polvo
🏡 Ideal para patios, fachadas y zonas exteriores', 3500, 6, 'catalogo/tapa-interperie.jpg'),
(106, 3, 'ISM-106', 'Tensor grande', 'tensor-grande', 'Tensor grande para sujetar y templar el cable de la acometida entre el poste y la vivienda.

🔗 Tensor grande
⚡ Sujeta y templa el cable de la acometida
🏠 Entre el poste y la vivienda', 6000, 2, 'catalogo/tensor-grande.jpg'),
(107, 3, 'ISM-107', 'Terminal EMT 1 1/2"', 'terminal-emt-1-1-2', 'Terminal EMT de 1 1/2" para conectar la tubería metálica a cajas y tableros.

✅ Terminal EMT de 1 1/2"
🔩 Para tubería metálica EMT
🔧 Conecta la tubería a cajas y tableros
🏗️ Para instalaciones residenciales y comerciales', 3000, 2, NULL),
(108, 3, 'ISM-108', 'Terminal EMT 1 1/4"', 'terminal-emt-1-1-4', 'Terminal EMT de 1 1/4" para conectar la tubería metálica a cajas y tableros.

✅ Terminal EMT de 1 1/4"
🔩 Para tubería metálica EMT
🔧 Conecta la tubería a cajas y tableros
🏗️ Para instalaciones residenciales y comerciales', 2500, 13, NULL),
(109, 3, 'ISM-109', 'Terminal EMT 1"', 'terminal-emt-1', 'Terminal EMT de 1" para conectar la tubería metálica a cajas y tableros.

✅ Terminal EMT de 1"
🔩 Para tubería metálica EMT
🔧 Conecta la tubería a cajas y tableros
🏗️ Para instalaciones residenciales y comerciales', 1800, 19, 'catalogo/terminal-1-emt.jpg'),
(110, 3, 'ISM-110', 'Terminal EMT 1/2"', 'terminal-emt-1-2', 'Terminal EMT de 1/2" para conectar la tubería metálica a cajas y tableros.

✅ Terminal EMT de 1/2"
🔩 Para tubería metálica EMT
🔧 Conecta la tubería a cajas y tableros
🏗️ Para instalaciones residenciales y comerciales', 1000, 2, 'catalogo/terminal-1-2-emt.jpg'),
(111, 3, 'ISM-111', 'Terminal EMT 3/4"', 'terminal-emt-3-4', 'Terminal EMT de 3/4" para conectar la tubería metálica a cajas y tableros.

✅ Terminal EMT de 3/4"
🔩 Para tubería metálica EMT
🔧 Conecta la tubería a cajas y tableros
🏗️ Para instalaciones residenciales y comerciales', 1100, 58, 'catalogo/terminal-3-4-emt.jpg'),
(112, 3, 'ISM-112', 'Tubo PVC 1 1/2"', 'tubo-pvc-1-1-2', 'Tubo de PVC de 1 1/2" para conducir y proteger el cableado eléctrico.

📏 Medida: 1 1/2"
🟠 Tubo de PVC
🛡️ Conduce y protege el cableado', 19000, 3, 'catalogo/tubo-1-1-2-pvc.jpg'),
(113, 3, 'ISM-113', 'Tubo PVC 1 1/4" pesado', 'tubo-pvc-1-1-4-pesado', 'Tubo de PVC pesado de 1 1/4" para conducir y proteger el cableado eléctrico; más resistente, ideal para acometidas y tramos expuestos.

📏 Medida: 1 1/4"
🟠 Tubo de PVC pesado
💪 Más resistente
🏠 Ideal para acometidas y tramos expuestos', 14000, 3, NULL),
(114, 3, 'ISM-114', 'Tubo EMT 1/2" semipesado', 'tubo-emt-1-2-semipesado', 'Tubo EMT semipesado de 1/2" para conducir y proteger el cableado eléctrico en instalaciones a la vista o empotradas.

📏 Medida: 1/2"
🔩 Tubo EMT semipesado
🛡️ Conduce y protege el cableado
🏗️ Para instalaciones a la vista o empotradas', 11000, 7, NULL),
(115, 3, 'ISM-115', 'Tubo PVC 1/2" semipesado', 'tubo-pvc-1-2-semipesado', 'Tubo de PVC semipesado de 1/2" para conducir y proteger el cableado eléctrico.

📏 Medida: 1/2"
🟠 Tubo de PVC semipesado
🛡️ Conduce y protege el cableado', 2200, 16, NULL),
(116, 3, 'ISM-116', 'Tubo EMT 3/4" semipesado', 'tubo-emt-3-4-semipesado', 'Tubo EMT semipesado de 3/4" para conducir y proteger el cableado eléctrico en instalaciones a la vista o empotradas.

📏 Medida: 3/4"
🔩 Tubo EMT semipesado
🛡️ Conduce y protege el cableado
🏗️ Para instalaciones a la vista o empotradas', 15000, 0, 'catalogo/tubo-3-4-emt-semi.jpg'),
(117, 3, 'ISM-117', 'Tubo PVC 1/2" pesado', 'tubo-pvc-1-2-pesado', 'Tubo de PVC pesado de 1/2" para conducir y proteger el cableado eléctrico; más resistente a los golpes.

📏 Medida: 1/2"
🟠 Tubo de PVC pesado
💪 Más resistente a los golpes
🛡️ Conduce y protege el cableado', 4500, 77, NULL),
(118, 3, 'ISM-118', 'Unión EMT 1 1/4"', 'union-emt-1-1-4', 'Unión EMT de 1 1/4" para empalmar dos tramos de tubería metálica.

✅ Unión EMT de 1 1/4"
🔩 Para tubería metálica EMT
🔧 Empalma dos tramos de tubería
🏗️ Para instalaciones residenciales y comerciales', 2200, 4, 'catalogo/union-1-1-4-emt.jpg'),
(119, 3, 'ISM-119', 'Unión EMT 1"', 'union-emt-1', 'Unión EMT de 1" para empalmar dos tramos de tubería metálica.

✅ Unión EMT de 1"
🔩 Para tubería metálica EMT
🔧 Empalma dos tramos de tubería
🏗️ Para instalaciones residenciales y comerciales', 1800, 7, 'catalogo/union-1-emt.jpg'),
(120, 3, 'ISM-120', 'Unión EMT 1 1/2"', 'union-emt-1-1-2', 'Unión EMT de 1 1/2" para empalmar dos tramos de tubería metálica.

✅ Unión EMT de 1 1/2"
🔩 Para tubería metálica EMT
🔧 Empalma dos tramos de tubería
🏗️ Para instalaciones residenciales y comerciales', 3000, 6, NULL),
(121, 3, 'ISM-121', 'Unión galvanizada 1"', 'union-galvanizada-1', 'Unión galvanizada de 1" para empalmar dos tramos de tubería galvanizada.

✅ Unión galvanizada de 1"
🔩 Para tubería galvanizada
🔧 Empalma dos tramos de tubería', 4000, 4, 'catalogo/union-1-galvanizada.jpg'),
(122, 3, 'ISM-122', 'Unión EMT 1/2"', 'union-emt-1-2', 'Unión EMT de 1/2" para empalmar dos tramos de tubería metálica.

✅ Unión EMT de 1/2"
🔩 Para tubería metálica EMT
🔧 Empalma dos tramos de tubería
🏗️ Para instalaciones residenciales y comerciales', 1000, 17, 'catalogo/union-1-2-emt.jpg'),
(123, 3, 'ISM-123', 'Unión EMT 3/4"', 'union-emt-3-4', 'Unión EMT de 3/4" para empalmar dos tramos de tubería metálica.

✅ Unión EMT de 3/4"
🔩 Para tubería metálica EMT
🔧 Empalma dos tramos de tubería
🏗️ Para instalaciones residenciales y comerciales', 1100, 39, 'catalogo/union-3-4-emt.jpg'),
(124, 3, 'ISM-124', 'Varilla de polo a tierra enchaquetada 1,50 m + conector', 'varilla-de-polo-a-tierra-enchaquetada-1-50-m-conector', 'Varilla de cobre enchaquetada de 1,50 m con conector, para el polo a tierra de la instalación eléctrica: protege a las personas y a los equipos.

📏 Longitud: 1,50 m
🟠 Varilla de cobre enchaquetada
🔩 Incluye conector
⚡ Para el polo a tierra de la instalación
🛡️ Protege a las personas y a los equipos', 26000, 1, 'catalogo/varilla-enchaquetada-1-50-conector.jpg'),
(125, 4, 'ISM-125', 'Ducha Boccherini Maxi', 'ducha-boccherini-maxi', 'Ducha eléctrica Boccherini Maxi para calentar el agua al instante en tu baño.

🚿 Ducha eléctrica
🏷️ Marca Boccherini, modelo Maxi
🔥 Calienta el agua al instante', 75000, 1, 'catalogo/ducha-bocherini-maxi.jpg'),
(126, 4, 'ISM-126', 'Ducha eléctrica con plato cuadrado negro', 'ducha-electrica-con-plato-cuadrado-negro', 'Ducha eléctrica con plato cuadrado en color negro, de diseño moderno, para calentar el agua al instante en tu baño.

🚿 Ducha eléctrica con plato
⬛ Plato cuadrado color negro
✨ Diseño moderno
🔥 Calienta el agua al instante', 95000, 3, 'catalogo/ducha-con-plato-cuadrado-negra.jpg'),
(127, 4, 'ISM-127', 'Ducha eléctrica con plato', 'ducha-electrica-con-plato', 'Ducha eléctrica con plato para calentar el agua al instante en tu baño.

🚿 Ducha eléctrica con plato
🔥 Calienta el agua al instante
🏠 Para el baño de tu hogar', 85000, 5, 'catalogo/duchas-con-plato.jpg'),
(128, 4, 'ISM-128', 'Ducha eléctrica con plato y selector', 'ducha-electrica-con-plato-y-selector', 'Ducha eléctrica con plato y selector de temperatura para elegir qué tan caliente quieres el agua.

🚿 Ducha eléctrica con plato
🌡️ Selector de temperatura
🔥 Calienta el agua al instante', 95000, 3, 'catalogo/duchas-con-plato-con-selectot.jpg'),
(129, 4, 'ISM-129', 'Ducha eléctrica económica', 'ducha-electrica-economica', 'Ducha eléctrica económica para calentar el agua al instante en tu baño.

🚿 Ducha eléctrica
💰 Línea económica
🔥 Calienta el agua al instante', 65000, 6, 'catalogo/duchas-economicas.jpg'),
(130, 4, 'ISM-130', 'Mezclador doble', 'mezclador-doble', 'Mezclador doble para lavamanos o lavaplatos, con control de agua fría y caliente.

🚰 Mezclador doble
🌡️ Control de agua fría y caliente
🏠 Para lavamanos o lavaplatos', 35000, 7, 'catalogo/mezclador-doble.jpg'),
(131, 4, 'ISM-131', 'Mezclador sencillo', 'mezclador-sencillo', 'Mezclador sencillo para lavamanos o lavaplatos.

🚰 Mezclador sencillo
🏠 Para lavamanos o lavaplatos', 25000, 5, 'catalogo/mezclador-sencillo.webp'),
(132, 4, 'ISM-132', 'Niple para ducha metálico', 'niple-para-ducha-metalico', 'Niple metálico para instalar la ducha en el punto de agua.

🔩 Niple metálico
🚿 Para instalar la ducha en el punto de agua', 10000, 4, 'catalogo/niple-para-ducha-metalico.jpg'),
(133, 4, 'ISM-133', 'Niple para ducha plástico', 'niple-para-ducha-plastico', 'Niple plástico para instalar la ducha en el punto de agua.

🔩 Niple plástico
🚿 Para instalar la ducha en el punto de agua', 12000, 5, 'catalogo/niple-para-ducha-plastico.jpg'),
(134, 3, 'ISM-134', 'Amarres plásticos Dexson 20 cm', 'amarres-plasticos-dexson-20-cm', 'Amarres plásticos Dexson de 20 cm para organizar y sujetar cables.

📏 Largo: 20 cm
🏷️ Marca Dexson
🔗 Organiza y sujeta cables', 8000, 10, 'catalogo/amarres-dexon-20cm.jpg'),
(135, 5, 'ISM-135', 'Candado de 60 mm', 'candado-de-60-mm', 'Candado de 60 mm para asegurar puertas, rejas, bodegas y portones.

📏 Tamaño: 60 mm
🔒 Asegura puertas, rejas, bodegas y portones', 60000, 5, 'catalogo/candado-de-60mm.jpg'),
(136, 5, 'ISM-136', 'Chapa de alcoba', 'chapa-de-alcoba', 'Chapa de pomo con llave para puerta de alcoba.

🚪 Chapa de pomo para alcoba
🔑 Con llave', 20000, 2, 'catalogo/chapa-de-alcoba.jpg'),
(137, 5, 'ISM-137', 'Pelacables', 'pelacables', 'Pela cable para retirar el aislamiento de los cables de forma rápida y precisa.

✂️ Retira el aislamiento de los cables
⚡ Rápido y preciso
🛠️ Herramienta para electricistas y para el hogar', 10000, 6, 'catalogo/pela-cable.jpg'),
(138, 2, 'ISM-138', 'Pulsador de timbre de sobreponer', 'pulsador-de-timbre-de-sobreponer', 'Pulsador para timbre de sobreponer, para instalar en la entrada de la casa o del local.

🔔 Pulsador para timbre
🔧 De sobreponer
🏠 Para la entrada de la casa o del local', 2800, 5, NULL),
(139, 2, 'ISM-139', 'Timbre inalámbrico', 'timbre-inalambrico', 'Timbre inalámbrico: no necesita cableado entre el pulsador y el timbre. Fácil de instalar en casas, apartamentos y locales.

🔔 Timbre inalámbrico
📡 Sin cables entre el pulsador y el timbre
🔧 Fácil instalación
🏠 Para casas, apartamentos y locales', 20000, 7, 'catalogo/timbre-inalambrico.jpg');

-- Marcas: salen del nombre de cada producto ("Gálica 2" es una línea de Legrand)
INSERT INTO marcas (id, nombre) VALUES
(1, 'AVE'),
(2, 'Boccherini'),
(3, 'Codelca'),
(4, 'Dexson'),
(5, 'FEM'),
(6, 'Legrand'),
(7, 'Leviton'),
(8, 'Luminex'),
(9, 'Tercol'),
(10, 'Rawelt'),
(11, 'Yale');
UPDATE productos SET marca_id = 1 WHERE id IN (51, 67);  -- AVE
UPDATE productos SET marca_id = 2 WHERE id IN (48, 70, 125);  -- Boccherini
UPDATE productos SET marca_id = 3 WHERE id IN (49, 50);  -- Codelca
UPDATE productos SET marca_id = 4 WHERE id IN (134);  -- Dexson
UPDATE productos SET marca_id = 5 WHERE id IN (93, 95, 96, 98);  -- FEM
UPDATE productos SET marca_id = 6 WHERE id IN (56, 59);  -- Legrand
UPDATE productos SET marca_id = 7 WHERE id IN (43, 63);  -- Leviton
UPDATE productos SET marca_id = 8 WHERE id IN (99);  -- Luminex
UPDATE productos SET marca_id = 9 WHERE id IN (94, 97);  -- Tercol
UPDATE productos SET marca_id = 10 WHERE id IN (73, 74, 76, 77);  -- Rawelt
UPDATE productos SET marca_id = 11 WHERE id IN (135);  -- Yale (se ve en la foto)
