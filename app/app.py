import os, psycopg2
from flask import Flask, jsonify, request
from contextlib import contextmanager

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://app:secret@db:5432/mydb")

@contextmanager
def get_conn():
    conn = psycopg2.connect(DATABASE_URL)

    try:
        yield conn
    finally:
        conn.close()

app = Flask(__name__)

@app.get("/")
def index():
    return jsonify(message="Flask application running; check /health to see if postgresql is running")

@app.get("/health")
def health():
    try:
        with get_conn() as conn, conn.cursor() as cur:
            cur.execute("SELECT 1")

        return jsonify(
            status="healthy",
            database="connected"
        ), 200

    except Exception as e:
        return jsonify(
            status="unhealthy",
            database="disconnected",
            error=str(e)
        ), 503

@app.get("/items")
def list_items():
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("CREATE TABLE IF NOT EXISTS items (id SERIAL PRIMARY KEY, name TEXT NOT NULL)")
        cur.execute("SELECT id, name FROM items ORDER BY id")
        rows = [{"id": r[0], "name": r[1]} for r in cur.fetchall()]
        return jsonify(rows)

@app.post("/items")
def create_item():
    data = request.get_json(force=True)
    name = data.get("name")
    if not name:
        return jsonify(error="name required"), 400
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO items(name) VALUES (%s) RETURNING id", (name,))
        new_id = cur.fetchone()[0]
        conn.commit()
        return jsonify(id=new_id, name=name), 201

@app.delete("/items/<int:item_id>")
def delete_item(item_id):
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            "DELETE FROM items WHERE id = %s RETURNING id",
            (item_id,)
        )

        deleted = cur.fetchone()

        if deleted is None:
            return jsonify(error="Item not found"), 404

        conn.commit()

    return jsonify(
        message="Item deleted",
        id=item_id
    ), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
