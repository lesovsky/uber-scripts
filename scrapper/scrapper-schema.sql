-- create tables for scrapper-client data
CREATE TABLE IF NOT EXISTS servers (id SERIAL PRIMARY KEY, company text NOT NULL, hostname text UNIQUE NOT NULL, updated_at timestamp);
CREATE TABLE IF NOT EXISTS hardware (id SERIAL PRIMARY KEY, hostname text REFERENCES servers(hostname) ON DELETE CASCADE, cpu text, memory text, network text, storage text, disks text);
CREATE TABLE IF NOT EXISTS software (id SERIAL PRIMARY KEY, hostname text REFERENCES servers(hostname) ON DELETE CASCADE, os text, ip text, kernel text, pg_version text, pgb_version text, databases text);
