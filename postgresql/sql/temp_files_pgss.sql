select
    (select datname from pg_database where oid = dbid) as database,
    (select rolname from pg_roles where oid = userid) as username,
    --queryid,
    calls,
    pg_size_pretty((temp_blks_read + temp_blks_written) * 8192) as temp_io,
    pg_size_pretty((temp_blks_written * 8192) / calls) as temp_size_avg,
    query
from pg_stat_statements p
where temp_blks_read + temp_blks_written > 0
order by (temp_blks_written / calls) desc;
