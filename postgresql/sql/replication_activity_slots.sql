SELECT
    slot_name,
    slot_type,
    plugin,
    database,
    active,
    active_pid,
    xmin,
    age(catalog_xmin) as xmin_horizon,
    pg_size_pretty(pg_xlog_location_diff(pg_current_xlog_location(), restart_lsn)) as accumulated_wal,
    pg_size_pretty(pg_xlog_location_diff(pg_current_xlog_location(), confirmed_flush_lsn)) last_confirmed_flush
FROM pg_replication_slots
ORDER BY xmin_horizon;
