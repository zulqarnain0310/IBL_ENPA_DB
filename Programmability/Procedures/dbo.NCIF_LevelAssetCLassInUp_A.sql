SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[NCIF_LevelAssetCLassInUp_A]

@TIMEKEY  INT=24745

AS 

--DECLARE
--@TIMEKEY  INT=24653


IF OBJECT_ID('TEMPDB..#NCIF_ASSET')IS NOT NULL
DROP TABLE #NCIF_ASSET

--SELECT  * FROM NPA_IntegrationDetails WHERE NCIF_AssetClassAlt_Key<>0
SELECT  MAX(AC_AssetClassAlt_Key)AC_AssetClassAlt_Key,NCIF_Id  INTO #NCIF_ASSET
FROM NPA_IntegrationDetails
WHERE (EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
AND ISNULL(AC_AssetClassAlt_Key,'')<>'' 
AND AC_AssetClassAlt_Key NOT IN(6,7)  ----EXCLUDE LOSS AND WRITE OFF
GROUP BY NCIF_Id

--SELECT * FROM #NCIF_ASSET

;WITH CTE 
AS
(
		SELECT MIN(AC_NPA_Date)AC_NPA_Date,A.NCIF_Id,A.AC_AssetClassAlt_Key
		 FROM NPA_IntegrationDetails A
		 INNER JOIN #NCIF_ASSET  B ON (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)
						             AND A.NCIF_Id=B.NCIF_Id
									 AND A.AC_AssetClassAlt_Key=B.AC_AssetClassAlt_Key	
		GROUP BY A.NCIF_Id,A.AC_AssetClassAlt_Key
)


UPDATE A
SET A.NCIF_AssetClassAlt_Key=B.AC_AssetClassAlt_Key
	,A.NCIF_NPA_Date=B.AC_NPA_Date
FROM NPA_IntegrationDetails A
INNER JOIN CTE  B  ON		(A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)
								AND	(A.NCIF_Id=B.NCIF_Id)
		  


GO