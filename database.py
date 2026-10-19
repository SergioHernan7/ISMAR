import os

import mysql.connector


def get_connection():
    return mysql.connector.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        user=os.environ.get('DB_USER', 'root'),
        password=os.environ.get('DB_PASSWORD', ''),
        database=os.environ.get('DB_NAME', 'ismar'),
        charset='utf8mb4',
        collation='utf8mb4_unicode_ci',
        # Hora de Colombia para NOW(), CURDATE() y las fechas automáticas, aunque el
        # servidor esté en otra zona (PythonAnywhere usa UTC). Colombia no cambia de horario.
        time_zone=os.environ.get('DB_TIME_ZONE', '-05:00'),
    )
