-- add unlogged table for pgbench inserts benchmark
CREATE UNLOGGED TABLE pgbench_inserts_unlogged (
  id serial UNIQUE NOT NULL,
  name char(10),
  price numeric,
  weight real,
  size int,
  color varchar,
  updated_at timestamp,
  built date,
  avail boolean
); 
