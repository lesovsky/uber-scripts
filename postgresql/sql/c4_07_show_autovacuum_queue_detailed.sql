-- antiwraparound vacuum determining may work incorrect (FunBox case)
WITH table_opts AS (
    SELECT
        c.oid, c.relname, c.relfrozenxid, c.relminmxid, n.nspname, array_to_string(c.reloptions, '') AS relopts
    FROM pg_class c
    INNER JOIN pg_namespace n ON c.relnamespace = n.oid
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
        -- todo: if value specified witmust get smallest from default or specified
        THEN regexp_replace(relopts, '.*autovacuum_freeze_max_age=([0-9.]+).*', E'\\1')::bigint
        ELSE current_setting('autovacuum_freeze_max_age')::bigint
    END AS autovacuum_freeze_max_age,
    CASE
        WHEN relopts LIKE '%autovacuum_multixact_freeze_max_age%'
        -- todo: if value specified witmust get smallest from default or specified
        THEN regexp_replace(relopts, '.*autovacuum_multixact_freeze_max_age=([0-9.]+).*', E'\\1')::bigint
        ELSE current_setting('autovacuum_multixact_freeze_max_age')::bigint
    END AS autovacuum_multixact_freeze_max_age
    FROM table_opts
)
SELECT
    s.schemaname ||'.'|| s.relname,
    CASE
        WHEN autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples) < s.n_dead_tup
        THEN true
        ELSE false
    END AS need_vacuum,
    CASE
        WHEN autovacuum_analyze_threshold + (autovacuum_analyze_scale_factor::numeric * pg_class.reltuples) < s.n_mod_since_analyze
        THEN true
        ELSE false
    END AS need_analyze,
    CASE
        WHEN (((txid_current() + 1 - 3) - autovacuum_freeze_max_age)::bigint > vacuum_settings.relfrozenxid::text::bigint) 
            OR ((1 - autovacuum_multixact_freeze_max_age)::bigint > vacuum_settings.relminmxid::text::bigint)
        THEN true
        ELSE false
    END AS need_wraparound
FROM pg_stat_user_tables s
INNER JOIN pg_class ON s.relid = pg_class.oid
INNER JOIN vacuum_settings ON pg_class.oid = vacuum_settings.oid
WHERE 
(autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples) < s.n_dead_tup) 
OR (autovacuum_analyze_threshold + (autovacuum_analyze_scale_factor::numeric * pg_class.reltuples) < s.n_mod_since_analyze)
OR (((txid_current() + 1 - 3) - autovacuum_freeze_max_age)::bigint > vacuum_settings.relfrozenxid::text::bigint)
OR ((1 - autovacuum_multixact_freeze_max_age)::bigint > vacuum_settings.relminmxid::text::bigint);