SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DimSourceSystemmail_search_BKP_20250422] --'','Finacle-3',''
@EMAILID VARCHAR(250),
@SOURCESYSTEM VARCHAR(50),
@ISACTIVE VARCHAR(3)

AS

BEGIN 

 IF ISNULL(@EMAILID,'') NOT LIKE ''
BEGIN
	DROP TABLE IF EXISTS DimSourceSystemMail_MOD_Search
	SELECT 
						DSS.SourceShortNameEnum [SourceSystem] 
						,DSM.SourceSystemMailID [EMailID]
						,DSM.SourceSystemMailValidCode [IsActive]
						,DSM.CreatedBy [OperationBy]
						,DSM.DATECREATED [OperationDate]
						,DSM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,DSM.CreatedBy [CrModBy]
						,DSM.MODIFIEDBY [ModAppBy]
						,DSM.ApprovedBy [CrAppBy]
						,DSM.ApprovedByFirstLevel [FirstLevelApprovedBy]
					INTO DimSourceSystemMail_MOD_Search
	FROM DimSourceSystemMail_MOD DSM INNER JOIN  DimSourceSystem DSS ON DSM.SourceAlt_Key=DSS.SourceAlt_Key
									WHERE DSM.SourceSystemMailID =@EMAILID
										

	SELECT case when SourceSystem like '%Prolendz%' then 'Finacle-3' else SourceSystem end SourceSystem
		,EMailID,IsActive,OperationBy,OperationDate,AuthorisationStatus,CrModBy,ModAppBy,CrAppBy,FirstLevelApprovedBy  FROM DimSourceSystemMail_MOD_Search	
	


END
ELSE IF  ISNULL(@SOURCESYSTEM,'')<> ''
BEGIN
	DROP TABLE IF EXISTS DimSourceSystemMail_MOD_Search
	SELECT 
						DSS.SourceShortNameEnum [SourceSystem] 
						,DSM.SourceSystemMailID [EMailID]
						,DSM.SourceSystemMailValidCode [IsActive]
						,DSM.CreatedBy [OperationBy]
						,DSM.DATECREATED [OperationDate]
						,DSM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,DSM.CreatedBy [CrModBy]
						,DSM.MODIFIEDBY [ModAppBy]
						,DSM.ApprovedBy [CrAppBy]
						,DSM.ApprovedByFirstLevel [FirstLevelApprovedBy]
					INTO DimSourceSystemMail_MOD_Search
	FROM DimSourceSystemMail_MOD DSM INNER JOIN  DimSourceSystem DSS ON DSM.SourceAlt_Key=DSS.SourceAlt_Key
									WHERE DSS.SourceShortNameEnum=@SOURCESYSTEM
										AND DSM.SourceSystemMailID IS NOT NULL

SELECT case when SourceSystem like '%Prolendz%' then 'Finacle-3' else SourceSystem end SourceSystem
		,EMailID,IsActive,OperationBy,OperationDate,AuthorisationStatus,CrModBy,ModAppBy,CrAppBy,FirstLevelApprovedBy  FROM DimSourceSystemMail_MOD_Search	
									
END

ELSE IF ISNULL(@ISACTIVE,'')<> ''
BEGIN
	DROP TABLE IF EXISTS DimSourceSystemMail_MOD_Search
	SELECT 
						DSS.SourceShortNameEnum [SourceSystem] 
						,DSM.SourceSystemMailID [EMailID]
						,DSM.SourceSystemMailValidCode [IsActive]
						,DSM.CreatedBy [OperationBy]
						,DSM.DATECREATED [OperationDate]
						,DSM.AUTHORISATIONSTATUS [AuthorisationStatus]
						,DSM.CreatedBy [CrModBy]
						,DSM.MODIFIEDBY [ModAppBy]
						,DSM.ApprovedBy [CrAppBy]
						,DSM.ApprovedByFirstLevel [FirstLevelApprovedBy]
					INTO DimSourceSystemMail_MOD_Search
			FROM DimSourceSystemMail_MOD DSM INNER JOIN  DimSourceSystem DSS ON DSM.SourceAlt_Key=DSS.SourceAlt_Key
									WHERE DSM.SourceSystemMailValidCode=@ISACTIVE
										AND DSM.SourceSystemMailID IS NOT NULL

SELECT case when SourceSystem like '%Prolendz%' then 'Finacle-3' else SourceSystem end SourceSystem
		,EMailID,IsActive,OperationBy,OperationDate,AuthorisationStatus,CrModBy,ModAppBy,CrAppBy,FirstLevelApprovedBy  FROM DimSourceSystemMail_MOD_Search	
									
END

END



GO