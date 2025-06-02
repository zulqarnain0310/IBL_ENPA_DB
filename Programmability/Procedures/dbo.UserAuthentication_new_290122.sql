SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

--With AD(Active Directory)
--exec UserAuthentication_new_AD @UserLoginID=N'dm410',@LoginPassword=N'6LAsLs52DsD7qxYRKAyYe8i32VQ=',@authType=N'AD'
--go

--exec UserAuthentication_new @UserLoginID=N'dm410',@LoginPassword=N'6LAsLs52DsD7qxYRKAyYe8i32VQ=',@authType=N'DB'
--go

create PROCEDURE [dbo].[UserAuthentication_new_290122] 
	(
	@UserLoginID varchar(20),
	@LoginPassword varchar(100),
	@authType char(2)='DB'
	)
AS 

--declare 
--	@UserLoginID varchar(20)='IBLFM8840',
--	@LoginPassword varchar(100)='DX2TCsOxMiyKEUL5siFp1O756FU=',
--	@authType char(2)='AD'


		Declare @TimeKey INT
		DECLARE @NONUSE AS SMALLINT
		DECLARE @LoginDate AS SMALLDATETIME
		DECLARE @Suspended AS INT     ------ ARITHMATIC  OVER COMMING WHEN @LOGIN DATE IS NULL THE ITS TAKES DEFAULT DATE		
		DECLARE @PwdChangeDate AS SMALLDATETIME
		DECLARE @PWDCHNG AS SMALLINT
		DECLARE @ExpiredUserDay AS SMALLINT
	    DECLARE @DateCreated AS SMALLDATETIME
		DECLARE @SuspendedUser AS char(1)='N'
		DECLARE @UserLogged AS bit=0

 	  IF OBJECT_ID('Tempdb..#tmpUserInfo')	IS NOT NULL
		BEGIN
			DROP TABLE #tmpUserInfo
		END   
	   
BEGIN
	   --  SET @TimeKey =(SELECT  TimeKey  FROM    SysDataMatrix_New WHERE  CurrentStatus = 'C' )
	   print 01
	   SET @TimeKey=(SELECT TimeKey FROM SysDayMatrix WHERE CAST(Date AS DATE)=CAST(GETDATE() AS DATE))
		SET @NONUSE=(SELECT ParameterValue FROM  DimUserParameters
			WHERE (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey)
				  AND ShortNameEnum='NONUSE')

				  print 'sb'
				  print @TimeKey
				  --print '@NONUSE'
				  --print @NONUSE

