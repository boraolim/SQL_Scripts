-- Script para Microsoft SQL Server que muestra los dias festivos de México.
-- Autor: Olimpo Bonilla Ramírez.
-- Fecha: 2020-02-05.

SET LANGUAGE Spanish;
GO

DROP FUNCTION dbo.Pascua;
GO

drop function dbo.getDiasFestivosMX;
go


CREATE FUNCTION dbo.Pascua(@Yr as int) RETURNS DATETIME2 AS
BEGIN
  /*Calculate date of easter based on Year passed - adjusted from Wikipedia*/
  Declare @Cent int, @I int, @J int, @K int, @Metonic int, @EMo int, @EDay int;
  Set @Cent = @Yr / 100;
  Set @Metonic = @Yr % 19;
  Set @K = (@Cent - 17)/25;
  Set @I = (@Cent - @Cent /4 - (@Cent - @K)/ 3 + 19 * @Metonic + 15) % 30;
  Set @I = @I - (@I / 28) * (1 - (@I / 28) * ( 29 / (@I + 1)) * ((21 - @Metonic)/11));
  Set @J = (@Yr + @Yr / 4 + @I + 2 - @Cent + @Cent/ 4) % 7;
  Set @EMo = 3 + (@I - @J + 40) / 44;
  Set @EDay = @I - @J + 28 - 31 * (@EMo / 4);
  RETURN CAST(CAST(@Yr * 10000 + @Emo * 100 + @Eday AS VARCHAR(8)) AS datetime2);
END;
GO

CREATE FUNCTION dbo.getDiasFestivosMX(@Annio smallint)
RETURNS @Calendario TABLE (Fecha Date primary key, FechaString varchar(10), Day_Week int, Dia_Name varchar(25),
                           Year_Int int, Month_Int int, Month_Name varchar(25), Day_Int int,
                           DiaEntreFinSemana varchar(255), Festividad varchar(255), Festivo varchar(60), DiaHabilFeriadoCorp varchar(255))
