SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[STDPROVCATMASTER_search]-- 'MSE',26922
@STD_ASSET_CATShortNameEnum VARCHAR(250),
@TIMEKEY INT

AS

BEGIN 

 IF ISNULL(@STD_ASSET_CATShortNameEnum,'') NOT LIKE ''
BEGIN
		

	DROP TABLE IF EXISTS DIM_STD_ASSET_CAT_MOD_Search
	
	SELECT 
		A.STD_ASSET_CATName,A.STD_ASSET_CATShortNameEnum,A.STD_ASSET_CAT_Prov*100 STD_ASSET_CAT_Prov,A.AuthorisationStatus
		INTO DIM_STD_ASSET_CAT_MOD_Search
		FROM DIM_STD_ASSET_CAT_MOD A WHERE A.STD_ASSET_CATShortNameEnum =@STD_ASSET_CATShortNameEnum
		AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY AND AuthorisationStatus <> 'R'

	UNION 
	
	SELECT 
		A.STD_ASSET_CATName,A.STD_ASSET_CATShortNameEnum,A.STD_ASSET_CAT_Prov*100 STD_ASSET_CAT_Prov,(CASE WHEN A.AuthorisationStatus IS NULL THEN 'A' 
																										WHEN A.AuthorisationStatus = 'NULL' THEN 'A'
																										WHEN A.AuthorisationStatus = '' THEN 'A' ELSE A.AuthorisationStatus END)
		FROM DIM_STD_ASSET_CAT A WHERE A.STD_ASSET_CATShortNameEnum =@STD_ASSET_CATShortNameEnum AND 
		EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY

										

	SELECT *  FROM DIM_STD_ASSET_CAT_MOD_Search									
	--SELECT *  FROM DIM_STD_ASSET_CAT_MOD
END

END





GO