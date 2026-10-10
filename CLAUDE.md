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
- `static/css` y `static/uploads` (imágenes de productos)

## Lo que ya está hecho (en main)

- Esquema de la base de datos
- Panel de administrador en `/admin`: crear el primer admin (`/admin/setup`), login/logout, dashboard, CRUD de productos (con imágenes, especificaciones y visibilidad), categorías, marcas, pedidos (ver y cambiar estado) y configuración de la tienda (por ejemplo, el número de WhatsApp)

## Lo que falta (siguiente paso)

- Tienda pública: inicio, catálogo con filtros por categoría y marca, detalle de producto, carrito y botón para enviar el pedido por WhatsApp (guardando también el pedido en la tabla `pedidos`)

## Forma de trabajar

- Repo privado github.com/SergioHernan7/ISMAR. El usuario trabaja con un compañero.
- Cada tarea va en su propia rama creada desde `main` y se une con un Pull Request. El merge lo hace el usuario.
- El esquema puede cambiar porque todavía no está todo definido con la cliente.
- El usuario es principiante en git/GitHub: explicar los pasos en español y de forma sencilla.
