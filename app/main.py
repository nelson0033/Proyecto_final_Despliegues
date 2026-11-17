"""API REST de catálogo de productos (FastAPI + PostgreSQL).

Endpoints pensados para generar carga variada:
  GET  /health                 -> sin BD (línea base de la app)
  GET  /products/{id}          -> lectura por clave primaria
  GET  /products?category=&limit=  -> lectura de lista filtrada
  GET  /search?q=              -> búsqueda con LIKE (más costosa)
  GET  /stats                  -> agregación sobre todos los registros
  POST /products               -> escritura (insert)
  PUT  /products/{id}/stock    -> escritura (update)
"""
import os
import random
import threading
from contextlib import contextmanager

from fastapi import FastAPI, HTTPException, Query
from psycopg2.extras import RealDictCursor
from psycopg2.pool import ThreadedConnectionPool
from pydantic import BaseModel

DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "catalog")
DB_USER = os.getenv("DB_USER", "catalog")
DB_PASSWORD = os.getenv("DB_PASSWORD", "catalog")
POOL_MAX = int(os.getenv("DB_POOL_MAX", "10"))

app = FastAPI(title="Catalog API")
_pool = None
_pool_lock = threading.Lock()
# ThreadedConnectionPool lanza PoolError (HTTP 500) si se agotan las conexiones.
# El semáforo hace que las peticiones esperen su turno en vez de fallar.
_slots = threading.BoundedSemaphore(POOL_MAX)


def get_pool():
    global _pool
    if _pool is None:
        with _pool_lock:
            if _pool is None:
                _pool = ThreadedConnectionPool(
                    1, POOL_MAX, host=DB_HOST, port=DB_PORT, dbname=DB_NAME,
                    user=DB_USER, password=DB_PASSWORD,
                )
    return _pool


@contextmanager
def cursor(commit=False):
    pool = get_pool()
    _slots.acquire()
    try:
        conn = pool.getconn()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                yield cur
            if commit:
                conn.commit()
            else:
                conn.rollback()
        except Exception:
            conn.rollback()
            raise
        finally:
            pool.putconn(conn)
    finally:
        _slots.release()


class ProductIn(BaseModel):
    name: str
    category: str
    price: float
    stock: int = 0


class StockIn(BaseModel):
    stock: int


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/products/{product_id}")
def get_product(product_id: int):
    with cursor() as cur:
        cur.execute("SELECT * FROM products WHERE id = %s", (product_id,))
        row = cur.fetchone()
    if not row:
        raise HTTPException(404, "not found")
    return row


@app.get("/products")
def list_products(category: str = None, limit: int = Query(50, le=500)):
    with cursor() as cur:
        if category:
            cur.execute(
                "SELECT * FROM products WHERE category = %s ORDER BY id LIMIT %s",
                (category, limit),
            )
        else:
            cur.execute("SELECT * FROM products ORDER BY id LIMIT %s", (limit,))
        return cur.fetchall()


@app.get("/search")
def search(q: str, limit: int = Query(20, le=100)):
    with cursor() as cur:
        cur.execute(
            "SELECT * FROM products WHERE name ILIKE %s ORDER BY id LIMIT %s",
            (f"%{q}%", limit),
        )
        return cur.fetchall()


@app.get("/stats")
def stats():
    with cursor() as cur:
        cur.execute(
            "SELECT category, count(*) AS n, avg(price)::numeric(10,2) AS avg_price, "
            "sum(stock) AS total_stock FROM products GROUP BY category ORDER BY category"
        )
        return cur.fetchall()


@app.post("/products", status_code=201)
def create_product(p: ProductIn):
    with cursor(commit=True) as cur:
        cur.execute(
            "INSERT INTO products (name, category, price, stock) "
            "VALUES (%s, %s, %s, %s) RETURNING *",
            (p.name, p.category, p.price, p.stock),
        )
        return cur.fetchone()


@app.put("/products/{product_id}/stock")
def update_stock(product_id: int, s: StockIn):
    with cursor(commit=True) as cur:
        cur.execute(
            "UPDATE products SET stock = %s WHERE id = %s RETURNING *",
            (s.stock, product_id),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(404, "not found")
    return row
