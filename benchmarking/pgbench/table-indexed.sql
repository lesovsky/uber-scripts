-- add table and indexes for pgbench inserts benchmark
CREATE TABLE pgbench_inserts_indexed (
  id serial unique not null,
  name char(10),
  price numeric,
  weight real,
  size int,
  color varchar,
  updated_at timestamp,
  built date,
  avail boolean
);
ALTER TABLE pgbench_inserts_indexed ADD PRIMARY KEY (id);
CREATE INDEX pgbench_inserts_indexed_name_idx ON pgbench_inserts_indexed (name);
CREATE INDEX pgbench_inserts_indexed_price_idx ON pgbench_inserts_indexed (price);
CREATE INDEX pgbench_inserts_indexed_weight_idx ON pgbench_inserts_indexed (weight);
CREATE INDEX pgbench_inserts_indexed_size_idx ON pgbench_inserts_indexed (size);
CREATE INDEX pgbench_inserts_indexed_color_idx ON pgbench_inserts_indexed (color);
CREATE INDEX pgbench_inserts_indexed_updated_at_idx ON pgbench_inserts_indexed (updated_at);
CREATE INDEX pgbench_inserts_indexed_built_idx ON pgbench_inserts_indexed (built);
