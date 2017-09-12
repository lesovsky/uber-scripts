-- shared_buffers usage sorted by usagecount (used pg_buffercache)
SELECT
  'total', pg_size_pretty(count(*) * (SELECT current_setting('block_size')::int))
FROM pg_buffercache 

UNION SELECT
  'dirty', pg_size_pretty(count(*) * (SELECT current_setting('block_size')::int))
FROM pg_buffercache 
WHERE isdirty 

UNION SELECT
  'clear', pg_size_pretty(count(*) * (SELECT current_setting('block_size')::int))
FROM pg_buffercache 
WHERE NOT isdirty 

UNION SELECT
  'used', pg_size_pretty(count(*) * (SELECT current_setting('block_size')::int))
FROM pg_buffercache 
WHERE reldatabase IS NOT NULL 
 
UNION SELECT
  'free',pg_size_pretty(count(*) * (SELECT current_setting('block_size')::int))
FROM pg_buffercache 
WHERE reldatabase IS NULL;
