-- Database structure checklist.
-- Show pg_catalog's largest tables.
SELECT
    relname,
    pg_size_pretty(pg_total_relation_size(relname::regclass)) AS size
FROM pg_stat_sys_tables
WHERE schemaname = 'pg_catalog'
ORDER BY pg_total_relation_size(relname::regclass) DESC LIMIT 10;
