SELECT                                                        
    CASE
        WHEN (indexdef ~'USING btree') THEN 'btree'
        WHEN (indexdef ~'USING hash') then 'hash'
        WHEN (indexdef ~'USING gin') then 'gin'
        WHEN (indexdef ~'USING gist') then 'gist'
        ELSE 'unknown'
    END AS am_type,
    count(*)
    -- indexname
FROM pg_indexes
-- WHERE indexdef ~'USING hash'
GROUP BY 1 ORDER BY 2;
