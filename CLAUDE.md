# Contexto del proyecto ISMAR

Es una tienda en línea de productos eléctricos para una cliente. Los clientes arman un carrito y el pedido se termina por WhatsApp (no hay pago en línea). El login es solo para el panel de administrador; los compradores no tienen cuenta.

## Tecnología

- Python + Flask 3.1, mysql-connector-python (sin ORM), Pillow (comprime las fotos subidas)
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
- Tamaños de la tienda en `rem` (no `px`, salvo bordes y sombras): desde 1800 px de ancho (pantallas grandes o zoom del navegador alejado) `html` agranda la letra base y todo crece parejo, con tope (ver el final de `tienda.css`). Al agregar estilos nuevos a la tienda, usar `rem`
- Los colores están en `:root` de `static/css/tienda.css` (tienda) y de `static/css/admin.css` (panel, que además pisa los colores de Bootstrap). Paleta: negro suave `#1b1b1b` + amarillo dorado apagado `#e2b53e` sobre fondo blanco hueso; el usuario la pidió poco saturada. Logo real de la cliente ("Eléctricos Ismar", redondo naranja) en `static/img/`: `logo-160.png` (barra superior y menú del panel), `logo-256.png` (pie y login), `favicon.png` y `apple-touch-icon.png`; se generaron recortando en círculo con fondo transparente la imagen que mandó la cliente. Su lema: "Conexión que ilumina tu mundo"

## Lo que ya está hecho

### Panel de administrador (`/admin`)
- Crear el primer admin (`/admin/setup`, solo funciona si no hay ninguno), login/logout, dashboard
- CRUD de productos (con imágenes, especificaciones y visibilidad), categorías (con subcategorías), marcas
- Buscador de productos del panel con sugerencias igual al de la tienda (ruta `/admin/productos/buscar`): incluye los ocultos (etiqueta "Oculto"), muestra código, categoría, stock y precio, respeta la categoría elegida y al hacer clic abre la edición. El listado usa la misma búsqueda por palabras (`filtros_admin_productos`)
- Ofertas (`/admin/ofertas`), como en UrbanStyle: cada producto tiene `productos.descuento` (% entero, 0 = sin oferta, máximo `DESCUENTO_MAXIMO` = 90). En esa página se filtra, se marcan varios y se les pone o quita el descuento de una vez (con barra de "cambios sin guardar"); también se cambia al editar cada producto. El precio final es `ROUND(precio * (100 - descuento) / 100)` (en `SQL_PRODUCTOS_PUBLICOS` y el filtro `con_descuento`), y es el que usan carrito, pedido y WhatsApp. Antes había `precio_oferta` (precio fijo): `asegurar_columna_descuento()` migra sola las bases viejas al arrancar (igual que `database/migraciones/001_descuento_productos.sql`)
- Los pedidos recuerdan el descuento: `pedido_detalle` guarda `precio_lista` (precio normal ese día) y `descuento` (%), además de `precio_unitario` (lo cobrado). El panel muestra "Con descuento" en la lista y el inicio, y en el detalle el precio tachado, -X % y "Descuento por ofertas"; la página de gracias y el mensaje de WhatsApp también lo dicen. Las bases viejas se actualizan solas (`asegurar_esquema()`, migración 002), deduciendo el descuento de pedidos anteriores si se cobró menos que el precio actual
- Robustez (revisión de errores): teléfonos de clientes y número de la tienda se normalizan con el 57 (`telefono_whatsapp`; Configuración no guarda un número inválido); formulario caducado (CSRF) avisa y vuelve a la página en vez de "Bad Request"; login bloquea 15 min tras 5 intentos fallidos (en memoria); fotos subidas se reducen a 1600 px y se guardan en WebP; página de error propia (`templates/error.html`, no usa la base); categorías de un solo nivel de subcategorías
- Pedidos: ver, cambiar estado (mueve el stock) y eliminar (para pruebas o duplicados; devuelve el stock si se había descontado). El menú muestra cuántos pedidos están pendientes (pendiente, confirmado, enviado, entregado, cancelado)
- Configuración de la tienda: nombre, número de WhatsApp, moneda y texto inicial del mensaje
- Administradores (`/admin/administradores`): crear, editar, activar/desactivar, eliminar y "Mi cuenta" (clic en el nombre del menú; para cambiar la propia contraseña pide la actual). Todos tienen los mismos permisos; nadie puede desactivarse ni borrarse a sí mismo; un admin desactivado pierde el acceso al instante (lo revisa `login_requerido`)
- Diseño del panel (mismo estilo que la tienda, en `static/css/admin.css`): menú lateral negro con el logo, grupos "Menú" y "Ajustes", y abajo "Ver la tienda" y la cuenta del admin (inicial en un círculo, "Mi cuenta" y botón de salir). En celular hay una barra con el logo y el menú se despliega. `admin.css` pisa los azules de Bootstrap (botones `btn-outline-primary`, pestañas `nav-pills`, campos y casillas)
- Cómo entra la cliente: enlace "Acceso administradores" en el pie de la tienda o la dirección corta `/login`. Con sesión abierta, la tienda muestra el botón "Panel" y el panel tiene "Ver la tienda"

