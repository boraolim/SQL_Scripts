USE [Connect]
GO

-- Validar la existencia del proyecto viejo para sacar el máximo Id del nuevo proyecto.
SELECT t2.InsuranceCompanyId, t1.ProjectId, t2.InsuranceCompanyShortName,
       t2.InsuranceCompanyOfficialName, t1.ProjectName, t2.CountryId, t1.ProjectInitials,
       t2.Logo
  FROM Project.Project t1
 INNER JOIN PM.InsuranceCompany t2 ON (t1.InsuranceCompanyId = t2.InsuranceCompanyId)
 WHERE (t1.IsInactive = 0)
   AND (t1.ProjectId in (46, 154))
 ORDER BY t1.ProjectId DESC;
-- Para clonar del origen al nuevo, ejecutar los SP's:
-- * PM.CreateOrUpdateInsuranceCompany
-- * PM.CreateOrUpdateProject

 -- Revisar los grupos del proyecto anterior.
SELECT * FROM [Project].[Group] WHERE ProjectId IN (46, 154);
-- Para clonar del origen al nuevo, ejecutar los SP's:
-- * PM.CreateOrUpdateGroup

-- Revisar el catálogo de "Roles" y sus permisos del proyecto anterior.
SELECT * FROM [Project].[Role] WHERE (ProjectId in (46, 154));
SELECT ROW_NUMBER() over (order by cast(t1.RoleId as int) ASC, cast(t1.PermissionId as int)) [Id],
       t1.RolePermissionId,
       t1.RoleId,
       t3.RoleName,
       t1.PermissionId,
       t2.PermissionName,
       t2.[Description],
       t1.CreatedBy,
       t1.CreatedOn
  FROM [Project].[RolePermission] t1
  LEFT JOIN [Project].[Permission] t2 ON (t2.PermissionId = t1.PermissionId)
  LEFT JOIN [Project].[Role] t3 ON (t3.RoleId = t1.RoleId)
 WHERE t1.RoleId in (SELECT RoleId FROM [Project].[Role] WHERE (ProjectId in (46, 154)));
-- Para clonar del origen al nuevo, ejecutar los SP's:
-- * PM.CreateOrUpdateRole
-- NOTA: Debe insertarse manualmente en la tabla [Project].[RolePermission] los mismos permisos del rol del proyecto anterior al nuevo.

-- Revisar los permisos de usuario, grupos y roles del proyecto anterior.
-------------------------------------------------------------------------
SELECT ROW_NUMBER() OVER (order by t1.UserId asc, t1.RoleId asc) [Id],
       t1.UserId, t3.UserName, t3.FullName, t1.RoleId, t2.RoleDescription, t2.RoleName, t1.CreatedBy, t1.CreatedOn
  FROM [Account].[UserRole] t1
 INNER JOIN [Project].[Role] t2 ON (t2.RoleId = t1.RoleId)
 INNER JOIN [Account].[User] t3 ON (t3.UserId = t1.UserId)
 where t1.RoleId in ( SELECT distinct RoleId
                        FROM [Project].[RolePermission]
                       WHERE RoleId IN ( SELECT distinct RoleId FROM [Project].[Role] WHERE (ProjectId in (46, 154))) );


SELECT ROW_NUMBER() OVER (order by t1.GroupId asc, t1.UserId asc) [Id],
       t1.UserId, t2.UserName, t1.GroupId, t3.GroupName, t1.CreatedBy, t1.CreatedOn
  FROM [Account].[UserGroup] t1
 INNER JOIN [Account].[User] t2 ON (t2.UserId = t1.UserId)
 INNER JOIN [Project].[Group] t3 ON (t3.GroupId = t1.GroupId)
 where (t1.UserId in ( SELECT distinct UserId
                         FROM [Account].[UserRole]
                        where RoleId in ( SELECT RoleId
                                            FROM [Project].[RolePermission]
                                           WHERE RoleId in (SELECT RoleId
                                                              FROM [Project].[Role]
                                                             WHERE (ProjectId in (46, 154)))) ) )
   AND (t1.GroupId in ( SELECT distinct GroupId FROM [Project].[Group] WHERE ProjectId IN (46, 154) ) );

