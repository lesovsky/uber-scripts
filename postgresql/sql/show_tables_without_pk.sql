SELECT
    n.nspname,
    c.relname,
    pg_size_pretty(pg_table_size((n.nspname||'.'||c.relname)::regclass)) as size,
    c.relhaspkey
FROM pg_class c 
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE NOT c.relhaspkey 
AND (n.nspname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name]))
AND n.nspname !~ '^pg_toast'::text
AND (c.relkind = ANY (ARRAY['r'::"char", 't'::"char", 'm'::"char"]))
ORDER BY pg_table_size((n.nspname||'.'||c.relname)::regclass) DESC;
