-- create function which show stand-by servers and their lag in bytes.
CREATE OR REPLACE FUNCTION streaming_slave_check() RETURNS TABLE (client_hostname text, client_addr inet, byte_lag float)
LANGUAGE SQL SECURITY DEFINER
AS $$
    SELECT
        client_hostname,
        client_addr,
        sent_offset - (replay_offset - (sent_xlog - replay_xlog) * 255 * 16 ^ 6 ) AS byte_lag
    FROM (
        SELECT
            client_hostname,
            client_addr,
            ('x' || lpad(split_part(sent_location,   '/', 1), 8, '0'))::bit(32)::bigint AS sent_xlog,
            ('x' || lpad(split_part(replay_location, '/', 1), 8, '0'))::bit(32)::bigint AS replay_xlog,
            ('x' || lpad(split_part(sent_location,   '/', 2), 8, '0'))::bit(32)::bigint AS sent_offset,
            ('x' || lpad(split_part(replay_location, '/', 2), 8, '0'))::bit(32)::bigint AS replay_offset
        FROM pg_stat_replication
    ) AS s; 
$$;
