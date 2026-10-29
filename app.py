import hashlib
import hmac
import os
import re
import secrets
import time
import unicodedata
import uuid
from datetime import date, timedelta
from decimal import ROUND_HALF_UP, Decimal, InvalidOperation
from functools import wraps
from urllib.parse import quote

import click
import mysql.connector
from PIL import Image, ImageOps, UnidentifiedImageError
from flask import (Flask, abort, flash, jsonify, redirect, render_template, request,
                   session, url_for)
from werkzeug.security import check_password_hash, generate_password_hash
from werkzeug.utils import secure_filename

from database import get_connection

app = Flask(__name__)
# En el servidor (al publicar) se definen como variables de entorno (ver deploy/wsgi_pythonanywhere.py):
#   SECRET_KEY    clave larga y aleatoria: python -c "import secrets; print(secrets.token_hex(32))"
#   ISMAR_HTTPS=1 la tienda va por https: activa el modo servidor (cookie solo cifrada, revisión de
#                 claves, /admin/setup cerrado)
#   ISMAR_IP_REAL  encabezado con la IP real del visitante cuando hay un proxy delante
#                  (en PythonAnywhere: X-Real-IP). Sin él, todos parecen venir de la misma IP.
#   DB_HOST, DB_USER, DB_PASSWORD, DB_NAME  (ver database.py)
EN_SERVIDOR = os.environ.get('ISMAR_HTTPS') == '1'
CLAVE_DESARROLLO = 'clave-de-desarrollo-cambiar-al-publicar'


def revisar_configuracion():
    """La sesión del panel va firmada con SECRET_KEY: quien la conozca puede fabricar una sesión de
    administrador sin contraseña. Por eso, en el servidor, la tienda NO arranca si la clave falta,
    es corta o es un texto de ejemplo publicado en GitHub (lo mismo con la contraseña de MySQL)."""
    clave = os.environ.get('SECRET_KEY', '')
    problemas = []
    if clave.startswith('CAMBIAR') or clave == CLAVE_DESARROLLO:
        problemas.append('SECRET_KEY tiene el texto de ejemplo: pon una clave aleatoria')
    elif EN_SERVIDOR and len(clave) < 32:
        problemas.append('SECRET_KEY falta o es muy corta (mínimo 32 caracteres)')
    if os.environ.get('DB_PASSWORD', '').startswith('CAMBIAR'):
        problemas.append('DB_PASSWORD tiene el texto de ejemplo: pon la contraseña de MySQL')
    if problemas:
        raise RuntimeError('Configuración insegura, la tienda no arranca: ' + '; '.join(problemas) +
                           '. Ver PUBLICAR.md, paso 6.')
    if not clave:
        app.logger.warning('SECRET_KEY no está definida: se usa una clave de desarrollo. Defínela al publicar.')
    return clave or CLAVE_DESARROLLO


app.secret_key = revisar_configuracion()
app.config.update(
    MAX_CONTENT_LENGTH=16 * 1024 * 1024,  # 16 MB por envío
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE='Lax',
    SESSION_COOKIE_SECURE=EN_SERVIDOR,
    # La sesión del panel vence tras SESION_INACTIVA sin usarlo (se renueva con cada página)
    PERMANENT_SESSION_LIFETIME=timedelta(hours=8),
)
SESION_MAXIMA_SEGUNDOS = 24 * 3600  # aunque se use sin parar, pide la contraseña de nuevo cada 24 h
IMAGEN_PIXELES_MAXIMOS = 40_000_000  # una "foto" más grande que esto se rechaza (evita colgar el servidor)
Image.MAX_IMAGE_PIXELS = IMAGEN_PIXELES_MAXIMOS

EXTENSIONES_IMAGEN = {'png', 'jpg', 'jpeg', 'webp', 'gif'}
ESTADOS_PEDIDO = ['pendiente', 'vendido', 'cancelado']
DIAS_PEDIDO_PENDIENTE = 7  # un pedido pendiente sin cambios en estos días se cancela solo
STOCK_BAJO = 5
# Ofertas: porcentaje de descuento por producto (0 = sin oferta), como en UrbanStyle
DESCUENTO_MAXIMO = 90
DESCUENTOS_SUGERIDOS = [5, 10, 15, 20, 25, 30, 40, 50]
# Icono de Bootstrap Icons para cada categoría (menú de la tienda y tarjetas del inicio)
ICONOS_CATEGORIA = {'iluminacion': 'lightbulb', 'tomas-e-interruptores': 'outlet', 'parte-electrica': 'plug',
                    'duchas': 'droplet', 'herramientas-y-ferreteria': 'tools', 'otros': 'box-seam'}


# =====================================================
#  Utilidades de base de datos
# =====================================================

def consultar(sql, params=(), uno=False):
    con = get_connection()
    try:
        cur = con.cursor(dictionary=True)
        cur.execute(sql, params)
        filas = cur.fetchall()
        return (filas[0] if filas else None) if uno else filas
    finally:
        con.close()


def ejecutar(sql, params=()):
    con = get_connection()
    try:
        cur = con.cursor()
        cur.execute(sql, params)
        con.commit()
        return cur.lastrowid
    finally:
        con.close()


def ejecutar_varios(sql, lista_params):
    """Ejecuta la misma consulta con varios juegos de parámetros en una sola transacción."""
    con = get_connection()
    try:
        cur = con.cursor()
        cur.executemany(sql, lista_params)
        con.commit()
    finally:
        con.close()


# =====================================================
#  Utilidades generales
# =====================================================

def slugify(texto):
    texto = unicodedata.normalize('NFKD', texto).encode('ascii', 'ignore').decode()
    texto = re.sub(r'[^a-zA-Z0-9]+', '-', texto).strip('-').lower()
    return texto or 'item'


def slug_unico(tabla, texto, excluir_id=None):
    base = slugify(texto)
    slug, n = base, 2
    while True:
        sql = f'SELECT id FROM {tabla} WHERE slug = %s'
        params = [slug]
        if excluir_id:
            sql += ' AND id <> %s'
            params.append(excluir_id)
        if not consultar(sql, params, uno=True):
            return slug
        slug, n = f'{base}-{n}', n + 1


IMAGEN_LADO_MAXIMO = 1600  # px: suficiente para la galería y liviano para cargar con datos móviles


def guardar_imagen(archivo, carpeta):
    """Guarda una imagen subida y devuelve su ruta dentro de /static, o None.
    Se reduce a IMAGEN_LADO_MAXIMO, se endereza (fotos de celular) y se guarda en WebP:
    una foto de celular de 4 MB queda en unos 100-300 KB."""
    if not archivo or not archivo.filename:
        return None
    ext = archivo.filename.rsplit('.', 1)[-1].lower() if '.' in archivo.filename else ''
    if ext not in EXTENSIONES_IMAGEN:
        flash(f'"{archivo.filename}" no es una imagen válida (usa png, jpg, webp o gif).', 'warning')
        return None
    try:
        imagen = Image.open(archivo.stream)
        # El tamaño se lee del encabezado, antes de cargar la imagen en memoria
        if imagen.width * imagen.height > IMAGEN_PIXELES_MAXIMOS:
            raise Image.DecompressionBombError(f'{imagen.width}x{imagen.height}')
        imagen = ImageOps.exif_transpose(imagen)  # respeta la orientación con la que se tomó la foto
        imagen.thumbnail((IMAGEN_LADO_MAXIMO, IMAGEN_LADO_MAXIMO))
        if imagen.mode not in ('RGB', 'RGBA'):
            imagen = imagen.convert('RGBA' if 'A' in imagen.getbands() or 'transparency' in imagen.info else 'RGB')
    except Image.DecompressionBombError:
        flash(f'"{archivo.filename}" es demasiado grande. Usa una foto de menos de 40 megapíxeles.', 'warning')
        return None
    except (UnidentifiedImageError, OSError):
        flash(f'"{archivo.filename}" no se pudo abrir como imagen.', 'warning')
        return None
    base = secure_filename(archivo.filename.rsplit('.', 1)[0])[:60] or 'imagen'
    ruta = f'uploads/{carpeta}/{uuid.uuid4().hex[:12]}_{base}.webp'
    imagen.save(os.path.join(app.static_folder, ruta), 'WEBP', quality=82, method=6)
    return ruta


def borrar_imagen(ruta):
    if ruta and ruta.startswith('uploads/'):
        try:
            os.remove(os.path.join(app.static_folder, ruta))
        except FileNotFoundError:
            pass


def a_decimal(valor, campo, obligatorio=True):
    valor = (valor or '').strip().replace(',', '.')
    if not valor:
        if obligatorio:
            raise ValueError(f'El campo {campo} es obligatorio.')
        return None
    try:
        numero = Decimal(valor)
    except InvalidOperation:
        raise ValueError(f'El campo {campo} debe ser un número.')
    if numero < 0:
        raise ValueError(f'El campo {campo} no puede ser negativo.')
    if numero >= 10 ** 10:
        raise ValueError(f'El campo {campo} es demasiado grande.')
    return numero


@app.template_filter('dinero')
def formato_dinero(valor):
    if valor is None:
        return ''
    return '$' + f'{valor:,.0f}'.replace(',', '.')


def leer_descuento(valor):
    """Valida el % de descuento de un formulario (vacío = 0 = sin oferta)."""
    texto = str(valor or '0').strip().replace('%', '')
    try:
        descuento = int(texto)
    except ValueError:
        descuento = -1
    if not 0 <= descuento <= DESCUENTO_MAXIMO:
        raise ValueError(f'El descuento debe ser un número entero entre 0 y {DESCUENTO_MAXIMO} %.')
    return descuento


@app.template_filter('con_descuento')
def precio_con_descuento(precio, descuento):
    """Precio final redondeado al peso; igual que ROUND(...) de SQL_PRODUCTOS_PUBLICOS."""
    precio = Decimal(precio or 0)
    return (precio * (100 - (descuento or 0)) / 100).quantize(Decimal('1'), rounding=ROUND_HALF_UP)


def columnas_de(tabla):
    return {f['COLUMN_NAME'] for f in consultar(
        'SELECT COLUMN_NAME FROM information_schema.COLUMNS '
        'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = %s', (tabla,))}


def asegurar_esquema():
    """Pone al día las bases creadas antes de las ofertas (lo mismo que database/migraciones/):
    001: productos.precio_oferta (precio fijo) -> productos.descuento (%)
    002: pedido_detalle guarda precio_lista y descuento del día de la compra
    003: pedidos.stock_descontado (el stock se descuenta al confirmar un pedido)
    004: datos personales (Ley 1581)
    005: estados de pedido pendiente / vendido / cancelado
    006: administradores.protegido (cuenta de soporte que los demás no pueden tocar)"""
    asegurar_columna_descuento()
    asegurar_descuento_en_pedidos()
    asegurar_datos_personales()
    if 'stock_descontado' not in columnas_de('pedidos'):
        ejecutar("ALTER TABLE pedidos ADD COLUMN stock_descontado TINYINT(1) NOT NULL DEFAULT 0 "
                 "COMMENT '1 = sus unidades ya se restaron del inventario' AFTER estado")
        app.logger.warning('Base actualizada: pedidos.stock_descontado')
    asegurar_estados_pedido()
    if 'protegido' not in columnas_de('administradores'):
        ejecutar("ALTER TABLE administradores ADD COLUMN protegido TINYINT(1) NOT NULL DEFAULT 0 "
                 "COMMENT '1 = solo esta misma cuenta puede editarse' AFTER activo")
        app.logger.warning('Base actualizada: administradores.protegido')


