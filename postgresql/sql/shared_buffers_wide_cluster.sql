SELECT
  d.datname,
  pg_size_pretty(pg_database_size(d.datname)) AS database_size,
  pg_size_pretty(count(b.bufferid) * (SELECT current_setting('block_size')::int)) AS size_in_shared_buffers,
  round((100 * count(b.bufferid) / (SELECT setting FROM pg_settings WHERE name = 'shared_buffers')::decimal),2) AS pct_of_shared_buffers
FROM pg_buffercache b
JOIN pg_database d ON b.reldatabase = d.oid
WHERE b.reldatabase IS NOT NULL
GROUP BY 1 ORDER BY 4 DESC LIMIT 10;
