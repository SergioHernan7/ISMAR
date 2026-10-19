# =====================================================
#  Archivo de arranque (WSGI) para PythonAnywhere
#
#  NO se usa tal cual desde aquí: se COPIA en PythonAnywhere, en la pestaña
#  Web > "WSGI configuration file" (/var/www/USUARIO_pythonanywhere_com_wsgi.py),
#  reemplazando todo lo que tenga ese archivo. Ver PUBLICAR.md, paso 6.
#
#  Las claves se escriben SOLO en la copia del servidor, nunca aquí:
#  este archivo está en GitHub y debe quedar con los valores de ejemplo.
# =====================================================
import os
import sys

USUARIO = 'CAMBIAR_usuario_de_pythonanywhere'

# --- Claves del servidor (cambiar en la copia de PythonAnywhere) ---
# Clave secreta: larga y aleatoria. Crearla en una consola con:
#   python3 -c "import secrets; print(secrets.token_hex(32))"
os.environ['SECRET_KEY'] = 'CAMBIAR_por_la_clave_secreta'
os.environ['ISMAR_HTTPS'] = '1'  # la página se sirve con candado (HTTPS)

# Base de datos (pestaña Databases de PythonAnywhere)
os.environ['DB_HOST'] = f'{USUARIO}.mysql.pythonanywhere-services.com'
os.environ['DB_USER'] = USUARIO
os.environ['DB_PASSWORD'] = 'CAMBIAR_por_la_contraseña_de_mysql'
os.environ['DB_NAME'] = f'{USUARIO}$ismar'

# --- Arranque de la tienda ---
proyecto = f'/home/{USUARIO}/ISMAR'
if proyecto not in sys.path:
    sys.path.insert(0, proyecto)

from app import app as application  # noqa: E402
