SELECT
  c.relname,
  pg_size_pretty(count(b.bufferid) * 8192) AS size_in_shared_buffers,
  round((100 * count(b.bufferid) / (SELECT setting FROM pg_settings WHERE name = 'shared_buffers')::decimal),2) AS pct_of_shared_buffers
FROM pg_buffercache b
INNER JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
AND b.reldatabase IN (0, (SELECT oid FROM pg_database WHERE datname = current_database()))
GROUP BY 1 ORDER BY 3 DESC LIMIT 10;
