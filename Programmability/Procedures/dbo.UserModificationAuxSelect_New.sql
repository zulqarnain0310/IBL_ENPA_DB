SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


--[dbo].[UserModificationAuxSelect_New] 'akshay123', 250000, 'BO', '3652'
CREATE PROCEDURE [dbo].[UserModificationAuxSelect_New] 
	@UserLoginId VARCHAR(20)
	,@UserLocationCode Varchar(10)
	,@UserLocation Varchar(2)
	,@TimeKey INT -- Nitin : 21 Dec 2010

AS
BEGIN	
	SET NOCOUNT ON;
	
		DECLARE @UserRoleAlt_Key INT
		  ---------END--------------------------
		 --------------SET VALUE---------------
		 SET @UserRoleAlt_Key=(SELECT UserRoleAlt_Key FROM dimuserinfo WHERE    (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey) and UserLoginID=@UserLoginID)
		 PRINT @UserRoleAlt_Key
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
		 IF @UserRoleAlt_Key IN(2,3,4) --SUPER ADMIN
		 BEGIN
			 IF @UserLocation='HO'-- OR @UserLocation='' 
			   BEGIN
				  SELECT DimUserInfo.UserLoginID,
					DimUserInfo.UserName,
					DimUserInfo.LoginPassword,
					DimUserInfo.UserLocation ,
					case when DimUserInfo.UserLocation = 'RO' then 'Region'
						 when  DimUserInfo.UserLocation = 'ZO' then 'Zone'
						 when  DimUserInfo.UserLocation = 'BO' then 'Branch'
						 --when  DimUserInfo.UserLocation = 'HO' then 'Bank'
						 when  DimUserInfo.UserLocation = 'HO' then 'HO'
						 when  DimUserInfo.UserLocation = 'HI' then 'HI'
						 when  DimUserInfo.UserLocation = 'RI' then 'RI'

						 End AS UserLocationName,
					ISNULL(DimUserInfo.UserLocationCode,'') as UserLocationCode,
					DimUserRole.UserRoleAlt_Key,
					DimUserRole.UserRoleShortNameEnum as RoleDescription,
					DimUserInfo.Activate,
					DimUserInfo.PasswordChanged,
					DimUserInfo.IsEmployee,
					'NOTSUSPEND' SUSPEND,
					'NOTExpiredUser' AS ExpiredUser,
					DimUserInfo.IsChecker ,DimUserInfo.IsChecker2 ,DimUserInfo.EmployeeID,Isnull(DimUserInfo.DeptGroupCode,'ALL') as DeptGroupCode,
					DimUserInfo.Email_ID,	--ad3
					DimUserInfo.MobileNo,
					DimUserInfo.DesignationAlt_Key,
					isnull( isCma,'N')isCma,
						'Y' as IsMainTable
					,DimUserInfo.ProffEntityId
					,DimUserInfo.GradeScaleAlt_Key
					,DimUserInfo.EmployeeTypeAlt_Key

				 FROM dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
				 WHERE   (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
				 AND UserLoginID <>(@UserLoginID)
			 END
		  END
		 
		IF @UserRoleAlt_Key=2 -- ADMIN
		 BEGIN
			
			print 2

		   IF @UserLocation='HO'-- OR @UserLocation='' 
			   BEGIN
				  SELECT DimUserInfo.UserLoginID,
					DimUserInfo.UserName,
					DimUserInfo.LoginPassword,
					DimUserInfo.UserLocation ,
					case when DimUserInfo.UserLocation = 'RO' then 'Region'
						 when  DimUserInfo.UserLocation = 'ZO' then 'Zone'
						 when  DimUserInfo.UserLocation = 'BO' then 'Branch'
						 --when  DimUserInfo.UserLocation = 'HO' then 'Bank'
						 when  DimUserInfo.UserLocation = 'HO' then 'HO'
						 when  DimUserInfo.UserLocation = 'HI' then 'HI'
						 when  DimUserInfo.UserLocation = 'RI' then 'RI'

						 End AS UserLocationName,
					ISNULL(DimUserInfo.UserLocationCode,'') as UserLocationCode,
					DimUserRole.UserRoleAlt_Key,
					DimUserRole.UserRoleShortNameEnum as RoleDescription,
					DimUserInfo.Activate,
					DimUserInfo.PasswordChanged,
					DimUserInfo.IsEmployee,
					'NOTSUSPEND' SUSPEND,
					'NOTExpiredUser' AS ExpiredUser,
					DimUserInfo.IsChecker ,DimUserInfo.IsChecker2,DimUserInfo.EmployeeID,Isnull(DimUserInfo.DeptGroupCode,'ALL') as DeptGroupCode,
					DimUserInfo.Email_ID,	--ad3
					DimUserInfo.MobileNo,
					DimUserInfo.DesignationAlt_Key,
					isnull( isCma,'N')isCma,
					DimUserInfo.UserType,
					DimUserInfo.CreatedBy,
					'Y' as IsMainTable
					,DimUserInfo.ProffEntityId
					,DimUserInfo.GradeScaleAlt_Key
					,DimUserInfo.EmployeeTypeAlt_Key

				 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
				 WHERE    (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
				 AND UserLoginID <>(@UserLoginID)
				 AND dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
				 --AND UserLocationCode IN(SELECT RegionAlt_Key from   Dimregion where RegionAlt_Key=@UserLocationCode )
			 END
		   IF @UserLocation='ZO'
			   BEGIN
				  SELECT DimUserInfo.UserLoginID,
					DimUserInfo.UserName,
					DimUserInfo.LoginPassword,
					DimUserInfo.UserLocation ,
					case when DimUserInfo.UserLocation = 'RO' then 'Region'
						 when  DimUserInfo.UserLocation = 'ZO' then 'Zone'
						 when  DimUserInfo.UserLocation = 'BO' then 'Branch'
						 --when  DimUserInfo.UserLocation = 'HO' then 'Bank'
						 when  DimUserInfo.UserLocation = 'HO' then 'HO'
						 when  DimUserInfo.UserLocation = 'HI' then 'HI'
						 when  DimUserInfo.UserLocation = 'RI' then 'RI'

						 End AS UserLocationName,
					ISNULL(DimUserInfo.UserLocationCode,'') as UserLocationCode,
					DimUserRole.UserRoleAlt_Key,
					DimUserRole.UserRoleShortNameEnum as RoleDescription,
					DimUserInfo.Activate,
					DimUserInfo.PasswordChanged,
					DimUserInfo.IsEmployee,
					'NOTSUSPEND' SUSPEND,
					'NOTExpiredUser' AS ExpiredUser,
					DimUserInfo.IsChecker ,DimUserInfo.IsChecker2,DimUserInfo.EmployeeID,Isnull(DimUserInfo.DeptGroupCode,'ALL') as DeptGroupCode,
					DimUserInfo.Email_ID,	--ad3
					DimUserInfo.MobileNo,
					DimUserInfo.DesignationAlt_Key,
							'Y' as IsMainTable,
					isnull( isCma,'N')isCma
					,DimUserInfo.ProffEntityId
					,DimUserInfo.GradeScaleAlt_Key
					,DimUserInfo.EmployeeTypeAlt_Key

				 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
				 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
				 AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
				 AND dimuserinfo.UserLocationCode=@UserLocationCode 
				 AND UserLoginID <>(@UserLoginID)
				  AND UserLocation IN('ZO','RO','BO')
			   END 
		  
		   IF @UserLocation='HI' --AMAR 15032011
			   BEGIN
				  SELECT DimUserInfo.UserLoginID,
					DimUserInfo.UserName,
					DimUserInfo.LoginPassword,
					DimUserInfo.UserLocation ,
					case when DimUserInfo.UserLocation = 'RO' then 'Region'
						 when  DimUserInfo.UserLocation = 'ZO' then 'Zone'
						 when  DimUserInfo.UserLocation = 'BO' then 'Branch'
						 --when  DimUserInfo.UserLocation = 'HO' then 'Bank'
						 when  DimUserInfo.UserLocation = 'HO' then 'HO'
						 when  DimUserInfo.UserLocation = 'HI' then 'HI'
						 when  DimUserInfo.UserLocation = 'RI' then 'RI'

						 End AS UserLocationName,
					ISNULL(DimUserInfo.UserLocationCode,'') as UserLocationCode,
					DimUserRole.UserRoleAlt_Key,
					DimUserRole.UserRoleShortNameEnum as RoleDescription,
					DimUserInfo.Activate,
					DimUserInfo.PasswordChanged,
					DimUserInfo.IsEmployee,
					'NOTSUSPEND' SUSPEND,
					'NOTExpiredUser' AS ExpiredUser,
					DimUserInfo.IsChecker ,DimUserInfo.IsChecker2,DimUserInfo.EmployeeID,Isnull(DimUserInfo.DeptGroupCode,'ALL') as DeptGroupCode,
					DimUserInfo.Email_ID,	--ad3
					DimUserInfo.MobileNo,
					DimUserInfo.DesignationAlt_Key,
					isnull( isCma,'N')isCma
					,DimUserInfo.ProffEntityId
					,DimUserInfo.GradeScaleAlt_Key
					,DimUserInfo.EmployeeTypeAlt_Key

					from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
				 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
				 AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
				 --AND dimuserinfo.UserLocationCode=@UserLocationCode 
				 AND UserLoginID <>(@UserLoginID)
				  AND UserLocation IN('HI','RI')
			   END 

		   IF @UserLocation='RI'--AMAR 15032011
			   BEGIN

			    print 'RI'
				  SELECT DimUserInfo.UserLoginID,
					DimUserInfo.UserName,
					DimUserInfo.LoginPassword,
					DimUserInfo.UserLocation ,
					case when DimUserInfo.UserLocation = 'RO' then 'Region'
						 when  DimUserInfo.UserLocation = 'ZO' then 'Zone'
						 when  DimUserInfo.UserLocation = 'BO' then 'Branch'
						 --when  DimUserInfo.UserLocation = 'HO' then 'Bank'
						 when  DimUserInfo.UserLocation = 'HO' then 'HO'
						 when  DimUserInfo.UserLocation = 'HI' then 'HI'
						 when  DimUserInfo.UserLocation = 'RI' then 'RI'

						 End AS UserLocationName,
					ISNULL(DimUserInfo.UserLocationCode,'') as UserLocationCode,
					DimUserRole.UserRoleAlt_Key,
					DimUserRole.UserRoleShortNameEnum as RoleDescription,
					DimUserInfo.Activate,
					DimUserInfo.PasswordChanged,
					DimUserInfo.IsEmployee,
					'NOTSUSPEND' SUSPEND,
					'NOTExpiredUser' AS ExpiredUser,
					DimUserInfo.IsChecker ,DimUserInfo.IsChecker2,DimUserInfo.EmployeeID,Isnull(DimUserInfo.DeptGroupCode,'ALL') as DeptGroupCode,
					DimUserInfo.Email_ID,	--ad3
					DimUserInfo.MobileNo,
					DimUserInfo.DesignationAlt_Key,
							'Y' as IsMainTable,
					isnull( isCma,'N')isCma
					,DimUserInfo.ProffEntityId
					,DimUserInfo.GradeScaleAlt_Key
					,DimUserInfo.EmployeeTypeAlt_Key

					from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
				 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
				 AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
				 AND dimuserinfo.UserLocationCode=@UserLocationCode 
				 AND UserLoginID <>(@UserLoginID)
				  AND UserLocation IN('RI')
			   END 
		  
		 IF @UserLocation='RO'
		   BEGIN
			
			 print 'RO'
		          
				  SELECT DimUserInfo.UserLoginID,
					DimUserInfo.UserName,
					DimUserInfo.LoginPassword,
					DimUserInfo.UserLocation ,
					case when DimUserInfo.UserLocation = 'RO' then 'Region'
						 when  DimUserInfo.UserLocation = 'ZO' then 'Zone'
						 when  DimUserInfo.UserLocation = 'BO' then 'Branch'
						 --when  DimUserInfo.UserLocation = 'HO' then 'Bank'
						 when  DimUserInfo.UserLocation = 'HO' then 'HO'
						 when  DimUserInfo.UserLocation = 'HI' then 'HI'
						 when  DimUserInfo.UserLocation = 'RI' then 'RI'

						 End AS UserLocationName,
					ISNULL(DimUserInfo.UserLocationCode,'') as UserLocationCode,
					DimUserRole.UserRoleAlt_Key,
					DimUserRole.UserRoleShortNameEnum as RoleDescription,
					DimUserInfo.Activate,
					DimUserInfo.PasswordChanged,
					DimUserInfo.IsEmployee,
					'NOTSUSPEND' SUSPEND,
							'Y' as IsMainTable,
					'NOTExpiredUser' AS ExpiredUser,
					DimUserInfo.IsChecker ,DimUserInfo.IsChecker2 ,DimUserInfo.EmployeeID,Isnull(DimUserInfo.DeptGroupCode,'ALL') as DeptGroupCode,
					DimUserInfo.Email_ID,	--ad3
					DimUserInfo.MobileNo,
					DimUserInfo.DesignationAlt_Key,
					isnull( isCma,'N')isCma
					,DimUserInfo.ProffEntityId
					,DimUserInfo.GradeScaleAlt_Key
					,DimUserInfo.EmployeeTypeAlt_Key

				from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
			  WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
			  AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
			  AND UserLocationCode IN(SELECT BranchCode from DimBranch 
			  INNER JOIN 
			  Dimregion ON DimBranch.BranchRegionAlt_Key=DimRegion.RegionAlt_Key where DimRegion.RegionAlt_Key=@UserLocationCode 
			  )
			  AND UserLoginID <>(@UserLoginID)
			   AND UserLocation IN('RO','BO')
			   UNION 
			     
			 SELECT 
					 DimUserInfo.UserLoginID,
					DimUserInfo.UserName,
					DimUserInfo.LoginPassword,
					DimUserInfo.UserLocation ,
					case when DimUserInfo.UserLocation = 'RO' then 'Region'
						 when  DimUserInfo.UserLocation = 'ZO' then 'Zone'
						 when  DimUserInfo.UserLocation = 'BO' then 'Branch'
						 --when  DimUserInfo.UserLocation = 'HO' then 'Bank'
						 when  DimUserInfo.UserLocation = 'HO' then 'HO'
						 when  DimUserInfo.UserLocation = 'HI' then 'HI'
						 when  DimUserInfo.UserLocation = 'RI' then 'RI'

						 End AS UserLocationName,
					ISNULL(DimUserInfo.UserLocationCode,'') as UserLocationCode,
					DimUserRole.UserRoleAlt_Key,
					DimUserRole.UserRoleShortNameEnum as RoleDescription,
					DimUserInfo.Activate,
					DimUserInfo.PasswordChanged,
					DimUserInfo.IsEmployee,
					'NOTSUSPEND' SUSPEND,
					'NOTExpiredUser' AS ExpiredUser,
					DimUserInfo.IsChecker ,DimUserInfo.IsChecker2,DimUserInfo.EmployeeID,Isnull(DimUserInfo.DeptGroupCode,'ALL') as DeptGroupCode,
					DimUserInfo.Email_ID,	--ad3
					DimUserInfo.MobileNo,
							'Y' as IsMainTable,
					DimUserInfo.DesignationAlt_Key,
					isnull( isCma,'N')isCma
					,DimUserInfo.ProffEntityId
					,DimUserInfo.GradeScaleAlt_Key
					,DimUserInfo.EmployeeTypeAlt_Key

			  from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
			  WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
			  AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
			  AND UserLocationCode IN(SELECT RegionAlt_Key from   Dimregion where RegionAlt_Key=@UserLocationCode )
			  AND UserLoginID <>(@UserLoginID)
			  AND UserLocation IN('RO','BO')
		        
		  END 
		IF @UserLocation='BO'
		   BEGIN
		   print 'BO'
			 	SELECT DimUserInfo.UserLoginID,
					DimUserInfo.UserName,
					DimUserInfo.LoginPassword,
					DimUserInfo.UserLocation ,
					case when DimUserInfo.UserLocation = 'RO' then 'Region'
						 when  DimUserInfo.UserLocation = 'ZO' then 'Zone'
						 when  DimUserInfo.UserLocation = 'BO' then 'Branch'
						 --when  DimUserInfo.UserLocation = 'HO' then 'Bank'
						 when  DimUserInfo.UserLocation = 'HO' then 'HO'
						 when  DimUserInfo.UserLocation = 'HI' then 'HI'
						 when  DimUserInfo.UserLocation = 'RI' then 'RI'

						 End AS UserLocationName,
					ISNULL(DimUserInfo.UserLocationCode,'') as UserLocationCode,
					DimUserRole.UserRoleAlt_Key,
					DimUserRole.UserRoleShortNameEnum as RoleDescription,
					DimUserInfo.Activate,
					DimUserInfo.PasswordChanged,
					DimUserInfo.IsEmployee,
					'NOTSUSPEND' SUSPEND,
					'NOTExpiredUser' AS ExpiredUser,
					DimUserInfo.IsChecker ,DimUserInfo.IsChecker2,DimUserInfo.EmployeeID,Isnull(DimUserInfo.DeptGroupCode,'ALL') as DeptGroupCode,
					DimUserInfo.Email_ID,	--ad3
					DimUserInfo.MobileNo,
						'Y' as IsMainTable,
					DimUserInfo.DesignationAlt_Key,
					isnull( isCma,'N')isCma
					,DimUserInfo.ProffEntityId
					,DimUserInfo.GradeScaleAlt_Key
					,DimUserInfo.EmployeeTypeAlt_Key

			 from dimuserinfo INNER JOIN DimUserRole ON dimuserinfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
			 WHERE (dimuserinfo.EffectiveFromTimeKey < = @TimeKey AND dimuserinfo.EffectiveToTimeKey  > = @TimeKey)
			 AND  dimuserinfo.UserRoleAlt_Key IN(2,3,4) 
			 AND UserLocationCode IN(SELECT BranchCode from DimBranch WHERE BranchCode =@UserLocationCode)
			 AND UserLoginID <>(@UserLoginID)
			  AND UserLocation IN('BO')
		   END
		 END
	END





GO