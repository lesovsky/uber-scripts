### Zabbix Partitioning for PostgreSQL

Source [how-to](https://www.zabbix.org/wiki/Docs/howto/zabbix2_postgresql_partitioning).

### Installation notes

1. Initialize zabbix database (schema.sql -> images.sql -> data.sql). Zabbix database must be empty and without any data.
2. Open zabbix-partitioning-init.sql and set timezone in "SET TIME ZONE 'Europe/Moscow';" to your timezone.
3. Import zabbix-partitioning-init.sql with psql:
   ```
   psql -f zabbix-partitioning-init.sql -U postgres zabbix_db
   ```
4. Copy zabbix-partitioning.py into /etc/cron.daily, make it executable and reload cron service.
5. Install psycopg2.
6. Edit connection setting in zabbix-partitioning.py
7. Run init partitioning.
   ```
   /etc/cron.daily/zabbix-partitioning.py --init
   ```
8. Run manual partition creating for a next day/month.
   ```
   /etc/cron.daily/zabbix-partitioning.sql
   ```
9. Check partitioned table in "partitions" schema in zabbix database.
   ```
   psql -U zabbix zabbix_db -c "\dt+ partitions.*"
   ```
10. At the next day check that the next-day partitions created automatically by cron.
