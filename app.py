import os
import re
import secrets
import unicodedata
import uuid
from decimal import Decimal, InvalidOperation
from functools import wraps

import mysql.connector
from flask import (Flask, abort, flash, redirect, render_template, request,
                   session, url_for)
from werkzeug.security import check_password_hash, generate_password_hash
from werkzeug.utils import secure_filename

from database import get_connection

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'cambia-esta-clave-en-produccion')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16 MB por envío

EXTENSIONES_IMAGEN = {'png', 'jpg', 'jpeg', 'webp', 'gif'}
ESTADOS_PEDIDO = ['pendiente', 'confirmado', 'enviado', 'entregado', 'cancelado']
STOCK_BAJO = 5


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


def guardar_imagen(archivo, carpeta):
    """Guarda una imagen subida y devuelve su ruta dentro de /static, o None."""
    if not archivo or not archivo.filename:
        return None
    ext = archivo.filename.rsplit('.', 1)[-1].lower() if '.' in archivo.filename else ''
    if ext not in EXTENSIONES_IMAGEN:
        flash(f'"{archivo.filename}" no es una imagen válida (usa png, jpg, webp o gif).', 'warning')
        return None
    nombre = f'{uuid.uuid4().hex[:12]}_{secure_filename(archivo.filename)}'
    ruta = f'uploads/{carpeta}/{nombre}'
    archivo.save(os.path.join(app.static_folder, ruta))
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
    return numero


@app.template_filter('dinero')
def formato_dinero(valor):
    if valor is None:
        return ''
    return '$' + f'{valor:,.0f}'.replace(',', '.')


# =====================================================
#  Sesión y seguridad
# =====================================================

def login_requerido(vista):
    @wraps(vista)
    def envoltura(*args, **kwargs):
        if 'admin_id' not in session:
            return redirect(url_for('admin_login', next=request.path))
        return vista(*args, **kwargs)
    return envoltura


@app.before_request
def verificar_csrf():
    if request.method == 'POST':
        token = session.get('csrf_token')
        if not token or token != request.form.get('csrf_token'):
            abort(400, 'Formulario caducado, vuelve a intentarlo.')


@app.context_processor
def variables_globales():
    if 'csrf_token' not in session:
        session['csrf_token'] = secrets.token_hex(16)
    return {'csrf_token': session['csrf_token'], 'ESTADOS_PEDIDO': ESTADOS_PEDIDO}


def hay_administradores():
    return consultar('SELECT COUNT(*) AS n FROM administradores', uno=True)['n'] > 0


# =====================================================
#  Acceso al panel
# =====================================================

@app.route('/')
def inicio():
    # La tienda pública aún no existe; por ahora se entra directo al panel.
    return redirect(url_for('admin_dashboard'))


@app.route('/admin/setup', methods=['GET', 'POST'])
def admin_setup():
    """Crea el primer administrador. Solo funciona si todavía no hay ninguno."""
    if hay_administradores():
        return redirect(url_for('admin_login'))
    if request.method == 'POST':
        nombre = request.form.get('nombre', '').strip()
        usuario = request.form.get('usuario', '').strip()
        email = request.form.get('email', '').strip()
        password = request.form.get('password', '')
        if not all([nombre, usuario, email, password]):
            flash('Completa todos los campos.', 'danger')
        elif len(password) < 8:
            flash('La contraseña debe tener al menos 8 caracteres.', 'danger')
        elif password != request.form.get('password2', ''):
            flash('Las contraseñas no coinciden.', 'danger')
        else:
            ejecutar('INSERT INTO administradores (nombre, usuario, email, password_hash) '
                     'VALUES (%s, %s, %s, %s)',
                     (nombre, usuario, email, generate_password_hash(password)))
            flash('Administrador creado. Ya puedes iniciar sesión.', 'success')
            return redirect(url_for('admin_login'))
    return render_template('admin/setup.html')


@app.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    if not hay_administradores():
        return redirect(url_for('admin_setup'))
    if request.method == 'POST':
        usuario = request.form.get('usuario', '').strip()
        admin = consultar('SELECT * FROM administradores WHERE (usuario = %s OR email = %s) AND activo = 1',
                          (usuario, usuario), uno=True)
        if admin and check_password_hash(admin['password_hash'], request.form.get('password', '')):
            session.clear()
            session['admin_id'] = admin['id']
            session['admin_nombre'] = admin['nombre']
            ejecutar('UPDATE administradores SET ultimo_acceso = NOW() WHERE id = %s', (admin['id'],))
            destino = request.args.get('next', '')
            return redirect(destino if destino.startswith('/admin') else url_for('admin_dashboard'))
        flash('Usuario o contraseña incorrectos.', 'danger')
    return render_template('admin/login.html')


