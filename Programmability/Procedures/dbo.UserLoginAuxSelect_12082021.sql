SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



CREATE PROC [dbo].[UserLoginAuxSelect_12082021]      
  @UserLoginID varchar(20) ,
  @TimeKey INT      
AS 
 SET NOCOUNT ON   
---------Variable Declaration--------

DECLARE @UserRole_Key INT
DECLARE @UserLocationCode varchar(10)
DECLARE @UserLocation VARCHAR(10)
PRINT 'Amol'
  ---------END--------------------------
 --------------SET VALUE---------------
 SET @UserRole_Key=(SELECT UserRoleAlt_Key FROM dimuserinfo 
						WHERE UserLoginID=@UserLoginID  
                     AND (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey))
					 PRINT 'Amol1'
 SET @UserLocation=(SELECT UserLocation FROM dimuserinfo 
						WHERE UserLoginID=@UserLoginID 
					AND (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey))
					PRINT 'Amol2'
					print @UserLocation
					print @UserRole_Key
 IF @UserLocation<>'HI'
	BEGIN
	SET @UserLocationCode=(SELECT UserLocationCode FROM dimuserinfo WHERE UserLoginID=@UserLoginID AND (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey))
 END 
  ------------END-----------------------
 IF @UserRole_Key=1--SUPER ADMIN
 BEGIN
       IF @UserLocation='HO'-- OR @UserLocation='' 
	   BEGIN
		 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRole_Key 
		 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
		 WHERE    (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
		 and UserLogged=1
		 AND UserLoginID <>(@UserLoginID)
		 --AND SuspendedUser='Y'

	  END
   END
IF @UserRole_Key IN (2,3,4)-- ADMIN
 BEGIN
   IF  @UserLocation='HO' 
	   BEGIN
		 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRole_Key 
		 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
		 WHERE    (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
		 and UserLogged=1
		 AND UserLoginID <>(@UserLoginID)
		-- AND SuspendedUser='Y'
		 --AND  dimuserinfo.UserRole_Key IN(2,3,4) 
		 and DimUserRole.UserRoleShortNameEnum in ('ADMIN','OPERATOR','VIEWER')
		  
	 END
  IF @UserLocation='ZO'
	   BEGIN
		 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRole_Key 
		 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
		 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
		 AND DimUserRole.UserRoleShortNameEnum in ('ADMIN','OPERATOR','VIEWER')  --dimuserinfo.UserRole_Key IN(2,3,4) 
		 AND dimuserinfo.UserLocationCode=@UserLocationCode 
		 AND UserLoginID <>(@UserLoginID)
		 AND SuspendedUser='Y'
		  AND UserLocation IN('ZO','RO','BO')
       END 
  
   IF @UserLocation='HI'
	   BEGIN
		 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRole_Key 
		 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
		 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
		 AND  DimUserRole.UserRoleShortNameEnum in ('ADMIN','OPERATOR','VIEWER')
		 --AND dimuserinfo.UserLocationCode=@UserLocationCode 
		 AND UserLoginID <>(@UserLoginID)
		 AND SuspendedUser='Y'
		  AND UserLocation IN('HI','RI')
       END 
  IF @UserLocation='RI'
	   BEGIN
		 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRole_Key 
		 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
		 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
		 AND  DimUserRole.UserRoleShortNameEnum in ('ADMIN','OPERATOR','VIEWER')
		 AND dimuserinfo.UserLocationCode=@UserLocationCode 
		 AND UserLoginID <>(@UserLoginID)
		 AND SuspendedUser='Y'
		  AND UserLocation IN('RI')
       END 
IF @UserLocation='RO'
   BEGIN
   
          
      SELECT UserLoginID,UserName,UserLocation,UserLocationCode,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRole_Key 
      from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
      WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
      AND  DimUserRole.UserRoleShortNameEnum in ('ADMIN','OPERATOR','VIEWER')
      AND UserLocationCode IN(SELECT BranchCode from DimBranch INNER JOIN   Dimregion ON DimBranch.BranchRegionAlt_Key=DimRegion.RegionAlt_Key
      where DimRegion.RegionAlt_Key=@UserLocationCode )AND UserLoginID <>(@UserLoginID)
        AND UserLocation IN('RO','BO')
      UNION ALL
	     
	  SELECT UserLoginID,UserName,UserLocation,UserLocationCode,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRole_Key 
      from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
      WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
      AND  DimUserRole.UserRoleShortNameEnum in ('ADMIN','OPERATOR','VIEWER')
      AND UserLocationCode IN(SELECT RegionAlt_Key from   Dimregion where RegionAlt_Key=@UserLocationCode )
      AND UserLoginID <>(@UserLoginID)
      AND SuspendedUser='Y'  
      AND UserLocation IN('RO','BO')
  END 
IF @UserLocation='BO'
   BEGIN
     SELECT UserLoginID,UserName,UserLocation,UserLocationCode,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRole_Key 
     from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
     WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
     AND  DimUserRole.UserRoleShortNameEnum in ('ADMIN','OPERATOR','VIEWER')
     AND UserLocationCode IN(SELECT BranchCode from DimBranch WHERE BranchCode =@UserLocationCode)
     AND UserLoginID <>(@UserLoginID)
     AND SuspendedUser='Y'
     AND UserLocation IN('BO')
   END
 END






GO