print 02
		SET @PWDCHNG=(SELECT ParameterValue  FROM  DimUserParameters
			WHERE (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey)
				  AND ShortNameEnum='PWDCHNG')
		 		
		print 0
		SELECT  @LoginDate=CurrentLoginDate,
				 @PwdChangeDate=PasswordChangeDate,
				 @DateCreated=DateCreated,
				 @SuspendedUser=SuspendedUser,
				 @UserLogged=UserLogged
		FROM DimUserInfo
			WHERE (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)
				  AND UserLoginID =@UserLoginID

		IF  @LoginDate IS NOT NULL
			BEGIN
				SET @Suspended= (SELECT datediff(d,@LoginDate,GETDATE()) AS 'Days')
				--PRINT '@LoginDate = @Suspended'
				--PRINT @Suspended
			END
		ELSE
			BEGIN
				PRINT '@DateCreated = @Suspended'
				SET @Suspended= (SELECT datediff(d,@DateCreated,GETDATE()) AS 'Days')
				--PRINT '@DateCreated = @Suspended'
				--PRINT @Suspended
			END
		
		IF	@PwdChangeDate IS NOT NULL
			BEGIN
				SET @ExpiredUserDay= (SELECT datediff(d,@PwdChangeDate,GETDATE()) AS 'Days')
			END
	    ELSE
			BEGIN
				SET @ExpiredUserDay= (SELECT datediff(d,@DateCreated,GETDATE()) AS 'Days')
			END

		Update A set A.Activate= Case When DATEDIFF(DD,LoginTime,GETDATE())>45 Then 'N' Else A.Activate End
		from DimUserInfo A
		INNER JOIN 
		(select USERID,MAX(LoginTime)LoginTime from UserLoginHistory 
		Where LoginSucceeded='Y' AND UserID=@UserLoginID
		Group BY USERID )B ON A.UserLoginID=B.UserID
		Where A.EffectiveToTimeKey=49999 AND A.UserLoginID=@UserLoginID


		--SELECT  @Suspended, @NONUSE, @ExpiredUserDay, @PWDCHNG	,@SuspendedUser
		 PRINT 1
		IF @Suspended>@NONUSE AND @NONUSE<>0
			BEGIN				
				 PRINT 2               
				UPDATE  DimUserInfo         
					SET   SuspendedUser='Y' 
	 					WHERE (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)
							  AND UserLoginID=@UserLoginID		--AND @authType<> 'AD'				
	 			--- AND @authType<> 'AD' This Code of Update Query is COMMENTED BY SATWAJI 
				--- as on 09/11/2021 as per Bank's Requirement Change
				--- as per User Suspend Should work irrespective of AD Authentication OR NO AD Authentication

				------SELECT  'SUSPEND' AS SUSPEND ,'NOTExpiredUser' AS ExpiredUser

				SELECT  NULL AS UserLoginID,
						NULL AS UserName,
						LoginPassword,
						NULL AS UserLocation,
						NULL AS UserLocationName,
						NULL AS UserLocationCode,
						CAST(0 AS SMALLINT) AS UserRoleALT_Key,
						CAST(0 AS SMALLINT) AS UserRole_Key,
						NULL AS PasswordChanged,
						NULL AS Activate,
						'SUSPEND' AS SUSPEND,
						'NOTExpiredUser' AS ExpiredUser,	
						CAST(0 AS SMALLINT) AS ExpiredUserDay,
						CAST(0 AS SMALLINT) AS MaxUserLogin,
						CAST(0 AS SMALLINT) AS UserLoginCount,
						NULL AS RoleDescription,
						NULL AS AllowLogin,
						NULL AS MIS_APP_USR_ID,
						NULL AS	MIS_APP_USR_PASS,
						IsChecker,
						NULL AS UserType
						,NULL as UserLogged,
						IsChecker2					------ New Parameter Added By Satwaji on 09/06/2021
					FROM DimUserInfo
						WHERE (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)
							   AND UserLoginID=@UserLoginID 
	 			PRINT 3   	
			END
			------------Checking to User has Expired Or Not 
		ELSE IF @ExpiredUserDay>@PWDCHNG  
			BEGIN
			print @ExpiredUserDay
				PRINT 4   	         
				
				SELECT  DimUserInfo.UserLoginID as UserLoginID,
						DimUserInfo.UserName as UserName,
						LoginPassword,
						NULL AS UserLocation,
						NULL AS UserLocationName,
						NULL AS UserLocationCode,
						CAST(0 AS SMALLINT) AS UserRoleALT_Key,
						CAST(0 AS SMALLINT) AS UserRole_Key,
						NULL AS PasswordChanged,
						NULL AS Activate,
						'NOTSUSPEND' AS SUSPEND,
						'ExpiredUser' AS ExpiredUser,	
						CAST(0 AS SMALLINT) AS ExpiredUserDay,
						CAST(0 AS SMALLINT) AS MaxUserLogin,
						CAST(0 AS SMALLINT) AS UserLoginCount,
						NULL AS RoleDescription,
						NULL AS AllowLogin,
						NULL AS MIS_APP_USR_ID,
						NULL AS	MIS_APP_USR_PASS,
						 IsChecker,
						NULL AS UserType
						,'N' as UserLogged,
						IsChecker2					------ New Parameter Added By Satwaji on 09/06/2021
					FROM DimUserInfo
						WHERE (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)
							   AND UserLoginID=@UserLoginID 
			END
		ELSE IF @SuspendedUser='Y'
			BEGIN 
				PRINT 5        
				SELECT  NULL AS UserLoginID,
						NULL AS UserName,
						LoginPassword,
						NULL AS UserLocation,
						NULL AS UserLocationName,
						NULL AS UserLocationCode,
						CAST(0 AS SMALLINT) AS UserRoleALT_Key,
						CAST(0 AS SMALLINT) AS UserRole_Key,
						NULL AS PasswordChanged,
						NULL AS Activate,
						'SUSPEND' AS SUSPEND,
						'NOTExpiredUser' AS ExpiredUser,
						CAST(0 AS SMALLINT) AS ExpiredUserDay,
						CAST(0 AS SMALLINT) AS MaxUserLogin,
						CAST(0 AS SMALLINT) AS UserLoginCount,
						NULL AS RoleDescription,
						NULL AS AllowLogin,
						NULL AS MIS_APP_USR_ID,
						NULL AS	MIS_APP_USR_PASS,
						IsChecker,
						NULL AS UserType
						,'N' as UserLogged,
						IsChecker2
				FROM DimUserInfo
				WHERE (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)
					  AND UserLoginID=@UserLoginID 
			END
		ELSE IF @UserLogged=1
		BEGIN
		   SELECT  NULL AS UserLoginID,
						NULL AS UserName,
						LoginPassword,
						NULL AS UserLocation,
						NULL AS UserLocationName,
						NULL AS UserLocationCode,
						CAST(0 AS SMALLINT) AS UserRoleALT_Key,
						CAST(0 AS SMALLINT) AS UserRole_Key,
						NULL AS PasswordChanged,
						Activate  AS Activate,
						'NOTSUSPEND' AS SUSPEND,
						'NOTExpiredUser' AS ExpiredUser,
						CAST(0 AS SMALLINT) AS ExpiredUserDay,
						CAST(0 AS SMALLINT) AS MaxUserLogin,
						CAST(0 AS SMALLINT) AS UserLoginCount,
						NULL AS RoleDescription,
						NULL AS AllowLogin,
						NULL AS MIS_APP_USR_ID,
						NULL AS	MIS_APP_USR_PASS,
						IsChecker,
						NULL AS UserType
						,'Y' as UserLogged,
						 IsChecker2
				FROM DimUserInfo
				WHERE (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)
					  AND UserLoginID=@UserLoginID 
		END
		ELSE	
			BEGIN
				PRINT 6

				SELECT
					
					DimUserInfo.UserLoginID as UserLoginID,
					DimUserInfo.UserName as UserName,
					DimUserInfo.LoginPassword,
					DimUserInfo.UserLocation ,
					CASE WHEN DimUserInfo.UserLocation = 'RO' then 'Region'
						 WHEN  DimUserInfo.UserLocation = 'ZO' then 'Zone'
						 WHEN  DimUserInfo.UserLocation = 'BO' then 'Branch'
						 WHEN  DimUserInfo.UserLocation = 'HO' then 'Bank'
						 End AS UserLocationName,
					DimUserInfo.UserLocationCode,
					DimUserInfo.UserRoleALT_Key,
					--DimUserInfo.IsAdmin,
					--DimUserInfo.IsAdmin,
					DimUserRole.UserRole_Key,
					DimUserInfo.PasswordChanged,
					DimUserInfo.Activate,
					'NOTSUSPEND' SUSPEND,
					'NOTExpiredUser' AS ExpiredUser, 
					@PWDCHNG-@ExpiredUserDay AS ExpiredUserDay,
					ISNULL( DimMaxLoginAllow.MaxUserLogin,0) AS MaxUserLogin,				
					ISNULL(DimMaxLoginAllow.UserLoginCount,0) AS UserLoginCount,
					DimUserRole.UserRoleShortNameEnum As RoleDescription,
					DimUserInfo.MIS_APP_USR_ID,
					DimUserInfo.MIS_APP_USR_PASS,
					DimUserInfo.IsChecker,
					DimUserInfo.IsChecker2,
					--Case WHEN DimUserInfo.UserLocation = 'BO' THEN (SELECT ISNULL(AllowLogin,'N') FROM DimBranch 
					--													WHERE (DimBranch.EffectiveFromTimeKey <=@TimeKey AND DimBranch.EffectiveToTimeKey> = @TimeKey) 
					--													AND BranchCode=DimUserinfo.UserLocationCode)
					--	 WHEN DimUserInfo.UserLocation = 'RO'	AND (SELECT COUNT(*) FROM DimBranch 
					--													WHERE BranchRegionAlt_Key=DimUserinfo.UserLocationCode 
					--														AND (DimBranch.EffectiveFromTimeKey <=@TimeKey AND DimBranch.EffectiveToTimeKey> = @TimeKey)
					--														AND ISNULL(AllowLogin,'N')='Y')>0 THEN 'Y'
					--	 WHEN DimUserInfo.UserLocation = 'RO'	AND (SELECT COUNT(*) FROM DimBranch 
					--													WHERE BranchRegionAlt_Key=DimUserinfo.UserLocationCode
					--														AND  (DimBranch.EffectiveFromTimeKey <=@TimeKey AND DimBranch.EffectiveToTimeKey> = @TimeKey) 
					--														AND ISNULL(AllowLogin,'N')='Y')=0 THEN 'N'
					--	 WHEN DimUserInfo.UserLocation = 'HO'	AND (SELECT COUNT(*) FROM DimBranch 
					--													WHERE (DimBranch.EffectiveFromTimeKey <=@TimeKey AND DimBranch.EffectiveToTimeKey> = @TimeKey)
					--														AND ISNULL(AllowLogin,'N')='Y')>0 THEN 'Y'  
					--	 WHEN DimUserInfo.UserLocation = 'HO'	AND (SELECT COUNT(*) FROM DimBranch 
					--													WHERE (DimBranch.EffectiveFromTimeKey <=@TimeKey AND DimBranch.EffectiveToTimeKey> = @TimeKey)
					--														 AND ISNULL(AllowLogin,'N')='Y')=0 THEN 'N'  
					--END AS AllowLogin,
					'Y' AS AllowLogin,		
					Case WHEN DimUserInfo.UserType = 'Employee' THEN 'Y' ELSE 'N' END AS UserType
								,'N' as UserLogged
						INTO #tmpUserInfo
				FROM DimUserInfo
					INNER JOIN DimUserRole
						ON DimUserInfo.UserRoleAlt_Key = DimUserRole.UserRoleAlt_Key
					LEFT OUTER JOIN DimMaxLoginAllow 
						ON DimMaxLoginAllow.UserLocation=DimUserInfo.UserLocation 
						AND DimMaxLoginAllow.UserLocationCode=DimUserInfo.UserLocationCode			
				WHERE (DimUserInfo.EffectiveFromTimekey<=@TimeKey AND DimUserInfo.EffectiveToTimekey>=@TimeKey)
						AND	DimUserInfo.UserLoginID=@UserLoginID 
						AND ISNULL(SuspendedUser,'N')='N'	 				
			

			IF @authType = 'AD'				
			BEGIN
					--Activate='Y',
				update #tmpUserInfo set PasswordChanged='Y',	SUSPEND='NOTSUSPEND',	ExpiredUser='NOTExpiredUser',	ExpiredUserDay='0' 
			END
				SELECT *
				FROM #tmpUserInfo

				PRINT 66
				 DECLARE @ChangePwdMax AS INT=0
				 SET @ChangePwdMax=(SELECT ParameterValue  FROM  DimUserParameters
										WHERE  (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey)
												AND ShortNameEnum='PWDCHNG')
			
			END

PRINT 7
	SELECT ParameterName, ParameterValue FROM SysSolutionParameter
	WHERE (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)

	Select ParameterValue from DimUserParameters 
	Where ParameterType ='Suspend User after Maximum Unsuccessful Log-On attempts' AND (EffectiveFromTimeKey <= @TimeKey	AND EffectiveToTimeKey >= @TimeKey)

	SELECT Count(UserLoginID) AS UserRegisteredCount FROM DIMUSERINFO_MOD WHERE CreatedBy = 'self'

	--Select ParameterName, ParameterValue from SysSolutionParameter Where ParameterName IN('TierValue','RegionCap','AllowHigherLevelAuth')
END








GO