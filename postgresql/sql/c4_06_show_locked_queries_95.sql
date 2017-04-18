SELECT
  COALESCE(l1.relation::regclass::text,l1.locktype) as locked_item, 
  w.waiting, w.query as waiting_query,
  l1.mode as waiting_mode,
  (select now() - xact_start as waiting_xact_duration from pg_stat_activity where pid = w.pid),
  (select now() - query_start as waiting_query_duration from pg_stat_activity where pid = w.pid),
  w.pid as waiting_pid, w.usename as waiting_user, w.state as waiting_state,
  l.waiting, l.query as locking_query, l2.mode as locking_mode,
  (select now() - xact_start as locking_xact_duration from pg_stat_activity where pid = l.pid),
  (select now() - query_start as locking_query_duration from pg_stat_activity where pid = l.pid),
  l.pid as locking_pid, l.usename as locking_user, l.state as locking_state
FROM pg_stat_activity w
JOIN pg_locks l1 ON w.pid = l1.pid AND NOT l1.granted
JOIN pg_locks l2 ON (l1.transactionid = l2.transactionid AND l1.pid != l2.pid)
    OR (l1.database = l2.database AND l1.relation = l2.relation and l1.pid != l2.pid)
JOIN pg_stat_activity l ON l2.pid = l.pid
WHERE w.waiting 
ORDER BY l.query_start,w.query_start;
