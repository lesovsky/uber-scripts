-- add normal table for pgbench inserts benchmark
CREATE TABLE pgbench_inserts_normal (
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
