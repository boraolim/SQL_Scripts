-- ==================================================
-- 2. Ambiente de Microsoft MySQL/MariaDB a Redshift.
-- ==================================================
-- Asigno la codificación a UTF-8.
SET CHARACTER SET 'UTF8';

SELECT t2.ORDINAL_POSITION                            AS "ColOrdinal",
       trim(t2.TABLE_NAME)                            AS "Tabla",
       lower(concat('t1.', trim(t2.COLUMN_NAME)))     AS "Columna",
       t2.DATA_TYPE                                   AS "Tipo",
       case when (t2.CHARACTER_MAXIMUM_LENGTH is null) then
         CONCAT(trim(t2.NUMERIC_PRECISION), ',', t2.NUMERIC_SCALE)
       else
         trim(t2.CHARACTER_MAXIMUM_LENGTH)
       end                                            AS "Tamanio",
       case when (t2.DATA_TYPE = 'decimal' OR t2.DATA_TYPE = 'double') then
              CONCAT('cast(round(cast(case when (t1.', lower(trim(t2.COLUMN_NAME)), ' is null) then 0 else t1.', lower(trim(t2.COLUMN_NAME)), ' end as decimal), 4) as decimal(25, 4)) AS "', lower(trim(t2.COLUMN_NAME)), '", ')
            when (t2.DATA_TYPE = 'float') then
              CONCAT('cast(case when (t1.', lower(trim(t2.COLUMN_NAME)), ' is null) then 0 else t1.', lower(trim(t2.COLUMN_NAME)), ' end as float) AS "', lower(trim(t2.COLUMN_NAME)), '", ')
            when (t2.DATA_TYPE = 'int' OR t2.DATA_TYPE = 'bigint' OR t2.DATA_TYPE = 'smallint' OR t2.DATA_TYPE = 'tinyint' OR t2.DATA_TYPE = 'bit') then
              CONCAT('cast(case when (t1.', lower(trim(t2.COLUMN_NAME)), ' is null) then 0 else t1.', lower(trim(t2.COLUMN_NAME)), ' end as unsigned) AS "', lower(trim(t2.COLUMN_NAME)), '", ')
            when (t2.DATA_TYPE = 'datetime' or t2.DATA_TYPE = 'date' or t2.DATA_TYPE = 'timestamp') then
              CONCAT('CONVERT(DATE_FORMAT(t1.', lower(trim(t2.COLUMN_NAME)), ', ''%Y-%m-%d %H:%i:%S''), CHAR(25)) AS "', lower(trim(t2.COLUMN_NAME)), '", ')
            when (t2.DATA_TYPE = 'nvarchar' or t2.DATA_TYPE = 'char' or t2.DATA_TYPE = 'varchar' or t2.DATA_TYPE = 'nchar' or t2.DATA_TYPE = 'tinytext') then
              CONCAT('case when(LENGTH(t1.', lower(trim(t2.COLUMN_NAME)), ') = 0 or t1.', lower(trim(t2.COLUMN_NAME)), ' is null) then ''-'' else CONVERT(trim(t1.', lower(trim(t2.COLUMN_NAME)), '), char(', t2.CHARACTER_MAXIMUM_LENGTH, ')) end AS "', lower(trim(t2.COLUMN_NAME)), '", ')
            when (t2.DATA_TYPE = 'text' or t2.DATA_TYPE = 'mediumtext' or t2.DATA_TYPE = 'longtext') then
              CONCAT('case when(LENGTH(t1.', lower(trim(t2.COLUMN_NAME)), ') = 0 or t1.', lower(trim(t2.COLUMN_NAME)), ' is null) then ''-'' else CAST(trim(t1.', lower(trim(t2.COLUMN_NAME)), ') AS varchar(', t2.CHARACTER_MAXIMUM_LENGTH, ')) end AS "', lower(trim(t2.COLUMN_NAME)), '", ')
       else
         ''
       end                                            AS "ColumnaConversionMySQL/MariaDB",
       case when (t2.DATA_TYPE = 'decimal' OR t2.DATA_TYPE = 'double') then
              CONCAT(lower(trim(t2.COLUMN_NAME)), ' numeric(25, 4) encode raw,')
            when (t2.DATA_TYPE = 'float') then
              CONCAT(lower(trim(t2.COLUMN_NAME)), ' float encode raw,')
            when (t2.DATA_TYPE = 'int') then
              CONCAT(lower(trim(t2.COLUMN_NAME)), ' int encode raw,')
            when (t2.DATA_TYPE = 'bigint') then
              CONCAT(lower(trim(t2.COLUMN_NAME)), ' bigint encode raw,')
            when (t2.DATA_TYPE = 'smallint' OR t2.DATA_TYPE = 'tinyint') then
              CONCAT(lower(trim(t2.COLUMN_NAME)), ' int encode raw,')
            when (t2.DATA_TYPE = 'bit') then
              CONCAT(lower(trim(t2.COLUMN_NAME)), ' boolean encode raw,')
            when (t2.DATA_TYPE = 'datetime' or t2.DATA_TYPE = 'date' or t2.DATA_TYPE = 'timestamp') then
              CONCAT(lower(trim(t2.COLUMN_NAME)), ' varchar(25) encode raw,')
            when (t2.DATA_TYPE = 'nvarchar' or t2.DATA_TYPE = 'char' or t2.DATA_TYPE = 'varchar' or t2.DATA_TYPE = 'nchar' or t2.DATA_TYPE = 'tinytext') then
              CONCAT(lower(trim(t2.COLUMN_NAME)), ' varchar(', (t2.CHARACTER_MAXIMUM_LENGTH + 1), ') encode raw,')
            when (t2.DATA_TYPE = 'text' or t2.DATA_TYPE = 'mediumtext' or t2.DATA_TYPE = 'longtext') then
              CONCAT(lower(trim(t2.COLUMN_NAME)), ' varchar(512) encode raw,')
       else
         ''
       end                                             AS "ColumnaConversionRedshift"
  FROM INFORMATION_SCHEMA.TABLES t1
 INNER JOIN INFORMATION_SCHEMA.COLUMNS t2 ON (t1.TABLE_SCHEMA = t2.TABLE_SCHEMA) AND (t1.TABLE_NAME = t2.TABLE_NAME)
 WHERE (t1.TABLE_NAME = 'ca_creditos')
   AND (t1.TABLE_SCHEMA = 'cartera_tape_orus_febrero');

-- =================
-- NOTAS IMPORTANTES
-- =================
-- 1. El tipo de dato "double" de MySQL/MariaDB no existe en Redshift. Se debe convertirse a decimal(25,4).
-- 2. El tipo de dato "float" de MySQL/MariaDB es el mismo en Redshift.
-- 3. Si hay campos encriptados del tipo VARCHAR o CHAR desde MySQL/MariaDB, en Redshift se tienen que desencriptar. Esto se haría por código fuente posiblemente.
-- 4. En el código fuente de la Lambda, no hay una lectura directa para los tipos de datos DATE, por lo que se tiene que ver con Miguel Imperial como cargar directamente los campos fecha para
--    que en Redshift se guarden como tal. Por el momento, se deja a VARCHAR(25).
-- 5. Los tipos de datos entero solo se convierten a BIGINT UNSIGNED (en realidad es UNSIGNED). En Redshift se tiene que ajustarse a bigint (lo siento: es MySQL y no es tan flexible como MSSQL Server).
-- 6. Tambien los booleanos se convierten a BIGINT UNSIGNED (lamentablemente).