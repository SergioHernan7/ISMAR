#!/bin/bash
# =====================================================
#  Respaldo de la tienda en PythonAnywhere: base de datos + fotos subidas
#
#  Uso, desde una consola Bash de PythonAnywhere:
#    cd ~/ISMAR
#    bash deploy/respaldar.sh
#
#  Deja en ~/respaldos/ un archivo .sql (productos, pedidos, configuración...)
#  y un .tar.gz con static/uploads (las fotos subidas desde el panel, que no
#  están en GitHub). Después se descargan desde la pestaña Files.
#  Tienen datos personales de clientes: guardarlos en un lugar privado.
# =====================================================
set -euo pipefail

USUARIO="$(whoami)"
HOST="$USUARIO.mysql.pythonanywhere-services.com"
BASE="$USUARIO\$ismar"
FECHA="$(date +%Y-%m-%d)"
DESTINO="$HOME/respaldos"
cd "$(dirname "$0")/.."
mkdir -p "$DESTINO"

read -r -s -p "Contraseña de MySQL: " CLAVE
echo
MYSQL_PWD="$CLAVE" mysqldump -h "$HOST" -u "$USUARIO" --single-transaction --no-tablespaces \
  --default-character-set=utf8mb4 "$BASE" > "$DESTINO/ismar-$FECHA.sql"
tar -czf "$DESTINO/fotos-$FECHA.tar.gz" static/uploads

echo "Respaldo listo en $DESTINO:"
ls -lh "$DESTINO" | tail -n 2
