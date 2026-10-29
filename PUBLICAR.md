# Cómo publicar la tienda en PythonAnywhere

Guía paso a paso para poner ISMAR en internet. Donde dice **USUARIO** va el nombre de usuario
de la cuenta de PythonAnywhere: la dirección de la tienda será `USUARIO.pythonanywhere.com`.

Antes de empezar, ten a mano:

- El **número de WhatsApp** real de la cliente y sus datos para la privacidad (correo, NIT o cédula, dirección).
- La decisión de la cliente: con o sin **dominio propio**.

**Se necesita el plan pago *Developer*** (10 dólares al mes, revisado en oct. 2026). Desde enero de 2026 las
cuentas gratis nuevas de PythonAnywhere **no traen MySQL**, y la tienda lo necesita; además la página gratis se
apaga si no se renueva cada mes. Mejor que la cuenta quede a nombre de la cliente y con su tarjeta.

---

## 1. Crear la cuenta

1. Entra a https://www.pythonanywhere.com y crea la cuenta (*Pricing & signup*).
   Elige el plan **Developer** y paga con tarjeta (el plan gratis *Beginner* no sirve: no trae MySQL).
2. Elige bien el **nombre de usuario**: será la dirección de la tienda (ej. `electricosismar`).
3. Usa un correo que se revise (ahí llegan los avisos de renovación) y una contraseña fuerte.
   En *Account > Security*, activa la **verificación en dos pasos**.

## 2. Crear la base de datos

1. Pestaña **Databases**.
2. En *MySQL password*, crea una contraseña **larga y distinta** a la de la cuenta. Guárdala: se usa en los pasos 4 y 6.
3. En *Create a database* escribe `ismar` y presiona *Create*. La base queda como `USUARIO$ismar`.

## 3. Descargar el código desde GitHub

El repositorio es privado, así que GitHub pide un permiso (token):

1. En GitHub: foto de perfil > *Settings* > *Developer settings* > *Personal access tokens* > *Tokens (classic)* >
   *Generate new token (classic)*. Marca solo **`repo`** y ponle vencimiento de **7 días**. Copia el token.
2. En PythonAnywhere, pestaña **Consoles** > **Bash**, y escribe:
   ```bash
   git clone https://github.com/SergioHernan7/ISMAR.git
   ```
   Cuando pida *Username* escribe tu usuario de GitHub, y en *Password* pega el **token** (no se ve al pegarlo; es normal).

## 4. Importar la base de datos (solo la primera vez)

En la misma consola Bash:

```bash
cd ~/ISMAR
bash deploy/importar_base.sh
```

Pide la contraseña de MySQL del paso 2. Al terminar dice `Productos cargados: 139`.

## 5. Instalar los programas de la tienda

En la consola Bash:

```bash
mkvirtualenv --python=/usr/bin/python3.12 ismar
pip install -r ~/ISMAR/requirements.txt
```

Si `python3.12` no existe, usa la versión más nueva que ofrezca PythonAnywhere (y la misma en el paso 6).

## 6. Crear la aplicación web

1. Pestaña **Web** > *Add a new web app* > *Next* > **Manual configuration** (no "Flask") > **Python 3.12**.
2. En la sección **Virtualenv** escribe: `/home/USUARIO/.virtualenvs/ismar`
3. En **Static files** agrega: URL `/static/` y Directory `/home/USUARIO/ISMAR/static`
4. En **Security**, activa **Force HTTPS**.
5. Crea la clave secreta. En la consola Bash:
   ```bash
   python3 -c "import secrets; print(secrets.token_hex(32))"
   ```
   Copia lo que salga.
6. En la sección **Code**, abre el *WSGI configuration file*. **Borra todo** su contenido y pega el de
   [`deploy/wsgi_pythonanywhere.py`](deploy/wsgi_pythonanywhere.py). Cambia los tres valores `CAMBIAR_...`:
   - `USUARIO`: tu usuario de PythonAnywhere.
   - `SECRET_KEY`: la clave que acabas de crear.
   - `DB_PASSWORD`: la contraseña de MySQL del paso 2.

   Guarda con *Save*. Estas claves quedan solo en el servidor: **nunca** las pongas en GitHub ni las mandes por WhatsApp.
   Si se te olvida cambiar alguno, la tienda **no arranca a propósito** y el *error log* dice cuál falta:
   con la clave de ejemplo, cualquiera podría entrar al panel.
