 -- Migration202003050950_IBEROLATAM2749
 ---------------------------------------

-- Date: 2020-03-05.
-- Author: Olimpo Bonilla Ramírez (o.bonilla@controlexpert.com | obonilla).
-- Purpose: New report for Mx/La Latino Seguros/GlassCheck.
---------------------------------------------------------------------------

-- STEP 0. Declaring variables.
-------------------------------
DECLARE @CreateBy                    [RC].[Email]     = 'o.bonilla@controlexpert.com',
        @CreateOn                    [RC].[ShortDate] = CURRENT_TIMESTAMP,

        -- Report
        @ReportId                    INT              = 95,
        @ReportFile                  NVARCHAR(100)    = 'postmaster/mexico/lalatinoseguros/glasscheck/ClaimDetailsLaLatinoSegurosGlassCheck.rdlc',
        @ReportTitle                 NVARCHAR(100)    = 'REPORT_CLAIMS_TITLE',
        @ReportProduct               NVARCHAR(10)     = 'pm',
        @ReportCountry               NVARCHAR(10)     = 'mx',
        @ReportMenu                  NVARCHAR(50)     = 'pm/GLOBAL_MEXICO/La Latino Seguros/Glass Check',
        @ReportDescription           NVARCHAR(100)    = 'Returns claims details for La Latino Seguros Glass Check project',
        @ReportRoute                 NVARCHAR(50)     = 'pm/mig/claimsdetaillalatinosegurosglasscheck',
        @ReportSP                    NVARCHAR(50)     = 'RC.MxLaLatinoSegurosGlassCheckGetClaimDetailReport',
        @ReportFileName              NVARCHAR(100)    = 'PM MX La Latino Seguros Glass Check Details Report';

        -- Record tabs
DECLARE @ReportTabId                 INT              = (SELECT MAX([ReportsTabId]) + 1 FROM [RC].[ReportsTab]),
        @ReportTabTitle              NVARCHAR(254)    = 'REPORT_TRANS_TAB1';

        -- Record groups
DECLARE @ReportGroupId               INT              = ( SELECT MAX([ReportsGroupId]) + 1 FROM [RC].[ReportsGroup] ),
        @ReportsGroupTitle           NVARCHAR(100)    = 'REPORT_TRANS_GROUP1';

        -- Report filters
DECLARE @ReportFilterMaxId           INT              = ( SELECT MAX([ReportsFilterId]) FROM [RC].[ReportsFilter] ),
        @ReportFilterClaimDateFrom   NVARCHAR(100)    = 'txtClaimDateFrom',
        @ReportFilterClaimDateTo     NVARCHAR(100)    = 'txtClaimDateTo';

        -- Permissions
DECLARE @RootRoleId                  SMALLINT         = 1,
        @MexicoRoleId                SMALLINT         = ( SELECT TOP(1) [RoleId] FROM [Project].[Role] WHERE [RoleName] ='Mexico' );

-- STEP 1. Register the new report.
-----------------------------------
IF NOT EXISTS ( SELECT 1 FROM [RC].[Report] t1 WHERE (t1.[ReportId] = @ReportId) )
BEGIN
  INSERT INTO [RC].[Report] ([ReportId], [ReportTitle], [ReportProduct], [ReportCountry], [ReportMenu],
                             [ReportDescription], [ReportFile], [ReportIcon], [ReportRoute], [ReportSP],
                             [ReportRecordLimit], [ReportFileName], [Order], [IsInactive], [CreatedBy], [CreatedOn])
       VALUES (@ReportId, @ReportTitle, @ReportProduct, @ReportCountry, @ReportMenu, @ReportDescription, @ReportFile,
               'fa-eye', @ReportRoute, @ReportSP, 0, @ReportFileName, 0, 0, @CreateBy,@CreateOn);
  end;
ELSE
BEGIN
  SELECT @ReportId = t1.[ReportId]
    FROM [RC].[Report] t1
   WHERE (t1.[ReportFile] = @ReportFile);
END;

