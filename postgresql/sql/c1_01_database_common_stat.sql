-- Database structure checklist.
-- Show databases common view 
select
  datname,
  numbackends,
  xact_commit,
  (tup_returned+tup_fetched) as reads,
  (tup_inserted+tup_updated+tup_deleted) as writes,
  pg_size_pretty(pg_database_size(datname)),
  stats_reset 
from pg_stat_database 
order by 
  pg_database_size(datname) desc;
