-- create tables for scrapper-client data
CREATE TABLE IF NOT EXISTS servers (
  id SERIAL PRIMARY KEY,
  company text NOT NULL,
  hostname text UNIQUE NOT NULL,
  is_alive boolean DEFAULT true,
  updated_at timestamp DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS hardware (
  id SERIAL PRIMARY KEY,
  hostname text REFERENCES servers(hostname) ON DELETE CASCADE,
  cpu text,
  memory text,
  network text,
  storage text,
  disks text
);
CREATE TABLE IF NOT EXISTS software (
  id SERIAL PRIMARY KEY,
  hostname text REFERENCES servers(hostname) ON DELETE CASCADE,
  os text,
  ip text,
  kernel text,
  pg_version text,
  pgb_version text,
  databases text
);

-- permissions
GRANT SELECT,INSERT,UPDATE ON ALL TABLES IN SCHEMA public TO scrapper;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA public TO scrapper;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT,INSERT,UPDATE ON TABLES TO scrapper;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES TO scrapper;