-- STEP 2. Add tabs reports.
----------------------------
IF NOT EXISTS ( SELECT 1 FROM [RC].[ReportsTab] t1 WHERE (t1.[ReportId] = @ReportId) AND (t1.[ReportsTabTitle] = @ReportTabTitle) )
BEGIN
  INSERT INTO RC.ReportsTab (ReportsTabId, ReportId, ReportsTabTitle, [Order], IsInactive, CreatedBy, CreatedOn)
       VALUES (@ReportTabId, @ReportId, @ReportTabTitle, 0, 0, @CreateBy, @CreateOn);
END;
ELSE
BEGIN
  -- Use the already existing report tab (that was already inserted before).
  SELECT @ReportTabId = t1.[ReportsTabId]
  FROM [RC].[ReportsTab] t1
  WHERE (t1.[ReportId] = @ReportId)
    AND (t1.[ReportsTabTitle] = @ReportTabTitle);
END;
----------------------------

-- STEP 3. Add new report group.
--------------------------------
IF NOT EXISTS ( SELECT 1 FROM [RC].[ReportsGroup] t1 WHERE (t1.[ReportsTabId] = @ReportTabId) AND (t1.[ReportsGroupTitle] = @ReportsGroupTitle) )
BEGIN
  -- Add Reports Group
  INSERT INTO RC.ReportsGroup (ReportsGroupId, ReportsTabId, ReportsGroupTitle, ReportsGroupDescription, [Order],
                               IsInactive, CreatedBy, CreatedOn)
       VALUES (@ReportGroupId, @ReportTabId, @ReportsGroupTitle, 'Sinister Date', 1, 0, @CreateBy, @CreateOn);
END;
ELSE
BEGIN
  -- Use the already existing report tab (that was already inserted before).
  SELECT @ReportGroupId = t1.[ReportsGroupId]
    FROM [RC].[ReportsGroup] t1
   WHERE (t1.[ReportsTabId] = @ReportTabId)
     AND (t1.[ReportsGroupTitle] = @ReportsGroupTitle);
END;
--------------------------------

-- STEP 4. Add new filters to new report.
-----------------------------------------
IF NOT EXISTS ( SELECT 1 FROM [RC].[ReportsFilter] t1 WHERE (t1.[ReportsGroupId] = @ReportGroupId) AND (t1.[ReportsFilterName] = @ReportFilterClaimDateFrom OR t1.[ReportsFilterName] = @ReportFilterClaimDateTo) )
BEGIN
  INSERT INTO [RC].ReportsFilter (ReportsFilterId, ReportsControlId, ReportsGroupId, ReportsFilterName, ReportsFilterLabel,
                                  ReportsFilterDescription, ReportsFilterDataType, ReportsFilterRegexp, ReportsFilterAttributes,
                                  ReportsFilterStyles, ReportsFilterSPName, [Order], CreatedBy, CreatedOn)
       VALUES ((@ReportFilterMaxId + 1), 5, @ReportGroupId, @ReportFilterClaimDateFrom, 'REPORT_TRANS_DATEFROM', 'Date from', 'Date',  '', '''required'':''true''', '', '',  1, @CreateBy, @CreateOn),
              ((@ReportFilterMaxId + 2), 5, @ReportGroupId, @ReportFilterClaimDateTo, 'REPORT_TRANS_DATETO', 'Date from', 'Date',  '', '''required'':''true''', '', '',  2, @CreateBy, @CreateOn);
END;
-----------------------------------------

-- STEP 5. Add new roles to new report.
---------------------------------------
IF NOT EXISTS ( SELECT 1 FROM [Account].[RoleReport] t1 WHERE (t1.[ReportId] = @ReportId) AND (t1.[RoleId] = @RootRoleId OR t1.[RoleId] = @MexicoId) )
BEGIN
  INSERT INTO Account.RoleReport (ReportId, RoleId, CreatedBy, CreatedOn)
       VALUES (@ReportId, @RootRoleId, @CreateBy, @CreateOn),
              (@ReportId, @MexicoRoleId, @CreateBy, @CreateOn);
END;
---------------------------------------

-- This is the end of SQL script.
-- Migration202003050950_IBEROLATAM2749