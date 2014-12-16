-- remove pgbench tables
TRUNCATE TABLE pgbench_inserts_unlogged RESTART IDENTITY;
TRUNCATE TABLE pgbench_inserts_normal RESTART IDENTITY;
TRUNCATE TABLE pgbench_inserts_indexed RESTART IDENTITY;
