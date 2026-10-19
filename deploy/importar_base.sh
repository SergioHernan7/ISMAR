#!/bin/bash
# =====================================================
#  Importa la base de datos de ISMAR en PythonAnywhere (SOLO LA PRIMERA VEZ)
#
#  Uso, desde una consola Bash de PythonAnywhere:
#    cd ~/ISMAR
#    bash deploy/importar_base.sh
#
#  Carga database/ismar.sql (tablas y configuración) y database/catalogo.sql
#  (los 139 productos). En PythonAnywhere la base se llama USUARIO$ismar, así que
#  se quitan las líneas DROP DATABASE / CREATE DATABASE / USE de los archivos.
#  Ojo: si las tablas ya existen, se detiene sin borrar nada.
# =====================================================
set -euo pipefail

USUARIO="$(whoami)"
HOST="$USUARIO.mysql.pythonanywhere-services.com"
BASE="$USUARIO\$ismar"
cd "$(dirname "$0")/.."

read -r -s -p "Contraseña de MySQL (la de la pestaña Databases): " CLAVE
echo
export MYSQL_PWD="$CLAVE"

if [ -n "$(mysql -h "$HOST" -u "$USUARIO" -N -e "SHOW TABLES LIKE 'productos'" "$BASE")" ]; then
  echo "La base $BASE ya tiene las tablas de la tienda. No se importó nada."
  exit 1
fi

for archivo in database/ismar.sql database/catalogo.sql; do
  echo "Importando $archivo ..."
  sed -E '/^(DROP DATABASE|CREATE DATABASE|USE )/d' "$archivo" \
    | mysql -h "$HOST" -u "$USUARIO" --default-character-set=utf8mb4 "$BASE"
done

echo "Listo. Productos cargados: $(mysql -h "$HOST" -u "$USUARIO" -N -e 'SELECT COUNT(*) FROM productos' "$BASE")"
