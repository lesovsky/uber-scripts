-- requires pgfincore
SELECT
  c.oid, c.relname,
  pg_size_pretty(pg_relation_size(c.oid)) AS relation_size,
  pg_size_pretty(count(b.bufferid) * (SELECT current_setting('block_size')::int)) AS size_in_shared_buffers,
  round((100 * count(b.bufferid) / (SELECT setting FROM pg_settings WHERE name = 'shared_buffers')::decimal),2) AS pct_of_shared_buffers,
  pg_size_pretty((select sum(pages_mem) * 4096 from pgfincore(c.oid::regclass))) as size_in_pagecache
FROM pg_buffercache b 
INNER JOIN pg_class c ON b.relfilenode = c.relfilenode
AND b.reldatabase IN (0, (SELECT oid FROM pg_database WHERE datname = current_database()))
GROUP BY 1,2 ORDER BY 5 DESC LIMIT 10;
