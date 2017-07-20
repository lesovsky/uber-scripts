SELECT
    conname AS constraint,
    CASE
        WHEN contype = 'c' THEN 'check'
        WHEN contype = 'f' THEN 'foreign'
        WHEN contype = 'p' THEN 'primary'
        WHEN contype = 'u' THEN 'unique'
        WHEN contype = 't' THEN 'trigger'
        WHEN contype = 'x' THEN 'excliusion'
    END AS type,
    connamespace::regnamespace AS schema, conrelid::regclass AS relation,
    array(SELECT attname FROM pg_attribute WHERE attrelid = conrelid::regclass AND attnum = any(conkey)) AS attributes,
    confrelid::regclass AS foreign_realtion,
    array(SELECT attname FROM pg_attribute WHERE attrelid = confrelid::regclass AND attnum = any(confkey)) AS foreign_attributes
FROM pg_constraint;
