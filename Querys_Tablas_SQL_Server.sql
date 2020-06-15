-- Ejemplo de un bulk insert.

BULK INSERT table_name FROM 'C:\file.csv' WITH ( FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a' );

-- Query generador de columnas para compatibilidad de Amazon Redshift Lambdas.
-- Autor: Olimpo Bonilla Ramírez.
-- Fecha: 2018-10-24.
-- Fecha de última modificación: 2019-01-21.
-- Comentarios: Tercera versión => agregado de armado de la definición de conversión de campos de MySQL/MariaDB a Redshift.

-- ===============================================
-- 1. Ambiente de Microsoft SQL Server a Redshift.
-- ===============================================
USE [Api]
GO

-- 1. Declaro variables.
DECLARE @NombreTabla varchar(255) = 'mtMerchantsAMEX';
Declare @BaseDatos varchar(255) = 'Api';
DECLARE @mtObjetos TABLE ( id bigint not null, BaseDatos varchar(255), Esquema varchar(255), Tabla varchar(255), Columna varchar(255),
                           Tipo varchar(255), Tamanio int, ColumnaConversionSQLServer varchar(max), ColumnaConversionRedshift varchar(max),
                           ColumnaCS varchar(max), ColOrdinal int primary key not null);
DECLARE @mtTablaFinal TABLE (id bigint not null, Tabla varchar(255), QuerySQLFinal text, QueryFinalAWS text);

-- 2. Inserto el query de la definición de la tabla.
INSERT INTO @mtObjetos
SELECT So.Id,
       ist.BaseDatos,
       ist.Esquema,
       ltrim(rtrim(So.name))                            AS 'Tabla',
       lower('t1.' + ltrim(rtrim(Sc.name)))             AS 'Columna',
       st.name                                          AS 'Tipo',
       sc.length                                        AS 'Tamanio',
       case when (st.name = 'decimal') then 'cast(round(cast(t1.' + lower(ltrim(rtrim(Sc.name))) + ' as money), 2, 1) as decimal(25, 4)) as ''' + lower(ltrim(rtrim(Sc.name))) + ''', '
            when (st.name = 'int') then 'cast(t1.' + lower(ltrim(rtrim(Sc.name))) + ' as int) as ''' + lower(ltrim(rtrim(Sc.name))) + ''', '
            when (st.name = 'bigint') then 'cast(t1.' + lower(ltrim(rtrim(Sc.name))) + ' as bigint) as ''' + lower(ltrim(rtrim(Sc.name))) + ''', '
            when (st.name = 'smallint') then 'cast(t1.' + lower(ltrim(rtrim(Sc.name))) + ' as int) as ''' + lower(ltrim(rtrim(Sc.name))) + ''', '
            when (st.name = 'bit') then 'case when (t1.' + lower(ltrim(rtrim(Sc.name))) + ' is null or t1.' + lower(ltrim(rtrim(Sc.name))) + ' = 0) then 0 else 1 end as ''' + lower(ltrim(rtrim(Sc.name))) + ''', '
            when (st.name = 'smalldatetime' or st.name = 'datetime' or st.name = 'date') then 'ltrim(rtrim(convert(varchar(25), t1.' + lower(ltrim(rtrim(Sc.name))) + ', 121))) as ''' + lower(ltrim(rtrim(Sc.name))) + ''', '
            when (st.name = 'nvarchar' or st.name = 'char' or st.name = 'varchar' or st.name = 'nchar') then ' ltrim(rtrim(cast( case when (len(t1.' + lower(ltrim(rtrim(Sc.name))) + ') = 0 or t1.' + lower(ltrim(rtrim(Sc.name))) + ' is null) then null else t1.' + lower(ltrim(rtrim(Sc.name))) + ' end as varchar(' + ltrim(rtrim(sc.length)) + ')))) as ''' + lower(ltrim(rtrim(Sc.name))) + ''', '
            when (st.name = 'text' or st.name = 'ntext' ) then 'ltrim(rtrim(cast(t1.' + lower(ltrim(rtrim(Sc.name))) + ' as varchar(255)))) as ''' + lower(ltrim(rtrim(Sc.name))) + ''', '
       else '' end                                      AS 'ColumnaConversionSQLSever',
       case when (st.name = 'decimal') then lower(ltrim(rtrim(Sc.name))) + ' numeric(25, 4) encode raw,'
            when (st.name = 'int') then lower(ltrim(rtrim(Sc.name))) + ' int encode raw, '
            when (st.name = 'bigint') then lower(ltrim(rtrim(Sc.name))) + ' bigint encode raw, '
            when (st.name = 'smallint') then lower(ltrim(rtrim(Sc.name))) + ' int encode raw, '
            when (st.name = 'bit') then lower(ltrim(rtrim(Sc.name))) + ' boolean encode raw, '
            when (st.name = 'smalldatetime' or st.name = 'datetime' or st.name = 'date') then lower(ltrim(rtrim(Sc.name))) + ' timestamp encode raw, '
            when (st.name = 'nvarchar' or st.name = 'char' or st.name = 'varchar' or st.name = 'nchar') then lower(ltrim(rtrim(Sc.name))) + ' varchar(' + ltrim(rtrim(sc.length + 1)) + ') encode raw, '
            when (st.name = 'text' or st.name = 'ntext' ) then lower(ltrim(rtrim(Sc.name))) + ' varchar(256) encode raw, '
       else '' end                                      AS 'ColumnaRedshift',
       case when (st.name = 'decimal') then 'public decimal ' + lower(ltrim(rtrim(Sc.name))) + ' { get; set; }'
            when (st.name = 'int') then 'public int ' + lower(ltrim(rtrim(Sc.name))) + ' { get; set; }'
            when (st.name = 'bigint') then 'public long ' + lower(ltrim(rtrim(Sc.name))) + ' { get; set; }'
            when (st.name = 'smallint') then 'public short ' + lower(ltrim(rtrim(Sc.name))) + ' { get; set; }'
            when (st.name = 'bit') then 'public bool ' + lower(ltrim(rtrim(Sc.name))) + ' { get; set; }'
            when (st.name = 'smalldatetime' or st.name = 'datetime' or st.name = 'date') then 'public DateTime ' + lower(ltrim(rtrim(Sc.name))) + ' { get; set; }'
            when (st.name = 'nvarchar' or st.name = 'char' or st.name = 'varchar' or st.name = 'nchar') then 'public string ' + lower(ltrim(rtrim(Sc.name))) + ' { get; set; }'
            when (st.name = 'text' or st.name = 'ntext' ) then 'public string ' + lower(ltrim(rtrim(Sc.name))) + ' { get; set; }'
       else '' end                                      AS 'ColumnaRedshift',
       sc.colorder                                      AS 'ColOrdinal'
  FROM sysobjects SO
 INNER JOIN syscolumns SC ON (SO.ID = SC.ID)
 INNER JOIN sys.types st ON (st.system_type_id = sc.xtype) AND (st.name != @NombreTabla) AND (st.name != 'sysname')
 INNER JOIN (
              select cast(t1.object_id as int)      as [IdObjetoDB],
                     ltrim(rtrim(t2.TABLE_CATALOG)) as [BaseDatos],
                     ltrim(rtrim(t2.TABLE_SCHEMA))  as [Esquema],
                     ltrim(rtrim(t1.name))          as [Tabla]
                from sys.tables t1
               INNER JOIN INFORMATION_SCHEMA.TABLES t2 ON (t1.name = t2.TABLE_NAME)
               WHERE (ltrim(rtrim(t1.name)) = @NombreTabla)
            ) ist ON (ist.Tabla = SO.name) and (SO.id = ist.IdObjetoDB) and (ist.BaseDatos = @BaseDatos)
 WHERE (SO.xtype = 'U')
   AND (SO.Name = @NombreTabla)
 ORDER BY SC.colorder asc;

SELECT * FROM @mtObjetos;

-- NOTAS:
-- En la definición de los campos de la vista, con respecto a su longitud, se deja la longitud del campo como lo marca SQL Server.
-- En Redshift, cuando son del tipo string, en general, se les aumenta la longitud del campo mas uno, con el fin de evitar errores en la inserción de datos en la nube.
-- Solo hay que poner el nombre de la tabla y en automatico, se trae la información de todos los campos en SQL Server.

-- Fin del script.