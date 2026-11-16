CREATE TABLE IF NOT EXISTS products (
    id         SERIAL PRIMARY KEY,
    name       TEXT        NOT NULL,
    category   TEXT        NOT NULL,
    price      NUMERIC(10,2) NOT NULL,
    stock      INTEGER     NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 20.000 registros (el enunciado exige mínimo 10K)
INSERT INTO products (name, category, price, stock)
SELECT
    'Producto ' || g || ' ' || (ARRAY['alfa','beta','gamma','delta','omega'])[1 + (g % 5)],
    (ARRAY['electronica','hogar','ropa','deportes','libros','juguetes','salud','jardin'])[1 + (g % 8)],
    round((random() * 990 + 10)::numeric, 2),
    (random() * 500)::int
FROM generate_series(1, 20000) AS g;

CREATE INDEX IF NOT EXISTS idx_products_category ON products (category);
ANALYZE products;
