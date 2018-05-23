-- Check relations with risk of wraparound.
-- Look at 'to_limit', as 'to_limit' values closer to zero, as sooner wraparound will occur.

SELECT        
    c.oid::regclass AS relname,
    age(c.relfrozenxid) AS xid_age,
    to_char(2147483647 - age(c.relfrozenxid), 'FM999,999,999,990') AS to_limit,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    CASE WHEN n_live_tup > 0 THEN round(n_dead_tup * 100.0 / n_live_tup, 2) END AS "dead_tup_%",
    now() - coalesce(pg_stat_get_last_autovacuum_time(c.oid), pg_stat_get_last_vacuum_time(c.oid)) AS last_vacuumed
FROM pg_class c
LEFT JOIN pg_stat_user_tables s ON s.relid=c.oid 
WHERE c.relkind IN ('r','t','m') 
ORDER BY age(c.relfrozenxid) DESC LIMIT 20;
