SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DimSourceSystemmail_search_20250512] --'','','True'
@EMAILID VARCHAR(250),
@SOURCESYSTEM VARCHAR(50),
@ISACTIVE VARCHAR(10)

AS

BEGIN 

IF @ISACTIVE='True'
	BEGIN
		SET @ISACTIVE='Y'
	END
IF @ISACTIVE='False'
	BEGIN
		SET @ISACTIVE='N'
	END


DECLARE @TIMEKEY INT = (SELECT TIMEKEY FROM SysDataMatrix WHERE CurrentStatus='C')

 IF ISNULL(@EMAILID,'') NOT LIKE ''
BEGIN
	DROP TABLE IF EXISTS DimSourceSystemMail_MOD_Search
	SELECT 
						DSS.SourceName [SourceSystem] 
						,DSM.SourceSystemMailID [EMailID]
						,DSM.SourceSystemMailValidCode [IsActive]
						,DSM.CreatedBy [OperationBy]
						,DSM.DATECREATED [OperationDate]
						,DSM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,DSM.CreatedBy [CrModBy]
						,DSM.MODIFIEDBY [ModAppBy]
						,DSM.ApprovedBy [CrAppBy]
						,DSM.ApprovedByFirstLevel [FirstLevelApprovedBy]
						,'QuickSearchTable' as TableName
					INTO DimSourceSystemMail_MOD_Search
	FROM DimSourceSystemMail_MOD DSM INNER JOIN  DimSourceSystem DSS ON DSM.SourceAlt_Key=DSS.SourceAlt_Key
									WHERE 
									DSM.SourceSystemMailID =@EMAILID
									AND DSM.EffectiveFromTimeKey<=@TIMEKEY
									AND DSM.EffectiveToTimeKey>=@TIMEKEY
	UNION ALL
	SELECT 
						DSS.SourceName [SourceSystem] 
						,DSM.SourceSystemMailID [EMailID]
						,DSM.SourceSystemMailValidCode [IsActive]
						,DSM.CreatedBy [OperationBy]
						,DSM.DATECREATED [OperationDate]
						,DSM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,DSM.CreatedBy [CrModBy]
						,DSM.MODIFIEDBY [ModAppBy]
						,DSM.ApprovedBy [CrAppBy]
						,DSM.ApprovedByFirstLevel [FirstLevelApprovedBy]
						,'QuickSearchTable' as TableName
	FROM DimSourceSystemMail DSM INNER JOIN  DimSourceSystem DSS ON DSM.SourceAlt_Key=DSS.SourceAlt_Key
									WHERE 
									DSM.SourceSystemMailID =@EMAILID
									AND DSM.EffectiveFromTimeKey<=@TIMEKEY
									AND DSM.EffectiveToTimeKey>=@TIMEKEY
										

	SELECT case when SourceSystem like '%Prolendz%' then 'Finacle-3' else SourceSystem end SourceSystem
		,EMailID,IsActive,OperationBy,OperationDate,AuthorisationStatus,CrModBy,ModAppBy,CrAppBy,FirstLevelApprovedBy,TableName  FROM DimSourceSystemMail_MOD_Search	
	


