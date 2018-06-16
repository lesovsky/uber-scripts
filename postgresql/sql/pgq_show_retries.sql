-- show number of retries in all pgq queues
SELECT
    queue_name AS queue,
    count(*) AS events_to_retry
FROM pgq.retry_queue rq
JOIN pgq.queue q ON q.queue_id = rq.ev_queue
GROUP BY q.queue_name ORDER BY q.queue_name DESC;