AS
BEGIN
  DECLARE @FechaInicio date;
  DECLARE @FechaFin date;
  DECLARE @DiasFestivosCountry TABLE(Pais varchar(10), Festividad varchar(255), Festivo varchar(60), TipoFeriado varchar(255),
                                     Dia_String varchar(4), Mes int, Dia int, FlgLunes int);
  DECLARE @dim TABLE (Fecha DATE, FechaString varchar(10), Year_Int int, Month_Int int, Month_Name varchar(25), Day_Int int, Day_Week int, Day_Name varchar(25), Dia_String varchar(4), FlgIsLunes int);
  DECLARE @CalendarioTmp TABLE (Fecha Date primary key, FechaString varchar(10), Day_Week int, Dia_Name varchar(25),
                                Year_Int int, Month_Int int, Month_Name varchar(25), Day_Int int,
                                Dia_String varchar(4), IdLunes int, Pais varchar(10), DiaEntreFinSemana varchar(255),
                    Festividad varchar(255), Festivo varchar(60), TipoFeriado varchar(255), FlgLunes int);

  -- En este punto le doy valor a las fechas
  Select @FechaInicio = cast(concat('01/01/', cast(@Annio as varchar(4))) as date);
  Select @FechaFin = Dateadd(year, 1, @FechaInicio);

  INSERT INTO @DiasFestivosCountry
  SELECT 'MX', 'Dia de todos los Santos', 'Festivo NO Obligatorio', 'NoAplica', '1101', 11, 1, 0
   UNION ALL
  SELECT 'MX', 'Dia de Muertos', 'Festivo NO Obligatorio', 'NoAplica', '1102', 11, 2, 0
   UNION ALL
  SELECT 'MX', 'Aniversario de la Batalla Puebla', 'Festivo NO Obligatorio', 'NoAplica', '0505', 5, 5, 0
   UNION ALL
  SELECT 'MX', 'Aniversario de la Revolución Mexicana', 'Festivo Obligatorio', 'Pasar', '1120', 11, 20, 3
   UNION ALL
  SELECT 'MX', 'Natalicio de Benito Juarez', 'Festivo Obligatorio', 'Pasar', '0321', 3, 21, 3
   UNION ALL
  SELECT 'MX', 'Navidad', 'Festivo Obligatorio', 'Fijo', '1225', 12, 25, 0
   UNION ALL
  SELECT 'MX', 'Dia de la Raza', 'Festivo NO Obligatorio', 'NoAplica', '1012', 10, 12, 0
   UNION ALL
  SELECT 'MX', 'Dia de la Bandera', 'Festivo NO Obligatorio', 'NoAplica', '0224', 2, 24, 0
   UNION ALL
  SELECT 'MX', 'Dia de Independencia', 'Festivo Obligatorio', 'Fijo', '0916', 9, 16,  0
   UNION ALL
  SELECT 'MX', 'Dia del Trabajo', 'Festivo Obligatorio', 'Fijo', '0501', 5, 1, 0
   UNION ALL
  SELECT 'MX', 'Año Nuevo', 'Festivo Obligatorio', 'Fijo', '0101', 1, 1, 0
   UNION ALL
  SELECT 'MX', 'Día de la Virgen de Guadalupe', 'Festivo NO obligatorio', 'NoAplica', '1212', 12, 12, 0
   UNION ALL
  SELECT 'MX', 'Dia de la Madre', 'Festivo NO Obligatorio', 'NoAplica', '0510', 5, 10, 0
   UNION ALL
  SELECT 'MX', 'Aniversario de la Constitucion', 'Festivo Obligatorio', 'Pasar', '0205', 2, 5, 1;

  INSERT @dim(Fecha, FechaString, Year_Int, Month_Int, Month_Name, Day_Int, Day_Week, Day_Name, Dia_String, FlgIsLunes)
  SELECT d,
       s = year(d) * 10000 + month(d) * 100 + day(d),
       yy = year(d),
     mm = month(d),
     mnm = CAST(DATENAME(Month, d) AS VARCHAR(25)),
     dd = day(d),
     dwk = DATEPART(Weekday, d),
     dnm = DATENAME(WEEKDAY, d),
     dstr = substring(cast((year(d) * 10000 + month(d) * 100 + day(d)) as varchar(8)), 5, 4),
     InitialMonday = ROW_NUMBER() OVER (PARTITION BY YEAR(d), MONTH(d), DATEPART(Weekday, d) ORDER BY cast(d as date) ASC)
    FROM (
           SELECT d = DATEADD(DAY, rn - 1, @FechaInicio)
             FROM (
                    SELECT TOP (DATEDIFF(DAY, @FechaInicio, @FechaFin))
                           rn = ROW_NUMBER() OVER (ORDER BY s1.[object_id])
                      FROM sys.all_objects AS s1
                     CROSS JOIN sys.all_objects AS s2
                     ORDER BY s1.[object_id]
                  ) AS x
         ) AS y;

  INSERT INTO @CalendarioTmp
  Select t1.Fecha,
         t1.FechaString,
         t1.Day_Week,
         t1.Day_Name,
         t1.Year_Int,
         t1.Month_Int,
         t1.Month_Name,
         t1.Day_Int,
         t1.Dia_String,
         t1.FlgIsLunes,
         t2.Pais,
         CASE WHEN DATEPART(Weekday, t1.Fecha) IN (6,7) THEN 'FinSemana'
         ELSE 'EntreSemana' END AS [DiaEntreFinSemana],
         isnull(t2.Festividad, 'No Festivo') as [Festividad],
         t2.Festivo,
         t2.TipoFeriado,
         case when (
           case when (t1.Year_Int > 2006) then
             CASE WHEN (T1.Month_Int = 2) THEN
                    case when ((t1.Day_Week = 1 and t1.FlgIsLunes = 1) and t2.Festivo is null) then t1.FlgIsLunes
                    else t2.FlgLunes end
                  WHEN (T1.Month_Int in (3, 11)) THEN
                    case when ((t1.Day_Week = 1 and t1.FlgIsLunes = 3) and t2.Festivo is null) then t1.FlgIsLunes
                    else t2.FlgLunes end
             ELSE 0 end
           else 0 end ) = 0 then null
         else
           case when (t1.Year_Int > 2006) then
             CASE WHEN (T1.Month_Int = 2) THEN
                    case when ((t1.Day_Week = 1 and t1.FlgIsLunes = 1) and t2.Festivo is null) then t1.FlgIsLunes
                    else t2.FlgLunes end
                  WHEN (T1.Month_Int in (3, 11)) THEN
                    case when ((t1.Day_Week = 1 and t1.FlgIsLunes = 3) and t2.Festivo is null) then t1.FlgIsLunes
                    else t2.FlgLunes end
             ELSE 0 end
           else 0 end
         end
    FROM @dim t1
    LEFT JOIN @DiasFestivosCountry t2
      ON (t1.Dia_String = t2.Dia_String)
     AND (t1.Month_Int = t2.Mes)
     AND (t1.Day_Int = t2.Dia)
   ORDER BY Fecha ASC;

  update t1
     set t1.Festividad = 'Aniversario de la Constitucion',
         t1.Festivo = 'Lunes: Festivo Pasado'
    from @CalendarioTmp t1
   inner join @CalendarioTmp t2 ON (t1.FlgLunes = t2.FlgLunes)
   where (t2.TipoFeriado = 'Pasar') and (t1.Month_Int = 2) and (t1.FlgLunes is not null);

  update t1
     set t1.Festividad = 'Natalicio de Benito Juarez',
         t1.Festivo = 'Lunes: Festivo Pasado'
    from @CalendarioTmp t1
   inner join @CalendarioTmp t2 ON (t1.FlgLunes = t2.FlgLunes)
   where (t2.TipoFeriado = 'Pasar') and (t1.Month_Int = 3) and (t1.FlgLunes is not null);

   update t1
      set t1.Festividad = 'Aniversario de la Revolución Mexicana',
          t1.Festivo = 'Lunes: Festivo Pasado'
     from @CalendarioTmp t1
    inner join @CalendarioTmp t2 ON (t1.FlgLunes = t2.FlgLunes)
    where (t2.TipoFeriado = 'Pasar') and (t1.Month_Int = 11) and (t1.FlgLunes is not null);

   update @CalendarioTmp set Festivo = 'No Festivo' where Festividad = 'No Festivo';
   update @CalendarioTmp set Festivo = 'Festivo Pasado' where TipoFeriado = 'Pasar';
   update @CalendarioTmp set Festividad = 'Domingo de Pascua' where dbo.Pascua(YEAR(Fecha))= Fecha;
   update @CalendarioTmp set Festividad = case when (Dia_Name = 'Sábado') then 'Sábado de Gloria' else Dia_Name + ' Santo' end
    where Fecha between dateadd(day, -3, dbo.Pascua(YEAR(Fecha))) and dateadd(day, -1, dbo.Pascua(YEAR(Fecha)));

   INSERT INTO @Calendario
   SELECT t1.Fecha, t1.FechaString,
          t1.Day_Week, t1.Dia_Name,
          t1.Year_int, t1.Month_int,
          t1.Month_Name, t1.Day_Int,
          t1.DiaEntreFinSemana,
          t1.Festividad,
          t1.Festivo,
          CASE WHEN YEAR(t1.Fecha)<1991 THEN 'No Aplica'
               WHEN DATEPART(Weekday, t1.Fecha) IN (7) THEN 'NO Hábil'
               WHEN t1.Fecha BETWEEN DATEADD(day, -3, dbo.Pascua(YEAR(t1.Fecha))) AND dbo.Pascua(YEAR(t1.Fecha)) THEN 'NO Hábil'
               WHEN (cast(t1.FechaString as int)%10000)=1201 AND ((cast(t1.FechaString as int)/10000)-1994)%6=0 THEN 'NO Hábil'    -- Primero de Diciembre 1 de Cada 6 años
               WHEN t1.Festivo='Festivo Obligatorio' AND (t1.TipoFeriado='Fijo' or YEAR(t1.Fecha)<=2006) THEN 'NO Hábil'           -- Nueva Ley Aplica del 2006 en Adelante
               WHEN t1.Festivo='Lunes: Festivo Pasado' AND DATEPART(Weekday, t1.Fecha) =1 THEN 'NO Hábil'
               WHEN t1.Festivo='Festivo Obligatorio' AND t1.TipoFeriado='Pasar' AND YEAR(t1.Fecha)>2006 THEN 'NO Hábil'
          ELSE 'Hábil' END AS DiaHabilFeriadoCorp
     FROM @CalendarioTmp t1;
   RETURN;
END;
GO

SELECT t1.* FROM dbo.getDiasFestivosMX(2020) t1 where Festivo in ('Festivo Obligatorio', 'Lunes: Festivo Pasado')
    or (Fecha between dateadd(day, -3, dbo.Pascua(YEAR(Fecha))) and dbo.Pascua(YEAR(Fecha)));

-- Fin del script.