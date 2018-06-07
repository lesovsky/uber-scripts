SELECT
    slot_name,
    slot_type,
    plugin,
    database,
    active,
    active_pid,
    xmin,
    age(catalog_xmin) as xmin_horizon,
    pg_size_pretty(pg_xlog_location_diff(pg_current_xlog_location(), restart_lsn)) as restart_lsn_diff,
    pg_size_pretty(pg_xlog_location_diff(pg_current_xlog_location(), confirmed_flush_lsn)) not_received
FROM pg_replication_slots
ORDER BY xmin_horizon DESC;
