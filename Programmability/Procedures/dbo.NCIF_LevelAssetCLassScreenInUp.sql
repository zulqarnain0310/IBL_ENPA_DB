SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[NCIF_LevelAssetCLassScreenInUp]

@TIMEKEY  INT=49999

AS 

--DECLARE
--@TIMEKEY  INT=@TIMEKEY


IF OBJECT_ID('TEMPDB..#NCIF_ASSET')IS NOT NULL
DROP TABLE #NCIF_ASSET

--SELECT  * FROM NPA_IntegrationDetails WHERE NCIF_AssetClassAlt_Key<>0
;WITH CTE AS
(
	SELECT NCIF_EntityID FROM NPA_IntegrationDetails 
	WHERE (EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
	AND AstClsChngByUser='Y'
	AND ISNULL(AuthorisationStatus,'A')='A'
	AND AC_AssetClassAlt_Key NOT IN(7)
	AND ProductAlt_Key<>3200 
	AND ISNULL(AC_AssetClassAlt_Key,'')<>''
	GROUP BY NCIF_EntityID
)
SELECT MAX(A.AC_AssetClassAlt_Key)AC_AssetClassAlt_Key,A.NCIF_Id INTO #NCIF_ASSET FROM NPA_IntegrationDetails A
INNER JOIN 	CTE B  ON (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)
						AND A.NCIF_EntityID=B.NCIF_EntityID
						AND A.AC_AssetClassAlt_Key NOT IN(7)
						AND A.ProductAlt_Key<>3200  ----Exclude Write Off product as discussed with Shihsir sir on 19/12/2017
						AND ISNULL(A.AC_AssetClassAlt_Key,'')<>''
						AND ISNULL(AuthorisationStatus,'A')='A'
 GROUP BY A.NCIF_Id

--SELECT * FROM #NCIF_ASSET

UPDATE A
SET A.NCIF_AssetClassAlt_Key=B.AC_AssetClassAlt_Key
	,A.NCIF_NPA_Date=B.AC_NPA_Date
FROM NPA_IntegrationDetails A
INNER JOIN
(
		
		SELECT MIN(AC_NPA_Date)AC_NPA_Date,A.NCIF_Id,A.AC_AssetClassAlt_Key
		 FROM NPA_IntegrationDetails A
		 INNER JOIN #NCIF_ASSET  B ON (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)
									 AND ISNULL(A.AuthorisationStatus,'A')='A'
									 AND ISNULL(A.AC_AssetClassAlt_Key,'')<>''
									 AND A.AC_AssetClassAlt_Key NOT IN(7)
									 AND A.ProductAlt_Key<>3200
						             AND A.NCIF_Id=B.NCIF_Id
									 AND A.AC_AssetClassAlt_Key=B.AC_AssetClassAlt_Key
		GROUP BY A.NCIF_Id,A.AC_AssetClassAlt_Key

)B  ON		(EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
		AND (A.NCIF_Id=B.NCIF_Id)
		--AND  ISNULL(A.AC_AssetClassAlt_Key,'')<>''
		AND A.AC_AssetClassAlt_Key NOT IN(7)
		AND A.ProductAlt_Key<>3200
		AND ISNULL(A.AuthorisationStatus,'A')='A'
		  

----UPDATE NICF WISE ASSET CLASSIFICATION IN CASA TABLE AS PER DISCUSSION WITH SHISHIR SIR ON 01/2/2017
UPDATE A
SET  A.NCIF_AssetClassAlt_Key=B.NCIF_AssetClassAlt_Key
	,A.NCIF_NPA_Date=B.NCIF_NPA_Date
FROM CASA_NPA_IntegrationDetails A
INNER JOIN NPA_IntegrationDetails  B  ON (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)
									      AND (B.EffectiveFromTimeKey<=@TIMEKEY AND B.EffectiveToTimeKey>=@TIMEKEY)
										  AND A.NCIF_Id=B.NCIF_Id
										  AND B.AstClsChngByUser='Y'
										  AND B.AC_AssetClassAlt_Key<>7
										  AND B.ProductAlt_Key<>3200
											 
		  


GO