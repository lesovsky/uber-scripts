-- show fetched rows ratio, values closer to 100 are better.
SELECT
    round(100 * sum(tup_fetched) / sum(tup_fetched + tup_returned), 3) as fetched_ratio
FROM pg_stat_database;
