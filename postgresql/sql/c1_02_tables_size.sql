-- Database structure checklist.
-- Show tables size distribution.
select 
  schemaname||'.'||relname as relation,
  (select count(column_name) from information_schema.columns where table_name = relname) as column_count,
  (select count(*) from pg_index where pg_index.indrelid=pg_stat_user_tables.relid) as index_count,
  pg_size_pretty(pg_relation_size(relname::regclass)) as t_size,
  pg_size_pretty(pg_indexes_size(relname::regclass)) as i_size,
  (pg_indexes_size(relname::regclass) * 100 / pg_relation_size(relname::regclass))::numeric(20,2) as i_ratio 
from pg_stat_user_tables
where
  pg_relation_size(relname::regclass) >= 1000000000 -- more or equal than 1GB

union all

select 
  'other' as relation,
  NULL as column_count,
  (select count(*) from pg_index,pg_stat_user_tables where pg_index.indrelid=pg_stat_user_tables.relid) as index_count,
  pg_size_pretty(sum(pg_relation_size(relname::regclass))) as t_size,
  pg_size_pretty(sum(pg_indexes_size(relname::regclass))) as i_size,
  (sum(pg_indexes_size(relname::regclass) * 100) / sum(pg_relation_size(relname::regclass)))::numeric(20,2) as i_ratio 
from pg_stat_user_tables
where
  pg_relation_size(relname::regclass) < 1000000000 -- less than 1GB

order by
  t_size desc
