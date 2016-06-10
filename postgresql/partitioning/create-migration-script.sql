\pset format unaligned
\pset tuples_only true
\o /tmp/batch.migration.sql
SELECT
    format(
        'with x as (DELETE FROM ONLY versions WHERE created_at >= ''%s'' AND created_at < ''%s'' returning *) INSERT INTO versions_%s SELECT * FROM x; SELECT pg_sleep(25);',
        ts,
        ts + interval '1 day',
        to_char(ts, 'yyyy_mm')
    )
FROM
    generate_series('2015-03-01'::date, '2016-07-01', '1 day') ts;
\o
