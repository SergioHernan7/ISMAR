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
    )
