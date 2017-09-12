-- Database structure checklist.
-- Show databases common view 
SELECT
  datname,
  numbackends,
  xact_commit,
  (tup_returned + tup_fetched) as reads,
  (tup_inserted + tup_updated + tup_deleted) as writes,
  round(((100 * tup_inserted + tup_updated + tup_deleted) / (tup_inserted + tup_updated + tup_deleted + tup_returned + tup_fetched)::numeric),3) as write_ratio,
  pg_size_pretty(pg_database_size(datname)),
  stats_reset 
FROM pg_stat_database
WHERE (tup_inserted + tup_updated + tup_deleted + tup_returned + tup_fetched) > 0
ORDER BY pg_database_size(datname) DESC;
