#!/bin/bash

while read tablename rows;
  do
    cat > /var/lib/postgresql/tmp/$tablename-migration.sql << EOF
begin;
update $tablename r set country_id = (select country_id from tables_to_drop.country_mappings as m where lower(m.country) = lower(r.country)) where id in (select id from tables_to_drop.id_from_$tablename order by id limit 100000) returning id,country_id,country;
delete from tables_to_drop.id_from_$tablename where id in (select id from tables_to_drop.id_from_$tablename order by id limit 100000);
commit;
EOF
  count=$((rows / 100000 + 1))
  for i in `seq 1 $count`; do echo $tablename: $i/$count; psql -d appcast -f /var/lib/postgresql/tmp/$tablename-migration.sql >> /var/lib/postgresql/tmp/modified-ids-$tablename.out; sleep 10; done
  done < /var/lib/postgresql/tmp/partitions-row-count-for-update.out
