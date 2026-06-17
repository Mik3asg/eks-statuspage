-- What:  Creates the database schema on first boot
-- Why:   Docker mounts this into postgres and runs it automatically — no manual migrations needed locally

CREATE TYPE service_status AS ENUM (
  'operational',
  'degraded',
  'partial_outage',
  'major_outage'
);

CREATE TYPE incident_status AS ENUM (
  'investigating',
  'identified',
  'monitoring',
  'resolved'
);

CREATE TABLE IF NOT EXISTS services (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  description TEXT,
  status      service_status NOT NULL DEFAULT 'operational',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS incidents (
  id          SERIAL PRIMARY KEY,
  service_id  INTEGER REFERENCES services(id) ON DELETE CASCADE,
  title       VARCHAR(200) NOT NULL,
  description TEXT,
  status      incident_status NOT NULL DEFAULT 'investigating',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed a few services so the UI isn't empty on first run
INSERT INTO services (name, description, status) VALUES
  ('API Gateway',  'Public-facing REST API',         'operational'),
  ('Frontend',     'React status page UI',           'operational'),
  ('Database',     'PostgreSQL primary',             'operational'),
  ('Auth Service', 'JWT authentication service',     'operational');
