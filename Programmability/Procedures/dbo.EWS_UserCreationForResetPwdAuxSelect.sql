SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROC [dbo].[EWS_UserCreationForResetPwdAuxSelect]      
 @UserLoginID varchar(20) 
 ,@TimeKey INT   
 ,@strloginId varchar(20)   
AS      
     
 SET NOCOUNT ON     

DECLARE @UserRoleAlt_Key INT	
DECLARE @UserLocationCode VARCHAR(10)
DECLARE @UserLocation VARCHAR(10)

 SET @UserRoleAlt_Key=(SELECT UserRoleAlt_Key FROM dimuserinfo WHERE  (EffectiveFromTimeKey < = @TimeKey   
	   AND EffectiveToTimeKey  > = @TimeKey) and UserLoginID=@UserLoginID   )

 SET @UserLocation=(SELECT UserLocation FROM dimuserinfo WHERE    (EffectiveFromTimeKey < = @TimeKey   
	   AND EffectiveToTimeKey  > = @TimeKey) and UserLoginID=@UserLoginID )

	   print @UserLocation
	   print @UserRoleAlt_Key
IF @UserLocation<>'HI'
BEGIN
 SET @UserLocationCode=(SELECT UserLocationCode FROM dimuserinfo WHERE   (EffectiveFromTimeKey < = @TimeKey   
	   AND EffectiveToTimeKey  > = @TimeKey) and UserLoginID=@UserLoginID )
	    print @UserLocation
END

  
 IF @strloginId is NULL
	  BEGIN  
				 select ShortNameEnum as  Abbrivi,ParameterType,ParameterValue,MinValue,MaxValue from DimUserParameters WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey)
	  END
 Else
	  BEGIN
			 IF @UserRoleAlt_Key IN(1,2,3,4) --SUPER ADMIN
			 BEGIN
			     
				   SELECT UserLoginID,UserName,LoginPassword,EffectiveFromTimeKey,EffectiveToTimeKey  
				   from dimuserinfo 
				   WHERE   (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey) 
				   				   AND SuspendedUser='N'-- AND PasswordChanged<>'N' -----commited by vinayak
				  -- AND UserLoginID=@strloginId
			 END
			IF @UserRoleAlt_Key=2-- ADMIN
			 BEGIN
			   IF @UserLocation='HO'
			   BEGIN
				   SELECT UserLoginID,UserName,LoginPassword,EffectiveFromTimeKey,EffectiveToTimeKey  
				   from dimuserinfo 
				   WHERE   (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey) 
				 
				   AND UserRoleAlt_Key IN(2,3,4) 
				   AND SuspendedUser='N' AND PasswordChanged<>'N'
				  -- AND UserLoginID=@strloginId
			   END 
			 IF @UserLocation='ZO'
			   BEGIN
				   SELECT UserLoginID,UserName,LoginPassword,EffectiveFromTimeKey,EffectiveToTimeKey  ,UserLocation ,UserLocationCode 
				   from dimuserinfo 
				   WHERE   UserLocationCode=@UserLocationCode AND (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)  
				   AND UserRoleAlt_Key IN(2,3,4)
				   AND UserLocation IN('ZO','RO','BO')
				   AND SuspendedUser='N' AND PasswordChanged<>'N'
				--   AND UserLoginID=@strloginId
				  END 

			 IF @UserLocation='HI' -- AMAR 15032011
			   BEGIN
				   SELECT UserLoginID,UserName,LoginPassword,EffectiveFromTimeKey,EffectiveToTimeKey  ,UserLocation ,UserLocationCode 
				   from dimuserinfo 
				   WHERE   		   (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)  
				   AND UserRoleAlt_Key IN(2,3,4)  ---AND UserLoginID NOT IN(@UserLoginID)
				   AND UserLocation IN('HI','RI')
				   AND SuspendedUser='N' AND PasswordChanged<>'N'
				 --  AND UserLoginID=@strloginId
				  END 

			 IF @UserLocation='RI' -- AMAR 15032011
			   BEGIN
				   SELECT UserLoginID,UserName,LoginPassword,EffectiveFromTimeKey,EffectiveToTimeKey  ,UserLocation ,UserLocationCode 
				   from dimuserinfo 
				   WHERE   UserLocationCode=@UserLocationCode AND (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)  
				   AND UserRoleAlt_Key IN(2,3,4) 
				   AND UserLocation IN('RI')
				   AND SuspendedUser='N' AND PasswordChanged<>'N'
				 --  AND UserLoginID=@strloginId
				  END 

			 IF @UserLocation='RO'
			  BEGIN
				SELECT UserLoginID,UserName,LoginPassword,EffectiveFromTimeKey,EffectiveToTimeKey  ,UserLocation ,UserLocationCode 
				 from dimuserinfo 
				 WHERE  (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey) 
				 AND UserLocationCode IN(SELECT BranchCode from DimBranch INNER JOIN 
				 Dimregion ON DimBranch.BranchRegionAlt_Key=DimRegion.RegionAlt_Key where 
				 DimRegion.RegionAlt_Key=@UserLocationCode ) 
				 AND UserRoleAlt_Key IN(2,3,4)   
				 AND UserLocation IN('RO','BO')
				 AND SuspendedUser='N' AND PasswordChanged<>'N'
				-- AND UserLoginID=@strloginId
				 UNION ALL
			     
				 SELECT UserLoginID,UserName,LoginPassword,EffectiveFromTimeKey,EffectiveToTimeKey  ,UserLocation ,UserLocationCode 
				 from dimuserinfo 
				 WHERE (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey) and UserLocationCode IN(SELECT RegionAlt_Key from Dimregion  where RegionAlt_Key=@UserLocationCode ) AND UserRoleAlt_Key IN(2,3,4) 
				 AND UserRoleAlt_Key IN(2,3,4)   
						AND UserLocation IN('RO','BO')
						AND SuspendedUser='N' AND PasswordChanged<>'N'
				--		AND UserLoginID=@strloginId
			  
			  
				
				  END 
			 IF @UserLocation='BO'
			   BEGIN
				  SELECT UserLoginID,UserName,UserLocation,UserLocationCode,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRole_Key 
				 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
				 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
				 AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
				 AND UserLocationCode IN(SELECT BranchCode from DimBranch WHERE BranchCode =@UserLocationCode)
				 AND UserLocation IN('BO')
				 AND SuspendedUser='N' AND PasswordChanged<>'N'
				-- AND UserLoginID=@strloginId
				  END
			 END
		END


SET ANSI_NULLS ON
-------------------



GO