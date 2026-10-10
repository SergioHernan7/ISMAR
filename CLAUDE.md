# Contexto del proyecto ISMAR

Es una tienda en línea de productos eléctricos para una cliente. Los clientes arman un carrito y el pedido se termina por WhatsApp (no hay pago en línea). El login es solo para el panel de administrador; los compradores no tienen cuenta.

## Tecnología

- Python + Flask 3.1, mysql-connector-python (sin ORM)
- MySQL con XAMPP en /opt/lampp, usuario root sin contraseña, base de datos `ismar`
- Para encender XAMPP: `sudo /opt/lampp/lampp start` (lo ejecuta el usuario)
- Entorno virtual en `venv/`. Para arrancar: `venv/bin/python app.py` → http://127.0.0.1:5000

## Estructura

- `app.py`: todas las rutas
- `database.py`: conexión a MySQL
- `database/ismar.sql`: esquema. Tablas: administradores, categorias, marcas, productos, producto_imagenes, producto_especificaciones, pedidos, pedido_detalle, configuracion
- `templates/admin/`: plantillas del panel
- `templates/tienda/`: plantillas de la tienda pública
- `static/css` (`admin.css`, `tienda.css`), `static/js/tienda.js` y `static/uploads` (imágenes de productos)

## Lo que ya está hecho (en main)

- Esquema de la base de datos
- Panel de administrador en `/admin`: crear el primer admin (`/admin/setup`), login/logout, dashboard, CRUD de productos (con imágenes, especificaciones y visibilidad), categorías, marcas, pedidos (ver y cambiar estado) y configuración de la tienda (por ejemplo, el número de WhatsApp) y administradores (`/admin/administradores`: crear, editar, activar/desactivar, eliminar y "Mi cuenta"; todos tienen los mismos permisos; nadie puede desactivarse ni borrarse a sí mismo, y un admin desactivado pierde el acceso al instante)
- Tienda pública: inicio (`/`), catálogo con búsqueda y orden (sin panel de filtros: se llega por el menú de categorías, "Ofertas" o las marcas del inicio) (`/catalogo`, `/categoria/<slug>`), detalle de producto (`/producto/<slug>`), carrito en la sesión (`/carrito`) y envío del pedido: se guarda en `pedidos` con código `ISM-000123` y se abre WhatsApp con el mensaje armado (`/pedido/<codigo>/gracias`)
- El stock no se descuenta al hacer el pedido; solo se valida que alcance

## Forma de trabajar

- Repo privado github.com/SergioHernan7/ISMAR. El usuario trabaja con un compañero.
- Cada tarea va en su propia rama creada desde `main` y se une con un Pull Request. El merge lo hace el usuario.
- El esquema puede cambiar porque todavía no está todo definido con la cliente.
- El usuario es principiante en git/GitHub: explicar los pasos en español y de forma sencilla.