SELECT ROW_NUMBER() OVER (order by t1.UserId asc, t1.PermissionId asc) [Id],
       t1.UserPermissionId,
       t1.UserId,
       t1.ProjectId,
       t1.PermissionId,
       t3.PermissionName,
       t3.[Description],
       t1.CreatedBy,
       t1.CreatedOn
  FROM [Account].[UserPermission] t1
 INNER JOIN [Account].[User] t2 ON (t2.UserId = t1.UserId)
 INNER JOIN [Project].[Permission] t3 ON (t3.PermissionId = t1.PermissionId)
 WHERE t1.ProjectId IN (46, 154);
-- Para clonar del origen al nuevo, ejecutar los SP's:
-- * PM.AddUserRole
-- * PM.AddUserGroup

-- Revisar los Workflows del proyecto anterior.
-----------------------------------------------
SELECT * FROM [Project].[WorkFlow] where ProjectId in (46, 154);
SELECT * FROM [Project].[WorkFlowStatus] where WorkFlowId in (SELECT WorkFlowId FROM [Project].[WorkFlow] where ProjectId in (46, 154));
SELECT t1.WorkFlowId, t1.RoleId, t1.WorkFlowStatusId, t2.StatusName, t1.NextWorkFlowStatusId, t3.StatusName
  FROM [Project].[WorkFlowStep] t1
 INNER JOIN [Project].[WorkFlowStatus] t2 ON (t2.WorkFlowStatusId = t1.WorkFlowStatusId)
 INNER JOIN [Project].[WorkFlowStatus] t3 ON (t3.WorkFlowStatusId = t1.NextWorkFlowStatusId)
 where t1.WorkFlowStatusId in (SELECT WorkFlowStatusId FROM [Project].[WorkFlowStatus] where WorkFlowId in (SELECT WorkFlowId FROM [Project].[WorkFlow] where ProjectId in (46, 154)))
 ORDER BY t1.WorkFlowStepId ASC;
-- Para clonar del origen al nuevo, ejecutar los SP's:
-- * PM.CreateOrUpdateWorkFlow
-- * PM.CreateOrUpdateWorkFlowStatus
-- * PM.AddWorkFlowStep

-- Revisar los Workflows status del proyecto anterior.
------------------------------------------------------
SELECT * FROM [Project].[ConfigurationClaimStatusGroup] t1 where ProjectId in (46, 154);
SELECT t1.ConfigurationWorkFlowStatusId,
       t4.StatusGroupDisplayResourceName,
       t1.ConfigurationClaimStatusGroupId,
       t3.StatusGroupDisplayResourceName,
       t1.WorkFlowStatusId,
       t2.StatusGroupDisplayResourceName
  FROM [Project].[ConfigurationWorkFlowStatus] t1
  LEFT JOIN [Project].[ConfigurationClaimStatusGroup] t2 ON (t2.ConfigurationClaimStatusGroupId = t1.WorkFlowStatusId)
  LEFT JOIN [Project].[ConfigurationClaimStatusGroup] t3 ON (t3.ConfigurationClaimStatusGroupId = t1.ConfigurationClaimStatusGroupId)
  LEFT JOIN [Project].[ConfigurationClaimStatusGroup] t4 ON (t4.ConfigurationClaimStatusGroupId = t1.ConfigurationWorkFlowStatusId)
 WHERE (t1.WorkFlowStatusId in ( SELECT _t1.WorkFlowStatusId
                                   FROM [Project].[WorkFlowStatus] _t1
                                  WHERE (_t1.WorkFlowId IN ( SELECT WorkFlowId FROM [Project].[WorkFlow] where ProjectId in (46, 154) ))));
-- Para clonar del origen al nuevo, ejecutar los SP's:
-- * PM.CreateOrUpdateConfigurationClaimStatusGroup
-- * PM.AddConfigurationWorkFlowStatus

-- Revisar los WorkTime del proyecto anterior.
----------------------------------------------
SELECT * FROM [Project].[WorkTime] WHERE ProjectId in (46, 154);
-- Para clonar del origen al nuevo, ejecutar los SP's:
-- * PM.CreateOrUpdateWorkTime

-- Revisar los Documents del proyecto anterior.
SELECT * FROM [Project].[Document] WHERE ProjectId in (46, 154);
-- Obtener el último identificador del documento, mas uno.
-- Para clonar del origen al nuevo, ejecutar los SP's:
-- * PM.CreateOrUpdateDocuments

-- NOTA: Si hay objetos de BD relacionados al proyecto viejo, incluirlos tambien en el proyecto nuevo, como SP, funciones o vistas.