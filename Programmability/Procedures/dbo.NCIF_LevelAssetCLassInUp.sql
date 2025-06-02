SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[NCIF_LevelAssetCLassInUp]

@TIMEKEY  INT=24745

AS 

DECLARE
--@TIMEKEY  INT=24745
@AstClsChngByUser	CHAR(1)='N'

IF EXISTS (SELECT 1 FROM NPA_IntegrationDetails WHERE (EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) AND AstClsChngByUser='Y' AND ISNULL(AuthorisationStatus,'A')='A')
	BEGIN
		  SET @AstClsChngByUser='Y'				
	END


IF OBJECT_ID('TEMPDB..#NCIF_ASSET')IS NOT NULL
DROP TABLE #NCIF_ASSET

--SELECT  * FROM NPA_IntegrationDetails WHERE NCIF_AssetClassAlt_Key<>0
;WITH CTE AS
(
	SELECT NCIF_EntityID FROM NPA_IntegrationDetails 
	WHERE (EffectiveFromTimeKey<=24745 AND EffectiveToTimeKey>=24745)
	AND ISNULL(AstClsChngByUser,'N')=@AstClsChngByUser
	AND ISNULL(AuthorisationStatus,'A')='A'
	AND AC_AssetClassAlt_Key NOT IN(7)
	AND ISNULL(AC_AssetClassAlt_Key,'')<>''
	GROUP BY NCIF_EntityID
)

SELECT MAX(A.AC_AssetClassAlt_Key)AC_AssetClassAlt_Key,A.NCIF_Id INTO #NCIF_ASSET FROM NPA_IntegrationDetails A
INNER JOIN 	CTE B  ON (A.EffectiveFromTimeKey<=24745 AND A.EffectiveToTimeKey>=24745)
						AND A.NCIF_EntityID=B.NCIF_EntityID
						AND A.AC_AssetClassAlt_Key NOT IN(7)
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
						             AND A.NCIF_Id=B.NCIF_Id
									 AND A.AC_AssetClassAlt_Key=B.AC_AssetClassAlt_Key
		GROUP BY A.NCIF_Id,A.AC_AssetClassAlt_Key

)B  ON		(EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
		AND (A.NCIF_Id=B.NCIF_Id)
		--AND  ISNULL(A.AC_AssetClassAlt_Key,'')<>''
		AND A.AC_AssetClassAlt_Key NOT IN(7)
		AND ISNULL(A.AuthorisationStatus,'A')='A'
		  

GO