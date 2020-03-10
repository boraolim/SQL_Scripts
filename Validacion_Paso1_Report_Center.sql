USE [ReportCenter]
GO

DECLARE @ReportId INT = 49;

-- Validar existencia del identificador del reporte nuevo, tomando la información del viejo reporte.
SELECT t1.*
  FROM [RC].[Report] t1
 WHERE (t1.ReportId IN (@ReportId, 95));

-- Validar la existencia del identificador de la tab para relacionarlo con el reporte nuevo.
SELECT t1.*
  FROM [RC].[ReportsTab] t1
 WHERE (t1.ReportId IN (
                         SELECT t2.ReportId
                           FROM [RC].[Report] t2
                          WHERE (t2.ReportId in (@ReportId, 95))
             ));

-- Validar la existencia del grupo de reportes para asociarlo al nuevo reporte.
SELECT t1.*
  FROM [RC].[ReportsGroup] t1
 WHERE (t1.ReportsTabId IN ( SELECT t2.ReportsTabId
                               FROM [RC].[ReportsTab] t2
                              WHERE (t2.ReportId IN ( SELECT t3.ReportId FROM [RC].[Report] t3 where (t3.ReportId IN (@ReportId, 95))))
                           ));

-- Validar la existencia del grupo de filtros asociados al nuevo reporte.
SELECT t1.*
  FROM [RC].[ReportsFilter] t1
 WHERE (t1.ReportsGroupId IN ( SELECT t2.ReportsGroupId
                                 FROM [RC].[ReportsGroup] t2
                                WHERE (t2.ReportsTabId IN ( SELECT t3.ReportsTabId
                                                              FROM [RC].[ReportsTab] t3
                                                             WHERE (t3.ReportId IN ( SELECT t4.ReportId
                                                                                       FROM [RC].[Report] t4
                                                                                      WHERE (t4.ReportId IN (@ReportId, 95))))
                             ))));

-- Asignar permisos al reporte.
-- SELECT TOP(1) [RoleId] FROM [Project].[Role] WHERE [RoleName] ='Mexico';
-- SELECT * FROM [Account].[RoleReport] t1 WHERE (t1.[ReportId] = @ReportId)
SELECT t1.*
  FROM [Account].[RoleReport] t1
 WHERE (t1.ReportId IN (@ReportId, 95))
   AND (t1.[RoleId] = 1 OR t1.[RoleId] = 5);

