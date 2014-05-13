CREATE SCHEMA partitions AUTHORIZATION zabbix;
CREATE OR REPLACE FUNCTION create_zbx_partitions(part TEXT ,part_mode TEXT, init INT DEFAULT 0 ) RETURNS VOID AS $$
DECLARE
  current_check TEXT;
  next_check TEXT;
  next_partition TEXT;
  created_partition TEXT;
  name RECORD;
  cons RECORD;
BEGIN
IF init > 0 THEN
  EXECUTE 'create table if not exists tpl_' || part || '(like ' || part || ' including defaults including storage including constraints including indexes)';
  FOR cons IN SELECT constraint_name FROM information_schema.table_constraints WHERE table_name = part AND constraint_type = 'PRIMARY KEY' LOOP
      EXECUTE 'ALTER TABLE ' || part || ' DROP CONSTRAINT IF EXISTS ' || quote_ident(cons.constraint_name) || ' CASCADE';
  END LOOP; 
  FOR name IN SELECT * FROM pg_indexes WHERE tablename = part  LOOP
      EXECUTE 'DROP INDEX ' || quote_ident(name.indexname);
  END LOOP;
END IF;
IF part_mode = 'daily' THEN
   IF init > 0 THEN
      SELECT EXTRACT(epoch FROM date_trunc('day',CURRENT_TIMESTAMP)) INTO current_check;
      SELECT EXTRACT(epoch FROM date_trunc('day',CURRENT_TIMESTAMP + INTERVAL '1 day')) INTO next_check;
      SELECT TO_CHAR(CURRENT_TIMESTAMP ,'_yyyymmdd') INTO next_partition;
   ELSE
      SELECT EXTRACT(epoch FROM date_trunc('day',CURRENT_TIMESTAMP + INTERVAL '1 day')) INTO current_check;
      SELECT EXTRACT(epoch FROM date_trunc('day',CURRENT_TIMESTAMP + INTERVAL '2 day')) INTO next_check;
      SELECT TO_CHAR(CURRENT_TIMESTAMP + INTERVAL '1 day','_yyyymmdd') INTO next_partition;
   END IF;
END IF;
IF part_mode = 'monthly' THEN
  IF init > 0 THEN
      SELECT EXTRACT(epoch FROM date_trunc('month',CURRENT_TIMESTAMP)) INTO current_check;
      SELECT EXTRACT(epoch FROM date_trunc('month',CURRENT_TIMESTAMP + INTERVAL '1 month')) INTO next_check;
      SELECT TO_CHAR(CURRENT_TIMESTAMP ,'_yyyymm') INTO next_partition;
  ELSE
      SELECT EXTRACT(epoch FROM date_trunc('month',CURRENT_TIMESTAMP + INTERVAL '1 month')) INTO current_check;
      SELECT EXTRACT(epoch FROM date_trunc('month',CURRENT_TIMESTAMP + INTERVAL '2 month')) INTO next_check;
      SELECT TO_CHAR(CURRENT_TIMESTAMP + INTERVAL '1 month','_yyyymm') INTO next_partition;
  END IF;
END IF;
created_partition:='partitions.' || part || next_partition;
EXECUTE 'create table if not exists ' || created_partition ||' (check ( clock >= ' || current_check || ' and clock < ' || next_check || '),like tpl_' || part
 || ' including defaults including storage including constraints including indexes) inherits(' || part || ')';
EXECUTE 'create table if not exists partitions.emergency_' || part || '( like ' || part || ' including defaults including storage including  constraints including indexes) inherits(' || part || ')';
END;
$$ LANGUAGE plpgsql 
SET TIME ZONE 'Europe/Moscow';
CREATE OR REPLACE FUNCTION dynamic_insert_trigger()
RETURNS TRIGGER AS $$
DECLARE
  timeformat TEXT;
  insert_sql TEXT;
 BEGIN
    IF TG_ARGV[0] = 'daily' THEN
      timeformat:='_yyyymmdd';
    ELSIF TG_ARGV[0] = 'monthly' THEN
      timeformat:='_yyyymm';
    END IF;
      EXECUTE 'INSERT INTO partitions.' || TG_TABLE_NAME || TO_CHAR(TO_TIMESTAMP(NEW.clock),timeformat) || ' SELECT ($1).*' USING NEW;    
    RETURN NULL;
 EXCEPTION
WHEN undefined_table THEN
  EXECUTE 'INSERT INTO partitions.emergency_' || TG_TABLE_NAME || ' SELECT ($1).*' USING NEW;
RETURN NULL;
END;
$$
LANGUAGE plpgsql
SET TIME ZONE 'Europe/Moscow';
CREATE TRIGGER history_trigger
      BEFORE INSERT ON history
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('daily');
CREATE TRIGGER history_sync_trigger
      BEFORE INSERT ON history_sync
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('daily');
CREATE TRIGGER history_uint_trigger
      BEFORE INSERT ON history_uint
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('daily');
CREATE TRIGGER history_uint_sync_trigger
      BEFORE INSERT ON history_uint_sync
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('daily');        
CREATE TRIGGER history_str_trigger
      BEFORE INSERT ON history_str
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('daily');      
CREATE TRIGGER history_str_sync_trigger
      BEFORE INSERT ON history_str_sync
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('daily');
CREATE TRIGGER history_log_trigger
      BEFORE INSERT ON history_log
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('daily');
CREATE TRIGGER history_text_trigger
      BEFORE INSERT ON history_text
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('daily');       
CREATE TRIGGER trends_trigger
      BEFORE INSERT ON trends
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('monthly');    
CREATE TRIGGER trends_uint_trigger
      BEFORE INSERT ON trends_uint
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('monthly');
CREATE TRIGGER acknowledges_trigger
      BEFORE INSERT ON acknowledges
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('monthly');
CREATE TRIGGER alerts_trigger
      BEFORE INSERT ON alerts
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('monthly');
CREATE TRIGGER auditlog_trigger
      BEFORE INSERT ON auditlog
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('monthly');
CREATE TRIGGER events_trigger
      BEFORE INSERT ON events
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('monthly');
CREATE TRIGGER service_alarms_trigger
      BEFORE INSERT ON service_alarms
      FOR EACH ROW EXECUTE PROCEDURE dynamic_insert_trigger('monthly');
