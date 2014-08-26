-- Database structure checklist.
-- Show indexes ratio per table. Tables with a lot of indexes has lower write performance.
with cte as (
  select 
    schemaname||'.'||relname as relation,
    (select count(column_name) from information_schema.columns where table_name = relname) as column_count,
    (select count(*) from pg_index where pg_index.indrelid=pg_stat_user_tables.relid) as index_count,
    pg_size_pretty(pg_relation_size(relname::regclass)) as t_size,
    pg_size_pretty(pg_indexes_size(relname::regclass)) as i_size,
    pg_indexes_size(relname::regclass) * 100 / greatest(pg_relation_size(relname::regclass),1) as i_ratio 
  from pg_stat_user_tables where pg_relation_size(relname::regclass) >= 1000000000
)
select 
  *
from cte 
where
  cte.i_ratio > 100 
order by
  cte.i_ratio desc
limit 20;
