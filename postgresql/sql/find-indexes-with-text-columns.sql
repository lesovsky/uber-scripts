SELECT
    c1.relname as table, c2.relname as index, a.attname as column, t.typname as type,
    pg_size_pretty(pg_relation_size(c2.relname::text)) as i_size
FROM
    pg_class c1,
    pg_class c2,
    pg_index i,
    pg_attribute a,
    pg_type t
WHERE
    c1.oid = i.indrelid
    and c2.oid = i.indexrelid
    and a.attrelid = c1.oid
    and a.attnum = ANY(i.indkey)
    and t.oid = a.atttypid
    and c1.relkind = 'r'
    and t.typname in (select typname from pg_type where typcategory='S')    -- text columns
order by
    c1.relname,
    c2.relname;
