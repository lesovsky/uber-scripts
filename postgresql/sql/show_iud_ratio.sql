with s as (
    select
        sum(tup_inserted) as sum_i,
        sum(tup_updated) as sum_u,
        sum(tup_deleted) as sum_d,
        sum(tup_inserted)+sum(tup_updated)+sum(tup_deleted) as total,
	min(stats_reset) as reset
    from pg_stat_database
    -- where datname ~* ''
)
select
    total,
    100 * sum_i::bigint / total as inserts_ratio,
    100 * sum_u::bigint / total as updates_ratio,
    100 * sum_d::bigint / total as deletes_ratio,
    now() - reset as stats_age
from s;
