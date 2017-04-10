WITH table_opts AS (
    SELECT
        c.oid, c.relname, c.relfrozenxid, c.relminmxid, n.nspname, array_to_string(c.reloptions, '') AS relopts
    FROM pg_class c
    INNER JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE c.relkind IN ('r', 't') AND n.nspname NOT IN ('pg_catalog', 'information_schema') AND n.nspname !~ '^pg_temp'
), 
vacuum_settings AS (
    SELECT
        oid, relname, nspname, relfrozenxid, relminmxid,
    CASE
        WHEN relopts LIKE '%autovacuum_vacuum_threshold%'
        THEN regexp_replace(relopts, '.*autovacuum_vacuum_threshold=([0-9.]+).*', E'\\1')::integer
        ELSE current_setting('autovacuum_vacuum_threshold')::integer
    END AS autovacuum_vacuum_threshold,
    CASE
        WHEN relopts LIKE '%autovacuum_vacuum_scale_factor%'
        THEN regexp_replace(relopts, '.*autovacuum_vacuum_scale_factor=([0-9.]+).*', E'\\1')::real
        ELSE current_setting('autovacuum_vacuum_scale_factor')::real
    END AS autovacuum_vacuum_scale_factor,
    CASE
        WHEN relopts LIKE '%autovacuum_analyze_threshold%'
        THEN regexp_replace(relopts, '.*autovacuum_analyze_threshold=([0-9.]+).*', E'\\1')::integer
        ELSE current_setting('autovacuum_analyze_threshold')::integer
    END AS autovacuum_analyze_threshold,
    CASE
        WHEN relopts LIKE '%autovacuum_analyze_scale_factor%'
        THEN regexp_replace(relopts, '.*autovacuum_analyze_scale_factor=([0-9.]+).*', E'\\1')::real
        ELSE current_setting('autovacuum_analyze_scale_factor')::real
    END AS autovacuum_analyze_scale_factor,
    CASE
        WHEN relopts LIKE '%autovacuum_freeze_max_age%'
        THEN least(regexp_replace(relopts, '.*autovacuum_freeze_max_age=([0-9.]+).*', E'\\1')::bigint,current_setting('autovacuum_freeze_max_age')::bigint)
        ELSE current_setting('autovacuum_freeze_max_age')::bigint
    END AS autovacuum_freeze_max_age,
    CASE
        WHEN relopts LIKE '%autovacuum_multixact_freeze_max_age%'
        THEN least(regexp_replace(relopts, '.*autovacuum_multixact_freeze_max_age=([0-9.]+).*', E'\\1')::bigint,current_setting('autovacuum_multixact_freeze_max_age')::bigint)
        ELSE current_setting('autovacuum_multixact_freeze_max_age')::bigint
    END AS autovacuum_multixact_freeze_max_age
    FROM table_opts
)
SELECT
    s.schemaname ||'.'|| s.relname,
    CASE
        WHEN v.autovacuum_vacuum_threshold + (v.autovacuum_vacuum_scale_factor::numeric * c.reltuples) < s.n_dead_tup
        THEN true
        ELSE false
    END AS need_vacuum,
    CASE
        WHEN v.autovacuum_analyze_threshold + (v.autovacuum_analyze_scale_factor::numeric * c.reltuples) < s.n_mod_since_analyze
        THEN true
        ELSE false
    END AS need_analyze,
    CASE
        WHEN (age(v.relfrozenxid)::bigint > v.autovacuum_freeze_max_age) OR (mxid_age(v.relminmxid)::bigint > v.autovacuum_multixact_freeze_max_age) 
        THEN true
        ELSE false
    END AS need_wraparound
--    count(*)
FROM pg_stat_user_tables s
INNER JOIN pg_class c ON s.relid = c.oid
INNER JOIN vacuum_settings v ON c.oid = v.oid
WHERE 
(v.autovacuum_vacuum_threshold + (v.autovacuum_vacuum_scale_factor::numeric * c.reltuples) < s.n_dead_tup) 
OR (v.autovacuum_analyze_threshold + (v.autovacuum_analyze_scale_factor::numeric * c.reltuples) < s.n_mod_since_analyze)
OR (age(v.relfrozenxid)::bigint > v.autovacuum_freeze_max_age) OR (mxid_age(v.relminmxid)::bigint > v.autovacuum_multixact_freeze_max_age)
--GROUP BY 1,2,3 ORDER BY 4 DESC