def asegurar_estados_pedido():
    """005: confirmado, enviado y entregado pasan a ser un solo estado, vendido."""
    fila = consultar("SELECT COLUMN_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() "
                     "AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = 'estado'", uno=True)
    if not fila or 'confirmado' not in str(fila['COLUMN_TYPE']):
        return
    ejecutar("ALTER TABLE pedidos MODIFY estado ENUM('pendiente','confirmado','enviado','entregado','vendido','cancelado') "
             "NOT NULL DEFAULT 'pendiente'")
    ejecutar("UPDATE pedidos SET estado = 'vendido' WHERE estado IN ('confirmado', 'enviado', 'entregado')")
    ejecutar("ALTER TABLE pedidos MODIFY estado ENUM('pendiente','vendido','cancelado') NOT NULL DEFAULT 'pendiente'")
    app.logger.warning('Base actualizada: estados de pedido pendiente / vendido / cancelado')


CONFIGURACION_DATOS_PERSONALES = [
    ('correo_contacto', 'Correo para dudas y solicitudes sobre datos personales (sale en la política de privacidad)'),
    ('nit', 'NIT o cédula del responsable de la tienda (sale en la política de privacidad)'),
    ('direccion_tienda', 'Dirección física de la tienda (opcional; sale en la política de privacidad)'),
]


def asegurar_datos_personales():
    """004: datos de la tienda para la política de privacidad y la fecha de autorización en cada pedido."""
    for clave, descripcion in CONFIGURACION_DATOS_PERSONALES:
        ejecutar("INSERT IGNORE INTO configuracion (clave, valor, descripcion) VALUES (%s, '', %s)", (clave, descripcion))
    if 'datos_autorizados_en' not in columnas_de('pedidos'):
        ejecutar("ALTER TABLE pedidos ADD COLUMN datos_autorizados_en DATETIME NULL "
                 "COMMENT 'Cuándo el cliente autorizó el tratamiento de sus datos' AFTER notas")
        app.logger.warning('Base actualizada: pedidos.datos_autorizados_en')


def asegurar_columna_descuento():
    columnas = columnas_de('productos')
    if 'descuento' in columnas:
        return
    conexion = get_connection()
    try:
        cur = conexion.cursor()
        cur.execute("ALTER TABLE productos ADD COLUMN descuento TINYINT UNSIGNED NOT NULL DEFAULT 0 "
                    "COMMENT '% de descuento (0 = sin oferta)' AFTER precio")
        if 'precio_oferta' in columnas:
            cur.execute('UPDATE productos SET descuento = LEAST(%s, GREATEST(0, ROUND((1 - precio_oferta / precio) * 100))) '
                        'WHERE precio_oferta IS NOT NULL AND precio > 0 AND precio_oferta < precio', (DESCUENTO_MAXIMO,))
            cur.execute('ALTER TABLE productos DROP COLUMN precio_oferta')
        conexion.commit()
        app.logger.warning('Base actualizada: productos.precio_oferta -> productos.descuento (%)')
    finally:
        conexion.close()


def asegurar_descuento_en_pedidos():
    if 'descuento' in columnas_de('pedido_detalle'):
        return
    conexion = get_connection()
    try:
        cur = conexion.cursor()
        cur.execute("ALTER TABLE pedido_detalle "
                    "ADD COLUMN precio_lista DECIMAL(12,2) NULL COMMENT 'Precio normal el día de la compra' AFTER precio_unitario, "
                    "ADD COLUMN descuento TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '% de oferta el día de la compra' AFTER precio_lista")
        # Pedidos anteriores: si se cobró por debajo del precio actual, se deduce el descuento
        cur.execute('UPDATE pedido_detalle d JOIN productos p ON p.id = d.producto_id '
                    'SET d.precio_lista = p.precio, d.descuento = LEAST(%s, ROUND((1 - d.precio_unitario / p.precio) * 100)) '
                    'WHERE d.precio_unitario < p.precio AND p.precio > 0', (DESCUENTO_MAXIMO,))
        cur.execute('UPDATE pedido_detalle SET precio_lista = precio_unitario WHERE precio_lista IS NULL')
        conexion.commit()
        app.logger.warning('Base actualizada: pedido_detalle guarda precio_lista y descuento')
    finally:
        conexion.close()


try:
    asegurar_esquema()
except mysql.connector.Error as error:  # MySQL apagado: la app arranca igual
    app.logger.warning('No se pudo revisar el esquema de la base: %s', error)


# =====================================================
#  Sesión y seguridad
# =====================================================

def ip_cliente():
    """IP del visitante. Detrás de un proxy (PythonAnywhere) request.remote_addr es la del proxy,
    la misma para todos; la real llega en el encabezado que indique ISMAR_IP_REAL (X-Real-IP)."""
    encabezado = os.environ.get('ISMAR_IP_REAL')
    if encabezado and request.headers.get(encabezado):
        return request.headers[encabezado].split(',')[0].strip()
    return request.remote_addr or ''


def huella_clave(password_hash):
    """Resumen de la contraseña guardado en la sesión. Si la contraseña cambia, la huella ya no
    coincide y todas las sesiones abiertas con la anterior se cierran. Va firmada con SECRET_KEY,
    así la cookie (que se puede leer) no revela nada del hash."""
    return hmac.new(app.secret_key.encode(), password_hash.encode(), hashlib.sha256).hexdigest()[:24]


def iniciar_sesion_admin(admin):
    session.clear()  # sesión nueva: nada de una sesión anterior se reutiliza
    session.permanent = True  # vence tras PERMANENT_SESSION_LIFETIME sin actividad
    session['admin_id'] = admin['id']
    session['admin_nombre'] = admin['nombre']
    session['admin_huella'] = huella_clave(admin['password_hash'])
    session['admin_desde'] = int(time.time())


def login_requerido(vista):
    @wraps(vista)
    def envoltura(*args, **kwargs):
        if 'admin_id' not in session:
            return redirect(url_for('admin_login', next=request.path))
        admin = consultar('SELECT activo, password_hash FROM administradores WHERE id = %s',
                          (session['admin_id'],), uno=True)
        motivo = None
        # Si otro admin lo desactivó o lo borró, pierde el acceso aunque tenga la sesión abierta
        if not admin or not admin['activo']:
            motivo = 'Tu cuenta de administrador está desactivada.'
        # Si su contraseña cambió (aquí o en otro computador), las sesiones viejas se cierran
        elif not hmac.compare_digest(session.get('admin_huella', ''), huella_clave(admin['password_hash'])):
            motivo = 'La contraseña de tu cuenta cambió. Inicia sesión de nuevo.'
        elif time.time() - session.get('admin_desde', 0) > SESION_MAXIMA_SEGUNDOS:
            motivo = 'Por seguridad, vuelve a iniciar sesión.'
        if motivo:
            session.clear()
            flash(motivo, 'warning')
            return redirect(url_for('admin_login', next=request.path))
        return vista(*args, **kwargs)
    return envoltura


def es_ruta_local(destino):
    """True si es una ruta de esta misma tienda ("/carrito"), y no otra página: "//otro.com" y
    "/\\otro.com" los navegadores los leen como otro sitio."""
    return bool(destino) and destino.startswith('/') and not destino.startswith(('//', '/\\')) \
        and '\\' not in destino and not any(ord(c) < 32 for c in destino)


def pagina_anterior(por_defecto):
    """La página desde donde se envió el formulario, si es de este mismo sitio."""
    anterior = request.referrer or ''
    return anterior if anterior.startswith(request.host_url) else por_defecto


@app.before_request
def verificar_csrf():
    if request.method == 'POST':
        token = session.get('csrf_token')
        if not token or not hmac.compare_digest(token, request.form.get('csrf_token') or ''):
            # Pasa si la sesión caducó (p. ej. el navegador se cerró con la pestaña abierta):
            # en vez de un error, se avisa y se vuelve a la página para intentarlo otra vez
            flash('La página estaba desactualizada. Vuelve a intentarlo.', 'warning')
            destino = pagina_anterior(url_for('admin_login') if request.path.startswith('/admin') else url_for('inicio'))
            if request.headers.get('X-Carrito') == '1':
                return jsonify(destino=destino)
            return redirect(destino)


@app.before_request
def cancelar_pedidos_olvidados():
    """Al usar el panel, los pedidos que siguen pendientes y nadie tocó en DIAS_PEDIDO_PENDIENTE días
    se cancelan solos (el cliente no terminó la compra por WhatsApp). Un pendiente nunca tiene
    stock descontado, así que el inventario no cambia. Si se vuelve a pasar a pendiente, cuenta de nuevo."""
    if request.method == 'GET' and request.path.startswith('/admin') and 'admin_id' in session:
        ejecutar("UPDATE pedidos SET estado = 'cancelado' WHERE estado = 'pendiente' AND stock_descontado = 0 "
                 "AND actualizado_en < NOW() - INTERVAL %s DAY", (DIAS_PEDIDO_PENDIENTE,))


@app.context_processor
def variables_panel():
    if not request.path.startswith('/admin') or 'admin_id' not in session:
        return {}
    fila = consultar("SELECT COUNT(*) AS n FROM pedidos WHERE estado = 'pendiente'", uno=True)
    return {'pedidos_pendientes_menu': fila['n'] if fila else 0}


@app.context_processor
def variables_globales():
    if 'csrf_token' not in session:
        session['csrf_token'] = secrets.token_hex(16)
    return {'csrf_token': session['csrf_token'], 'ESTADOS_PEDIDO': ESTADOS_PEDIDO, 'CLAVE_MINIMA': CLAVE_MINIMA}


CLAVE_MINIMA = 10
CLAVES_COMUNES = {
    '1234567890', '0123456789', '12345678910', '1234512345', '1122334455', 'qwertyuiop', 'asdfghjkl1',
    'password12', 'password123', 'contrasena', 'contraseña', 'contrasena1', 'contraseña1', 'contrasena123',
    'administrador', 'admin12345', 'admin123456', 'ismar12345', 'ismar123456', 'electricos', 'bogota1234',
    'colombia12', 'colombia123', 'iloveyou12', 'abcdefghij', 'abc1234567', 'tienda1234', 'tienda12345',
}


def problema_con_clave(password, password2, usuario='', email='', nombre=''):
    """Devuelve qué tiene de malo una contraseña nueva, o None si sirve."""
    if len(password) < CLAVE_MINIMA:
        return f'La contraseña debe tener al menos {CLAVE_MINIMA} caracteres.'
    if password != password2:
        return 'Las contraseñas no coinciden.'
    baja = password.lower()
    if baja in CLAVES_COMUNES or len(set(baja)) < 4:
        return 'Esa contraseña es muy fácil de adivinar. Usa una frase o mezcla palabras y números.'
    for dato in (usuario, email.split('@')[0], nombre):
        if dato and len(dato) >= 3 and dato.lower() in baja:
            return 'La contraseña no puede contener el usuario, el correo ni el nombre.'
    return None


def hay_administradores():
    return consultar('SELECT COUNT(*) AS n FROM administradores', uno=True)['n'] > 0


# =====================================================
#  Acceso al panel
# =====================================================


