# ISMAR

Tienda en línea de productos eléctricos con panel de administrador. Los pedidos se finalizan por WhatsApp.

## Cómo ejecutarlo

1. Enciende XAMPP: `sudo /opt/lampp/lampp start`
2. Importa la base de datos `database/ismar.sql` (en phpMyAdmin o con `mysql -u root < database/ismar.sql`).
3. Instala las dependencias (solo la primera vez):
   ```bash
   python3 -m venv venv
   venv/bin/pip install -r requirements.txt
   ```
4. Arranca la aplicación:
   ```bash
   venv/bin/python app.py
   ```
5. Abre http://127.0.0.1:5000/admin — la primera vez te pedirá crear el administrador.

## Ramas

Cada tarea se trabaja en su propia rama creada desde `main` y se une con un pull request.
