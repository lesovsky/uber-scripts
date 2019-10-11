-- Database structure checklist.
-- Show tables size distribution.
select 
        coalesce(t.spcname, 'pg_default') as tablespace,
        n.nspname ||'.'||c.relname as table,
        (select count(*) from pg_index i where i.indrelid=c.oid) as index_count,
        pg_size_pretty(pg_relation_size(c.oid, 'main')) as rel_main_size,
        pg_size_pretty(pg_relation_size(c.oid, 'fsm')) as rel_fsm_size,
        pg_size_pretty(pg_relation_size(c.oid, 'vm')) as rel_vm_size,
        pg_size_pretty(pg_relation_size(c.oid, 'init')) as rel_init_size,
        pg_size_pretty(pg_indexes_size(c.oid)) as indexes_size,
	pg_size_pretty(pg_relation_size(c.reltoastrelid)) as toast_size,
	pg_size_pretty(pg_total_relation_size(c.oid)) as summary_size
from pg_class c
join pg_namespace n on c.relnamespace = n.oid
left join pg_tablespace t on c.reltablespace = t.oid
where c.relkind in ('r', 'm')
order by pg_total_relation_size(c.oid) desc limit 20;
