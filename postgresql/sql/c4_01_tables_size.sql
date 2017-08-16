-- Database structure checklist.
-- Show tables size distribution.
select 
	coalesce(t.spcname, 'pg_default') as tablespace,
	n.nspname ||'.'||c.relname as table,
	(select count(*) from pg_index i where i.indrelid=c.oid) as index_count,
	pg_size_pretty(pg_relation_size(c.oid)) as t_size,
	pg_size_pretty(pg_indexes_size(c.oid)) as i_size
from pg_class c
join pg_namespace n on c.relnamespace = n.oid
left join pg_tablespace t on c.reltablespace = t.oid
order by (pg_relation_size(c.oid),pg_indexes_size(c.oid)) desc;
