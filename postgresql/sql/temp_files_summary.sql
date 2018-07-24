WITH RECURSIVE
tablespace_dirs AS (
    SELECT
        dirname,
        'pg_tblspc/' || dirname || '/' AS path,
        1 AS depth
    FROM
        pg_catalog.pg_ls_dir('pg_tblspc/', true, false) AS dirname
    UNION ALL
    SELECT
        subdir,
        td.path || subdir || '/',
        td.depth + 1
    FROM
        tablespace_dirs AS td,
        pg_catalog.pg_ls_dir(td.path, true, false) AS subdir
    WHERE
        td.depth < 3
),
temp_dirs AS (
    SELECT
        td.path,
        ts.spcname AS tablespace
    FROM                                                                                                                                                                                                                        
        tablespace_dirs AS td                                                                                                                                                                                                   
        INNER JOIN pg_catalog.pg_tablespace AS ts ON (ts.oid = substring(td.path FROM 'pg_tblspc/(\d+)')::int)                                                                                                                  
    WHERE                                                                                                                                                                                                                       
        td.depth = 3                                                                                                                                                                                                            
        AND                                                                                                                                                                                                                     
        td.dirname = 'pgsql_tmp'                                                                                                                                                                                                
    UNION ALL                                                                                                                                                                                                                   
    VALUES                                                                                                                                                                                                                      
    ('base/pgsql_tmp/', 'pg_default')                                                                                                                                                                                           
),                                                                                                                                                                                                                              
temp_files AS (                                                                                                                                                                                                                 
    SELECT                                                                                                                                                                                                                      
        substring(filename FROM 'pgsql_tmp(\d+)')::int AS pid,                                                                                                                                                                  
        td.tablespace,
        pg_stat_file(td.path || '/' || filename, true) AS file_stat
    FROM
        temp_dirs AS td,
        pg_catalog.pg_ls_dir(td.path, true, false) AS filename
)
SELECT
    tablespace,
    count((file_stat).size) AS total_files,
    pg_size_pretty(sum((file_stat).size)::BIGINT) AS total_size,
    now() - min((file_stat).modification) AS oldest_modified
FROM
    temp_files
GROUP BY
    1
HAVING
    count((file_stat).size) > 0;