@app.route('/admin/setup', methods=['GET', 'POST'])
def admin_setup():
    """Crea el primer administrador. Solo funciona si todavía no hay ninguno."""
    if hay_administradores():
        return redirect(url_for('admin_login'))
    # En el servidor esta página quedaría abierta a cualquiera hasta crear el primer admin:
    # allá se crea desde la consola (flask --app app crear-admin), ver PUBLICAR.md
    if EN_SERVIDOR:
        return render_template('admin/setup.html', solo_consola=True)
    if request.method == 'POST':
        nombre = request.form.get('nombre', '').strip()
        usuario = request.form.get('usuario', '').strip()
        email = request.form.get('email', '').strip()
        password = request.form.get('password', '')
        problema = problema_con_clave(password, request.form.get('password2', ''), usuario, email, nombre)
        if not all([nombre, usuario, email, password]):
            flash('Completa todos los campos.', 'danger')
        elif problema:
            flash(problema, 'danger')
        else:
            ejecutar('INSERT INTO administradores (nombre, usuario, email, password_hash) '
                     'VALUES (%s, %s, %s, %s)',
                     (nombre, usuario, email, generate_password_hash(password)))
            flash('Administrador creado. Ya puedes iniciar sesión.', 'success')
            return redirect(url_for('admin_login'))
    return render_template('admin/setup.html')


@app.route('/login')
def login_corto():
    # Dirección fácil de recordar para la cliente: tutienda.com/login
    return redirect(url_for('admin_login'))


# Límite de intentos de inicio de sesión, en BLOQUEO_SEGUNDOS:
#  * desde una misma IP: INTENTOS_POR_IP fallos -> esa IP espera (frena a quien prueba contraseñas)
#  * contra un mismo usuario: INTENTOS_POR_USUARIO fallos, desde cualquier IP. Es más alto a
#    propósito: si fuera 5, cualquiera podría dejar a la cliente sin entrar escribiendo mal su usuario.
# Vive en la memoria del servidor (se reinicia al reiniciarlo); es suficiente para una tienda pequeña.
INTENTOS_POR_IP = 5
INTENTOS_POR_USUARIO = 20
BLOQUEO_SEGUNDOS = 15 * 60
intentos_fallidos = {}
# Para comparar contra algo cuando el usuario no existe y tardar lo mismo (no delata qué usuarios existen)
HASH_DE_RELLENO = generate_password_hash(secrets.token_hex(16))


def contar_recientes(clave, ahora):
    recientes = [t for t in intentos_fallidos.get(clave, []) if ahora - t < BLOQUEO_SEGUNDOS]
    if recientes:
        intentos_fallidos[clave] = recientes
    else:
        intentos_fallidos.pop(clave, None)
    return recientes


