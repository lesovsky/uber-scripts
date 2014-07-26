SELECT
  d.datname,
  pg_size_pretty(count(b.bufferid) * 8192) AS size,
  round((100 * count(b.bufferid) / (SELECT setting FROM pg_settings WHERE name = 'shared_buffers')::decimal),2) AS pct 
FROM pg_buffercache b 
JOIN pg_database d ON b.reldatabase = d.oid 
WHERE b.reldatabase IS NOT NULL
GROUP BY 1 ORDER BY 3 DESC LIMIT 10;
