-- show tables with high amount of dead rows 

SELECT *,
  n_dead_tup > av_thresh AS "av_need",
  n_mod_tup > anl_thresh AS "anl_need",
  CASE WHEN reltuples > 0
    THEN round(100.0 * n_dead_tup / (reltuples))
    ELSE 0
  END AS pct_dead
FROM
  (SELECT
     N.nspname ||'.'|| C.relname AS relation,
     pg_stat_get_tuples_inserted(C.oid) AS n_tup_ins,
     pg_stat_get_tuples_updated(C.oid) AS n_tup_upd,
     pg_stat_get_tuples_deleted(C.oid) AS n_tup_del,
     pg_stat_get_live_tuples(C.oid) AS n_live_tup,
     pg_stat_get_dead_tuples(C.oid) AS n_dead_tup,
     pg_stat_get_mod_since_analyze(C.oid) AS n_mod_tup,
     C.reltuples AS reltuples,
     round(current_setting('autovacuum_vacuum_threshold')::integer + current_setting('autovacuum_vacuum_scale_factor')::numeric * C.reltuples) AS av_thresh, 
     round(current_setting('autovacuum_analyze_threshold')::integer + current_setting('autovacuum_analyze_scale_factor')::numeric * C.reltuples) AS anl_thresh, 
     date_trunc('days',now() - greatest(pg_stat_get_last_vacuum_time(C.oid),
     pg_stat_get_last_autovacuum_time(C.oid))) AS last_vacuum,
     date_trunc('days',now() - greatest(pg_stat_get_last_analyze_time(C.oid),
     pg_stat_get_last_analyze_time(C.oid))) AS last_analyze
   FROM pg_class C
   LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
   WHERE C.relkind IN ('r', 't')
   AND N.nspname NOT IN ('pg_catalog', 'information_schema')
   AND N.nspname !~ '^pg_toast'
  ) AS av
ORDER BY av_need, anl_need, n_dead_tup DESC;
