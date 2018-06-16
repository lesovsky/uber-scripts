-- show pgq queues with highest lag
SELECT
    queue_name,
    max(lag) lag,
    max(last_seen) last_seen,
    sum(pending_events) pending_events
FROM pgq.get_consumer_info()
WHERE pending_events > 0
GROUP BY queue_name ORDER BY lag DESC NULLS LAST LIMIT 10;
