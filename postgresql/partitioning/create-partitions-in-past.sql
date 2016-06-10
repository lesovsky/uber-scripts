do $$
declare
    i text;
    created_at_min timestamp;
    created_at_max timestamp;
begin
    for i in select to_char(ts, 'yyyy_mm') from generate_series('2015-03-01'::date, '2016-07-01', '1 month') as ts
    loop
        select to_timestamp(i, 'yyyy-mm-dd') into strict created_at_min;
        select to_timestamp(i, 'yyyy-mm-dd') + interval '1 month' into created_at_max;
        execute format('CREATE TABLE versions_%s ( like versions including all ) tablespace jobs', i );
        execute format('ALTER TABLE versions_%s inherit versions', i);
        execute format('ALTER TABLE versions_%s add constraint versions_insert_trigger check ( created_at >= ''%s'' AND created_at < ''%s'' )', i, created_at_min, created_at_max );
    end loop;
end;
$$;