### Tienda pública
- Inicio (`/`): portada, categorías, destacados y marcas. **Sin sección de ofertas** (el usuario pidió quitarla): los productos con descuento salen mezclados en "Algunos de nuestros productos" con su etiqueta -X %
- Ofertas (`/ofertas`): titular automático según los descuentos asignados ("N productos con descuento · Hasta X %"); tarjetas, producto y carrito muestran -X %, precio tachado y cuánto se ahorra. `/catalogo?ofertas=1` redirige aquí
- Catálogo (`/catalogo`, `/categoria/<slug>`): búsqueda, orden y paginación. **Sin panel de filtros** (el usuario pidió quitarlo); se llega por el menú de categorías o las marcas del inicio (`?marca=` sigue funcionando)
- Menú de categorías (franja bajo la barra negra): "Todo", cada categoría con su icono y "Ofertas" como botón dorado; la página actual se marca en dorado. Los iconos salen de `ICONOS_CATEGORIA` en `app.py` (por slug; una categoría nueva sin icono usa el rayo). El inicio usa el mismo diccionario
- Buscador con sugerencias (estilo Google): mientras se escribe (desde 2 letras) aparece una lista con foto, nombre, categoría y precio de hasta 6 productos, y el enlace "Ver los N resultados". Usa la ruta JSON `/buscar?q=`; el código está en `static/js/buscador.js` y `static/css/buscador.css`, compartidos con el panel (se activa en cualquier `<form data-sugerencias="URL">`). Se maneja con mouse o teclado (flechas, Enter, Esc). La búsqueda la hace `filtro_busqueda()` en `app.py`, que comparte con el catálogo: cada palabra por separado, en cualquier orden, en nombre, descripción, código, marca o categoría
- Detalle de producto (`/producto/<slug>`): galería, especificaciones, relacionados. Stock visible solo como "Disponible", "Últimas unidades" (≤ 5) o "Agotado"
- Vista previa al compartir enlaces (WhatsApp, Facebook): etiquetas Open Graph en `tienda/base.html` (bloques `og_titulo`, `og_imagen`, `og_tipo`; la descripción sale del bloque `descripcion`). Imagen por defecto `static/img/compartir.jpg` (1200x630, logo + nombre). Cada producto comparte su foto, nombre y precio (con el descuento si tiene); las categorías, su descripción. Solo se ve cuando la tienda esté publicada (WhatsApp tiene que poder abrir la dirección)
- Datos personales (Ley 1581 de 2012): página `/privacidad` (borrador de política: responsable, datos, finalidades, derechos, cómo ejercerlos, cookies) que toma nombre, WhatsApp, `correo_contacto`, `nit` y `direccion_tienda` de Configuración (los vacíos no salen). En el carrito hay una casilla **obligatoria** de autorización con un resumen desplegable; el pedido guarda `pedidos.datos_autorizados_en` (prueba de la autorización, Decreto 1377) y el panel la muestra en el detalle. Enlace en el pie. Migración 004
- Carrito en la sesión (`/carrito`), limitado al stock. Agregar, quitar y cambiar cantidades se envían con `fetch` (encabezado `X-Carrito`, ver `volver_a()` en `app.py` y el final de `tienda.js`) y luego `location.replace`, para que el botón "atrás" no repita páginas; sin JavaScript funcionan como formularios normales. Las páginas HTML llevan `Cache-Control: no-store` (`sin_copias_viejas`) para que al volver atrás el contador del carrito esté al día
- Pedido: obligatorios nombre y teléfono (ciudad, dirección y notas opcionales). Se guarda en `pedidos` con código `ISM-000123` y la página de gracias (`/pedido/<codigo>/gracias`) redirige sola a WhatsApp (en 1,2 s, una sola vez por pedido gracias a `sessionStorage`) con la lista del carrito ya escrita; el botón verde queda de respaldo
- Stock: al hacer el pedido solo se valida que alcance. Se **descuenta cuando el admin lo pasa a confirmado** (o enviado/entregado) y **vuelve** si lo pasa a pendiente/cancelado o lo elimina; `pedidos.stock_descontado` evita descontar dos veces (`cambiar_estado_pedido`, `mover_stock_pedido`). Si no alcanza, no deja confirmar y dice qué falta

