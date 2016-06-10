REATE OR REPLACE FUNCTION versions_insert_trigger()
  RETURNS TRIGGER AS $$
  DECLARE
    timeformat TEXT := '_yyyy_mm';
BEGIN
  EXECUTE 'INSERT INTO public.' || TG_TABLE_NAME || to_char(NEW.created_at,timeformat) || ' SELECT ($1).*' USING NEW;
  RETURN NULL;
EXCEPTION
  WHEN undefined_table THEN
    RAISE EXCEPTION 'trying insert into a non-existent partition: %', 'public.' || TG_TABLE_NAME || to_char(NEW.created_at,timeformat);
END;
$$
LANGUAGE plpgsql