END
ELSE IF  ISNULL(@SOURCESYSTEM,'')<> ''
BEGIN
	DROP TABLE IF EXISTS DimSourceSystemMail_MOD_Search
	SELECT 
						DSS.SourceName [SourceSystem] 
						,DSM.SourceSystemMailID [EMailID]
						,DSM.SourceSystemMailValidCode [IsActive]
						,DSM.CreatedBy [OperationBy]
						,DSM.DATECREATED [OperationDate]
						,DSM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,DSM.CreatedBy [CrModBy]
						,DSM.MODIFIEDBY [ModAppBy]
						,DSM.ApprovedBy [CrAppBy]
						,DSM.ApprovedByFirstLevel [FirstLevelApprovedBy]
						,'QuickSearchTable' as TableName
					INTO DimSourceSystemMail_MOD_Search
	FROM DimSourceSystemMail_MOD DSM INNER JOIN  DimSourceSystem DSS ON DSM.SourceAlt_Key=DSS.SourceAlt_Key
									WHERE DSS.SourceName=@SOURCESYSTEM -- CHANGED BY ZAIN ON 20250422 FROM "DSS.SourceShortNameEnum=@SOURCESYSTEM"
										--AND DSM.SourceSystemMailID IS NOT NULL
										AND DSM.EffectiveFromTimeKey<=@TIMEKEY
									AND DSM.EffectiveToTimeKey>=@TIMEKEY
	UNION
	SELECT 
						DSS.SourceName [SourceSystem] 
						,DSM.SourceSystemMailID [EMailID]
						,DSM.SourceSystemMailValidCode [IsActive]
						,DSM.CreatedBy [OperationBy]
						,DSM.DATECREATED [OperationDate]
						,DSM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,DSM.CreatedBy [CrModBy]
						,DSM.MODIFIEDBY [ModAppBy]
						,DSM.ApprovedBy [CrAppBy]
						,DSM.ApprovedByFirstLevel [FirstLevelApprovedBy]
						,'QuickSearchTable' as TableName
	FROM DimSourceSystemMail DSM INNER JOIN  DimSourceSystem DSS ON DSM.SourceAlt_Key=DSS.SourceAlt_Key
									WHERE DSS.SourceName=@SOURCESYSTEM -- CHANGED BY ZAIN ON 20250422 FROM "DSS.SourceShortNameEnum=@SOURCESYSTEM"
										--AND DSM.SourceSystemMailID IS NOT NULL
										AND DSM.EffectiveFromTimeKey<=@TIMEKEY
									AND DSM.EffectiveToTimeKey>=@TIMEKEY

SELECT case when SourceSystem like '%Prolendz%' then 'Finacle-3' else SourceSystem end SourceSystem
		,EMailID,IsActive,OperationBy,OperationDate,AuthorisationStatus,CrModBy,ModAppBy,CrAppBy,FirstLevelApprovedBy,TableName  FROM DimSourceSystemMail_MOD_Search	
									
END

ELSE IF ISNULL(@ISACTIVE,'')<> ''
BEGIN
	DROP TABLE IF EXISTS DimSourceSystemMail_MOD_Search
	SELECT 
						DSS.SourceName [SourceSystem] 
						,DSM.SourceSystemMailID [EMailID]
						,DSM.SourceSystemMailValidCode [IsActive]
						,DSM.CreatedBy [OperationBy]
						,DSM.DATECREATED [OperationDate]
						,DSM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,DSM.CreatedBy [CrModBy]
						,DSM.MODIFIEDBY [ModAppBy]
						,DSM.ApprovedBy [CrAppBy]
						,DSM.ApprovedByFirstLevel [FirstLevelApprovedBy]
						,'QuickSearchTable' as TableName
					INTO DimSourceSystemMail_MOD_Search
			FROM DimSourceSystemMail_MOD DSM INNER JOIN  DimSourceSystem DSS ON DSM.SourceAlt_Key=DSS.SourceAlt_Key
									WHERE DSM.SourceSystemMailValidCode=@ISACTIVE
										--AND DSM.SourceSystemMailID IS NOT NULL
										AND DSM.EffectiveFromTimeKey<=@TIMEKEY
									AND DSM.EffectiveToTimeKey>=@TIMEKEY
	UNION
	SELECT 
						DSS.SourceName [SourceSystem] 
						,DSM.SourceSystemMailID [EMailID]
						,DSM.SourceSystemMailValidCode [IsActive]
						,DSM.CreatedBy [OperationBy]
						,DSM.DATECREATED [OperationDate]
						,DSM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,DSM.CreatedBy [CrModBy]
						,DSM.MODIFIEDBY [ModAppBy]
						,DSM.ApprovedBy [CrAppBy]
						,DSM.ApprovedByFirstLevel [FirstLevelApprovedBy]
						,'QuickSearchTable' as TableName
			FROM DimSourceSystemMail DSM INNER JOIN  DimSourceSystem DSS ON DSM.SourceAlt_Key=DSS.SourceAlt_Key
									WHERE DSM.SourceSystemMailValidCode=@ISACTIVE
										--AND DSM.SourceSystemMailID IS NOT NULL
										AND DSM.EffectiveFromTimeKey<=@TIMEKEY
									AND DSM.EffectiveToTimeKey>=@TIMEKEY

SELECT case when SourceSystem like '%Prolendz%' then 'Finacle-3' else SourceSystem end SourceSystem
		,EMailID,IsActive,OperationBy,OperationDate,AuthorisationStatus,CrModBy,ModAppBy,CrAppBy,FirstLevelApprovedBy,TableName   FROM DimSourceSystemMail_MOD_Search	
									
END

END



GO