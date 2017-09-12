SELECT (clock_timestamp() - xact_start) AS xact_age,
       (clock_timestamp() - query_start) AS query_age,
       (clock_timestamp() - state_change) AS change_age,
       pid, state, datname, usename,
       coalesce(wait_event_type = 'Lock', 'f') AS waiting,
       wait_event_type ||'.'|| wait_event as wait_details,
       client_addr ||'.'|| client_port AS client,
       query
FROM pg_stat_activity
WHERE clock_timestamp() - coalesce(xact_start, query_start) > '00:00:00.1'::interval
AND pid <> pg_backend_pid() AND state <> 'idle'
ORDER BY coalesce(xact_start, query_start);
