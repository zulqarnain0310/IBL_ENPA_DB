SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[Rpt-Ganaseva_ReverseFeed_Main_SSRS]
@DtEnter		VARCHAR(10)
 AS

DECLARE @TimeKey   INT

SELECT @TimeKey=TimeKey FROM SysDataMatrix WHERE MonthLastDate=CONVERT(DATE,@DtEnter,105)

IF OBJECT_ID ('TEMPDB..#FinalECS_Data')IS NOT NULL
DROP TABLE 	#FinalECS_Data

SELECT NCIF_Id,
	   CustomerId,
	   CustomerACID,
	   SrcSysAlt_Key
	
INTO #ImpactingSource
FROM NPA_IntegrationDetails

WHERE EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey
and ISNULL(AC_AssetClassAlt_Key,'')=ISNULL(NCIF_AssetClassAlt_Key,'')
and ISNULL(AC_NPA_Date,'')=ISNULL(NCIF_NPA_Date,'')
 and ISNULL(NPA_IntegrationDetails.Balance,0)<>0
 AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
SELECT 

	ROW_NUMBER()OVER (ORDER BY NCIF_Id,CustomerID,CustomerACID)SrNo,
	
	B.SourceName AS 'SourceSystemName' ,
	
	CustomerACID AS 'AccountNumber'
	
	,CustomerID AS 'ClientID',
	
	NCIF_Id,

	CASE WHEN FinalAssetClass=1 
		 THEN 0		 
		 ELSE 1
    END FinalSystemAssetClass 
	
	,C.GanasevaAssetClassCode,
	
	C.AssetClassShortNameEnum 'FinalAssetClassDesc',
	
	CONVERT(VARCHAR(10),FinalNPA_Date,105)FinalNPA_Date 

INTO #FinalECS_Data

FROM 
	(
	SELECT * FROM 
	(
		SELECT SrcSysAlt_Key,
			   NCIF_Id,
			   ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)'FinalAssetClass',
			   CustomerACID,
			   CustomerID,
			   AC_AssetClassAlt_Key,
			   AC_NPA_Date,
		CASE WHEN MOC_AssetClassAlt_Key IS NULL 
			 THEN NCIF_NPA_Date 
			 ELSE MOC_NPA_Date 
			 END'FinalNPA_Date' 
			 
			 FROM NPA_IntegrationDetails 
				WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					  AND AC_AssetClassAlt_Key NOT IN (7)
					  AND ISNULL(AuthorisationStatus,'A')='A'
					  AND SrcSysAlt_Key=70
					  AND ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)<>1
					  and ISNULL(NPA_IntegrationDetails.Balance,0)<>0
					  AND (ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)<>0)
					  AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
					  --and isnull(AC_AssetClassAlt_Key,'')<>ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)
	)A WHERE  FinalAssetClass<>AC_AssetClassAlt_Key 	   or (FinalAssetClass=AC_AssetClassAlt_Key
	 AND AC_NPA_Date<>FinalNPA_Date  	)
			   
  
	)A 

INNER JOIN DimSourceSystem  B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
									AND A.SrcSysAlt_Key=B.SourceAlt_Key

INNER JOIN DimAssetClass    C   ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
									AND C.AssetClassAlt_Key=A.FinalAssetClass
--WHERE A.NCIF_Id='14881969'

GROUP BY SrcSysAlt_Key,NCIF_Id,CustomerACID,CustomerID,FinalAssetClass,FinalNPA_Date,B.SourceName,C.GanasevaAssetClassCode,C.AssetClassShortNameEnum,
AC_AssetClassAlt_Key

order by SrNo

-------============================PIPE Delimited===================================--------------------
--insert into Ganaseva_ReverseFeedDetail(SNo
--                                       ,SourceSystemName
--                                       ,SourceName
--                                       ,NCIF_Id
--                                       ,ClientID
--                                       ,AccountNumber
--                                       ,FinalSystemAssetClass
--                                       ,FinalAssetClassDesc
--                                       ,FinalNPA_Date)
        SELECT  CAST(SrNo AS VARCHAR(MAX)) SNo,
		SourceSystemName ,
		DimSourceSystem.SourceName ,
		#ImpactingSource.NCIF_Id ,
		ClientID ,
		AccountNumber ,
		CAST(FinalSystemAssetClass AS VARCHAR(10)) as FinalSystemAssetClass,
		FinalAssetClassDesc ,
		FinalNPA_Date

FROM #FinalECS_Data

INNER JOIN #ImpactingSource			ON #ImpactingSource.NCIF_Id=#FinalECS_Data.NCIF_Id

INNER JOIN DimSourceSystem			ON DimSourceSystem.SourceAlt_Key=#ImpactingSource.SrcSysAlt_Key
									and DimSourceSystem.EffectiveFromTimeKey<=@TimeKey and DimSourceSystem.EffectiveToTimeKey>=@TimeKey


ORDER BY #ImpactingSource.NCIF_Id,SNo


OPTION(RECOMPILE)
DROP TABLE #ImpactingSource

DROP TABLE #FinalECS_Data










GO