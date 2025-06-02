SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[ReverseAsset]

  @DATE		VARCHAR(10)='30-09-2017'
 ,@SrcSysAlt_Key  INT=10

AS


 DECLARE
  @TimeKey   INT

 --,@DATE		VARCHAR(10)='30-09-2017'
 --,@SrcSysAlt_Key  INT=10

 SELECT @TimeKey=TimeKey FROM SysDataMatrix WHERE MonthLastDate=CONVERT(DATE,@DATE,105)


 IF OBJECT_ID('TEMPDB..#ClientID_OriginalData')IS NOT NULL
 DROP TABLE #ClientID_OriginalData


SELECT A.SrcSysAlt_Key,A.NCIF_Id,A.CustomerId,ISNULL(B.AC_AssetClassAlt_Key,A.AC_AssetClassAlt_Key)AS 'OriginalAssetClass',CASE WHEN B.AC_AssetClassAlt_Key IS NULL THEN A.AC_NPA_Date ELSE B.AC_NPA_Date END 'OriginalNPA_Dt',A.CustomerACID INTO #ClientID_OriginalData FROM NPA_IntegrationDetails A
LEFT JOIN  NPA_IntegrationDetails_MOD  B   ON 	 (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
											   AND (A.CustomerACID=B.CustomerACID)
											   AND A.NCIF_EntityID=B.NCIF_EntityID
											   AND B.AuthorisationStatus='O'

WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)	
--AND (A.AstClsChngByUser='Y' OR A.MOC_Status='Y')
AND  A.AC_AssetClassAlt_Key NOT IN (7)   
AND ISNULL(A.AuthorisationStatus,'A')='A' 
AND A.SrcSysAlt_Key=@SrcSysAlt_Key	
----AND A.NCIF_Id='849872'    ------NCIF ID WHICH YOU HAD PROVIDED.


IF OBJECT_ID('TEMPDB..#FinalClientIdData')IS NOT NULL
DROP TABLE 	#FinalClientIdData


SELECT  A.SrcSysAlt_Key,A.NCIF_Id,A.CustomerId,A.OriginalAssetClass,MIN(B.OriginalNPA_Dt)'OriginalNPA_Date',CASE WHEN @SrcSysAlt_Key=10  THEN C.FinacleAssetClassCode ELSE C.ProlendzAssetClassCode END FinacleAssetClassCode  INTO #FinalClientIdData  FROM 
(
				SELECT A.SrcSysAlt_Key,A.NCIF_Id,A.CustomerId,MAX(A.OriginalAssetClass)AS OriginalAssetClass  FROM	#ClientID_OriginalData A
			
				GROUP BY A.SrcSysAlt_Key,A.NCIF_Id,A.CustomerId,A.CustomerId
			
		 )A  LEFT JOIN #ClientID_OriginalData	B ON A.NCIF_Id=B.NCIF_Id
												AND A.CustomerId=B.CustomerId
												AND A.SrcSysAlt_Key=B.SrcSysAlt_Key
												AND B.OriginalAssetClass=A.OriginalAssetClass
												
INNER JOIN DimAssetClass    C    ON C.AssetClassAlt_Key=A.OriginalAssetClass
														
GROUP BY A.SrcSysAlt_Key,A.NCIF_Id,A.CustomerId,A.OriginalAssetClass,C.FinacleAssetClassCode ,C.ProlendzAssetClassCode



IF OBJECT_ID('TEMPDB..#ENCIF_Data')IS NOT NULL
DROP TABLE #ENCIF_Data

CREATE TABLE  #ENCIF_Data
(
	  NCIF_Id VARCHAR(20)
	,CrossMappedAssetClass	 INT
	,CrossMappedNPA_Date     DATE
	,PercolatedByAccount	 VARCHAR(20)
	,PercolatedBySystem      INT
	,MinAssetFlag			CHAR(1)


)
INSERT INTO #ENCIF_Data
(
	 NCIF_Id
	,CrossMappedAssetClass
	,CrossMappedNPA_Date

)

SELECT A.NCIF_Id,A.CrossMappedAssetClass,A.CrossMappedNPA_Date  FROM
(
SELECT A.NCIF_Id,ISNULL(A.MOC_AssetClassAlt_Key,A.NCIF_AssetClassAlt_Key)CrossMappedAssetClass,ISNULL(A.MOC_NPA_Date,NCIF_NPA_Date)CrossMappedNPA_Date 

FROM NPA_IntegrationDetails A
 INNER JOIN	#FinalClientIdData	     B   ON A.EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey
											AND A.NCIF_Id=B.NCIF_Id
											AND A.AC_AssetClassAlt_Key NOT IN (7)
											AND ISNULL(A.AuthorisationStatus,'A')='A'
											--AND A.SrcSysAlt_Key=10

)A 

GROUP BY A.NCIF_Id,A.CrossMappedAssetClass,A.CrossMappedNPA_Date



OPTION (RECOMPILE)

UPDATE A
SET  A.PercolatedByAccount=B.CustomerACID
	,A.PercolatedBySystem=B.SrcSysAlt_Key

