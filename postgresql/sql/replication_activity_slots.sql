SELECT
    r.slot_name,
    r.slot_type,
    r.plugin,
    r.database,
    a.usename,
    a.client_addr,
    a.wait_event_type ||'.'|| a.wait_event AS await,
    a.state,
    r.active,
    r.active_pid,
    coalesce(r.catalog_xmin,'NULL') ||'/'|| coalesce(r.xmin,'NULL') as horizon,
    greatest(age(r.catalog_xmin),age(r.xmin)) as horizon_age,
    pg_size_pretty(pg_xlog_location_diff(pg_current_xlog_location(), r.restart_lsn)) as restart_lsn_diff,
    pg_size_pretty(pg_xlog_location_diff(pg_current_xlog_location(), r.confirmed_flush_lsn)) not_received
FROM pg_replication_slots r
LEFT JOIN pg_stat_activity a ON r.active_pid = a.pid
ORDER BY horizon_age DESC;
