with s AS (SELECT 
sum(total_time) AS sum_time,
sum(blk_read_time+blk_write_time) as sum_iotime,
sum(total_time-blk_read_time-blk_write_time) as sum_cputime,
sum(calls) AS sum_calls,
sum(rows) as sum_rows
FROM pg_stat_statements
)

SELECT 
'all_users@all_databases' as "user@database",
100 AS time_percent,
100 AS iotime_percent,
100 AS cputime_percent,
(sum_time/1000)*'1 second'::interval as total_time,
(sum_cputime/sum_calls)::numeric(20, 2) AS avg_cpu_time_ms,
(sum_iotime/sum_calls)::numeric(20, 2) AS avg_io_time_ms,
sum_calls as calls,
100 AS calls_percent,
sum_rows as rows,
100 as row_percent,
'all_queries' as query
FROM s

UNION ALL

SELECT
(select rolname from pg_roles where oid = p.userid) || '@' || (select datname from pg_database where oid = p.dbid) as "user@database",
(100*total_time/(SELECT sum_time FROM s))::numeric(20, 2) AS time_percent,
(100*(blk_read_time+blk_write_time)/(SELECT sum_iotime FROM s))::numeric(20, 2) AS iotime_percent,
(100*(total_time-blk_read_time-blk_write_time)/(SELECT sum_cputime FROM s))::numeric(20, 2) AS cputime_percent,
(total_time/1000)*'1 second'::interval as total_time,
((total_time-blk_read_time-blk_write_time)/calls)::numeric(20, 2) AS avg_cpu_time_ms,
((blk_read_time+blk_write_time)/calls)::numeric(20, 2) AS avg_io_time_ms,
calls,
(100*calls/(SELECT sum_calls FROM s))::numeric(20, 2) AS calls_percent,
rows,
(100*rows/(SELECT sum_rows from s))::numeric(20, 2) AS row_percent,
query
FROM pg_stat_statements p
WHERE
(total_time-blk_read_time-blk_write_time)/(SELECT sum_cputime FROM s)>=0.005

UNION ALL

SELECT
'all_users@all_databases' as "user@database",
(100*sum(total_time)/(SELECT sum_time FROM s))::numeric(20, 2) AS time_percent,
(100*sum(blk_read_time+blk_write_time)/(SELECT sum_iotime FROM s))::numeric(20, 2) AS iotime_percent,
(100*sum(total_time-blk_read_time-blk_write_time)/(SELECT sum_cputime FROM s))::numeric(20, 2) AS cputime_percent,
(sum(total_time)/1000)*'1 second'::interval,
(sum(total_time-blk_read_time-blk_write_time)/sum(calls))::numeric(10, 3) AS avg_cpu_time_ms,
(sum(blk_read_time+blk_write_time)/sum(calls))::numeric(10, 3) AS avg_io_time_ms,
sum(calls),
(100*sum(calls)/(SELECT sum_calls FROM s))::numeric(20, 2) AS calls_percent,
sum(rows),
(100*sum(rows)/(SELECT sum_rows from s))::numeric(20, 2) AS row_percent,
'other' AS query
FROM pg_stat_statements p
WHERE
(total_time-blk_read_time-blk_write_time)/(SELECT sum_cputime FROM s)<0.005

ORDER BY 4 DESC;
