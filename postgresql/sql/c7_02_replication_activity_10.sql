SELECT  
    client_addr AS client,
    usename AS user,
    application_name AS name,
    state, sync_state AS mode,
    (pg_wal_lsn_diff(pg_current_wal_lsn(),sent_lsn) / 1024)::bigint as pending,
    (pg_wal_lsn_diff(sent_lsn,write_lsn) / 1024)::bigint as write,
    (pg_wal_lsn_diff(write_lsn,flush_lsn) / 1024)::bigint as flush,
    (pg_wal_lsn_diff(flush_lsn,replay_lsn) / 1024)::bigint as replay,
    (pg_wal_lsn_diff(pg_current_wal_lsn(),replay_lsn))::bigint / 1024 as total_lag,
    (pg_last_committed_xact()).xid::text::bigint - backend_xmin::text::bigint as xact_age,
    (pg_last_committed_xact()).timestamp - pg_xact_commit_timestamp(backend_xmin) as time_age
FROM pg_stat_replication;
