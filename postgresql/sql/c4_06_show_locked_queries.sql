SELECT 
  w.query as waiting_query,
  (select now() - query_start as waiting_query_duration from pg_stat_activity where pid = w.pid),
  (select now() - xact_start as waiting_xact_duration from pg_stat_activity where pid = w.pid),
  w.pid as waiting_pid, w.usename as waiting_user, w.state as waiting_state,
  l.query as locking_query,
  (select now() - query_start as locking_query_duration from pg_stat_activity where pid = l.pid),
  (select now() - xact_start as locking_xact_duration from pg_stat_activity where pid = l.pid),
  l.pid as locking_pid, l.usename as locking_user, l.state as locking_state 
FROM pg_stat_activity w
JOIN pg_locks l1 ON w.pid = l1.pid AND NOT l1.granted
JOIN pg_locks l2 ON l1.transactionid = l2.transactionid AND l2.granted
JOIN pg_stat_activity l ON l2.pid = l.pid
WHERE w.waiting 
ORDER BY w.query_start;
