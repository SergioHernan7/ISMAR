# Cómo publicar la tienda en PythonAnywhere

Guía paso a paso para poner ISMAR en internet. Donde dice **USUARIO** va el nombre de usuario
de la cuenta de PythonAnywhere: la dirección de la tienda será `USUARIO.pythonanywhere.com`.

Antes de empezar, ten a mano:

- El **número de WhatsApp** real de la cliente y sus datos para la privacidad (correo, NIT o cédula, dirección).
- La decisión de la cliente: **plan gratis** o **plan pago** (con o sin dominio propio).

---

## 1. Crear la cuenta

1. Entra a https://www.pythonanywhere.com y crea la cuenta (*Pricing & signup*).
   - Plan gratis: *Create a Beginner account*.
   - Plan pago: elige *Developer* y paga con tarjeta.
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
7. Arriba de la pestaña Web, presiona el botón verde **Reload**.

## 7. Primeros pasos en la tienda publicada (hacerlo de inmediato)

1. Abre `https://USUARIO.pythonanywhere.com/admin/setup` y crea el administrador de **soporte técnico**
   (el de ustedes, por ejemplo usuario `soporte`). Esta página queda abierta para cualquiera mientras no
   exista ninguno, por eso va primero. Guarden su contraseña en un gestor de contraseñas compartido.
2. **Protege** esa cuenta, para que nadie más pueda editarla, desactivarla ni borrarla. En la consola Bash:
   ```bash
   cd ~/ISMAR && workon ismar && flask --app app proteger-admin soporte
   ```
   Si la cliente olvida su contraseña, entran con esta cuenta y en **Administradores** le ponen una nueva.
3. En **Administradores**, crea la cuenta de la cliente. Ella la cambia en *Mi cuenta* la primera vez que entre.
4. En **Configuración**, pon el WhatsApp real, el correo, el NIT o cédula y la dirección.

## 8. Revisar que todo funcione

- [ ] La tienda se ve bien en el celular y en el computador.
- [ ] Pedido de prueba completo: llega al WhatsApp de la cliente y la **hora** del pedido es la de Colombia. Después bórralo en el panel.
- [ ] Subir una foto a un producto desde el panel.
- [ ] Compartir el enlace de un producto por WhatsApp: sale la vista previa con foto.
- [ ] Buscador, categorías, ofertas y carrito.
- [ ] Botones *Vendido* y *Cancelar* en Pedidos.
- [ ] `/admin/setup` ya no deja crear otro administrador.
- [ ] En **Administradores**, la cuenta de soporte sale como "Soporte técnico · protegida".
- [ ] La página de privacidad muestra los datos de la cliente.

Si algo sale mal, la pestaña **Web** > *Log files* > **error log** dice qué pasó.

---

## Después de publicar

**Plan gratis:** cada 3 meses hay que entrar a la pestaña **Web** y presionar *Run until 3 months from today*.
Si se olvida, la tienda se apaga hasta que alguien lo presione (antes llega un correo de aviso).

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

**Dominio propio** (solo plan pago): cómpralo (por ejemplo `electricosismar.com`). En la pestaña Web, agrega una nueva
web app con ese dominio (`www.electricosismar.com`) y copia la misma configuración (virtualenv, static files, WSGI).
PythonAnywhere muestra un dato CNAME (`webapp-XXXX.pythonanywhere.com`) que se pone en la página donde se compró el
dominio. Cuando funcione, en *Security* activa el certificado HTTPS gratuito (*Let's Encrypt*).
