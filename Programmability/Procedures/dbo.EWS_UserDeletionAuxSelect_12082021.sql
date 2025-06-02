SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROC [dbo].[EWS_UserDeletionAuxSelect_12082021]      
  @UserLoginID varchar(20) ,
  @TimeKey INT,
  @FrmType as Char(1)      
AS 
 SET NOCOUNT ON   
---------Variable Declaration--------
IF @FrmType='D' -- for Delete screen
BEGIN 

		DECLARE @UserRoleAlt_Key INT
		DECLARE @UserLocationCode INT
		DECLARE @UserLocation VARCHAR(10)
		  ---------END--------------------------
		 --------------SET VALUE---------------
		 SET @UserRoleAlt_Key=(SELECT UserRoleAlt_Key FROM dimuserinfo WHERE    (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey) and UserLoginID=@UserLoginID)

		 SET @UserLocation=(SELECT UserLocation FROM dimuserinfo WHERE (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey) and UserLoginID=@UserLoginID)
			IF   @UserLocation='HI'
				BEGIN
					SET @UserLocationCode=0
				END
			ELSE
				BEGIN
					SET @UserLocationCode=(SELECT UserLocationCode FROM dimuserinfo WHERE (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey) and UserLoginID=@UserLoginID)
				END
		  ------------END-----------------------
		 IF @UserRoleAlt_Key=1--SUPER ADMIN
		 BEGIN
			 IF @UserLocation='HO'-- OR @UserLocation='' 
			   BEGIN
				 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,Authlevel,IsChecker,IsChecker2,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRoleAlt_Key 
				 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
				 WHERE    (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
				 AND UserLoginID <>(@UserLoginID)
			 END
		  END
		 
		IF @UserRoleAlt_Key=2 -- ADMIN
		 BEGIN
		   IF @UserLocation='HO'-- OR @UserLocation='' 
			   BEGIN
				 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,Authlevel,IsChecker,IsChecker2,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRoleAlt_Key 
				 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
				 WHERE    (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
				 AND UserLoginID <>(@UserLoginID)
				 AND dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
				 --AND UserLocationCode IN(SELECT RegionAlt_Key from   Dimregion where RegionAlt_Key=@UserLocationCode )
			 END
		   IF @UserLocation='ZO'
			   BEGIN
				 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,Authlevel,IsChecker,IsChecker2,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRoleAlt_Key 
				 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
				 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
				 AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
				 AND dimuserinfo.UserLocationCode=@UserLocationCode 
				 AND UserLoginID <>(@UserLoginID)
				  AND UserLocation IN('ZO','RO','BO')
			   END 
		  
		   IF @UserLocation='HI' --AMAR 15032011
			   BEGIN
				 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,Authlevel,IsChecker,IsChecker2,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRoleAlt_Key 
				 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
				 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
				 AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
				 --AND dimuserinfo.UserLocationCode=@UserLocationCode 
				 AND UserLoginID <>(@UserLoginID)
				  AND UserLocation IN('HI','RI')
			   END 

		   IF @UserLocation='RI'--AMAR 15032011
			   BEGIN
				 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,Authlevel,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRoleAlt_Key 
				 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
				 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
				 AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
				 AND dimuserinfo.UserLocationCode=@UserLocationCode 
				 AND UserLoginID <>(@UserLoginID)
				  AND UserLocation IN('RI')
			   END 
		  
		 IF @UserLocation='RO'
		   BEGIN
			
			
		          
			  SELECT UserLoginID,UserName,UserLocation,UserLocationCode,Authlevel,IsChecker,IsChecker2,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRoleAlt_Key 
			  from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
			  WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
			  AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
			  AND UserLocationCode IN(SELECT BranchCode from DimBranch 
			  INNER JOIN 
			  Dimregion ON DimBranch.BranchRegionAlt_Key=DimRegion.RegionAlt_Key where DimRegion.RegionAlt_Key=@UserLocationCode 
			  )
			  AND UserLoginID <>(@UserLoginID)
			   AND UserLocation IN('RO','BO')
			   UNION ALL
			     
			 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,Authlevel,IsChecker,IsChecker2,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRoleAlt_Key 
			  from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
			  WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
			  AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
			  AND UserLocationCode IN(SELECT RegionAlt_Key from   Dimregion where RegionAlt_Key=@UserLocationCode )
			  AND UserLoginID <>(@UserLoginID)
			  AND UserLocation IN('RO','BO')
		        
		  END 
		IF @UserLocation='BO'
		   BEGIN
			 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,Authlevel,IsChecker,IsChecker2,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRoleAlt_Key 
			 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
			 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
			 AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
			 AND UserLocationCode IN(SELECT BranchCode from DimBranch WHERE BranchCode =@UserLocationCode)
			 AND UserLoginID <>(@UserLoginID)
			  AND UserLocation IN('BO')
		   END
		 END
	END
ELSE IF @FrmType='U' -- For User Screen
  BEGIN
			 SELECT UserLoginID,UserName,UserLocation,UserLocationCode,Authlevel,IsChecker,IsChecker2,DimUserRole.UserRoleShortNameEnum as RoleDescription, DimUserRole.UserRoleAlt_Key 
			 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
			 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
			 ---AND UserLoginID =@UserLoginID	-- comented as discussed with amar sir on 06-11-2015 
			 --AND dimuserinfo.RecordStatus='C'			
  END

----------------


/****** Object:  StoredProcedure [dbo].[UserCreationForResetPwdF5Select]    Script Date: 08/26/2009 18:23:04 ******/
SET ANSI_NULLS ON




GO