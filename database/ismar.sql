-- =====================================================
--  ISMAR - Tienda de productos eléctricos
--  Base de datos MySQL / MariaDB
-- =====================================================

DROP DATABASE IF EXISTS ismar;
CREATE DATABASE ismar CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ismar;

-- -----------------------------------------------------
-- Administradores (solo ellos inician sesión, en el panel)
-- -----------------------------------------------------
CREATE TABLE administradores (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    usuario         VARCHAR(50)  NOT NULL UNIQUE,
    email           VARCHAR(120) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,          -- nunca guardar la contraseña en texto plano
    activo          TINYINT(1)   NOT NULL DEFAULT 1,
    ultimo_acceso   DATETIME     NULL,
    creado_en       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Categorías (admite subcategorías: Iluminación > Bombillos LED)
-- -----------------------------------------------------
CREATE TABLE categorias (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    categoria_padre_id INT NULL,
    nombre          VARCHAR(100) NOT NULL,
    slug            VARCHAR(120) NOT NULL UNIQUE,   -- para la URL: /categoria/iluminacion
    descripcion     TEXT NULL,
    imagen          VARCHAR(255) NULL,
    orden           INT NOT NULL DEFAULT 0,
    activa          TINYINT(1) NOT NULL DEFAULT 1,
    creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_categoria_padre FOREIGN KEY (categoria_padre_id)
        REFERENCES categorias(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Marcas
-- -----------------------------------------------------
CREATE TABLE marcas (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL UNIQUE,
    logo            VARCHAR(255) NULL,
    activa          TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Productos
-- -----------------------------------------------------
CREATE TABLE productos (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    categoria_id        INT NOT NULL,
    marca_id            INT NULL,
    sku                 VARCHAR(50)  NOT NULL UNIQUE,   -- código interno del producto
    nombre              VARCHAR(150) NOT NULL,
    slug                VARCHAR(170) NOT NULL UNIQUE,
    descripcion_corta   VARCHAR(255) NULL,              -- la que sale en la tarjeta del catálogo
    descripcion         TEXT NULL,                      -- la completa, en la página del producto
    precio              DECIMAL(12,2) NOT NULL,
    precio_oferta       DECIMAL(12,2) NULL,             -- si tiene valor, el producto está en oferta
    stock               INT NOT NULL DEFAULT 0,
    imagen_principal    VARCHAR(255) NULL,
    destacado           TINYINT(1) NOT NULL DEFAULT 0,  -- para mostrarlo en la página de inicio
    activo              TINYINT(1) NOT NULL DEFAULT 1,  -- ocultarlo sin borrarlo
    creado_en           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_id)
        REFERENCES categorias(id) ON DELETE RESTRICT,
    CONSTRAINT fk_producto_marca FOREIGN KEY (marca_id)
        REFERENCES marcas(id) ON DELETE SET NULL,
    CONSTRAINT chk_precio CHECK (precio >= 0),
    CONSTRAINT chk_stock  CHECK (stock >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_productos_categoria ON productos(categoria_id);
CREATE INDEX idx_productos_activo    ON productos(activo, destacado);

-- -----------------------------------------------------
-- Imágenes adicionales de cada producto (galería)
-- -----------------------------------------------------
CREATE TABLE producto_imagenes (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    producto_id     INT NOT NULL,
    url             VARCHAR(255) NOT NULL,
    orden           INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_imagen_producto FOREIGN KEY (producto_id)
        REFERENCES productos(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Especificaciones técnicas (voltaje, potencia, calibre...)
-- Cada producto puede tener las que necesite.
-- -----------------------------------------------------
CREATE TABLE producto_especificaciones (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    producto_id     INT NOT NULL,
    nombre          VARCHAR(80)  NOT NULL,   -- ej: 'Voltaje'
    valor           VARCHAR(120) NOT NULL,   -- ej: '110V'
    orden           INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_espec_producto FOREIGN KEY (producto_id)
        REFERENCES productos(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Pedidos: se guardan cuando el cliente pulsa "Pagar"
-- y se le redirige a WhatsApp. El admin los ve en el panel.
-- -----------------------------------------------------
CREATE TABLE pedidos (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    codigo              VARCHAR(20)  NOT NULL UNIQUE,   -- ej: ISM-000123, va en el mensaje de WhatsApp
    cliente_nombre      VARCHAR(120) NOT NULL,
    cliente_telefono    VARCHAR(30)  NOT NULL,
    cliente_direccion   VARCHAR(255) NULL,
    cliente_ciudad      VARCHAR(100) NULL,
    notas               TEXT NULL,
    total               DECIMAL(12,2) NOT NULL,
    estado              ENUM('pendiente','confirmado','enviado','entregado','cancelado')
                        NOT NULL DEFAULT 'pendiente',
    creado_en           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE INDEX idx_pedidos_estado ON pedidos(estado, creado_en);

-- Productos de cada pedido. Se copian nombre y precio para que el
-- pedido no cambie si luego se edita o se borra el producto.
CREATE TABLE pedido_detalle (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id           INT NOT NULL,
    producto_id         INT NULL,
    nombre_producto     VARCHAR(150) NOT NULL,
    precio_unitario     DECIMAL(12,2) NOT NULL,
    cantidad            INT NOT NULL,
    subtotal            DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_detalle_pedido FOREIGN KEY (pedido_id)
        REFERENCES pedidos(id) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (producto_id)
        REFERENCES productos(id) ON DELETE SET NULL,
    CONSTRAINT chk_cantidad CHECK (cantidad > 0)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Configuración de la tienda (editable desde el panel)
-- -----------------------------------------------------
CREATE TABLE configuracion (
    clave           VARCHAR(50) PRIMARY KEY,
    valor           VARCHAR(255) NOT NULL,
    descripcion     VARCHAR(255) NULL
) ENGINE=InnoDB;


-- =====================================================
--  DATOS DE PRUEBA
-- =====================================================

INSERT INTO configuracion (clave, valor, descripcion) VALUES
('nombre_tienda',   'ISMAR',          'Nombre que aparece en la web'),
('whatsapp_numero', '57XXXXXXXXXX',   'Número de WhatsApp con código de país, sin + ni espacios'),
('moneda',          'COP',            'Moneda de los precios'),
('mensaje_pedido',  'Hola, quiero finalizar mi pedido', 'Texto inicial del mensaje de WhatsApp');

INSERT INTO categorias (id, categoria_padre_id, nombre, slug, descripcion, orden) VALUES
(1, NULL, 'Iluminación',            'iluminacion',            'Bombillos, lámparas y reflectores', 1),
(2, NULL, 'Cables y conductores',   'cables-y-conductores',   'Cable eléctrico por metro y rollo', 2),
(3, NULL, 'Interruptores y tomas',  'interruptores-y-tomas',  'Interruptores, tomacorrientes y placas', 3),
(4, NULL, 'Protección eléctrica',   'proteccion-electrica',   'Breakers, tacos y tableros', 4),
(5, NULL, 'Herramientas',           'herramientas',           'Herramientas para electricistas', 5),
(6, 1,    'Bombillos LED',          'bombillos-led',          NULL, 1),
(7, 1,    'Reflectores',            'reflectores',            NULL, 2);

INSERT INTO marcas (id, nombre) VALUES
(1, 'Philips'), (2, 'Schneider Electric'), (3, 'Legrand'), (4, 'Centelsa'), (5, 'Truper');

INSERT INTO productos (id, categoria_id, marca_id, sku, nombre, slug, descripcion_corta, descripcion, precio, precio_oferta, stock, destacado) VALUES
(1, 6, 1, 'LED-9W-BF',   'Bombillo LED 9W luz blanca',   'bombillo-led-9w-luz-blanca',
    'Bombillo LED de bajo consumo, rosca E27', 'Bombillo LED de 9W equivalente a 60W incandescente. Luz blanca fría 6500K, rosca E27, vida útil de 15.000 horas.',
    8500, 6900, 120, 1),
(2, 7, 1, 'REF-50W',     'Reflector LED 50W exterior',   'reflector-led-50w-exterior',
    'Reflector resistente al agua IP65', 'Reflector LED de 50W para exteriores, carcasa de aluminio, protección IP65.',
    65000, NULL, 30, 1),
(3, 2, 4, 'CAB-12-100',  'Cable THHN calibre 12 x 100m', 'cable-thhn-calibre-12-100m',
    'Rollo de 100 metros de cable de cobre', 'Cable de cobre THHN/THWN calibre 12 AWG, rollo de 100 metros, aislamiento en PVC.',
    285000, NULL, 15, 0),
(4, 3, 3, 'TOM-DOB-BL',  'Tomacorriente doble blanco',   'tomacorriente-doble-blanco',
    'Toma doble con polo a tierra', 'Tomacorriente doble con polo a tierra, 15A 125V, incluye placa.',
    9800, NULL, 80, 0),
(5, 4, 2, 'BRK-1P-20A',  'Breaker monopolar 20A',        'breaker-monopolar-20a',
    'Interruptor automático enchufable', 'Breaker monopolar de 20A tipo enchufable para tablero residencial.',
    24000, 21500, 40, 1),
(6, 5, 5, 'PIN-PEL-8',   'Pinza peladora de cables 8"',  'pinza-peladora-cables-8',
    'Pela, corta y poncha cables', 'Pinza peladora multifuncional de 8 pulgadas con mangos aislados.',
    32000, NULL, 25, 0);

INSERT INTO producto_especificaciones (producto_id, nombre, valor, orden) VALUES
(1, 'Potencia', '9W', 1), (1, 'Voltaje', '110-220V', 2), (1, 'Rosca', 'E27', 3), (1, 'Temperatura de color', '6500K', 4),
(2, 'Potencia', '50W', 1), (2, 'Protección', 'IP65', 2),
(3, 'Calibre', '12 AWG', 1), (3, 'Longitud', '100 m', 2), (3, 'Material', 'Cobre', 3),
(4, 'Corriente', '15A', 1), (4, 'Voltaje', '125V', 2),
(5, 'Corriente', '20A', 1), (5, 'Polos', '1', 2);

-- Un pedido de ejemplo para ver cómo queda en el panel
INSERT INTO pedidos (id, codigo, cliente_nombre, cliente_telefono, cliente_direccion, cliente_ciudad, total, estado) VALUES
(1, 'ISM-000001', 'Cliente de prueba', '3000000000', 'Calle 1 # 2-3', 'Bogotá', 35300, 'pendiente');

INSERT INTO pedido_detalle (pedido_id, producto_id, nombre_producto, precio_unitario, cantidad, subtotal) VALUES
(1, 1, 'Bombillo LED 9W luz blanca', 6900, 2, 13800),
(1, 5, 'Breaker monopolar 20A',      21500, 1, 21500);

-- El administrador se crea desde la aplicación (para guardar la
-- contraseña cifrada), no aquí.
