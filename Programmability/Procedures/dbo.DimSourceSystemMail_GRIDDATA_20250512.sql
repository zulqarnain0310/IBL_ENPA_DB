SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DimSourceSystemMail_GRIDDATA_20250512]--'D2K','26852',2
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
						,ISNULL(MM.AUTHORISATIONSTATUS,'A') [AuthorisationStatus]
						,MM.CreatedBy [CrModBy]
						,MM.MODIFIEDBY [ModAppBy]
						,MM.ApprovedBy [CrAppBy]
						,MM.ApprovedByFirstLevel [FirstLevelApprovedBy]
					INTO DimSourceSystemMail_MOD_DISPLAY
					FROM DimSourceSystemMail_MOD MM INNER JOIN DimSourceSystem SM  ON  MM.SourceAlt_Key =SM.SourceAlt_Key 
				WHERE MM.EFFECTIVEFROMTIMEKEY<=@TIMEKEY
						AND MM.EFFECTIVETOTIMEKEY>=@TIMEKEY
						AND SM.EFFECTIVEFROMTIMEKEY<=@TIMEKEY
						AND SM.EFFECTIVETOTIMEKEY>=@TIMEKEY

/*ADDED BY MOHIT ON 202050410 FOR GANASEVA OBSERVATION*/

					INSERT INTO DimSourceSystemMail_MOD_DISPLAY
					SELECT 
						SM.SourceName [SourceSystem] 
						,MM.SourceSystemMailID [EMailID]
						,MM.SourceSystemMailValidCode [IsActive]
						,MM.CreatedBy [OperationBy]
						,MM.DATECREATED [OperationDate]
						,ISNULL(MM.AUTHORISATIONSTATUS,'A') [AuthorisationStatus]
						,MM.CreatedBy [CrModBy]
						,MM.MODIFIEDBY [ModAppBy]
						,MM.ApprovedBy [CrAppBy]
						,MM.ApprovedByFirstLevel [FirstLevelApprovedBy]
					FROM DimSourceSystemMail MM INNER JOIN DimSourceSystem SM  ON  MM.SourceAlt_Key =SM.SourceAlt_Key 
					AND MM.EFFECTIVEFROMTIMEKEY<=@TIMEKEY
						AND MM.EFFECTIVETOTIMEKEY>=@TIMEKEY
						AND SM.EFFECTIVEFROMTIMEKEY<=@TIMEKEY
						AND SM.EFFECTIVETOTIMEKEY>=@TIMEKEY
					--and MM.SourceSystemMailValidCode='Y'
					AND MM.SourceSystemMailID NOT IN (SELECT EMAILID FROM DimSourceSystemMail_MOD_DISPLAY )
					AND ISNULL(MM.AuthorisationStatus,'A')='A'

/*ADDED BY MOHIT ON 202050410 FOR GANASEVA OBSERVATION END*/			

			SELECT DISTINCT SourceName as SOURCENAME FROM DimSourceSystem WHERE EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
			
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
			ORDER BY 1

			
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
						,ISNULL(MM.AUTHORISATIONSTATUS,'A') [AuthorisationStatus]
						,MM.CreatedBy [CrModBy]
						,MM.MODIFIEDBY [ModAppBy]
						,MM.ApprovedBy [CrAppBy]
						,MM.ApprovedByFirstLevel [FirstLevelApprovedBy]
					INTO DimSourceSystemMail_MOD_DISPLAY
					FROM DimSourceSystemMail_MOD MM INNER JOIN DimSourceSystem SM  ON  MM.SourceAlt_Key =SM.SourceAlt_Key 
					WHERE MM.AUTHORISATIONSTATUS IN ('NP','MP')
					AND MM.EFFECTIVEFROMTIMEKEY<=@TIMEKEY
						AND MM.EFFECTIVETOTIMEKEY>=@TIMEKEY
						AND SM.EFFECTIVEFROMTIMEKEY<=@TIMEKEY
						AND SM.EFFECTIVETOTIMEKEY>=@TIMEKEY

			
			SELECT DISTINCT SourceName as SOURCENAME FROM DimSourceSystem WHERE EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
			
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
			ORDER BY 1
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
						,ISNULL(MM.AUTHORISATIONSTATUS,'A') [AuthorisationStatus]
						,MM.CreatedBy [CrModBy]
						,MM.MODIFIEDBY [ModAppBy]
						,MM.ApprovedBy [CrAppBy]
						,MM.ApprovedByFirstLevel [FirstLevelApprovedBy]
					INTO DimSourceSystemMail_MOD_DISPLAY
					FROM DimSourceSystemMail_MOD MM INNER JOIN DimSourceSystem SM  ON  MM.SourceAlt_Key =SM.SourceAlt_Key 
					WHERE MM.AUTHORISATIONSTATUS='1A'
					AND MM.EFFECTIVEFROMTIMEKEY<=@TIMEKEY
						AND MM.EFFECTIVETOTIMEKEY>=@TIMEKEY
						AND SM.EFFECTIVEFROMTIMEKEY<=@TIMEKEY
						AND SM.EFFECTIVETOTIMEKEY>=@TIMEKEY
			
			SELECT DISTINCT SourceName as SOURCENAME FROM DimSourceSystem WHERE EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
			
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
			ORDER BY 1
		END

END


--DimSourceSystemMail_GRIDDATA'D2K','26852'


GO