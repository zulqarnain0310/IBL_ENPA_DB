SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MocReasonMaster_search_20240321] 
 @MocReasonCategory VARCHAR(250)
,@MocReasonName varchar(250)
,@TIMEKEY INT

AS
BEGIN 

IF (ISNULL(@MocReasonCategory,'') NOT LIKE '') OR (ISNULL(@MocReasonName,'') NOT LIKE '') 
BEGIN
		
	DROP TABLE IF EXISTS MocReasonMaster_MOD_Search

	SELECT 
					 
							MocReasonAlt_Key
							,MocReasonCategory
							,MocReasonName
							,CreatedBy AS [Operation By]
							,DateCreated as [Operation Date]
							,AuthorisationStatus
	INTO MocReasonMaster_MOD_Search
	FROM DimMocReason_Mod 
	WHERE	(MocReasonCategory=@MocReasonCategory OR MocReasonName=@MocReasonName) 
		AND EffectiveFromTimeKey<=@TIMEKEY 
		AND EffectiveToTimeKey>=@TIMEKEY 
		AND AuthorisationStatus not in ('R','A')

	UNION 
	
	SELECT 
							MocReasonAlt_Key
							,MocReasonCategory
							,MocReasonName
							,CreatedBy AS [Operation By]
							,DateCreated as [Operation Date]
							,(CASE WHEN A.AuthorisationStatus IS NULL THEN 'A' 
								   WHEN A.AuthorisationStatus = 'NULL' THEN 'A'
								  WHEN A.AuthorisationStatus = '' THEN 'A' ELSE A.AuthorisationStatus END)
	FROM DimMocReason A  
	WHERE	(MocReasonCategory=@MocReasonCategory OR MocReasonName=@MocReasonName) 
			AND EffectiveFromTimeKey<=@TIMEKEY 
			AND EffectiveToTimeKey>=@TIMEKEY 
			AND AuthorisationStatus not in ('MP')

	SELECT  *  FROM MocReasonMaster_MOD_Search									
	--SELECT *  FROM STD_ASSET_CAT_MASTER_MOD

END
END



GO