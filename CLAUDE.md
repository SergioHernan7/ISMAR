# Contexto del proyecto ISMAR

Es una tienda en línea de productos eléctricos para una cliente. Los clientes arman un carrito y el pedido se termina por WhatsApp (no hay pago en línea). El login es solo para el panel de administrador; los compradores no tienen cuenta.

## Tecnología

- Python + Flask 3.1, mysql-connector-python (sin ORM)
- MySQL con XAMPP en /opt/lampp, usuario root sin contraseña, base de datos `ismar`
- Para encender XAMPP: `sudo /opt/lampp/lampp start` (lo ejecuta el usuario)
- Entorno virtual en `venv/`. Para arrancar: `venv/bin/python app.py` → http://127.0.0.1:5000
- Estilos con Bootstrap 5.3 y Bootstrap Icons (CDN), en el panel y en la tienda

## Estructura

- `app.py`: todas las rutas, separadas por secciones (panel, administradores, tienda pública)
- `database.py`: conexión a MySQL
- `database/catalogo.sql`: catálogo real (139 productos y 5 categorías importados del catálogo de Treinta de la cliente: catalogo.treinta.co/ismar-productoselectricos). Se importa después de `ismar.sql`; reemplaza categorías, marcas y productos sin tocar admins, pedidos ni configuración
- `static/catalogo/`: fotos del catálogo real (sí van en git; `static/uploads/` no)
- `database/ismar.sql`: esquema. Tablas: administradores, categorias, marcas, productos, producto_imagenes, producto_especificaciones, pedidos, pedido_detalle, configuracion
- `templates/admin/`: plantillas del panel
- `templates/tienda/`: plantillas de la tienda pública (`base.html`, `_producto_tarjeta.html`, inicio, catálogo, producto, carrito, gracias, 404)
- `static/css` (`admin.css`, `tienda.css`), `static/js/tienda.js` y `static/uploads` (imágenes de productos)
- Los colores de la tienda están en `:root` de `static/css/tienda.css` (azul oscuro + amarillo, logo provisional con el rayo ⚡)

## Lo que ya está hecho

### Panel de administrador (`/admin`)
- Crear el primer admin (`/admin/setup`, solo funciona si no hay ninguno), login/logout, dashboard
- CRUD de productos (con imágenes, especificaciones y visibilidad), categorías (con subcategorías), marcas
- Pedidos: ver y cambiar estado (pendiente, confirmado, enviado, entregado, cancelado)
- Configuración de la tienda: nombre, número de WhatsApp, moneda y texto inicial del mensaje
- Administradores (`/admin/administradores`): crear, editar, activar/desactivar, eliminar y "Mi cuenta" (clic en el nombre del menú; para cambiar la propia contraseña pide la actual). Todos tienen los mismos permisos; nadie puede desactivarse ni borrarse a sí mismo; un admin desactivado pierde el acceso al instante (lo revisa `login_requerido`)
- Cómo entra la cliente: enlace "Acceso administradores" en el pie de la tienda o la dirección corta `/login`. Con sesión abierta, la tienda muestra el botón "Panel" y el panel tiene "Ver la tienda"

### Tienda pública
- Inicio (`/`): portada, categorías, destacados, ofertas y marcas
- Catálogo (`/catalogo`, `/categoria/<slug>`): búsqueda, orden y paginación. **Sin panel de filtros** (el usuario pidió quitarlo); se llega por el menú de categorías, el enlace "Ofertas" o las marcas del inicio (`?marca=`, `?ofertas=1` siguen funcionando)
- Detalle de producto (`/producto/<slug>`): galería, especificaciones, relacionados. Stock visible solo como "Disponible", "Últimas unidades" (≤ 5) o "Agotado"
- Carrito en la sesión (`/carrito`), limitado al stock
- Pedido: obligatorios nombre y teléfono (ciudad, dirección y notas opcionales). Se guarda en `pedidos` con código `ISM-000123` y la página de gracias (`/pedido/<codigo>/gracias`) redirige sola a WhatsApp (en 1,2 s, una sola vez por pedido gracias a `sessionStorage`) con la lista del carrito ya escrita; el botón verde queda de respaldo
- El stock **no** se descuenta al hacer el pedido; solo se valida que alcance

## Pendiente (en pausa: esperando información de la cliente)

- Revisar con la cliente el catálogo importado: 21 productos sin foto, 6 en la categoría "Otros" (no tenían categoría en Treinta), "Framel 24w sobreponer L/C" con stock 15000 (parece un error de digitación), nombres con errores ("selectot", "extencion", "interperie"), ninguno tiene marca, destacado ni precio de oferta

- Logo, colores y textos definitivos de la tienda
- Número de WhatsApp real de la cliente (en la base local hay uno de prueba)
- Decidir si el stock se descuenta al confirmar un pedido
- Publicar en internet: hosting con Python + MySQL (recomendado PythonAnywhere) y dominio opcional. Antes de publicar: `SECRET_KEY` real por variable de entorno, quitar `debug=True`, contraseña de MySQL
- Una vez publicada, crear la cuenta de administrador de la cliente desde "Administradores"

## Forma de trabajar

- Repo privado github.com/SergioHernan7/ISMAR. El usuario trabaja con un compañero.
- Mismo flujo que su otro proyecto UrbanStyle: cada tarea va en su propia rama creada desde `main`, se sube y se abre un Pull Request. El merge lo hace el usuario; después se borra la rama (local y en GitHub).
- No hacer merge ni subir directo a `main` salvo que el usuario lo pida.
- El esquema puede cambiar porque todavía no está todo definido con la cliente.
- El usuario es principiante en git/GitHub: explicar los pasos en español y de forma sencilla.
- Al probar contra la base local, borrar después los pedidos o admins de prueba y no tocar la cuenta `sergio`.