7. Arriba de la pestaña Web, presiona el botón verde **Reload**.

## 7. Primeros pasos en la tienda publicada (hacerlo de inmediato)

1. Los datos de la base del archivo WSGI solo los lee la página web, **no la consola**. Para que los comandos
   `flask --app app ...` encuentren la base, guárdalos en el entorno (una sola vez; cambia USUARIO y la contraseña
   de MySQL del paso 2). En la consola Bash, pega todo el bloque:
   ```bash
   cat >> ~/.virtualenvs/ismar/bin/postactivate <<'EOF'
   export DB_HOST=USUARIO.mysql.pythonanywhere-services.com
   export DB_USER=USUARIO
   export DB_NAME='USUARIO$ismar'
   export DB_PASSWORD='CONTRASEÑA_DE_MYSQL'
   EOF
   workon ismar
   ```
   Sin esto, los comandos fallan con `Can't connect to MySQL server on 'localhost'`.
2. Crea el administrador de **soporte técnico** (el de ustedes) ya **protegido**, desde la consola Bash.
   En el servidor la página `/admin/setup` está cerrada a propósito: si no, quedaría abierta para
   cualquiera hasta crear el primero.
   ```bash
   cd ~/ISMAR && workon ismar && flask --app app crear-admin soporte --protegido
   ```
   Te pide nombre, correo y la contraseña (mínimo 10 caracteres; no se ve al escribirla). Guárdenla en un
   gestor de contraseñas compartido. Protegida significa que nadie más la puede editar, desactivar ni borrar:
   si la cliente olvida su contraseña, entran con esta cuenta y en **Administradores** le ponen una nueva.
3. Si algún día se pierden **todas** las contraseñas, en la consola Bash:
   `cd ~/ISMAR && workon ismar && flask --app app cambiar-clave soporte`
4. Crea la cuenta de la cliente (en **Administradores** o con `flask --app app crear-admin USUARIO`). Ella la cambia en *Mi cuenta* la primera vez que entre.
5. En **Configuración**, pon el WhatsApp real, el correo, el NIT o cédula y la dirección.

## 8. Revisar que todo funcione

- [ ] La tienda se ve bien en el celular y en el computador.
- [ ] Pedido de prueba completo: llega al WhatsApp de la cliente y la **hora** del pedido es la de Colombia. Después bórralo en el panel.
- [ ] Subir una foto a un producto desde el panel.
- [ ] Compartir el enlace de un producto por WhatsApp: sale la vista previa con foto.
- [ ] Buscador, categorías, ofertas y carrito.
- [ ] Botones *Vendido* y *Cancelar* en Pedidos.
- [ ] `/admin/setup` no deja crear administradores (dice que se usa la consola).
- [ ] Al fallar 5 veces la contraseña, solo te bloquea a ti: desde el celular con datos (otra IP) se sigue pudiendo entrar.
- [ ] En **Administradores**, la cuenta de soporte sale como "Soporte técnico · protegida".
- [ ] La página de privacidad muestra los datos de la cliente.

Si algo sale mal, la pestaña **Web** > *Log files* > **error log** dice qué pasó.

---

## Después de publicar

**Subir cambios nuevos** (después de hacer el merge en GitHub). En la consola Bash:

```bash
cd ~/ISMAR
git pull
```

Y presiona **Reload** en la pestaña Web. Si cambió `requirements.txt`, antes de Reload: `workon ismar` y `pip install -r requirements.txt`.
La base de datos se actualiza sola al arrancar (no hay que volver a importarla).

**Respaldos** (por lo menos una vez al mes). En la consola Bash:

```bash
cd ~/ISMAR
bash deploy/respaldar.sh
```

Deja la base de datos y las fotos subidas en la carpeta `respaldos`. Descárgalos desde la pestaña **Files** y guárdalos
en un lugar privado: tienen datos personales de los clientes.

**Dominio propio** (opcional): cómpralo (por ejemplo `electricosismar.com`). En la pestaña Web, agrega una nueva
web app con ese dominio (`www.electricosismar.com`) y copia la misma configuración (virtualenv, static files, WSGI).
PythonAnywhere muestra un dato CNAME (`webapp-XXXX.pythonanywhere.com`) que se pone en la página donde se compró el
dominio. Cuando funcione, en *Security* activa el certificado HTTPS gratuito (*Let's Encrypt*).