def minutos_de_bloqueo(usuario):
    ahora = time.time()
    for clave, limite in ((f'ip:{ip_cliente()}', INTENTOS_POR_IP), (f'usuario:{usuario.lower()}', INTENTOS_POR_USUARIO)):
        recientes = contar_recientes(clave, ahora)
        if len(recientes) >= limite:
            return int((BLOQUEO_SEGUNDOS - (ahora - recientes[0])) // 60) + 1
    return 0


def registrar_intento(usuario, correcto):
    for clave in (f'ip:{ip_cliente()}', f'usuario:{usuario.lower()}'):
        if correcto:
            intentos_fallidos.pop(clave, None)
        else:
            intentos_fallidos.setdefault(clave, []).append(time.time())


@app.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    if not hay_administradores():
        return redirect(url_for('admin_setup'))
    if request.method == 'GET' and 'admin_id' in session:
        return redirect(url_for('admin_dashboard'))
    if request.method == 'POST':
        usuario = request.form.get('usuario', '').strip()
        espera = minutos_de_bloqueo(usuario)
        if espera:
            flash(f'Demasiados intentos fallidos. Espera {espera} minuto{"" if espera == 1 else "s"} '
                  'y vuelve a intentarlo.', 'danger')
            return render_template('admin/login.html'), 429
        admin = consultar('SELECT * FROM administradores WHERE (usuario = %s OR email = %s) AND activo = 1',
                          (usuario, usuario), uno=True)
        correcto = check_password_hash(admin['password_hash'] if admin else HASH_DE_RELLENO,
                                       request.form.get('password', '')) and bool(admin)
        registrar_intento(usuario, correcto)
        if correcto:
            iniciar_sesion_admin(admin)
            ejecutar('UPDATE administradores SET ultimo_acceso = NOW() WHERE id = %s', (admin['id'],))
            destino = request.args.get('next', '')
            return redirect(destino if es_ruta_local(destino) and destino.startswith('/admin/')
                            else url_for('admin_dashboard'))
        flash('Usuario o contraseña incorrectos.', 'danger')
    return render_template('admin/login.html')


@app.route('/admin/logout', methods=['GET', 'POST'])
def admin_logout():
    # Solo cierra con el botón (POST, con su clave CSRF): un enlace o una imagen en otra página
    # no puede cerrarle la sesión a nadie
    if request.method == 'POST':
        session.clear()
        flash('Cerraste sesión.', 'success')
        return redirect(url_for('admin_login'))
    return redirect(url_for('admin_dashboard') if 'admin_id' in session else url_for('admin_login'))


# =====================================================
#  Dashboard
# =====================================================

@app.route('/admin/')
@login_requerido
def admin_dashboard():
    stats = consultar('''
        SELECT
          (SELECT COUNT(*) FROM productos WHERE activo = 1)                AS productos_activos,
          (SELECT COUNT(*) FROM productos WHERE activo = 1 AND stock <= %s) AS stock_bajo,
          (SELECT COUNT(*) FROM categorias WHERE activa = 1)               AS categorias,
          (SELECT COUNT(*) FROM pedidos WHERE estado = 'pendiente')        AS pedidos_pendientes,
          (SELECT COALESCE(SUM(total), 0) FROM pedidos
             WHERE estado = 'vendido'
               AND creado_en >= DATE_FORMAT(CURDATE(), '%%Y-%%m-01'))        AS ventas_mes
    ''', (STOCK_BAJO,), uno=True)
    ultimos_pedidos = consultar(SQL_PEDIDOS + ' ORDER BY pe.creado_en DESC LIMIT 5')
    poco_stock = consultar('SELECT id, nombre, stock FROM productos '
                           'WHERE activo = 1 AND stock <= %s ORDER BY stock LIMIT 5', (STOCK_BAJO,))
    ocultos = consultar('SELECT id, nombre FROM productos WHERE activo = 0 ORDER BY actualizado_en DESC LIMIT 5')
    total_ocultos = consultar('SELECT COUNT(*) AS n FROM productos WHERE activo = 0', uno=True)['n']
    revisiones = [r for r in conteo_revisiones() if r[3]]
    return render_template('admin/dashboard.html', stats=stats, ultimos_pedidos=ultimos_pedidos,
                           poco_stock=poco_stock, ocultos=ocultos, total_ocultos=total_ocultos,
                           revisiones=revisiones)


# =====================================================
#  Productos
# =====================================================

def opciones_formulario_producto():
    categorias = consultar('''
        SELECT c.id, IF(p.id IS NULL, c.nombre, CONCAT(p.nombre, ' › ', c.nombre)) AS nombre
        FROM categorias c LEFT JOIN categorias p ON p.id = c.categoria_padre_id
        ORDER BY nombre''')
    marcas = consultar('SELECT id, nombre FROM marcas ORDER BY nombre')
    return categorias, marcas


def specs_del_formulario(f):
    return [{'nombre': n, 'valor': v} for n, v in zip(f.getlist('spec_nombre'), f.getlist('spec_valor'))]


SQL_PRODUCTOS_ADMIN = '''SELECT p.*, c.nombre AS categoria, m.nombre AS marca
             FROM productos p
             JOIN categorias c ON c.id = p.categoria_id
             LEFT JOIN marcas m ON m.id = p.marca_id
             WHERE 1 = 1'''


# "Para revisar" (inicio del panel): productos a los que les falta algo o tienen un dato raro.
# clave -> (texto, condición SQL sobre p = productos y c = categorías, icono)
REVISIONES = {
    'sin_foto': ('Sin foto', 'p.imagen_principal IS NULL', 'bi-image'),
    'otros': ('En la categoría "Otros"', "c.slug = 'otros'", 'bi-question-circle'),
    'stock_raro': ('Stock de 1.000 o más (¿error al escribirlo?)', 'p.stock >= 1000', 'bi-exclamation-diamond'),
    'sin_descripcion': ('Sin descripción', "(p.descripcion IS NULL OR TRIM(p.descripcion) = '')", 'bi-card-text'),
}


def conteo_revisiones():
    columnas = ', '.join(f'SUM({cond}) AS {clave}' for clave, (_, cond, _) in REVISIONES.items())
    fila = consultar(f'SELECT {columnas} FROM productos p JOIN categorias c ON c.id = p.categoria_id', uno=True) or {}
    return [(clave, texto, icono, int(fila.get(clave) or 0)) for clave, (texto, _, icono) in REVISIONES.items()]


def filtros_admin_productos(q, categoria, solo_ocultos=False, revisar=None):
    """Filtros del listado de productos del panel (incluye los ocultos)."""
    filtros, params = '', []
    if q:
        filtros, params = filtro_busqueda(q)
    if categoria:
        filtros += ' AND (p.categoria_id = %s OR c.categoria_padre_id = %s)'
        params += [categoria, categoria]
    if solo_ocultos:
        filtros += ' AND p.activo = 0'
    if revisar in REVISIONES:  # la condición sale del diccionario, nunca de lo que escriba el usuario
        filtros += ' AND ' + REVISIONES[revisar][1]
    return filtros, params


@app.route('/admin/productos')
@login_requerido
def admin_productos():
    q = request.args.get('q', '').strip()
    categoria = request.args.get('categoria', type=int)
    solo_ocultos = request.args.get('ocultos') == '1'
    revisar = request.args.get('revisar') if request.args.get('revisar') in REVISIONES else None
    filtros, params = filtros_admin_productos(q, categoria, solo_ocultos, revisar)
    productos = consultar(SQL_PRODUCTOS_ADMIN + filtros + ' ORDER BY p.creado_en DESC', params)
    categorias = consultar('SELECT id, nombre FROM categorias ORDER BY nombre')
    return render_template('admin/productos.html', productos=productos, categorias=categorias,
                           q=q, categoria=categoria, solo_ocultos=solo_ocultos, STOCK_BAJO=STOCK_BAJO,
                           revisar=revisar, texto_revisar=REVISIONES[revisar][0] if revisar else None)


@app.route('/admin/productos/buscar')
@login_requerido
def admin_productos_buscar():
    """Sugerencias del buscador del panel: como las de la tienda, pero con los productos
    ocultos y llevando a la página de edición."""
    q = request.args.get('q', '').strip()[:80]
    if len(q) < 2:
        return jsonify(total=0, productos=[])
    filtros, params = filtros_admin_productos(q, request.args.get('categoria', type=int))
    total = consultar(f'SELECT COUNT(*) AS n FROM ({SQL_PRODUCTOS_ADMIN}{filtros}) t', params, uno=True)['n']
    filas = consultar(SQL_PRODUCTOS_ADMIN + filtros + ' ORDER BY (p.nombre LIKE %s) DESC, p.nombre LIMIT 6',
                      params + [f'{q}%'])
    productos = []
    for f in filas:
        avisos = []
        if not f['activo']:
            avisos.append({'texto': 'Oculto', 'tipo': 'oculto'})
        if f['stock'] <= 0:
            avisos.append({'texto': 'Agotado', 'tipo': 'agotado'})
        elif f['stock'] <= STOCK_BAJO:
            avisos.append({'texto': f'{f["stock"]} uds.', 'tipo': 'poco'})
        else:
            avisos.append({'texto': f'{f["stock"]} uds.', 'tipo': 'stock'})
        productos.append({
            'nombre': f['nombre'],
            'url': url_for('admin_producto_form', id=f['id']),
            'imagen': url_for('static', filename=f['imagen_principal']) if f['imagen_principal'] else None,
            'detalle': f'{f["sku"]} · {f["categoria"]}',
            'precio': formato_dinero(precio_con_descuento(f['precio'], f['descuento'])),
            'precio_anterior': formato_dinero(f['precio']) if f['descuento'] else None,
            'avisos': avisos,
        })
    return jsonify(total=total, productos=productos)



@app.route('/admin/ofertas', methods=['GET', 'POST'])
@login_requerido
def admin_ofertas():
    """Asignar el % de descuento a los productos (uno por uno o a varios a la vez).
    Con descuento, el producto sale en la página de Ofertas de la tienda."""
    if request.method == 'POST':
        actuales = {f['id']: f for f in consultar('SELECT id, nombre, descuento FROM productos')}
        cambios, errores = [], []
        for clave, valor in request.form.items():
            if not clave.startswith('descuento_'):
                continue
            id_texto = clave.removeprefix('descuento_')
            if not id_texto.isdigit() or int(id_texto) not in actuales:
                continue
            pid = int(id_texto)
            try:
                descuento = leer_descuento(valor)
            except ValueError:
                errores.append(actuales[pid]['nombre'])
                continue
            if descuento != actuales[pid]['descuento']:
                cambios.append((descuento, pid))
        if errores:
            flash(f'No se guardó el descuento de: {", ".join(errores)}. Debe ser un número entero '
                  f'entre 0 y {DESCUENTO_MAXIMO} %.', 'danger')
        if cambios:
            ejecutar_varios('UPDATE productos SET descuento = %s WHERE id = %s', cambios)
            flash(f'Se actualizaron las ofertas de {len(cambios)} producto{"" if len(cambios) == 1 else "s"}.', 'success')
        elif not errores:
            flash('No había cambios para guardar.', 'info')
        return redirect(url_for('admin_ofertas'))

    productos = consultar(SQL_PRODUCTOS_ADMIN + ' ORDER BY p.descuento > 0 DESC, p.descuento DESC, p.nombre')
    categorias = consultar('SELECT id, nombre FROM categorias ORDER BY nombre')
    en_oferta = [p for p in productos if p['descuento']]
    return render_template('admin/ofertas.html', productos=productos, categorias=categorias,
                           en_oferta=len(en_oferta), descuento_max=max((p['descuento'] for p in en_oferta), default=0))


@app.route('/admin/productos/nuevo', methods=['GET', 'POST'])
@app.route('/admin/productos/<int:id>/editar', methods=['GET', 'POST'])
@login_requerido
def admin_producto_form(id=None):
    producto, imagenes, especificaciones = None, [], []
    if id:
        producto = consultar('SELECT * FROM productos WHERE id = %s', (id,), uno=True)
        if not producto:
            abort(404)
        imagenes = consultar('SELECT * FROM producto_imagenes WHERE producto_id = %s ORDER BY orden, id', (id,))
        especificaciones = consultar('SELECT * FROM producto_especificaciones '
                                     'WHERE producto_id = %s ORDER BY orden, id', (id,))

    if request.method == 'POST':
        f = request.form
        try:
            nombre = f.get('nombre', '').strip()
            sku = f.get('sku', '').strip()
            if not nombre or not sku:
                raise ValueError('El nombre y el SKU son obligatorios.')
            if not f.get('categoria_id'):
                raise ValueError('Elige una categoría.')
            precio = a_decimal(f.get('precio'), 'precio')
            descuento = leer_descuento(f.get('descuento'))
            stock = int(f.get('stock') or 0)
            if stock < 0:
                raise ValueError('El stock no puede ser negativo.')
        except ValueError as e:
            msg = str(e)
            flash(msg if 'invalid literal' not in msg else 'El stock debe ser un número entero.', 'danger')
            categorias, marcas = opciones_formulario_producto()
            return render_template('admin/producto_form.html', producto=f, imagenes=imagenes,
                                   especificaciones=specs_del_formulario(f), categorias=categorias,
                                   marcas=marcas, editando=id)

        datos = {
            'categoria_id': int(f['categoria_id']),
            'marca_id': int(f['marca_id']) if f.get('marca_id') else None,
            'sku': sku,
            'nombre': nombre,
            'slug': slug_unico('productos', nombre, excluir_id=id),
            'descripcion_corta': f.get('descripcion_corta', '').strip() or None,
            'descripcion': f.get('descripcion', '').replace('\r\n', '\n').strip() or None,  # \r\n del navegador -> \n
            'precio': precio,
            'descuento': descuento,
            'stock': stock,
            'destacado': 1 if f.get('destacado') else 0,
            'activo': 1 if f.get('activo') else 0,
        }
        nueva_imagen = guardar_imagen(request.files.get('imagen_principal'), 'productos')
        if nueva_imagen:
            datos['imagen_principal'] = nueva_imagen

        galeria_nueva = []  # fotos de galería guardadas en disco en este envío (se borran si algo falla)
        con = get_connection()
        try:
            cur = con.cursor()
            columnas = list(datos)
            if id:
                cur.execute(f'UPDATE productos SET {", ".join(c + " = %s" for c in columnas)} WHERE id = %s',
                            [datos[c] for c in columnas] + [id])
                producto_id = id
            else:
                cur.execute(f'INSERT INTO productos ({", ".join(columnas)}) '
                            f'VALUES ({", ".join(["%s"] * len(columnas))})',
                            [datos[c] for c in columnas])
                producto_id = cur.lastrowid

            # Las especificaciones se reemplazan completas en cada guardado
            cur.execute('DELETE FROM producto_especificaciones WHERE producto_id = %s', (producto_id,))
            nombres = f.getlist('spec_nombre')
            valores = f.getlist('spec_valor')
            for orden, (n, v) in enumerate(zip(nombres, valores), start=1):
                if n.strip() and v.strip():
                    cur.execute('INSERT INTO producto_especificaciones (producto_id, nombre, valor, orden) '
                                'VALUES (%s, %s, %s, %s)', (producto_id, n.strip(), v.strip(), orden))

            for archivo in request.files.getlist('galeria'):
                ruta = guardar_imagen(archivo, 'productos')
                if ruta:
                    galeria_nueva.append(ruta)
                    cur.execute('INSERT INTO producto_imagenes (producto_id, url) VALUES (%s, %s)',
                                (producto_id, ruta))
            con.commit()
        except mysql.connector.IntegrityError:
            con.rollback()
            for ruta in [nueva_imagen] + galeria_nueva:
                borrar_imagen(ruta)
            flash(f'Ya existe un producto con el SKU "{sku}".', 'danger')
            categorias, marcas = opciones_formulario_producto()
            return render_template('admin/producto_form.html', producto=f, imagenes=imagenes,
                                   especificaciones=specs_del_formulario(f), categorias=categorias,
                                   marcas=marcas, editando=id)
        finally:
            con.close()

        if nueva_imagen and producto and producto.get('imagen_principal'):
            borrar_imagen(producto['imagen_principal'])
        flash('Producto guardado.', 'success')
        return redirect(url_for('admin_producto_form', id=producto_id))

    categorias, marcas = opciones_formulario_producto()
    return render_template('admin/producto_form.html', producto=producto, imagenes=imagenes,
                           especificaciones=especificaciones, categorias=categorias,
                           marcas=marcas, editando=id)


@app.route('/admin/productos/<int:id>/visibilidad', methods=['POST'])
@login_requerido
def admin_producto_visibilidad(id):
    ejecutar('UPDATE productos SET activo = 1 - activo WHERE id = %s', (id,))
    return redirect(pagina_anterior(url_for('admin_productos')))


@app.route('/admin/productos/<int:id>/eliminar', methods=['POST'])
@login_requerido
def admin_producto_eliminar(id):
    producto = consultar('SELECT imagen_principal FROM productos WHERE id = %s', (id,), uno=True)
    if producto:
        imagenes = consultar('SELECT url FROM producto_imagenes WHERE producto_id = %s', (id,))
        ejecutar('DELETE FROM productos WHERE id = %s', (id,))
        borrar_imagen(producto['imagen_principal'])
        for img in imagenes:
            borrar_imagen(img['url'])
        flash('Producto eliminado.', 'success')
    return redirect(url_for('admin_productos'))


@app.route('/admin/productos/imagen/<int:img_id>/eliminar', methods=['POST'])
@login_requerido
def admin_producto_imagen_eliminar(img_id):
    img = consultar('SELECT * FROM producto_imagenes WHERE id = %s', (img_id,), uno=True)
    if not img:
        abort(404)
    ejecutar('DELETE FROM producto_imagenes WHERE id = %s', (img_id,))
    borrar_imagen(img['url'])
    flash('Imagen eliminada.', 'success')
    return redirect(url_for('admin_producto_form', id=img['producto_id']))


# =====================================================
#  Categorías
# =====================================================

@app.route('/admin/categorias')
@login_requerido
def admin_categorias():
    categorias = consultar('''
        SELECT c.*, p.nombre AS padre,
               (SELECT COUNT(*) FROM productos WHERE categoria_id = c.id) AS num_productos
        FROM categorias c LEFT JOIN categorias p ON p.id = c.categoria_padre_id
        ORDER BY COALESCE(p.orden, c.orden), COALESCE(p.id, c.id), c.categoria_padre_id IS NOT NULL, c.orden''')
    return render_template('admin/categorias.html', categorias=categorias)


@app.route('/admin/categorias/nueva', methods=['GET', 'POST'])
@app.route('/admin/categorias/<int:id>/editar', methods=['GET', 'POST'])
@login_requerido
def admin_categoria_form(id=None):
    categoria = None
    if id:
        categoria = consultar('SELECT * FROM categorias WHERE id = %s', (id,), uno=True)
        if not categoria:
            abort(404)
    # Solo se ofrecen como padre las categorías principales (un nivel de subcategorías)
    padres = consultar('SELECT id, nombre FROM categorias WHERE categoria_padre_id IS NULL AND id <> %s '
                       'ORDER BY orden, nombre', (id or 0,))

    if request.method == 'POST':
        f = request.form
        nombre = f.get('nombre', '').strip()
        padre_id = f.get('categoria_padre_id', type=int)
        error = None
        if not nombre:
            error = 'El nombre es obligatorio.'
        elif not re.fullmatch(r'-?\d{1,6}', (f.get('orden') or '0').strip()):
            error = 'El orden debe ser un número entero (ej: 1, 2, 3).'
        elif padre_id and padre_id not in {c['id'] for c in padres}:
            error = 'Solo se puede elegir como padre una categoría principal.'
        elif padre_id and id and consultar('SELECT id FROM categorias WHERE categoria_padre_id = %s LIMIT 1', (id,)):
            # Hay un solo nivel de subcategorías: si esta tiene hijas, sus hijas quedarían fuera del catálogo
            error = 'Esta categoría tiene subcategorías, así que no puede ser subcategoría de otra.'
        if error:
            flash(error, 'danger')
            return render_template('admin/categoria_form.html', categoria=f, padres=padres, editando=id)
        datos = {
            'nombre': nombre,
            'slug': slug_unico('categorias', nombre, excluir_id=id),
            'categoria_padre_id': padre_id,
            'descripcion': f.get('descripcion', '').replace('\r\n', '\n').strip() or None,  # \r\n del navegador -> \n
            'orden': int((f.get('orden') or '0').strip()),
            'activa': 1 if f.get('activa') else 0,
        }
        nueva_imagen = guardar_imagen(request.files.get('imagen'), 'categorias')
        if nueva_imagen:
            datos['imagen'] = nueva_imagen
        columnas = list(datos)
        if id:
            ejecutar(f'UPDATE categorias SET {", ".join(c + " = %s" for c in columnas)} WHERE id = %s',
                     [datos[c] for c in columnas] + [id])
            if nueva_imagen:
                borrar_imagen(categoria.get('imagen'))
        else:
            ejecutar(f'INSERT INTO categorias ({", ".join(columnas)}) '
                     f'VALUES ({", ".join(["%s"] * len(columnas))})', [datos[c] for c in columnas])
        flash('Categoría guardada.', 'success')
        return redirect(url_for('admin_categorias'))

    return render_template('admin/categoria_form.html', categoria=categoria, padres=padres, editando=id)


@app.route('/admin/categorias/<int:id>/eliminar', methods=['POST'])
@login_requerido
def admin_categoria_eliminar(id):
    categoria = consultar('SELECT * FROM categorias WHERE id = %s', (id,), uno=True)
    if not categoria:
        abort(404)
    try:
        ejecutar('DELETE FROM categorias WHERE id = %s', (id,))
    except mysql.connector.IntegrityError:
        flash('No se puede eliminar: la categoría tiene productos. Muévelos a otra categoría o desactívala.',
              'danger')
    else:
        borrar_imagen(categoria['imagen'])
        flash('Categoría eliminada.', 'success')
    return redirect(url_for('admin_categorias'))


# =====================================================
#  Marcas
# =====================================================

@app.route('/admin/marcas', methods=['GET', 'POST'])
@login_requerido
def admin_marcas():
    if request.method == 'POST':
        nombre = request.form.get('nombre', '').strip()
        marca_id = request.form.get('id', type=int)
        if not nombre:
            flash('El nombre es obligatorio.', 'danger')
        else:
            try:
                if marca_id:
                    ejecutar('UPDATE marcas SET nombre = %s WHERE id = %s', (nombre, marca_id))
                else:
                    ejecutar('INSERT INTO marcas (nombre) VALUES (%s)', (nombre,))
                flash('Marca guardada.', 'success')
            except mysql.connector.IntegrityError:
                flash(f'La marca "{nombre}" ya existe.', 'danger')
        return redirect(url_for('admin_marcas'))
    marcas = consultar('''SELECT m.*, (SELECT COUNT(*) FROM productos WHERE marca_id = m.id) AS num_productos
                          FROM marcas m ORDER BY m.nombre''')
    return render_template('admin/marcas.html', marcas=marcas)


@app.route('/admin/marcas/<int:id>/eliminar', methods=['POST'])
@login_requerido
def admin_marca_eliminar(id):
    ejecutar('DELETE FROM marcas WHERE id = %s', (id,))
    flash('Marca eliminada. Sus productos quedaron sin marca.', 'success')
    return redirect(url_for('admin_marcas'))


# =====================================================
#  Pedidos
# =====================================================

# Pedidos con lo que se descontó en total (0 si se vendieron a precio normal)
SQL_PEDIDOS = '''SELECT pe.*,
    (SELECT COALESCE(SUM((d.precio_lista - d.precio_unitario) * d.cantidad), 0)
       FROM pedido_detalle d WHERE d.pedido_id = pe.id AND d.descuento > 0) AS ahorro
    FROM pedidos pe'''


@app.route('/admin/pedidos')
@login_requerido
def admin_pedidos():
    estado = request.args.get('estado', '')
    if estado in ESTADOS_PEDIDO:
        pedidos = consultar(SQL_PEDIDOS + ' WHERE pe.estado = %s ORDER BY pe.creado_en DESC', (estado,))
    else:
        estado = ''
        pedidos = consultar(SQL_PEDIDOS + ' ORDER BY pe.creado_en DESC')
    conteo = {f['estado']: f['n'] for f in
              consultar('SELECT estado, COUNT(*) AS n FROM pedidos GROUP BY estado')}
    return render_template('admin/pedidos.html', pedidos=pedidos, estado=estado, conteo=conteo,
                           dias_pendiente=DIAS_PEDIDO_PENDIENTE)


@app.route('/admin/pedidos/estado', methods=['POST'])
@login_requerido
def admin_pedidos_estado():
    """Cambia el estado desde la lista: el botón de una fila (solo = "id:estado") o los pedidos marcados."""
    if request.form.get('solo'):
        id_texto, _, nuevo = request.form['solo'].partition(':')
        ids = [id_texto]
    else:
        ids, nuevo = request.form.getlist('ids'), request.form.get('estado')
    ids = [int(i) for i in ids if i.isdigit()]
    volver = redirect(pagina_anterior(url_for('admin_pedidos')))
    if nuevo not in ESTADOS_PEDIDO or not ids:
        flash('Marca al menos un pedido.', 'warning')
        return volver
    pedidos = consultar(f'SELECT * FROM pedidos WHERE id IN ({", ".join(["%s"] * len(ids))})', ids)
    cambiados = 0
    for pedido in pedidos:
        if pedido['estado'] == nuevo:
            continue
        ok, mensaje = cambiar_estado_pedido(pedido, nuevo)
        if ok:
            cambiados += 1
            if len(pedidos) == 1:
                flash(f'{pedido["codigo"]}: {mensaje}', 'success')
        else:
            flash(f'{pedido["codigo"]}: {mensaje}', 'danger')
    if len(pedidos) > 1 and cambiados:
        flash(f'{cambiados} pedido(s) marcados como {nuevo}.', 'success')
    return volver


# En este estado las unidades del pedido ya salieron del inventario
ESTADOS_CON_STOCK_DESCONTADO = {'vendido'}


def mover_stock_pedido(cur, pedido_id, signo):
    """Resta (signo = -1) o devuelve (signo = 1) al inventario las unidades de un pedido.
    Al restar, primero revisa que alcance y devuelve la lista de productos que no tienen suficiente.
    Los productos borrados del catálogo (producto_id NULL) se saltan."""
    cur.execute('SELECT producto_id, nombre_producto, cantidad FROM pedido_detalle '
                'WHERE pedido_id = %s AND producto_id IS NOT NULL', (pedido_id,))
    cantidades, nombres = {}, {}
    for producto_id, nombre, cantidad in cur.fetchall():
        cantidades[producto_id] = cantidades.get(producto_id, 0) + cantidad
        nombres[producto_id] = nombre
    if not cantidades:
        return []
    # Bloquea esos productos hasta terminar, para que dos cambios a la vez no se pisen
    cur.execute(f'SELECT id, stock FROM productos WHERE id IN ({", ".join(["%s"] * len(cantidades))}) FOR UPDATE',
                list(cantidades))
    stock = dict(cur.fetchall())
    if signo < 0:
        faltan = [f'{nombres[pid]} (hay {stock.get(pid, 0)}, el pedido lleva {cant})'
                  for pid, cant in cantidades.items() if stock.get(pid, 0) < cant]
        if faltan:
            return faltan
    for pid, cant in cantidades.items():
        if pid in stock:
            cur.execute('UPDATE productos SET stock = stock + %s WHERE id = %s', (signo * cant, pid))
    return []


def cambiar_estado_pedido(pedido, nuevo):
    """Cambia el estado y mueve el inventario: al marcarlo vendido se restan las unidades;
    si vuelve a pendiente o se cancela, se devuelven. Devuelve (ok, mensaje)."""
    descontar = nuevo in ESTADOS_CON_STOCK_DESCONTADO
    con = get_connection()
    try:
        cur = con.cursor()
        mensaje_stock = ''
        if descontar and not pedido['stock_descontado']:
            faltan = mover_stock_pedido(cur, pedido['id'], -1)
            if faltan:
                con.rollback()
                return False, ('No se pudo marcar como ' + nuevo + ': no hay stock suficiente de ' + '; '.join(faltan) +
                               '. Ajusta el inventario en Productos o habla con el cliente.')
            mensaje_stock = ' Se descontaron sus unidades del inventario.'
        elif not descontar and pedido['stock_descontado']:
            mover_stock_pedido(cur, pedido['id'], 1)
            mensaje_stock = ' Sus unidades volvieron al inventario.'
        cur.execute('UPDATE pedidos SET estado = %s, stock_descontado = %s WHERE id = %s',
                    (nuevo, 1 if descontar else 0, pedido['id']))
        con.commit()
        return True, f'Pedido marcado como {nuevo}.{mensaje_stock}'
    except Exception:
        con.rollback()
        raise
    finally:
        con.close()


@app.route('/admin/pedidos/<int:id>', methods=['GET', 'POST'])
@login_requerido
def admin_pedido(id):
    pedido = consultar('SELECT * FROM pedidos WHERE id = %s', (id,), uno=True)
    if not pedido:
        abort(404)
    if request.method == 'POST':
        nuevo = request.form.get('estado')
        if nuevo in ESTADOS_PEDIDO and nuevo != pedido['estado']:
            ok, mensaje = cambiar_estado_pedido(pedido, nuevo)
            flash(mensaje, 'success' if ok else 'danger')
        return redirect(url_for('admin_pedido', id=id))
    detalle = consultar('SELECT d.*, p.stock AS stock_actual FROM pedido_detalle d '
                        'LEFT JOIN productos p ON p.id = d.producto_id WHERE d.pedido_id = %s', (id,))
    ahorro = sum((d['precio_lista'] - d['precio_unitario']) * d['cantidad'] for d in detalle if d['descuento'])
    telefono = telefono_whatsapp(pedido['cliente_telefono'])
    return render_template('admin/pedido.html', pedido=pedido, detalle=detalle, telefono=telefono, ahorro=ahorro)


@app.route('/admin/pedidos/<int:id>/eliminar', methods=['POST'])
@login_requerido
def admin_pedido_eliminar(id):
    """Borra un pedido (p. ej. uno de prueba o duplicado). Si ya había descontado stock, lo devuelve."""
    pedido = consultar('SELECT * FROM pedidos WHERE id = %s', (id,), uno=True)
    if not pedido:
        abort(404)
    con = get_connection()
    try:
        cur = con.cursor()
        if pedido['stock_descontado']:
            mover_stock_pedido(cur, id, 1)
        cur.execute('DELETE FROM pedidos WHERE id = %s', (id,))  # el detalle se borra en cascada
        con.commit()
    except Exception:
        con.rollback()
        raise
    finally:
        con.close()
    flash(f'Pedido {pedido["codigo"]} eliminado.' + (' Sus unidades volvieron al inventario.'
                                                      if pedido['stock_descontado'] else ''), 'success')
    return redirect(url_for('admin_pedidos'))


# =====================================================
#  Configuración
# =====================================================

@app.route('/admin/configuracion', methods=['GET', 'POST'])
@login_requerido
def admin_configuracion():
    if request.method == 'POST':
        valores = {}
        for clave in [f['clave'] for f in consultar('SELECT clave FROM configuracion')]:
            if clave in request.form:
                valores[clave] = request.form[clave].strip()
        actual = config_tienda().get('whatsapp_numero', '')
        if 'whatsapp_numero' in valores and valores['whatsapp_numero'] != actual:
            # Se guarda solo con dígitos y con el código de país, que WhatsApp necesita
            numero = telefono_whatsapp(valores['whatsapp_numero'])
            if not 11 <= len(numero) <= 15:
                flash('El número de WhatsApp no es válido. Escríbelo con el código de país, '
                      'por ejemplo 573001234567 (57 + el celular). No se guardó ningún cambio.', 'danger')
                return redirect(url_for('admin_configuracion'))
            valores['whatsapp_numero'] = numero
        correo = valores.get('correo_contacto', '')
        if correo and not re.fullmatch(r'[^@\s]+@[^@\s]+\.[^@\s]+', correo):
            flash('El correo de contacto no parece válido. No se guardó ningún cambio.', 'danger')
            return redirect(url_for('admin_configuracion'))
        for clave, valor in valores.items():
            ejecutar('UPDATE configuracion SET valor = %s WHERE clave = %s', (valor, clave))
        flash('Configuración guardada.', 'success')
        return redirect(url_for('admin_configuracion'))
    ajustes = consultar("SELECT * FROM configuracion ORDER BY FIELD(clave, 'nombre_tienda', 'whatsapp_numero', "
                        "'mensaje_pedido', 'moneda', 'correo_contacto', 'nit', 'direccion_tienda') = 0, "
                        "FIELD(clave, 'nombre_tienda', 'whatsapp_numero', 'mensaje_pedido', 'moneda', "
                        "'correo_contacto', 'nit', 'direccion_tienda'), clave")
    return render_template('admin/configuracion.html', ajustes=ajustes)


# =====================================================
#  Administradores
# =====================================================

@app.route('/admin/administradores')
@login_requerido
def admin_administradores():
    administradores = consultar('SELECT * FROM administradores ORDER BY activo DESC, nombre')
    return render_template('admin/administradores.html', administradores=administradores)


def protegida_para_mi(admin):
    """Una cuenta protegida (la de soporte técnico) solo la puede tocar ella misma: ningún otro
    administrador la puede editar, cambiarle la contraseña, desactivar ni borrar. Así, si la cliente
    olvida su contraseña, el soporte siempre puede entrar a ponerle una nueva."""
    return bool(admin and admin.get('protegido') and admin['id'] != session['admin_id'])


MENSAJE_PROTEGIDA = 'Esa es la cuenta de soporte técnico: está protegida y solo ella misma puede modificarse.'


@app.route('/admin/administradores/nuevo', methods=['GET', 'POST'])
@app.route('/admin/administradores/<int:id>/editar', methods=['GET', 'POST'])
@login_requerido
def admin_administrador_form(id=None):
    admin = None
    if id:
        admin = consultar('SELECT * FROM administradores WHERE id = %s', (id,), uno=True)
        if not admin:
            abort(404)
        if protegida_para_mi(admin):
            flash(MENSAJE_PROTEGIDA, 'warning')
            return redirect(url_for('admin_administradores'))
    es_yo = id == session['admin_id']

    if request.method == 'POST':
        f = request.form
        nombre = f.get('nombre', '').strip()
        usuario = f.get('usuario', '').strip()
        email = f.get('email', '').strip()
        password = f.get('password', '')
        # Uno mismo no se puede desactivar: así siempre queda al menos un admin activo
        activo = 1 if f.get('activo') or es_yo else 0

        # En la propia cuenta, cambiar la contraseña, el usuario o el correo (con lo que se inicia
        # sesión) pide la contraseña actual: así nadie se adueña de una sesión que quedó abierta
        cambia_acceso = es_yo and (password or usuario != admin['usuario'] or email != admin['email'])
        error = None
        if not all([nombre, usuario, email]):
            error = 'El nombre, el usuario y el correo son obligatorios.'
        elif not id and not password:
            error = 'Escribe una contraseña para el nuevo administrador.'
        elif password and (problema := problema_con_clave(password, f.get('password2', ''), usuario, email, nombre)):
            error = problema
        elif cambia_acceso and not check_password_hash(admin['password_hash'], f.get('password_actual', '')):
            error = 'Para cambiar tu contraseña, usuario o correo, escribe bien tu contraseña actual.'
        if error:
            flash(error, 'danger')
            return render_template('admin/administrador_form.html', admin=f, editando=id, es_yo=es_yo)

        datos = {'nombre': nombre, 'usuario': usuario, 'email': email, 'activo': activo}
        if password:
            datos['password_hash'] = generate_password_hash(password)
        columnas = list(datos)
        try:
            if id:
                ejecutar(f'UPDATE administradores SET {", ".join(c + " = %s" for c in columnas)} '
                         'WHERE id = %s AND (protegido = 0 OR id = %s)',
                         [datos[c] for c in columnas] + [id, session['admin_id']])
            else:
                ejecutar(f'INSERT INTO administradores ({", ".join(columnas)}) '
                         f'VALUES ({", ".join(["%s"] * len(columnas))})', [datos[c] for c in columnas])
        except mysql.connector.IntegrityError:
            flash('Ya existe un administrador con ese usuario o correo.', 'danger')
            return render_template('admin/administrador_form.html', admin=f, editando=id, es_yo=es_yo)

        if es_yo:
            session['admin_nombre'] = nombre
            if password:  # las demás sesiones de esta cuenta se cierran; esta sigue abierta
                session['admin_huella'] = huella_clave(datos['password_hash'])
        flash('Administrador guardado.' + (' Las sesiones abiertas con la contraseña anterior se cerraron.'
                                           if password and id else ''), 'success')
        return redirect(url_for('admin_administradores'))

    return render_template('admin/administrador_form.html', admin=admin, editando=id, es_yo=es_yo)


@app.route('/admin/administradores/<int:id>/activo', methods=['POST'])
@login_requerido
def admin_administrador_activo(id):
    admin = consultar('SELECT id, protegido FROM administradores WHERE id = %s', (id,), uno=True)
    if id == session['admin_id']:
        flash('No puedes desactivar tu propia cuenta.', 'warning')
    elif protegida_para_mi(admin):
        flash(MENSAJE_PROTEGIDA, 'warning')
    else:
        ejecutar('UPDATE administradores SET activo = 1 - activo WHERE id = %s AND protegido = 0', (id,))
    return redirect(url_for('admin_administradores'))


@app.route('/admin/administradores/<int:id>/eliminar', methods=['POST'])
@login_requerido
def admin_administrador_eliminar(id):
    admin = consultar('SELECT id, protegido FROM administradores WHERE id = %s', (id,), uno=True)
    if id == session['admin_id']:
        flash('No puedes eliminar tu propia cuenta.', 'warning')
    elif protegida_para_mi(admin):
        flash(MENSAJE_PROTEGIDA, 'warning')
    else:
        ejecutar('DELETE FROM administradores WHERE id = %s AND protegido = 0', (id,))
        flash('Administrador eliminado.', 'success')
    return redirect(url_for('admin_administradores'))


# Comandos de consola (en el computador o en el servidor). Proteger la cuenta de soporte se hace
# solo así, nunca desde el panel, para que nadie con acceso al panel pueda quitarle la protección:
#   flask --app app crear-admin USUARIO [--protegido]   crear un administrador (el primero, en el servidor)
#   flask --app app cambiar-clave USUARIO               último recurso si se pierden las contraseñas
#   flask --app app proteger-admin USUARIO
#   flask --app app desproteger-admin USUARIO
def marcar_protegido(usuario, valor):
    admin = consultar('SELECT id, nombre FROM administradores WHERE usuario = %s OR email = %s',
                      (usuario, usuario), uno=True)
    if not admin:
        raise click.ClickException(f'No existe un administrador con usuario o correo "{usuario}".')
    ejecutar('UPDATE administradores SET protegido = %s, activo = IF(%s = 1, 1, activo) WHERE id = %s',
             (valor, valor, admin['id']))
    click.echo(f'La cuenta "{admin["nombre"]}" ({usuario}) {"quedó protegida" if valor else "ya no está protegida"}.')


def pedir_clave_nueva(usuario, email='', nombre=''):
    while True:
        password = click.prompt('Contraseña nueva (no se ve al escribir)', hide_input=True)
        password2 = click.prompt('Repítela', hide_input=True)
        problema = problema_con_clave(password, password2, usuario, email, nombre)
        if not problema:
            return password
        click.echo(problema)


@app.cli.command('crear-admin')
@click.argument('usuario')
@click.option('--nombre', prompt='Nombre', help='Nombre que se muestra en el panel')
@click.option('--email', prompt='Correo', help='Correo (también sirve para iniciar sesión)')
@click.option('--protegido', is_flag=True, help='Protegerla de una vez (cuenta de soporte técnico)')
def crear_admin(usuario, nombre, email, protegido):
    """Crea un administrador (en el servidor, el primero se crea así)."""
    password = pedir_clave_nueva(usuario, email, nombre)
    try:
        ejecutar('INSERT INTO administradores (nombre, usuario, email, password_hash, protegido) '
                 'VALUES (%s, %s, %s, %s, %s)',
                 (nombre.strip(), usuario.strip(), email.strip(), generate_password_hash(password), int(protegido)))
    except mysql.connector.IntegrityError:
        raise click.ClickException('Ya existe un administrador con ese usuario o correo.')
    click.echo(f'Administrador "{usuario}" creado' + (' y protegido.' if protegido else '.'))


@app.cli.command('cambiar-clave')
@click.argument('usuario')
def cambiar_clave(usuario):
    """Último recurso: pone una contraseña nueva a cualquier cuenta, también a una protegida.
    Cierra sus sesiones abiertas."""
    admin = consultar('SELECT * FROM administradores WHERE usuario = %s OR email = %s', (usuario, usuario), uno=True)
    if not admin:
        raise click.ClickException(f'No existe un administrador con usuario o correo "{usuario}".')
    password = pedir_clave_nueva(admin['usuario'], admin['email'], admin['nombre'])
    ejecutar('UPDATE administradores SET password_hash = %s, activo = 1 WHERE id = %s',
             (generate_password_hash(password), admin['id']))
    click.echo(f'Contraseña de "{admin["usuario"]}" cambiada. Sus sesiones abiertas se cerraron.')


@app.cli.command('proteger-admin')
@click.argument('usuario')
def proteger_admin(usuario):
    """Protege una cuenta: solo ella misma podrá modificarse."""
    marcar_protegido(usuario, 1)


@app.cli.command('desproteger-admin')
@click.argument('usuario')
def desproteger_admin(usuario):
    """Quita la protección de una cuenta."""
    marcar_protegido(usuario, 0)


# =====================================================
#  Tienda pública: utilidades
# =====================================================

PRODUCTOS_POR_PAGINA = 24
MAX_CANTIDAD = 999

# Productos que el público puede ver: activos y de una categoría activa
SQL_PRODUCTOS_PUBLICOS = '''
    SELECT p.*, c.nombre AS categoria, c.slug AS categoria_slug, m.nombre AS marca,
           ROUND(p.precio * (100 - p.descuento) / 100) AS precio_final
    FROM productos p
    JOIN categorias c ON c.id = p.categoria_id
    LEFT JOIN categorias cp ON cp.id = c.categoria_padre_id
    LEFT JOIN marcas m ON m.id = p.marca_id
    WHERE p.activo = 1 AND c.activa = 1 AND COALESCE(cp.activa, 1) = 1'''


def filtro_busqueda(q):
    """Filtro SQL del buscador: cada palabra debe aparecer en el nombre, la descripción,
    el código, la marca o la categoría, sin importar el orden ("20w bombillo" encuentra "Bombillo 20w").
    La intercalación utf8mb4_unicode_ci ya ignora mayúsculas y tildes."""
    filtros, params = '', []
    for palabra in q.split()[:8]:
        filtros += (' AND (p.nombre LIKE %s OR p.descripcion_corta LIKE %s OR p.sku LIKE %s'
                    ' OR m.nombre LIKE %s OR c.nombre LIKE %s)')
        params += [f'%{palabra}%'] * 5
    return filtros, params


def config_tienda():
    return {f['clave']: f['valor'] for f in consultar('SELECT clave, valor FROM configuracion')}


def telefono_whatsapp(numero):
    """Deja solo los dígitos y, si es un celular colombiano sin código de país (10 dígitos que
    empiezan por 3, p. ej. 3214249330), le agrega el 57. WhatsApp necesita el número completo."""
    numero = re.sub(r'\D', '', numero or '')
    if len(numero) == 10 and numero.startswith('3'):
        numero = '57' + numero
    return numero


def enlace_whatsapp(numero, texto=''):
    """Devuelve el enlace wa.me, o None si el número no está bien configurado."""
    numero = telefono_whatsapp(numero)
    if len(numero) < 11:
        return None
    return f'https://wa.me/{numero}' + (f'?text={quote(texto)}' if texto else '')


def carrito_sesion():
    """El carrito vive en la sesión como {'id_producto': cantidad}."""
    return session.get('carrito', {})


def guardar_carrito(carrito):
    session['carrito'] = {k: v for k, v in carrito.items() if v > 0}


def carrito_detallado():
    """Junta el carrito de la sesión con los datos actuales de la base de datos."""
    carrito = carrito_sesion()
    if not carrito:
        return [], Decimal(0)
    ids = [int(i) for i in carrito]
    productos = consultar(SQL_PRODUCTOS_PUBLICOS + f' AND p.id IN ({", ".join(["%s"] * len(ids))})', ids)
    items, total = [], Decimal(0)
    for p in productos:
        cantidad = carrito[str(p['id'])]
        subtotal = p['precio_final'] * cantidad
        ahorro = (p['precio'] - p['precio_final']) * cantidad
        items.append({'producto': p, 'cantidad': cantidad, 'subtotal': subtotal, 'ahorro': ahorro})
        total += subtotal
    # Si un producto se ocultó o se borró desde el panel, sale del carrito
    if len(items) != len(carrito):
        guardar_carrito({str(i['producto']['id']): i['cantidad'] for i in items})
    return items, total


@app.context_processor
def constantes_ofertas():
    return {'DESCUENTO_MAXIMO': DESCUENTO_MAXIMO, 'DESCUENTOS_SUGERIDOS': DESCUENTOS_SUGERIDOS}


@app.after_request
def sin_copias_viejas(respuesta):
    """Las páginas HTML no se guardan en caché: al usar "atrás", el navegador las vuelve a pedir
    y muestra el carrito real (si no, enseñaba una copia con el contador viejo)."""
    if respuesta.mimetype == 'text/html':
        respuesta.headers['Cache-Control'] = 'no-store'
    return respuesta


@app.after_request
def cabeceras_de_seguridad(respuesta):
    """Ninguna otra página puede mostrar la tienda o el panel dentro de un marco (evita que engañen
    a la cliente para que haga clic en botones del panel sin darse cuenta), el navegador no adivina
    tipos de archivo, y los enlaces a otros sitios no les cuentan la dirección completa."""
    respuesta.headers.setdefault('X-Frame-Options', 'DENY')
    respuesta.headers.setdefault('Content-Security-Policy', "frame-ancestors 'none'")
    respuesta.headers.setdefault('X-Content-Type-Options', 'nosniff')
    respuesta.headers.setdefault('Referrer-Policy', 'strict-origin-when-cross-origin')
    respuesta.headers.setdefault('Permissions-Policy', 'camera=(), microphone=(), geolocation=()')
    if EN_SERVIDOR:  # el navegador recuerda usar siempre https
        respuesta.headers.setdefault('Strict-Transport-Security', 'max-age=15552000')
    return respuesta


@app.context_processor
def variables_tienda():
    def categorias_menu():
        return consultar('SELECT id, nombre, slug FROM categorias '
                         'WHERE activa = 1 AND categoria_padre_id IS NULL ORDER BY orden, nombre')
    if request.path.startswith('/admin'):
        return {}
    tienda = config_tienda()
    return {
        'tienda': tienda,
        'whatsapp_contacto': enlace_whatsapp(tienda.get('whatsapp_numero')),
        'carrito_cantidad': sum(carrito_sesion().values()),
        # Unidades de cada producto que ya están en el carrito ({'12': 3}); las tarjetas
        # lo usan para desactivar "Agregar" cuando ya se pidió todo el stock
        'carrito_items': carrito_sesion(),
        'categorias_menu': categorias_menu,
        'STOCK_BAJO': STOCK_BAJO,
        'iconos_categoria': ICONOS_CATEGORIA,
        'anio_actual': date.today().year,
    }


# =====================================================
#  Tienda pública: páginas
# =====================================================

@app.route('/')
def inicio():
    # Cada categoría con cuántos productos visibles tiene (contando sus subcategorías)
    categorias = consultar('''SELECT c.*,
        (SELECT COUNT(*) FROM productos p LEFT JOIN categorias s ON s.id = p.categoria_id
          WHERE p.activo = 1 AND (p.categoria_id = c.id OR s.categoria_padre_id = c.id)) AS num_productos
        FROM categorias c WHERE c.activa = 1 AND c.categoria_padre_id IS NULL ORDER BY c.orden, c.nombre''')
    destacados = consultar(SQL_PRODUCTOS_PUBLICOS + ' AND p.destacado = 1 ORDER BY p.creado_en DESC LIMIT 8')
    titulo_destacados = 'Productos destacados'
    if not destacados:
        # Mientras no se marquen destacados en el panel, se muestran algunos con foto
        destacados = consultar(SQL_PRODUCTOS_PUBLICOS + ' AND p.imagen_principal IS NOT NULL AND p.stock > 0 '
                               'ORDER BY RAND() LIMIT 8')
        titulo_destacados = 'Algunos de nuestros productos'
    marcas = consultar(f'''SELECT DISTINCT m.id, m.nombre, m.logo FROM marcas m
                           JOIN ({SQL_PRODUCTOS_PUBLICOS}) p ON p.marca_id = m.id
                           WHERE m.activa = 1 ORDER BY m.nombre''')
    return render_template('tienda/inicio.html', categorias=categorias, destacados=destacados,
                           titulo_destacados=titulo_destacados, marcas=marcas)


@app.route('/catalogo')
@app.route('/categoria/<slug>')
def catalogo(slug=None):
    # Los enlaces viejos a ?ofertas=1 llevan a la página de Ofertas
    if request.args.get('ofertas') == '1':
        return redirect(url_for('ofertas'), 301)
    categoria = None
    if slug:
        categoria = consultar('SELECT * FROM categorias WHERE slug = %s AND activa = 1', (slug,), uno=True)
        if not categoria:
            abort(404)
    q = request.args.get('q', '').strip()
    marca = request.args.get('marca', type=int)
    orden = request.args.get('orden', '')
    pagina = max(request.args.get('pagina', 1, type=int), 1)

    filtros, params = '', []
    if categoria:
        filtros += ' AND (c.id = %s OR c.categoria_padre_id = %s)'
        params += [categoria['id'], categoria['id']]
    if q:
        filtro_q, params_q = filtro_busqueda(q)
        filtros += filtro_q
        params += params_q
    if marca:
        filtros += ' AND p.marca_id = %s'
        params.append(marca)

    ordenes = {
        'precio_asc': 'precio_final ASC',
        'precio_desc': 'precio_final DESC',
        'nombre': 'p.nombre ASC',
    }
    orden_sql = ordenes.get(orden, 'p.destacado DESC, p.creado_en DESC')

    total = consultar(f'SELECT COUNT(*) AS n FROM ({SQL_PRODUCTOS_PUBLICOS}{filtros}) t', params, uno=True)['n']
    paginas = max((total + PRODUCTOS_POR_PAGINA - 1) // PRODUCTOS_POR_PAGINA, 1)
    pagina = min(pagina, paginas)
    productos = consultar(SQL_PRODUCTOS_PUBLICOS + filtros + f' ORDER BY {orden_sql} LIMIT %s OFFSET %s',
                          params + [PRODUCTOS_POR_PAGINA, (pagina - 1) * PRODUCTOS_POR_PAGINA])

    # Título de la página según desde dónde se llegó (menú, buscador o marcas del inicio)
    if categoria:
        titulo = categoria['nombre']
    elif q:
        titulo = f'Resultados para "{q}"'
    elif marca:
        fila = consultar('SELECT nombre FROM marcas WHERE id = %s', (marca,), uno=True)
        titulo = fila['nombre'] if fila else 'Catálogo'
    else:
        titulo = 'Catálogo'

    return render_template('tienda/catalogo.html', productos=productos, categoria=categoria, titulo=titulo,
                           q=q, marca=marca, orden=orden,
                           pagina=pagina, paginas=paginas, total=total)


@app.route('/ofertas')
def ofertas():
    """Productos con descuento. El titular sale de los descuentos que el admin tenga asignados
    (cantidad y "hasta X %"): si cambian o se quitan, la página cambia sola."""
    productos = consultar(SQL_PRODUCTOS_PUBLICOS + ' AND p.descuento > 0 '
                          'ORDER BY (p.stock > 0) DESC, p.descuento DESC, p.nombre')
    descuentos = {p['descuento'] for p in productos}
    return render_template('tienda/ofertas.html', productos=productos,
                           descuento_max=max(descuentos, default=0), descuento_variable=len(descuentos) > 1)


@app.route('/privacidad')
def privacidad():
    """Política de tratamiento de datos personales (Ley 1581 de 2012). Los datos del responsable
    (correo, NIT, dirección) salen de Configuración."""
    return render_template('tienda/privacidad.html')


@app.route('/buscar')
def buscar_sugerencias():
    """Resultados rápidos para la lista que aparece bajo el buscador mientras se escribe."""
    q = request.args.get('q', '').strip()[:80]
    if len(q) < 2:
        return jsonify(total=0, productos=[])
    filtros, params = filtro_busqueda(q)
    total = consultar(f'SELECT COUNT(*) AS n FROM ({SQL_PRODUCTOS_PUBLICOS}{filtros}) t', params, uno=True)['n']
    # Primero los que empiezan con lo escrito, luego los disponibles, luego por nombre
    filas = consultar(SQL_PRODUCTOS_PUBLICOS + filtros +
                      ' ORDER BY (p.nombre LIKE %s) DESC, (p.stock > 0) DESC, p.destacado DESC, p.nombre LIMIT 6',
                      params + [f'{q}%'])
    productos = [{
        'nombre': f['nombre'],
        'url': url_for('producto_detalle', slug=f['slug']),
        'imagen': url_for('static', filename=f['imagen_principal']) if f['imagen_principal'] else None,
        'detalle': f['categoria'],
        'precio': formato_dinero(f['precio_final']),
        'precio_anterior': formato_dinero(f['precio']) if f['descuento'] else None,
        'avisos': [{'texto': 'Agotado', 'tipo': 'agotado'}] if f['stock'] <= 0 else [],
    } for f in filas]
    return jsonify(total=total, productos=productos)

@app.route('/producto/<slug>')
def producto_detalle(slug):
    producto = consultar(SQL_PRODUCTOS_PUBLICOS + ' AND p.slug = %s', (slug,), uno=True)
    if not producto:
        abort(404)
    imagenes = consultar('SELECT url FROM producto_imagenes WHERE producto_id = %s ORDER BY orden, id',
                         (producto['id'],))
    especificaciones = consultar('SELECT nombre, valor FROM producto_especificaciones '
                                 'WHERE producto_id = %s ORDER BY orden, id', (producto['id'],))
    relacionados = consultar(SQL_PRODUCTOS_PUBLICOS + ' AND p.categoria_id = %s AND p.id <> %s '
                             'ORDER BY RAND() LIMIT 4', (producto['categoria_id'], producto['id']))
    return render_template('tienda/producto.html', producto=producto, imagenes=imagenes,
                           especificaciones=especificaciones, relacionados=relacionados)


# =====================================================
#  Tienda pública: carrito y pedido
# =====================================================

@app.route('/carrito')
def carrito():
    items, total = carrito_detallado()
    return render_template('tienda/carrito.html', items=items, total=total,
                           datos=session.get('datos_cliente', {}))


def volver_a(url):
    """Respuesta de las acciones del carrito. Si la pidió static/js/tienda.js (encabezado X-Carrito),
    devuelve la dirección en JSON para que el navegador *reemplace* la página actual; así agregar,
    quitar o cambiar cantidades no deja páginas repetidas en el historial (botón "atrás").
    Sin JavaScript, redirige como siempre."""
    if request.headers.get('X-Carrito') == '1':
        return jsonify(destino=url)
    return redirect(url)


@app.route('/carrito/agregar', methods=['POST'])
def carrito_agregar():
    producto_id = request.form.get('producto_id', type=int)
    cantidad = max(request.form.get('cantidad', 1, type=int), 1)
    producto = consultar(SQL_PRODUCTOS_PUBLICOS + ' AND p.id = %s', (producto_id,), uno=True)
    if not producto:
        abort(404)
    carrito = carrito_sesion()
    deseada = carrito.get(str(producto_id), 0) + cantidad
    nueva = min(deseada, producto['stock'], MAX_CANTIDAD)
    if nueva <= 0:
        flash(f'"{producto["nombre"]}" está agotado.', 'warning')
    else:
        carrito[str(producto_id)] = nueva
        guardar_carrito(carrito)
        if nueva < deseada:
            flash(f'Solo hay {producto["stock"]} unidades de "{producto["nombre"]}"; '
                  f'tu carrito quedó con el máximo disponible.', 'warning')
        else:
            flash(f'"{producto["nombre"]}" se agregó al carrito.', 'success')
    destino = request.form.get('volver', '')
    return volver_a(destino if es_ruta_local(destino) else url_for('carrito'))


@app.route('/carrito/actualizar', methods=['POST'])
def carrito_actualizar():
    carrito = carrito_sesion()
    items, _ = carrito_detallado()
    for item in items:
        p = item['producto']
        cantidad = request.form.get(f'cantidad_{p["id"]}', type=int)
        if cantidad is None:
            continue
        if cantidad > p['stock']:
            flash(f'Solo hay {p["stock"]} unidades de "{p["nombre"]}".', 'warning')
        carrito[str(p['id'])] = max(min(cantidad, p['stock'], MAX_CANTIDAD), 0)
    guardar_carrito(carrito)
    return volver_a(url_for('carrito'))


@app.route('/carrito/quitar/<int:producto_id>', methods=['POST'])
def carrito_quitar(producto_id):
    carrito = carrito_sesion()
    carrito.pop(str(producto_id), None)
    guardar_carrito(carrito)
    flash('Producto quitado del carrito.', 'success')
    return volver_a(url_for('carrito'))


PEDIDOS_POR_HORA = 10  # por IP; un cliente real casi nunca pasa de uno o dos
pedidos_por_ip = {}


@app.route('/pedido/enviar', methods=['POST'])
def pedido_enviar():
    f = request.form
    datos = {
        'nombre': f.get('nombre', '').strip()[:120],
        'telefono': f.get('telefono', '').strip()[:30],
        'ciudad': f.get('ciudad', '').strip()[:100],
        'direccion': f.get('direccion', '').strip()[:255],
        'notas': f.get('notas', '').strip()[:1000],
    }
    session['datos_cliente'] = datos  # para no tener que escribirlos otra vez

    items, total = carrito_detallado()
    if not items:
        flash('Tu carrito está vacío.', 'warning')
        return redirect(url_for('carrito'))
    if not datos['nombre'] or len(re.sub(r'\D', '', datos['telefono'])) < 7:
        flash('Escribe tu nombre y un número de teléfono válido.', 'danger')
        return redirect(url_for('carrito'))
    if not f.get('acepto_datos'):
        flash('Para enviar el pedido debes autorizar el tratamiento de tus datos personales.', 'danger')
        return redirect(url_for('carrito'))
    agotados = [i['producto']['nombre'] for i in items if i['cantidad'] > i['producto']['stock']]
    if agotados:
        flash('Ya no hay suficientes unidades de: ' + ', '.join(agotados) + '. Ajusta las cantidades.', 'danger')
        return redirect(url_for('carrito'))

    # Freno a pedidos falsos en serie: cada uno llena el panel y le escribe a la cliente
    ahora = time.time()
    recientes = [t for t in pedidos_por_ip.get(ip_cliente(), []) if ahora - t < 3600]
    if len(recientes) >= PEDIDOS_POR_HORA:
        flash('Recibimos varios pedidos seguidos desde tu conexión. Si necesitas algo más, '
              'escríbenos directamente por WhatsApp.', 'warning')
        return redirect(url_for('carrito'))
    pedidos_por_ip[ip_cliente()] = recientes + [ahora]

    con = get_connection()
    try:
        cur = con.cursor()
        # El código se arma con el id, así que primero se guarda con uno temporal
        cur.execute('INSERT INTO pedidos (codigo, cliente_nombre, cliente_telefono, cliente_direccion, '
                    'cliente_ciudad, notas, total, datos_autorizados_en) VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())',
                    (uuid.uuid4().hex[:20], datos['nombre'], datos['telefono'], datos['direccion'] or None,
                     datos['ciudad'] or None, datos['notas'] or None, total))
        pedido_id = cur.lastrowid
        codigo = f'ISM-{pedido_id:06d}'
        cur.execute('UPDATE pedidos SET codigo = %s WHERE id = %s', (codigo, pedido_id))
        for i in items:
            p = i['producto']
            cur.execute('INSERT INTO pedido_detalle (pedido_id, producto_id, nombre_producto, precio_unitario, '
                        'precio_lista, descuento, cantidad, subtotal) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)',
                        (pedido_id, p['id'], p['nombre'], p['precio_final'], p['precio'], p['descuento'],
                         i['cantidad'], i['subtotal']))
        con.commit()
    except Exception:
        con.rollback()
        raise
    finally:
        con.close()

    session.pop('carrito', None)
    session['ultimo_pedido'] = codigo
    return redirect(url_for('pedido_gracias', codigo=codigo))


@app.route('/pedido/<codigo>/gracias')
def pedido_gracias(codigo):
    # Solo quien hizo el pedido puede ver esta página
    if session.get('ultimo_pedido') != codigo:
        return redirect(url_for('inicio'))
    pedido = consultar('SELECT * FROM pedidos WHERE codigo = %s', (codigo,), uno=True)
    if not pedido:
        abort(404)
    detalle = consultar('SELECT * FROM pedido_detalle WHERE pedido_id = %s', (pedido['id'],))
    tienda = config_tienda()

    saludo = (tienda.get('mensaje_pedido') or 'Hola, quiero finalizar mi pedido').strip()
    if saludo[-1] not in '.!?:':
        saludo += '.'
    lineas = [saludo, '', f'*Pedido {pedido["codigo"]}*', '', '*Productos*']
    ahorro = 0
    for d in detalle:
        lineas.append(f'• {d["cantidad"]} x {d["nombre_producto"]}')
        # Debajo de cada producto: precio unitario si son varios y el descuento si tiene
        precio = formato_dinero(d['subtotal'])
        if d['cantidad'] > 1:
            precio = f'{formato_dinero(d["precio_unitario"])} c/u = {precio}'
        if d['descuento']:
            precio += f' (oferta -{d["descuento"]} %)'
            ahorro += (d['precio_lista'] - d['precio_unitario']) * d['cantidad']
        lineas.append(f'   {precio}')
    lineas.append('')
    if ahorro:
        lineas.append(f'Ahorro por ofertas: -{formato_dinero(ahorro)}')
    lineas += [f'*Total: {formato_dinero(pedido["total"])}*', '',
               '*Datos de entrega*',
               f'Nombre: {pedido["cliente_nombre"]}', f'Teléfono: {pedido["cliente_telefono"]}']
    if pedido['cliente_ciudad']:
        lineas.append(f'Ciudad: {pedido["cliente_ciudad"]}')
    if pedido['cliente_direccion']:
        lineas.append(f'Dirección: {pedido["cliente_direccion"]}')
    if pedido['notas']:
        lineas += ['', f'*Notas:* {pedido["notas"]}']
    lineas += ['', 'Quedo pendiente de la confirmación. ¡Gracias!']
    whatsapp = enlace_whatsapp(tienda.get('whatsapp_numero'), '\n'.join(lineas))

    return render_template('tienda/gracias.html', pedido=pedido, detalle=detalle, whatsapp=whatsapp, ahorro=ahorro)


@app.errorhandler(404)
def no_encontrado(e):
    if request.path.startswith('/admin'):
        if 'admin_id' not in session:
            return e
        # P. ej. al volver con "atrás" a un pedido o producto que se acaba de eliminar
        return render_template('error.html', titulo='Esta página ya no existe', icono='search',
                               mensaje='Puede que se haya eliminado (por ejemplo, un pedido o un producto).',
                               enlace=url_for('admin_dashboard'), enlace_texto='Volver al panel'), 404
    return render_template('tienda/404.html'), 404


@app.errorhandler(413)
def archivo_muy_grande(e):
    flash('El archivo es demasiado grande (máximo 16 MB por envío).', 'danger')
    return redirect(pagina_anterior(url_for('admin_dashboard')))


@app.errorhandler(500)
def error_del_servidor(e):
    # Página propia (sin la base de datos) en vez del error técnico; el detalle queda en el registro
    return render_template('error.html', titulo='Algo salió mal', icono='exclamation-triangle',
                           mensaje='Tuvimos un problema al cargar esta página. Inténtalo de nuevo en unos minutos.'), 500


if __name__ == '__main__':
    # Solo para trabajar en el computador. Al publicar, el servidor importa "app" (WSGI) y no pasa por aquí,
    # así que el modo de pruebas nunca queda activo en internet. ISMAR_DEBUG=0 lo apaga también aquí.
    app.run(debug=os.environ.get('ISMAR_DEBUG', '1') == '1')
