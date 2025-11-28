-- =====================================================
-- 1️⃣ Activar la extensión pgvector
-- =====================================================
-- Esto permite almacenar vectores (embeddings) y realizar operaciones de similitud.
-- Si ya está activada, no da error gracias a "IF NOT EXISTS".
CREATE EXTENSION IF NOT EXISTS vector;

-- =====================================================
-- 2️⃣ Crear la tabla de documentos (base vectorial)
-- =====================================================
-- Esta tabla almacenará:
--   - content: el texto del documento
--   - metadata: información adicional en formato JSON
--   - embedding: el vector que representa el documento (por ejemplo generado por un modelo de IA)
CREATE TABLE documents (
  id bigserial PRIMARY KEY,   -- Identificador único automático
  content text,               -- Contenido textual del documento
  metadata jsonb,             -- Metadatos en JSON (categoría, fecha, autor, etc.)
  embedding vector(768)       -- Embedding del documento (768 dimensiones, ajustar según modelo)
);

-- =====================================================
-- 3️⃣ Crear función para buscar documentos similares
-- =====================================================
-- Parámetros de entrada:
--   query_embedding: embedding de la consulta
--   match_count: número máximo de resultados a devolver (por defecto 10)
--   filter: filtro opcional sobre metadata en formato JSON (por defecto '{}', sin filtrar)
-- Salida:
--   id, content, metadata, similarity (1 = muy similar, 0 = muy distinto)
CREATE OR REPLACE FUNCTION match_documents (
  query_embedding vector(768),   -- Vector de la consulta
  match_count int DEFAULT 10,    -- Máximo de resultados
  filter jsonb DEFAULT '{}'       -- Filtro opcional sobre metadata
) RETURNS TABLE (
  id bigint,       -- ID del documento
  content text,    -- Contenido del documento
  metadata jsonb,  -- Metadata del documento
  similarity float -- Similitud calculada entre 0 y 1
)
LANGUAGE sql
AS $$
  -- =====================================================
  -- Selecciona documentos que cumplen el filtro y calcula similitud
  -- =====================================================
  SELECT
    id,
    content,
    metadata,
    1 - (embedding <=> query_embedding) AS similarity -- Distancia coseno convertida en similitud
  FROM documents
  WHERE metadata @> filter   -- Aplica filtro JSON, si se pasa
  ORDER BY embedding <=> query_embedding  -- Ordena por cercanía del embedding (menor distancia = más cercano)
  LIMIT match_count;         -- Limita la cantidad de resultados
$$;