FROM  #ENCIF_Data A 
INNER JOIN
(

		SELECT MIN(B.CustomerACID)CustomerACID,B.SrcSysAlt_Key,B.NCIF_Id
		FROM  #ENCIF_Data A
		INNER JOIN 	 NPA_IntegrationDetails   B   ON (B.EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
														AND A.NCIF_Id=B.NCIF_Id
														AND A.CrossMappedAssetClass=B.AC_AssetClassAlt_Key
														--AND ISNULL(A.CrossMappedNPA_Date,'')=ISNULL(B.AC_NPA_Date,'')
														AND A.CrossMappedNPA_Date=B.AC_NPA_Date
														AND B.AC_AssetClassAlt_Key NOT IN (7)
														AND ISNULL(B.AuthorisationStatus,'A')='A'
														AND ISNULL(B.MOC_Status,'N')='N'
														---AND B.SrcSysAlt_Key=10

		GROUP BY B.SrcSysAlt_Key,B.NCIF_Id													

		
)B ON A.NCIF_Id=B.NCIF_Id

----FOR MOC 

UPDATE A
SET  A.PercolatedByAccount='MOC'
	,A.PercolatedBySystem=0
FROM  #ENCIF_Data A 
INNER JOIN NPA_IntegrationDetails B    ON (B.EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
											AND A.NCIF_Id=B.NCIF_Id
											AND B.AC_AssetClassAlt_Key NOT IN (7)
											AND ISNULL(B.AuthorisationStatus,'A')='A'
											AND B.MOC_Status='Y'


 IF @SrcSysAlt_Key=10 
	BEGIN

		SELECT
		
		  CASE WHEN [SourceSubClassificaiton]='001' THEN '001' Else '002' End +'|'+ [SourceSubClassificaiton]+'|'+ OriginalNPA_Date+'|'+CustomerId
		  +'|'+NCIF_Id+'|'+ CASE WHEN [CrossMappedSubClassification]='001' THEN '001' Else '002' End +'|'+[CrossMappedSubClassification] +'|'
		  + CrossMappedNPA_Date  +'|'+  PercolatedByAccount +'|'
		  +PercolatedBySystemName+'|'+@DATE 

		
		 FROM
		(
				SELECT A.SrcSysAlt_Key,A.NCIF_Id,A.CustomerId,A.OriginalAssetClass,ISNULL(CONVERT(VARCHAR(10),A.OriginalNPA_Date,105),'')OriginalNPA_Date,A.FinacleAssetClassCode AS [SourceSubClassificaiton]
				,B.CrossMappedAssetClass
				,D.FinacleAssetClassCode AS [CrossMappedSubClassification]
				,ISNULL(CONVERT(VARCHAR(10),B.CrossMappedNPA_Date,105),'')CrossMappedNPA_Date,ISNULL(PercolatedByAccount,'')PercolatedByAccount, CASE WHEN B.PercolatedBySystem=0 THEN 'MOC' ELSE  ISNULL(C.SourceName,'') END 'PercolatedBySystemName' 
				
				FROM #FinalClientIdData   A
				INNER JOIN #ENCIF_Data            B   ON (A.NCIF_Id=B.NCIF_Id)
				LEFT JOIN DimSourceSystem         C   ON (C.SourceAlt_Key=B.PercolatedBySystem)
				LEFT JOIN DimAssetClass           D   ON  B.CrossMappedAssetClass=D.AssetClassAlt_Key

		)A 
		WHERE CASE WHEN (A.OriginalAssetClass=A.CrossMappedAssetClass AND A.OriginalNPA_Date<>A.CrossMappedNPA_Date) THEN 1
				   WHEN (A.OriginalAssetClass<>A.CrossMappedAssetClass) THEN 1 END=1
		 
		ORDER BY A.NCIF_Id
		
	END	
	
ELSE
	 BEGIN
		SELECT
		  
		  CustomerId+'|'+ +NCIF_Id+'|'+[CrossMappedSubClassification] +'|'
		  + CrossMappedNPA_Date  +'|'+  PercolatedByAccount +'|' +PercolatedBySystemName+'|'+@DATE+'|'
		  + [SourceSubClassificaiton]+'|'+ OriginalNPA_Date+'|'
		   	
		 FROM
		(
				SELECT A.SrcSysAlt_Key,A.NCIF_Id,A.CustomerId,A.OriginalAssetClass,ISNULL(CONVERT(VARCHAR(10),A.OriginalNPA_Date,105),'')OriginalNPA_Date,A.FinacleAssetClassCode AS [SourceSubClassificaiton]
				,B.CrossMappedAssetClass
				, D.ProlendzAssetClassCode AS [CrossMappedSubClassification]
				 ,ISNULL(CONVERT(VARCHAR(10),B.CrossMappedNPA_Date,105),'')CrossMappedNPA_Date,ISNULL(PercolatedByAccount,'')PercolatedByAccount, CASE WHEN B.PercolatedBySystem=0 THEN 'MOC' ELSE  ISNULL(C.SourceName,'') END 'PercolatedBySystemName' 		
				
				FROM #FinalClientIdData   A
				INNER JOIN #ENCIF_Data            B   ON (A.NCIF_Id=B.NCIF_Id)
				LEFT JOIN DimSourceSystem         C   ON (C.SourceAlt_Key=B.PercolatedBySystem)
				LEFT JOIN DimAssetClass           D   ON  B.CrossMappedAssetClass=D.AssetClassAlt_Key
		)A 
		WHERE CASE WHEN (A.OriginalAssetClass=A.CrossMappedAssetClass AND A.OriginalNPA_Date<>A.CrossMappedNPA_Date) THEN 1
				   WHEN (A.OriginalAssetClass<>A.CrossMappedAssetClass) THEN 1 END=1
		
		ORDER BY A.NCIF_Id


	 END
		----Finacle_NPAFILE_ddmmyyyy.txt

			







 




							

																					

	



									






  
GO