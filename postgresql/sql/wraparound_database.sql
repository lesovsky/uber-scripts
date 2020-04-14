SELECT        
    d.datname,
    age(d.datfrozenxid) AS xid_age,
    to_char(2147483647 - age(d.datfrozenxid), 'FM999,999,999,990') AS to_limit,
    pg_size_pretty(pg_database_size(d.oid)) AS total_size
FROM pg_database d
ORDER BY age(d.datfrozenxid) DESC;
