SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[NCIF_LevelAssetCLassBackendProInUp]
@TIMEKEY  INT=24927
AS 


IF OBJECT_ID('TEMPDB..#NCIF_ASSET') IS NOT NULL
   DROP TABLE #NCIF_ASSET
BEGIN
	
	--DROP TABLE IF EXISTS #NCIF_ASSET
	--DECLARE @Timekey INT= 24927

------NCIF_ASSETCLASSALT_KEY And NCIF_NPA_DATE IS UPDATED AS NULL BECAUSE FROM  EXTRACTION PROCESS NCIF_ASSETCLASSALT_KEY IS UPDATED AS 0

 UPDATE NPA_IntegrationDetails
 SET NCIF_AssetClassAlt_Key=NULL,
 NCIF_NPA_Date=NULL
 WHERE EffectiveFromTimeKey<=@TImekey AND EffectiveToTimeKey>=@TImekey
 
 	
	SELECT	 NCIF_Id
			,AccountEntityID
			,AC_AssetClassAlt_Key
			,AC_NPA_Date
			,CAST(NULL AS TINYINT)NEWAC_AssetClassAlt_Key
			, CAST(NULL AS DATE)NEW_AC_NPA_Date
	INTO #NCIF_ASSET
	FROM NPA_IntegrationDetails
	WHERE (EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
	AND ISNULL(AC_AssetClassAlt_Key,'')<>'' 
	AND AC_AssetClassAlt_Key <>7  ----EXCLUDE  WRITE OFF
	AND ISNULL(ProductAlt_Key,0)<>3200    ----Exclude Write Off product as discusseda with Shihsir sir on 19/12/2017
	AND ISNULL(AuthorisationStatus,'A')='A'
	AND CASE        WHEN SrcSysAlt_Key = 10  AND CUSTOMER_IDENTIFIER = 'R' AND ( ISNULL(SanctionedLimit,0)<>0        
	                        OR ISNULL(DrawingPower,0)<>0 OR ISNULL(PrincipleOutstanding,0)<>0 OR ISNULL(BALANCE,0)<>0)  
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key = 10  AND CUSTOMER_IDENTIFIER = 'C'
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key = 20 AND ISNULL(ActualPrincipleOutstanding,0)<>0 AND ISNULL(Balance,0)<>0
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key = 60 AND ISNULL(PrincipleOutstanding,0)<>0 AND ISNULL(Balance,0)<>0
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key NOT IN (10, 20, 60)
	                                        THEN 1
	                        ELSE 0
	        END = 1
	
	CREATE NONCLUSTERED INDEX NCI_NCIF_ASSET ON #NCIF_ASSET(NCIF_Id)
	
	--UDPATNG A MAX ASSET CLASS NCIF WISE
	UPDATE A
	SET NEWAC_AssetClassAlt_Key = B.AC_AssetClassAlt_Key
	 FROM #NCIF_ASSET A
	INNER JOIN
	(
	        SELECT         NCIF_Id
	                        ,MAX(AC_AssetClassAlt_Key) AC_AssetClassAlt_Key
	        FROM #NCIF_ASSET
	        GROUP BY NCIF_Id
	)B ON A.NCIF_Id = B.NCIF_Id
	
	
	 --UDPATNG A MIN NPA DATE NICIF ID WISE AND MAX ASSET CLASSALT_KEY
	 UPDATE A
	 SET NEW_AC_NPA_Date = B.AC_NPA_Date
	  FROM #NCIF_ASSET A
	 INNER JOIN 
	 (
		SELECT B.NCIF_Id, MIN(A.AC_NPA_Date)AC_NPA_Date  
		FROM  #NCIF_ASSET A
			INNER JOIN #NCIF_ASSET B
				ON A.NCIF_Id = B.NCIF_Id
				AND A.AC_AssetClassAlt_Key<>1
				AND A.AC_AssetClassAlt_Key = B.NEWAC_AssetClassAlt_Key
		GROUP BY B.NCIF_Id
	 )B
	 ON A.NCIF_Id = B.NCIF_Id
	
	
	 UPDATE A
	 SET NCIF_AssetClassAlt_Key = B.NEWAC_AssetClassAlt_Key
	    , NCIF_NPA_Date = B.NEW_AC_NPA_Date
	 FROM NPA_IntegrationDetails A
	 INNER JOIN #NCIF_ASSET B
		ON  (A.EffectiveFromTimeKey <= @Timekey AND A.EffectiveToTimeKey >= @Timekey)
		AND A.NCIF_Id = B.NCIF_Id
		AND A.AccountEntityID = B.AccountEntityID
	
	WHERE ISNULL(A.AC_AssetClassAlt_Key,'')<>'' 
	AND A.AC_AssetClassAlt_Key <>7  ----EXCLUDE  WRITE OFF
	AND ISNULL(ProductAlt_Key,0)<>3200    ----Exclude Write Off product as discusseda with Shihsir sir on 19/12/2017
	AND ISNULL(AuthorisationStatus,'A')='A'


	
	UPDATE A
	SET  A.NCIF_AssetClassAlt_Key=B.NCIF_AssetClassAlt_Key
		,A.NCIF_NPA_Date=B.NCIF_NPA_Date
	FROM CASA_NPA_IntegrationDetails A
	INNER JOIN NPA_IntegrationDetails  B  ON (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)
										      AND (B.EffectiveFromTimeKey<=@TIMEKEY AND B.EffectiveToTimeKey>=@TIMEKEY)
											  AND A.NCIF_Id=B.NCIF_Id
											  AND B.AC_AssetClassAlt_Key<>7
											  AND ISNULL(B.ProductAlt_Key,0)<>3200  
	
	AND CASE        WHEN B.SrcSysAlt_Key = 10  AND B.CUSTOMER_IDENTIFIER = 'R' AND  ISNULL(B.SanctionedLimit,0)<>0        
	                        AND ISNULL(B.DrawingPower,0)<>0 AND ISNULL(B.PrincipleOutstanding,0)<>0  
	                                        THEN 1
	
	                        WHEN B.SrcSysAlt_Key = 10  AND B.CUSTOMER_IDENTIFIER = 'C'
	                                        THEN 1
	
	                        WHEN B.SrcSysAlt_Key = 20 AND ISNULL(ActualPrincipleOutstanding,0)<>0 AND ISNULL(B.Balance,0)<>0
	                                        THEN 1
	
	                        WHEN B.SrcSysAlt_Key = 60 AND ISNULL(B.PrincipleOutstanding,0)<>0 AND ISNULL(B.Balance,0)<>0
	                                        THEN 1
	
	                        WHEN B.SrcSysAlt_Key NOT IN (10, 20, 60)
	                                        THEN 1
	                        ELSE 0
	        END = 1
	
	
	--ADDED ON 02 JAN 2018
	UPDATE          a
	SET         a.NCIF_AssetClassAlt_Key=b.NCIF_AssetClassAlt_Key
	        ,a.NCIF_NPA_Date=b.NCIF_NPA_Date
	FROM  NPA_IntegrationDetails a
	INNER JOIN (
	
	
	SELECT NCIF_Id,NCIF_AssetClassAlt_Key,NCIF_NPA_Date FROM  NPA_IntegrationDetails
	WHERE NCIF_Id IN (
	
	                                                        SELECT NCIF_Id FROM         NPA_IntegrationDetails
	                                                        WHERE (EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
	                                                        AND   SrcSysAlt_Key=40
	
	                                           )
	AND (EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
	AND   SrcSysAlt_Key<>40
	group by  NCIF_Id,NCIF_AssetClassAlt_Key,NCIF_NPA_Date         )b        on (a.NCIF_Id=B.NCIF_Id)
	WHERE  (EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
	                                                        AND   SrcSysAlt_Key=40
END
GO