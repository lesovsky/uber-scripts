-- show cache hit ratio, values closer to 100 are better.
SELECT
  round(100 * sum(blks_hit) / sum(blks_hit + blks_read), 3) as cache_hit_ratio
FROM pg_stat_database;
