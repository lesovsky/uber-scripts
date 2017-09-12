-- requires pgfincore
WITH qq AS (SELECT
  c.oid,
  count(b.bufferid) * (SELECT current_setting('block_size')::int) AS size_in_shared_buffers,
  (select sum(pages_mem) * 4096 from pgfincore(c.oid::regclass)) as size_in_pagecache
FROM pg_buffercache b
INNER JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
AND b.reldatabase IN (0, (SELECT oid FROM pg_database WHERE datname = current_database()))
GROUP BY 1)
SELECT 
  pg_size_pretty(sum(distinct(qq.size_in_shared_buffers))) AS size_in_shared_buffers,
  pg_size_pretty(sum(qq.size_in_pagecache)) AS size_in_pagecache,
  pg_size_pretty(pg_database_size(current_database())) AS database_size 
FROM qq;
