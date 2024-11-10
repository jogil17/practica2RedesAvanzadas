import os
from flask import Flask, jsonify
import psycopg2
import redis

app = Flask(__name__, static_folder="/app/static")

def get_db_connection():
    db_url = os.getenv('DATABASE_URL')
    try:
        conn = psycopg2.connect(db_url)
        return conn
    except Exception as e:
        print(f"Error conectando a la base de datos: {e}")
        return None

def get_cache_connection():
    cache_url = os.getenv('CACHE_URL')
    if cache_url and cache_url != 'none':
        try:
            cache = redis.StrictRedis.from_url(cache_url)
            # Probar conexión
            cache.ping()
            return cache
        except Exception as e:
            print(f"Error conectando a la caché: {e}")
            return None
    return None

@app.route('/')
def index():
    # Estado de la base de datos
    conn = get_db_connection()
    db_status = "Conectado" if conn else "No conectado"
    if conn:
        conn.close()
    
    # Estado de la caché
    cache = get_cache_connection()
    cache_status = "Conectado" if cache else "No conectado"
    
    return jsonify({
        "Database": db_status,
        "Cache": cache_status
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
