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
    descuento           TINYINT UNSIGNED NOT NULL DEFAULT 0, -- % de descuento (0 = sin oferta); lo asigna el admin en Ofertas
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
    CONSTRAINT chk_stock  CHECK (stock >= 0),
    CONSTRAINT chk_descuento CHECK (descuento <= 90)
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
    datos_autorizados_en DATETIME NULL,             -- cuándo autorizó el tratamiento de sus datos (Ley 1581)
    total               DECIMAL(12,2) NOT NULL,
    estado              ENUM('pendiente','vendido','cancelado')
                        NOT NULL DEFAULT 'pendiente',
    stock_descontado    TINYINT(1) NOT NULL DEFAULT 0,  -- 1 = sus unidades ya se restaron del inventario (al marcarlo vendido)
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
    precio_unitario     DECIMAL(12,2) NOT NULL,         -- lo que se cobró (ya con el descuento)
    precio_lista        DECIMAL(12,2) NULL,             -- precio normal el día de la compra
    descuento           TINYINT UNSIGNED NOT NULL DEFAULT 0, -- % de oferta que tenía el día de la compra
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
--  DATOS INICIALES
-- =====================================================

INSERT INTO configuracion (clave, valor, descripcion) VALUES
('nombre_tienda',   'ISMAR',          'Nombre que aparece en la web'),
('whatsapp_numero', '57XXXXXXXXXX',   'Número de WhatsApp con código de país, sin + ni espacios'),
('moneda',          'COP',            'Moneda de los precios'),
('mensaje_pedido',  'Hola, quiero finalizar mi pedido', 'Texto inicial del mensaje de WhatsApp'),
('correo_contacto',  '', 'Correo para dudas y solicitudes sobre datos personales (sale en la política de privacidad)'),
('nit',              '', 'NIT o cédula del responsable de la tienda (sale en la política de privacidad)'),
('direccion_tienda', '', 'Dirección física de la tienda (opcional; sale en la política de privacidad)');

-- Los productos, categorías y fotos del catálogo real están en
-- database/catalogo.sql: impórtalo después de este archivo.

-- El administrador se crea desde la aplicación (para guardar la
-- contraseña cifrada), no aquí.
