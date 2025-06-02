SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DimSourceSystemMail_GRIDDATA_BKP_20251804]--'D2K','26852'
@USERLOGINID VARCHAR(250),
@TIMEKEY INT,
@OPERATIONFLAG INT
--@SourceAlt_Key AS VARCHAR(MAX)
AS
BEGIN

		IF @OPERATIONFLAG=2
			BEGIN
			DROP TABLE IF EXISTS DimSourceSystemMail_MOD_DISPLAY
					SELECT 
						SM.SourceName [SourceSystem] 
						,MM.SourceSystemMailID [EMailID]
						,MM.SourceSystemMailValidCode [IsActive]
						,MM.CreatedBy [OperationBy]
						,MM.DATECREATED [OperationDate]
						,MM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,MM.CreatedBy [CrModBy]
						,MM.MODIFIEDBY [ModAppBy]
						,MM.ApprovedBy [CrAppBy]
						,MM.ApprovedByFirstLevel [FirstLevelApprovedBy]
					INTO DimSourceSystemMail_MOD_DISPLAY
					FROM DimSourceSystemMail_MOD MM INNER JOIN DimSourceSystem SM  ON  MM.SourceAlt_Key =SM.SourceAlt_Key 
/*ADDED BY MOHIT ON 202050410 FOR GANASEVA OBSERVATION*/
					INSERT INTO DimSourceSystemMail_MOD_DISPLAY
					SELECT 
						SM.SourceName [SourceSystem] 
						,MM.SourceSystemMailID [EMailID]
						,MM.SourceSystemMailValidCode [IsActive]
						,MM.CreatedBy [OperationBy]
						,MM.DATECREATED [OperationDate]
						,MM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,MM.CreatedBy [CrModBy]
						,MM.MODIFIEDBY [ModAppBy]
						,MM.ApprovedBy [CrAppBy]
						,MM.ApprovedByFirstLevel [FirstLevelApprovedBy]
					FROM DimSourceSystemMail MM INNER JOIN DimSourceSystem SM  ON  MM.SourceAlt_Key =SM.SourceAlt_Key 
					--and MM.EffectiveToTimeKey>=@TIMEKEY
					and MM.SourceSystemMailValidCode='Y'
					AND MM.SourceSystemMailID NOT IN (SELECT EMAILID FROM DimSourceSystemMail_MOD_DISPLAY)
					AND ISNULL(MM.AuthorisationStatus,'A')='A'

/*ADDED BY MOHIT ON 202050410 FOR GANASEVA OBSERVATION END*/			

			SELECT DISTINCT SourceShortNameEnum as SOURCENAME FROM DimSourceSystem
			
			select 
				case when SourceSystem like '%Prolendz%' then 'Finacle-3' else SourceSystem end SourceSystem,
				EMailID,
				IsActive,
				OperationBy,
				OperationDate,
				AuthorisationStatus,
				CrModBy,
				ModAppBy,
				CrAppBy,
				FirstLevelApprovedBy 
			from DimSourceSystemMail_MOD_DISPLAY
		END


		IF @OPERATIONFLAG=16
			BEGIN
			DROP TABLE IF EXISTS DimSourceSystemMail_MOD_DISPLAY
					SELECT 
						SM.SourceName [SourceSystem] 
						,MM.SourceSystemMailID [EMailID]
						,MM.SourceSystemMailValidCode [IsActive]
						,MM.CreatedBy [OperationBy]
						,MM.DATECREATED [OperationDate]
						,MM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,MM.CreatedBy [CrModBy]
						,MM.MODIFIEDBY [ModAppBy]
						,MM.ApprovedBy [CrAppBy]
						,MM.ApprovedByFirstLevel [FirstLevelApprovedBy]
					INTO DimSourceSystemMail_MOD_DISPLAY
					FROM DimSourceSystemMail_MOD MM INNER JOIN DimSourceSystem SM  ON  MM.SourceAlt_Key =SM.SourceAlt_Key 
					WHERE MM.AUTHORISATIONSTATUS='NP'
			
			SELECT DISTINCT SourceShortNameEnum as SOURCENAME FROM DimSourceSystem
			
			select 
				case when SourceSystem like '%Prolendz%' then 'Finacle-3' else SourceSystem end SourceSystem,
				EMailID,
				IsActive,
				OperationBy,
				OperationDate,
				AuthorisationStatus,
				CrModBy,
				ModAppBy,
				CrAppBy,
				FirstLevelApprovedBy 
			from DimSourceSystemMail_MOD_DISPLAY
		END

		IF @OPERATIONFLAG=20
			BEGIN
			DROP TABLE IF EXISTS DimSourceSystemMail_MOD_DISPLAY
					SELECT 
						SM.SourceName [SourceSystem] 
						,MM.SourceSystemMailID [EMailID]
						,MM.SourceSystemMailValidCode [IsActive]
						,MM.CreatedBy [OperationBy]
						,MM.DATECREATED [OperationDate]
						,MM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,MM.CreatedBy [CrModBy]
						,MM.MODIFIEDBY [ModAppBy]
						,MM.ApprovedBy [CrAppBy]
						,MM.ApprovedByFirstLevel [FirstLevelApprovedBy]
					INTO DimSourceSystemMail_MOD_DISPLAY
					FROM DimSourceSystemMail_MOD MM INNER JOIN DimSourceSystem SM  ON  MM.SourceAlt_Key =SM.SourceAlt_Key 
					WHERE MM.AUTHORISATIONSTATUS='1A'
			
			SELECT DISTINCT SourceShortNameEnum as SOURCENAME FROM DimSourceSystem
			
			select 
				case when SourceSystem like '%Prolendz%' then 'Finacle-3' else SourceSystem end SourceSystem,
				EMailID,
				IsActive,
				OperationBy,
				OperationDate,
				AuthorisationStatus,
				CrModBy,
				ModAppBy,
				CrAppBy,
				FirstLevelApprovedBy 
			from DimSourceSystemMail_MOD_DISPLAY
		END

END


--DimSourceSystemMail_GRIDDATA'D2K','26852'


GO