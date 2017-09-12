-- this very approximate evaluation about minimal required size of shared_buffers, and result may depends of when last checkpoint occurs.
SELECT
  pg_size_pretty(count(bufferid) * (SELECT current_setting('block_size')::int)) AS minimum_required_shared_buffers
FROM pg_buffercache
WHERE reldatabase IN (0, (SELECT oid FROM pg_database WHERE datname = current_database()))
AND usagecount >= 3;

-- usagecount distribution
SELECT
  usagecount,
  pg_size_pretty(count(*) * (SELECT current_setting('block_size')::int)) as size 
FROM pg_buffercache
GROUP BY usagecount ORDER BY usagecount DESC;
