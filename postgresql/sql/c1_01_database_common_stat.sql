-- Database structure checklist.
-- Show databases common view 
SELECT
  datname,
  numbackends,
  xact_commit,
  (tup_returned + tup_fetched) as reads,
  (tup_inserted + tup_updated+tup_deleted) as writes,
  pg_size_pretty(pg_database_size(datname)),
  stats_reset 
FROM pg_stat_database 
ORDER BY pg_database_size(datname) DESC;
