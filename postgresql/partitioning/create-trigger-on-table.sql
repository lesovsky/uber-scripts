create trigger versions_insert_trigger before insert on versions for each row execute procedure versions_insert_trigger();
