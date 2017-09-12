-- show shared_buffers content
SELECT
  c.relname,
  pg_size_pretty(pg_relation_size(c.oid)) as relation_size,
  pg_size_pretty(count(b.bufferid) * (SELECT current_setting('block_size')::int)) AS buffered_in_shared_buffers,
  round(100 * count(b.bufferid) * (SELECT current_setting('block_size')::int) / greatest(1,pg_relation_size(c.oid)),1) as pct_of_relation,
  round((100 * count(b.bufferid) / greatest(1,(SELECT setting FROM pg_settings WHERE name = 'shared_buffers')::decimal)),2) AS pct_of_shared_buffers
FROM pg_class c                                             
INNER JOIN pg_buffercache b ON b.relfilenode = c.relfilenode
AND b.reldatabase IN (0, (SELECT oid FROM pg_database WHERE datname = current_database()))
-- WHERE c.relname = 'products' AND usagecount >= 2 -- show how much shared_buffers are used by most used part of relation
GROUP BY c.oid, c.relname ORDER BY count(b.bufferid) * 8192 DESC LIMIT 10;
