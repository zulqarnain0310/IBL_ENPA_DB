SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[usp_UserLogin_New] 	 
	@Userid	VARCHAR(100)= NULL,
	@Password VARCHAR(400)=NULL,
	@SessionId Integer
		
AS
--Declare 
--	@Userid	VARCHAR(100)= 'amol1234',
--	@Password VARCHAR(400)='oLhGeeiMcVLW0QcsI6jgwuatb3A=',
--	@SessionId Integer=12487

	 DECLARE @TimeKey  INTEGER
    -- SET  @TimeKey=(SELECT TimeKey From DimDayMatrix WHERE convert(varchar(10),Date,103)= convert(varchar(10),Getdate(),103))
	  SET  @TimeKey=(SELECT TimeKey From SysDayMatrix WHERE convert(varchar(10),Date,103)= convert(varchar(10),Getdate(),103))		
	  Declare @Tier int
	 --Select @Tier=Tier from Reportformat where Active='Y'
	 Select @Tier=Tier From SysReportformat WHERE Active='Y'
	 Declare @UserLocation varchar(10)
	 Declare @ClientName as Varchar(50)
	 select @ClientName=ParameterValue from syssolutionparameter where ParameterAlt_Key=101
	 --SET @Password='PQeNNdp54jtioHEwiEZOB9Jh4o0='
 BEGIN
	IF(EXISTS(SELECT 1 FROM LEGAL.DimProfessionalDetail  DPD
						INNER JOIN DimUserInfo DU 
							ON (DU.EffectiveFromTimeKey<=@TimeKey And DU.EffectiveToTimeKey>=@TimeKey)
							AND DPD.EffectiveFromTimeKey<=@TimeKey And DPD.EffectiveToTimeKey>=@TimeKey
							AND DPD.ProfEntityId=DU.ProffEntityId 
					    WHERE DU.UserLoginID = @Userid     --UserID=@Userid
						AND LoginPassword=@Password
						AND SuspendedUser='N'
						AND Activate='Y' ))
					BEGIN
					
						SELECT DISTINCT
						 DU.UserLoginID   As adv_Id,
						du.UserName    As adv_Name,
						'Login Successful' As error_msg 
						,0 AS error_Code
						,@SessionId AS session_Id
						,'Advocate' As UserScope
						,'None' AS UserLevel
						,'None' AS UserLocationCode
						,CASE WHEN UserLocation ='ZO' THEN DZ .ZoneName WHEN UserLocation ='RO' THEN DR .RegionName WHEN UserLocation ='BO' THEN DB .BranchName  ELSE ' ' end as UserLocationName
						,@ClientName AS ClientName
						,@Tier AS Tier
						,@TimeKey as TimeKey

						FROM LEGAL.DimProfessionalDetail  DPD    -- DimAdvocateDetails

						INNER JOIN DimUserInfo DU
						 ON (DU.EffectiveFromTimeKey<=@TimeKey And DU.EffectiveToTimeKey>=@TimeKey)
											   AND DPD.EffectiveFromTimeKey<=@TimeKey And DPD.EffectiveToTimeKey>=@TimeKey
											   AND DPD.ProfEntityId=DU.ProffEntityId
											   AND DU.UserLoginID = @Userid 
											   AND DU.LoginPassword = @Password
											   AND SuspendedUser='N'
											   AND Activate='Y'

						LEFT JOIN DimZone  DZ
							ON (DZ.EffectiveFromTimeKey<=@TimeKey And DZ.EffectiveToTimeKey>=@TimeKey)
							AND DZ.ZoneAlt_Key =DU.UserLocationCode 
						LEFT JOIN DimRegion DR
							ON DR .RegionAlt_Key  =DU.UserLocationCode 
						AND (DR.EffectiveFromTimeKey<=@TimeKey And DR.EffectiveToTimeKey>=@TimeKey)
						LEFT JOIN DimBranch DB 
							ON DB.BranchCode  =DU.UserLocationCode 
						AND DB.EffectiveFromTimeKey<=@TimeKey And DB.EffectiveToTimeKey>=@TimeKey
					
					
						UPDATE DPD
							Set SessionId = @SessionId 
						FROM LEGAL.DimProfessionalDetail DPD   --DimAdvocateDetails 
						INNER JOIN DimUserInfo DU
							ON (DU.EffectiveFromTimeKey<=@TimeKey AND DU.EffectiveToTimeKey>=@TimeKey)
							AND (DPD.EffectiveFromTimeKey<=@TimeKey AND DPD.EffectiveToTimeKey>=@TimeKey)
							AND DPD.ProfEntityId=DU.ProffEntityid
							where DU.UserLoginID = @Userid 


						update ACD
							set Sessionid=@Sessionid
							From AssignedCaseDetail ACD
							inner join Legal.DimProfessionalDetail DPD
								ON (ACD.EffectiveFromTimeKey<=@Timekey and ACD.EffectiveToTimeKey>=@TimeKey)
								and (DPD.EffectiveFromTimeKey<=@TimeKey and DPD.EffectiveToTimeKey>=@TimeKey)
								and ACD.Assignedid=cast(DPD.ProfEntityid as Varchar(10))
								and DPD.SessionId=@SessionId


						UPDATE ABD
							SET SessionId=@SessionId
							From AssignedBranchDetail ABD
							INNER JOIN DimUserInfo DU
								ON (ABD.EffectiveFromTimeKey<=@TimeKey AND ABD.EffectiveToTimeKey>=@TimeKey)
								and (DU.EffectiveFromTimeKey<=@TimeKey AND DU.EffectiveToTimeKey>=@TimeKey)
								AND du.UserLoginID=abd.AssignedId
								WHERE DU.UserLoginID=@Userid
						
						
					END

	ELSE IF (EXISTS(SELECT 1 FROM AssignedBranchDetail   ABD
						 INNER JOIN DimUserInfo DU 
						 ON (DU.EffectiveFromTimeKey<=@TimeKey And DU.EffectiveToTimeKey>=@TimeKey)
						 AND ABD.EffectiveFromTimeKey<=@TimeKey And ABD.EffectiveToTimeKey>=@TimeKey
						 AND ABD.AssignedId =DU.UserLoginID 
						 WHERE DU.UserLoginID = @Userid 
						 AND LoginPassword=@Password
						 AND SuspendedUser='N'
						 AND Activate='Y'))

		BEGIN
					PRINT 'Dealing Officer Details'

					UPDATE AssignedBranchDetail Set SessionId = @SessionId where AssignedBranchDetail.AssignedId  = @Userid 
					AND EffectiveFromTimeKey<=@TimeKey And EffectiveToTimeKey>=@TimeKey


					    SELECT DISTINCT
					 
						AssignedId AS adv_Id, ---OfficerID  As adv_Id,
						AssignedType AS adv_Name,  --OfficerName  As adv_Name,
						'Login Successful' As error_msg ,
						0 AS error_Code,
						@SessionId AS session_Id,
						'Dealing' As UserScope,
						DU.UserLocation  AS UserLevel,
						DU.UserLocationCode,
						CASE WHEN UserLocation ='ZO' THEN DimZone .ZoneName WHEN UserLocation ='RO' THEN DimRegion .RegionName WHEN UserLocation ='BO' THEN DimBranch .BranchName  ELSE ' ' end as UserLocationName,
						@ClientName AS ClientName,
						@Tier AS Tier,
						@TimeKey as TimeKey

						FROM AssignedBranchDetail  ABD
						INNER JOIN DimUserInfo DU
							ON (DU.EffectiveFromTimeKey<=@TimeKey And DU.EffectiveToTimeKey>=@TimeKey)
							AND (ABD.EffectiveFromTimeKey<=@TimeKey And ABD.EffectiveToTimeKey>=@TimeKey)
							AND ABD.AssignedId =DU.UserLoginID
							AND DU.UserLoginID  = @Userid 
							AND DU.LoginPassword = @Password
							AND SuspendedUser='N'
							AND Activate='Y'
							AND ABD.AssignedType='DLGOFF'

						LEFT JOIN DimZone ON DimZone .ZoneAlt_Key =DU.UserLocationCode 
						AND (DimZone.EffectiveFromTimeKey<=@TimeKey And DimZone.EffectiveToTimeKey>=@TimeKey)

						LEFT JOIN DimRegion  ON DimRegion .RegionAlt_Key  =DU.UserLocationCode 
						AND (DimRegion.EffectiveFromTimeKey<=@TimeKey And DimRegion.EffectiveToTimeKey>=@TimeKey)

						LEFT JOIN DimBranch  ON DimBranch .BranchCode  =DU.UserLocationCode 
						AND (DimBranch.EffectiveFromTimeKey<=@TimeKey And DimBranch.EffectiveToTimeKey>=@TimeKey)

						
		END

		ELSE IF (EXISTS(SELECT 1 FROM AssignedBranchDetail    ABD
						 INNER JOIN DimUserInfo DU
							ON (DU.EffectiveFromTimeKey<=@TimeKey And DU.EffectiveToTimeKey>=@TimeKey)
							AND ABD.EffectiveFromTimeKey<=@TimeKey And ABD.EffectiveToTimeKey>=@TimeKey
							AND ABD.AssignedId =DU.UserLoginID 
						WHERE DU.UserLoginID = @Userid 
						AND LoginPassword=@Password
						 AND SuspendedUser='N'
						 AND Activate='Y'))
		BEGIN

					    PRINT 'Nodale Officer Details'

						
						UPDATE AssignedBranchDetail Set SessionId = @SessionId where AssignedId = @Userid 
						AND EffectiveFromTimeKey<=@TimeKey And EffectiveToTimeKey>=@TimeKey


					    SELECT DISTINCT
						AssignedId AS adv_Id, -- OfficerID  As adv_Id,
						AssignedType AS adv_Name, --OfficerName  As adv_Name,
						'Nodel Login Successful' As error_msg ,
						0 AS error_Code,
						@SessionId AS session_Id,
						'Nodel' As UserScope,
						UserLocation  AS UserLevel,
						UserLocationCode,
						CASE WHEN UserLocation ='ZO' THEN DimZone .ZoneName WHEN UserLocation ='RO' THEN DimRegion .RegionName WHEN UserLocation ='BO' THEN DimBranch .BranchName  ELSE ' ' end as UserLocationName,
						@ClientName AS ClientName,
						@Tier AS Tier,
						@TimeKey as TimeKey
						
						FROM AssignedBranchDetail  ABD
						INNER JOIN DimUserInfo DU
							ON (DU.EffectiveFromTimeKey<=@TimeKey And DU.EffectiveToTimeKey>=@TimeKey)
						AND (ABD.EffectiveFromTimeKey<=@TimeKey And ABD.EffectiveToTimeKey>=@TimeKey)
						AND ABD.AssignedId =DU.UserLoginID
						AND DU.UserLoginID  = @Userid 
						AND DU.LoginPassword = @Password
						AND SuspendedUser='N'
						AND Activate='Y'
						AND ABD.AssignedType='NDLOFF'

						LEFT JOIN DimZone ON DimZone .ZoneAlt_Key =DU.UserLocationCode 
						AND (DimZone.EffectiveFromTimeKey<=@TimeKey And DimZone.EffectiveToTimeKey>=@TimeKey)

						LEFT JOIN DimRegion  ON DimRegion .RegionAlt_Key =DU.UserLocationCode 
						AND (DimRegion.EffectiveFromTimeKey<=@TimeKey And DimRegion.EffectiveToTimeKey>=@TimeKey)

						LEFT JOIN DimBranch  ON DimBranch .BranchCode  =DU.UserLocationCode 
						AND (DimBranch.EffectiveFromTimeKey<=@TimeKey And DimBranch.EffectiveToTimeKey>=@TimeKey)

						
		END

		ELSE IF (EXISTS(SELECT 1 FROM DimUserInfo DUI  
		                 WHERE DUI.EffectiveFromTimeKey<=@TimeKey And DUI.EffectiveToTimeKey>=@TimeKey
						 AND LoginPassword=@Password
						 AND DUI.UserLoginID   = @Userid 
						 AND SuspendedUser='N'
						 AND Activate='Y'))
		BEGIN
		
					    PRINT 'Admin User'
						
						UPDATE DimUserInfo Set SessionId = @SessionId where DimUserInfo.UserLoginID   = @Userid 
						AND DimUserInfo.EffectiveFromTimeKey<=@TimeKey And DimUserInfo.EffectiveToTimeKey>=@TimeKey


					    SELECT DISTINCT
						DUI.UserLoginID   As adv_Id,
						DUI.UserName  As adv_Name,
						'Admin Login Successful' As error_msg ,
						0 AS error_Code,
						@SessionId AS session_Id,
						'Admin' As UserScope,
						DUI.UserLocation  AS UserLevel,
						DUI.UserLocationCode,
						CASE WHEN DUI.UserLocation ='ZO' THEN DimZone .ZoneName WHEN DUI.UserLocation ='RO' THEN DimRegion .RegionName WHEN DUI.UserLocation ='BO' THEN DimBranch .BranchName  ELSE ' ' end as UserLocationName,
						@ClientName AS ClientName,
						@Tier AS Tier,
						@TimeKey as TimeKey
						
						FROM DimUserInfo  DUI  
						  INNER JOIN DimUserInfo ON DimUserInfo.EffectiveFromTimeKey<=@TimeKey And DimUserInfo.EffectiveToTimeKey>=@TimeKey

						AND DUI.UserLoginID   = @Userid 
						AND DUI.LoginPassword = @Password
						AND DUI.SuspendedUser='N'
						AND DUI.Activate='Y'
						AND DUI.EffectiveFromTimeKey<=@TimeKey And DUI.EffectiveToTimeKey>=@TimeKey
						
						LEFT JOIN DimZone ON DimZone .ZoneAlt_Key =DUI.UserLocationCode 
						AND DimZone.EffectiveFromTimeKey<=@TimeKey And DimZone.EffectiveToTimeKey>=@TimeKey

						LEFT JOIN DimRegion  ON DimRegion .RegionAlt_Key  =DUI.UserLocationCode 
						AND DimRegion.EffectiveFromTimeKey<=@TimeKey And DimRegion.EffectiveToTimeKey>=@TimeKey

						LEFT JOIN DimBranch  ON DimBranch .BranchCode  =DUI.UserLocationCode 
						AND DimBranch.EffectiveFromTimeKey<=@TimeKey And DimBranch.EffectiveToTimeKey>=@TimeKey

						
		END
		ELSE

					BEGIN
					SELECT	0 AS UserLoginID						  --0 AS adv_Id,
							,'' AS UserName					  --'' AS adv_Name,
							,'Login not Successful' As error_msg	  --'Login not Successful' As error_msg ,
							,1 AS error_Code						  --1 AS error_Code,
							,0 AS session_Id						  --0 AS session_Id
					END



          Select @UserLocation=UserLocation from DimUserInfo where (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey)
		  and UserLoginID=@Userid

		  IF @UserLocation='HO'
	BEGIN
	print @Tier
	     IF @Tier=4
		 BEGIN
				 Select 
				
				case ParameterName WHEN 'BankCap' THEN 'HO'
									WHEN	'ZoneCap' THEN 'ZO'
									WHEN    'RegionCap' THEN 'RO'
									WHEN 'BranchCap' THEN 'BO'
									ELSE ParameterName
									END
				AS LevelName,ParameterValue as LevelCaption 
				,case ParameterName WHEN 'BankCap' THEN 1
									WHEN	'ZoneCap' THEN 2
									WHEN    'RegionCap' THEN 3
									WHEN 'BranchCap' THEN 4
									ELSE 0
									END
				AS SrNo
				,@ClientName as ClientName
				
				from SysSolutionParameter where ParameterName IN ('BankCap','ZoneCap','RegionCap','BranchCap')
		 END
	    
		IF @Tier=3
		BEGIN
				Select 
				
				case ParameterName WHEN 'BankCap' THEN 'HO'
									WHEN	'ZoneCap' THEN 'ZO'
									WHEN    'RegionCap' THEN 'RO'
									WHEN 'BranchCap' THEN 'BO'
									ELSE ParameterName
									END
				AS LevelName,ParameterValue as LevelCaption 
				,case ParameterName WHEN 'BankCap' THEN 1
									WHEN	'ZoneCap' THEN 2
									WHEN    'RegionCap' THEN 3
									WHEN 'BranchCap' THEN 4
									ELSE 0
									END
				AS SrNo
				
				from SysSolutionParameter where ParameterName IN ('BankCap','RegionCap','BranchCap')
		END

		IF @Tier=2
		BEGIN
			
			Select 
				
				case ParameterName WHEN 'BankCap' THEN 'HO'
									WHEN	'ZoneCap' THEN 'ZO'
									WHEN    'RegionCap' THEN 'RO'
									WHEN 'BranchCap' THEN 'BO'
									ELSE ParameterName
									END
				AS LevelName,ParameterValue as LevelCaption 
				,case ParameterName WHEN 'BankCap' THEN 1
									WHEN	'ZoneCap' THEN 2
									WHEN    'RegionCap' THEN 3
									WHEN 'BranchCap' THEN 4
									ELSE 0
									END
				AS SrNo
				from SysSolutionParameter where ParameterName IN ('BankCap','BranchCap')


		END

	END

	IF @UserLocation='ZO'
	BEGIN
			Select 
				
				case ParameterName WHEN 'BankCap' THEN 'HO'
									WHEN	'ZoneCap' THEN 'ZO'
									WHEN    'RegionCap' THEN 'RO'
									WHEN 'BranchCap' THEN 'BO'
									ELSE ParameterName
									END
				AS LevelName,ParameterValue as LevelCaption 
				,case ParameterName WHEN 'BankCap' THEN 1
									WHEN	'ZoneCap' THEN 2
									WHEN    'RegionCap' THEN 3
									WHEN 'BranchCap' THEN 4
									ELSE 0
									END
				AS SrNo
				from SysSolutionParameter where ParameterName IN ('ZoneCap','RegionCap','BranchCap')
	END

	IF @UserLocation='RO'
	BEGIN
			Select 
				
				case ParameterName WHEN 'BankCap' THEN 'HO'
									WHEN	'ZoneCap' THEN 'ZO'
									WHEN    'RegionCap' THEN 'RO'
									WHEN 'BranchCap' THEN 'BO'
									ELSE ParameterName
									END
				AS LevelName,ParameterValue as LevelName 
				,case ParameterName WHEN 'BankCap' THEN 1
									WHEN	'ZoneCap' THEN 2
									WHEN    'RegionCap' THEN 3
									WHEN 'BranchCap' THEN 4
									ELSE 0
									END
				AS SrNo
				from SysSolutionParameter where ParameterName IN ('RegionCap','BranchCap')
	END

	IF @UserLocation='BO'
	BEGIN
		Select 
				
				case ParameterName WHEN 'BankCap' THEN 'HO'
									WHEN	'ZoneCap' THEN 'ZO'
									WHEN    'RegionCap' THEN 'RO'
									WHEN 'BranchCap' THEN 'BO'
									ELSE ParameterName
									END
				AS LevelName,ParameterValue as LevelCaption 
				,case ParameterName WHEN 'BankCap' THEN 1
									WHEN	'ZoneCap' THEN 2
									WHEN    'RegionCap' THEN 3
									WHEN 'BranchCap' THEN 4
									ELSE 0
									END
				AS SrNo
				from SysSolutionParameter where ParameterName IN ('BranchCap')
	END
	--else
	--    BEGIN
	--			SELECT  '' LevelName ,'' LevelName,0 as SrNo
	--	END
END


GO