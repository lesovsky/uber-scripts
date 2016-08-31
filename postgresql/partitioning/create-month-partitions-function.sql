CREATE OR REPLACE FUNCTION create_partitions(part TEXT , tblspace TEXT, init INT DEFAULT 0 ) RETURNS VOID AS $$
DECLARE
  current_check TIMESTAMP;
  next_check TIMESTAMP;
  next_partition TEXT;
  created_partition TEXT;
BEGIN
IF init > 0 THEN
    SELECT date_trunc('month', current_timestamp) into current_check;
    SELECT date_trunc('month',current_timestamp + interval '1 month') into next_check;
    SELECT to_char(current_timestamp ,'_yyyy_mm') into next_partition;
ELSE
    SELECT date_trunc('month',current_timestamp + interval '1 month') into current_check;
    SELECT date_trunc('month',current_timestamp + interval '2 month') into next_check;
    SELECT to_char(current_timestamp + interval '1 month','_yyyy_mm') into next_partition;
END IF;
created_partition:='public.' || part || next_partition;
EXECUTE 'create table if not exists ' || created_partition || '(check ( created_at >= ''' || current_check || ''' and created_at < ''' || next_check || '''),like ' || part || ' including all) inherits(' || part || ') tablespace ' || tblspace;
END;
$$ LANGUAGE plpgsql
