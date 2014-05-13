#!/usr/bin/python
 
import psycopg2
from optparse import OptionParser
 
tables = {
  'history':'daily',
  'history_sync':'daily',
  'history_uint':'daily',
  'history_uint_sync':'daily',
  'history_str':'daily',
  'history_str_sync':'daily',
  'history_log':'daily',
  'history_text':'daily',
  'trends':'monthly',
  'trends_uint':'monthly',
  'acknowledges':'monthly',
  'alerts':'monthly',
  'auditlog':'monthly',
  'events':'monthly',
  'service_alarms':'monthly',
}
 
#change these settings
db_user = 'zabbix'
db_pw = 'zabbix'
db = 'zabbix'
db_host = 'localhost'
#####
 
parser = OptionParser()
parser.add_option("-i", "--init", dest="init",help="partitioning init",action="store_true", default=False)
 
(options, args) = parser.parse_args()
 
if options.init:
	init = 1
else:
        init = 0
 
db_connection = psycopg2.connect(database=db, user=db_user, password=db_pw,host=db_host)
db_cursor = db_connection.cursor()
 
for table_key, table_value in tables.iteritems():
 
	db_cursor.execute('''select create_zbx_partitions(%s,%s,%s)''',[table_key,table_value,init])
 
db_connection.commit()
db_cursor.close()
db_connection.close()