## Pendiente (en pausa: esperando información de la cliente)

- Revisar con la cliente las descripciones: las 131 que no venían de Treinta las escribió Claude a partir del nombre y la foto (sin inventar datos técnicos). Formato de todas: un párrafo y debajo una lista con emojis al estilo de la cliente (✅ Potencia: …, 💡 …, 🏠 Ideal para …). Las 5 originales que ya tenían ese estilo no se tocaron; a las 3 cortas de la cliente (Panel 18w incrustar, Panel 18w sobreponer, Taco luminex) solo se les agregó la lista debajo
- Revisar con la cliente el catálogo importado: 21 productos sin foto, 6 en la categoría "Otros" (no tenían categoría en Treinta), "Framel 24w sobreponer L/C" con stock 15000 (parece un error de digitación), confirmar si "Tous de madera" y "Tous para espejo" deben llamarse "Touch" (por la foto son interruptores táctiles) y la marca "rawuel" de las cajas (los errores de escritura de los nombres ya se corrigieron en `catalogo.sql`: tildes, selector, extensión, intemperie y las marcas Boccherini, Dexson, Leviton y Gálica 2), las medidas de "Panel 18w sobreponer" (dice 2.4cm de ancho), ninguno es destacado ni tiene descuento. Marcas: 9 asignadas desde el nombre de 19 productos (AVE, Boccherini, Codelca, Dexson, FEM, Legrand por "Gálica 2", Leviton, Luminex, Tercol; ver el final de `catalogo.sql`); el resto no dice la marca en el nombre

- Que la cliente revise el borrador de la política de datos (`/privacidad`) y complete en Configuración su correo, NIT/cédula y dirección
- Textos definitivos de la tienda (el logo ya está; los colores negro + dorado los eligió el usuario)
- Número de WhatsApp real de la cliente (en la base local hay uno de prueba)
- Publicar en internet: hosting con Python + MySQL (recomendado PythonAnywhere) y dominio opcional. Variables de entorno en el servidor: `SECRET_KEY` (larga y aleatoria), `ISMAR_HTTPS=1`, `DB_HOST`/`DB_USER`/`DB_PASSWORD`/`DB_NAME`. El modo debug solo se activa con `python app.py` (el servidor WSGI no lo usa). Respaldar `static/uploads/` (las fotos subidas no van a git)
- Una vez publicada, crear **de inmediato** el primer administrador (`/admin/setup` queda abierto mientras no exista ninguno) y luego la cuenta de la cliente desde "Administradores"

## Forma de trabajar

- Repo privado github.com/SergioHernan7/ISMAR. El usuario trabaja con un compañero.
- Mismo flujo que su otro proyecto UrbanStyle: cada tarea va en su propia rama creada desde `main`, se sube y se abre un Pull Request. El merge lo hace el usuario; después se borra la rama (local y en GitHub).
- No hacer merge ni subir directo a `main` salvo que el usuario lo pida.
- El esquema puede cambiar porque todavía no está todo definido con la cliente.
- El usuario es principiante en git/GitHub: explicar los pasos en español y de forma sencilla.
- Al probar contra la base local, borrar después los pedidos o admins de prueba y no tocar la cuenta `sergio`.