@app.route('/admin/logout')
def admin_logout():
    session.clear()
    return redirect(url_for('admin_login'))


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
             WHERE estado IN ('confirmado', 'enviado', 'entregado')
               AND creado_en >= DATE_FORMAT(CURDATE(), '%%Y-%%m-01'))        AS ventas_mes
    ''', (STOCK_BAJO,), uno=True)
    ultimos_pedidos = consultar('SELECT * FROM pedidos ORDER BY creado_en DESC LIMIT 5')
    poco_stock = consultar('SELECT id, nombre, stock FROM productos '
                           'WHERE activo = 1 AND stock <= %s ORDER BY stock LIMIT 5', (STOCK_BAJO,))
    return render_template('admin/dashboard.html', stats=stats,
                           ultimos_pedidos=ultimos_pedidos, poco_stock=poco_stock)


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


@app.route('/admin/productos')
@login_requerido
def admin_productos():
    q = request.args.get('q', '').strip()
    categoria = request.args.get('categoria', type=int)
    sql = '''SELECT p.*, c.nombre AS categoria, m.nombre AS marca
             FROM productos p
             JOIN categorias c ON c.id = p.categoria_id
             LEFT JOIN marcas m ON m.id = p.marca_id
             WHERE 1 = 1'''
    params = []
    if q:
        sql += ' AND (p.nombre LIKE %s OR p.sku LIKE %s)'
        params += [f'%{q}%', f'%{q}%']
    if categoria:
        sql += ' AND (p.categoria_id = %s OR c.categoria_padre_id = %s)'
        params += [categoria, categoria]
    sql += ' ORDER BY p.creado_en DESC'
    productos = consultar(sql, params)
    categorias = consultar('SELECT id, nombre FROM categorias ORDER BY nombre')
    return render_template('admin/productos.html', productos=productos, categorias=categorias,
                           q=q, categoria=categoria, STOCK_BAJO=STOCK_BAJO)


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
            precio_oferta = a_decimal(f.get('precio_oferta'), 'precio de oferta', obligatorio=False)
            if precio_oferta is not None and precio_oferta >= precio:
                raise ValueError('El precio de oferta debe ser menor que el precio normal.')
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
            'descripcion': f.get('descripcion', '').strip() or None,
            'precio': precio,
            'precio_oferta': precio_oferta,
            'stock': stock,
            'destacado': 1 if f.get('destacado') else 0,
            'activo': 1 if f.get('activo') else 0,
        }
        nueva_imagen = guardar_imagen(request.files.get('imagen_principal'), 'productos')
        if nueva_imagen:
            datos['imagen_principal'] = nueva_imagen

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
                    cur.execute('INSERT INTO producto_imagenes (producto_id, url) VALUES (%s, %s)',
                                (producto_id, ruta))
            con.commit()
        except mysql.connector.IntegrityError:
            con.rollback()
            borrar_imagen(nueva_imagen)
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
    return redirect(request.referrer or url_for('admin_productos'))


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
        if not nombre:
            flash('El nombre es obligatorio.', 'danger')
            return render_template('admin/categoria_form.html', categoria=f, padres=padres, editando=id)
        datos = {
            'nombre': nombre,
            'slug': slug_unico('categorias', nombre, excluir_id=id),
            'categoria_padre_id': int(f['categoria_padre_id']) if f.get('categoria_padre_id') else None,
            'descripcion': f.get('descripcion', '').strip() or None,
            'orden': int(f.get('orden') or 0),
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

@app.route('/admin/pedidos')
@login_requerido
def admin_pedidos():
    estado = request.args.get('estado', '')
    if estado in ESTADOS_PEDIDO:
        pedidos = consultar('SELECT * FROM pedidos WHERE estado = %s ORDER BY creado_en DESC', (estado,))
    else:
        estado = ''
        pedidos = consultar('SELECT * FROM pedidos ORDER BY creado_en DESC')
    conteo = {f['estado']: f['n'] for f in
              consultar('SELECT estado, COUNT(*) AS n FROM pedidos GROUP BY estado')}
    return render_template('admin/pedidos.html', pedidos=pedidos, estado=estado, conteo=conteo)


@app.route('/admin/pedidos/<int:id>', methods=['GET', 'POST'])
@login_requerido
def admin_pedido(id):
    pedido = consultar('SELECT * FROM pedidos WHERE id = %s', (id,), uno=True)
    if not pedido:
        abort(404)
    if request.method == 'POST':
        nuevo = request.form.get('estado')
        if nuevo in ESTADOS_PEDIDO:
            ejecutar('UPDATE pedidos SET estado = %s WHERE id = %s', (nuevo, id))
            flash(f'Pedido marcado como {nuevo}.', 'success')
        return redirect(url_for('admin_pedido', id=id))
    detalle = consultar('SELECT * FROM pedido_detalle WHERE pedido_id = %s', (id,))
    telefono = re.sub(r'\D', '', pedido['cliente_telefono'])
    return render_template('admin/pedido.html', pedido=pedido, detalle=detalle, telefono=telefono)


# =====================================================
#  Configuración
# =====================================================

@app.route('/admin/configuracion', methods=['GET', 'POST'])
@login_requerido
def admin_configuracion():
    if request.method == 'POST':
        for clave in [f['clave'] for f in consultar('SELECT clave FROM configuracion')]:
            if clave in request.form:
                ejecutar('UPDATE configuracion SET valor = %s WHERE clave = %s',
                         (request.form[clave].strip(), clave))
        flash('Configuración guardada.', 'success')
        return redirect(url_for('admin_configuracion'))
    ajustes = consultar('SELECT * FROM configuracion ORDER BY clave')
    return render_template('admin/configuracion.html', ajustes=ajustes)


if __name__ == '__main__':
    app.run(debug=True)
