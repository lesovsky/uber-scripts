-- show table's dependent views (DROP VIEW -> ALTER TABLE -> CREATE VIEW)
-- don't forget edit tablename in WHERE clause
WITH RECURSIVE vlist AS (
    SELECT c.oid::REGCLASS AS view_name
      FROM pg_class c
     WHERE c.relname = 'change_me'
     UNION ALL
    SELECT DISTINCT r.ev_class::REGCLASS AS view_name
      FROM pg_depend d
      JOIN pg_rewrite r ON (r.oid = d.objid)
      JOIN vlist ON (vlist.view_name = d.refobjid)
     WHERE d.refobjsubid != 0
)
SELECT * FROM vlist;
