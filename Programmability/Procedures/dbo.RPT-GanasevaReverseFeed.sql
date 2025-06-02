SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



-------------===============GANASEVA Reverse Feed=======================================-------
------------/*
--------------CREATED BY  : VEDIKA
--------------CREATED DATE: 18-06-2018
--------------DESCRIPTION : GANASEVA REVERSE FEED
------------*/


CREATE PROC [dbo].[RPT-GanasevaReverseFeed]	
@TimeKey AS INT,
@COST AS FLOAT
AS


--DECLARE	 
--@TimeKey AS INT=26084
--,@Cost as float=1

DECLARE @DtEnter1 AS DATE

SET @DtEnter1=(SELECT DATE FROM SYSDAYMATRIX WHERE TIMEKEY=@TIMEKEY)
--PRINT @DtEnter1

IF OBJECT_ID('TEMPDB..#Impacted') IS NOT NULL
 DroP TABLE #Impacted

IF OBJECT_ID('TEMPDB..#Percolated') IS NOT NULL
 DroP TABLE #Percolated

IF OBJECT_ID('TEMPDB..#MOCDATA') IS NOT NULL
DROP TABLE #MOCDATA

 SELECT 
	NPA_IntegrationDetails.NCIF_Id,
	NPA_IntegrationDetails.ProductType,
	NPA_IntegrationDetails.CustomerName,
	NPA_IntegrationDetails.CustomerId,
	NPA_IntegrationDetails.PAN,
	NPA_IntegrationDetails.CustomerACID,
	NPA_IntegrationDetails.SanctionedLimit,
	NPA_IntegrationDetails.Balance,
	NPA_IntegrationDetails.ActualPrincipleOutstanding,
	NPA_IntegrationDetails.MaxDPD,
	NPA_IntegrationDetails.DPD_Renewals,
	NPA_IntegrationDetails.SubSegment,
	NPA_IntegrationDetails.AC_AssetClassAlt_Key		
	,NPA_IntegrationDetails.AC_NPA_Date				
	,NPA_IntegrationDetails.SrcSysAlt_Key
	,NPA_IntegrationDetails.MOC_Status
	,NPA_IntegrationDetails.MOC_AssetClassAlt_Key
	,NPA_IntegrationDetails.MOC_NPA_Date 
	,NPA_IntegrationDetails.AstClsChngByUser
	,NPA_IntegrationDetails.ActualOutStanding,
	NPA_IntegrationDetails.PrincipleOutstanding ,
	NPA_IntegrationDetails.DrawingPower,
	NPA_IntegrationDetails.ProductCode,
	NPA_IntegrationDetails.ProductDesc,
	NPA_IntegrationDetails.CUSTOMER_IDENTIFIER CUSTOMER_IDENTIFIER 	,
	NPA_IntegrationDetails.NCIF_AssetClassAlt_Key,
	NPA_IntegrationDetails.NCIF_NPA_Date

 INTO #MOCDATA
FROM NPA_IntegrationDetails

WHERE NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
AND MOC_AssetClassAlt_Key IS NOT NULL and SrcSysAlt_Key=70 and MOC_Status='Y' AND MOC_AssetClassAlt_Key<>1
ORDER BY NCIF_Id

--------------========================IMPACTED=============================-------------------
	SELECT 

	NPA_IntegrationDetails.NCIF_Id,
	NPA_IntegrationDetails.ProductType,
	NPA_IntegrationDetails.CustomerName,
	NPA_IntegrationDetails.CustomerId,
	NPA_IntegrationDetails.PAN,
	NPA_IntegrationDetails.CustomerACID,
	NPA_IntegrationDetails.SanctionedLimit,
	NPA_IntegrationDetails.Balance,
	NPA_IntegrationDetails.ActualPrincipleOutstanding,
	NPA_IntegrationDetails.MaxDPD,
	NPA_IntegrationDetails.DPD_Renewals,
	NPA_IntegrationDetails.SubSegment,
	NPA_IntegrationDetails_MOD.AC_AssetClassAlt_Key PreviousAssetClass,
	NPA_IntegrationDetails.AC_AssetClassAlt_Key		ChangedAssetClass,
	NPA_IntegrationDetails_MOD.AC_NPA_Date			PreviousNPADate
	,NPA_IntegrationDetails.AC_NPA_Date				ChangedNPADate
	,NPA_IntegrationDetails.SrcSysAlt_Key
	,NPA_IntegrationDetails.MOC_Status
	,NPA_IntegrationDetails.MOC_AssetClassAlt_Key
	,NPA_IntegrationDetails.MOC_NPA_Date 
	,NPA_IntegrationDetails.AstClsChngByUser
	,NPA_IntegrationDetails.ActualOutStanding,
	NPA_IntegrationDetails.PrincipleOutstanding ,
	NPA_IntegrationDetails.DrawingPower,
	NPA_IntegrationDetails.ProductCode,
	NPA_IntegrationDetails.ProductDesc,
	NPA_IntegrationDetails.CUSTOMER_IDENTIFIER CUSTOMER_IDENTIFIER 

	INTO #Impacted

	FROM NPA_IntegrationDetails  

	LEFT JOIN NPA_IntegrationDetails_MOD		ON  NPA_IntegrationDetails_MOD.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey and NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey								
												AND NPA_IntegrationDetails_MOD.NCIF_Id=NPA_IntegrationDetails.NCIF_Id	
												AND NPA_IntegrationDetails_MOD.CustomerACID=NPA_IntegrationDetails.CustomerACID
												AND NPA_IntegrationDetails_MOD.AuthorisationStatus='O'
												AND NPA_IntegrationDetails.AuthorisationStatus='A'
												
	WHERE NPA_IntegrationDetails.AC_AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
	AND ISNULL(NPA_IntegrationDetails.AC_NPA_Date,'')=ISNULL(NPA_IntegrationDetails.NCIF_NPA_Date,'')
	AND (NPA_IntegrationDetails.NCIF_AssetClassAlt_Key IS NOT NULL AND ISNULL(NPA_IntegrationDetails.NCIF_AssetClassAlt_Key,'')<>1)
	AND ISNULL(NPA_IntegrationDetails.AC_AssetClassAlt_Key,0)<> 7
	and ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200
	AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
	AND (NPA_IntegrationDetails.NCIF_Id)  NOT IN  (SELECT DISTINCT NCIF_Id FROM #MOCDATA)

	GROUP BY 
		NPA_IntegrationDetails.NCIF_Id,
		NPA_IntegrationDetails.ProductType,
		NPA_IntegrationDetails.CustomerName,
		NPA_IntegrationDetails.CustomerId,
		NPA_IntegrationDetails.PAN,
		NPA_IntegrationDetails.CustomerACID,
		NPA_IntegrationDetails.SanctionedLimit,
		NPA_IntegrationDetails.Balance,
		NPA_IntegrationDetails.ActualPrincipleOutstanding,
		NPA_IntegrationDetails.MaxDPD,
		NPA_IntegrationDetails.DPD_Renewals,
		NPA_IntegrationDetails.SubSegment,
		NPA_IntegrationDetails_MOD.AC_AssetClassAlt_Key, 
		NPA_IntegrationDetails.AC_AssetClassAlt_Key,		
		NPA_IntegrationDetails_MOD.AC_NPA_Date,	
		NPA_IntegrationDetails.AC_NPA_Date,			
		NPA_IntegrationDetails.SrcSysAlt_Key,
		NPA_IntegrationDetails.MOC_Status,
		NPA_IntegrationDetails.MOC_AssetClassAlt_Key,
		NPA_IntegrationDetails.MOC_NPA_Date,
		NPA_IntegrationDetails.AstClsChngByUser,
		NPA_IntegrationDetails.ActualOutStanding,
		NPA_IntegrationDetails.PrincipleOutstanding ,
		NPA_IntegrationDetails.DrawingPower,
		NPA_IntegrationDetails.ProductCode,
		NPA_IntegrationDetails.ProductDesc,
		NPA_IntegrationDetails.CUSTOMER_IDENTIFIER 

OPTION(RECOMPILE)		


		SELECT  

		NPA_IntegrationDetails.NCIF_Id,
		NPA_IntegrationDetails.ProductType,
		NPA_IntegrationDetails.CustomerName,
		NPA_IntegrationDetails.CustomerId,
		NPA_IntegrationDetails.PAN,
		NPA_IntegrationDetails.CustomerACID,
		NPA_IntegrationDetails.SanctionedLimit,
		NPA_IntegrationDetails.Balance,
		NPA_IntegrationDetails.ActualPrincipleOutstanding,
		NPA_IntegrationDetails.MaxDPD,
		NPA_IntegrationDetails.DPD_Renewals,
		NPA_IntegrationDetails.SubSegment,
		NPA_IntegrationDetails_MOD.AC_AssetClassAlt_Key		PreviousAssetClass,
		NPA_IntegrationDetails.AC_AssetClassAlt_Key			ChangedAssetClass,
		NPA_IntegrationDetails_MOD.AC_NPA_Date				PreviousNPADate
	   ,NPA_IntegrationDetails.AC_NPA_Date					ChangedNPADate
	   ,NPA_IntegrationDetails.SrcSysAlt_Key
	   ,NPA_IntegrationDetails.MOC_Status
	   ,NPA_IntegrationDetails.MOC_AssetClassAlt_Key
	   ,NPA_IntegrationDetails.MOC_NPA_Date
	   ,NPA_IntegrationDetails.AstClsChngByUser
	   ,NPA_IntegrationDetails.ActualOutStanding,
		NPA_IntegrationDetails.PrincipleOutstanding,
		NPA_IntegrationDetails.DrawingPower,
		NPA_IntegrationDetails.ProductCode,
		NPA_IntegrationDetails.ProductDesc,
		NPA_IntegrationDetails.CUSTOMER_IDENTIFIER

        INTO #Percolated

		FROM  NPA_IntegrationDetails

		LEFT JOIN NPA_IntegrationDetails_MOD	ON  NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey and NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationDetails_MOD.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationDetails_MOD.NCIF_Id=NPA_IntegrationDetails.NCIF_Id	
												AND NPA_IntegrationDetails_MOD.CustomerACID=NPA_IntegrationDetails.CustomerACID
												AND NPA_IntegrationDetails_MOD.AuthorisationStatus='O'
												AND NPA_IntegrationDetails.AuthorisationStatus='A'
												
		


		WHERE( (NPA_IntegrationDetails.AC_AssetClassAlt_Key<>NPA_IntegrationDetails.NCIF_AssetClassAlt_Key  
		      OR ISNULL(NPA_IntegrationDetails.AC_NPA_Date,'')<>ISNULL(NPA_IntegrationDetails.NCIF_NPA_Date,''))
			  AND ISNULL(NPA_IntegrationDetails.AC_AssetClassAlt_Key,0)<>7
			  AND ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200
			  AND NPA_IntegrationDetails.NCIF_AssetClassAlt_Key IS NOT NULL
			  AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
			  AND (NPA_IntegrationDetails.NCIF_Id)  NOT IN  (SELECT DISTINCT NCIF_Id FROM #MOCDATA)
			  )


		GROUP BY 

		NPA_IntegrationDetails.NCIF_Id,
		NPA_IntegrationDetails.ProductType,
		NPA_IntegrationDetails.CustomerName,
		NPA_IntegrationDetails.CustomerId,
		NPA_IntegrationDetails.PAN,
		NPA_IntegrationDetails.CustomerACID,
		NPA_IntegrationDetails.SanctionedLimit,
		NPA_IntegrationDetails.Balance,
		NPA_IntegrationDetails.ActualPrincipleOutstanding,
		NPA_IntegrationDetails.MaxDPD,
		NPA_IntegrationDetails.DPD_Renewals,
		NPA_IntegrationDetails.SubSegment,
		NPA_IntegrationDetails_MOD.AC_AssetClassAlt_Key,
		NPA_IntegrationDetails.AC_AssetClassAlt_Key	,
		NPA_IntegrationDetails_MOD.AC_NPA_Date
	   ,NPA_IntegrationDetails.AC_NPA_Date
	   ,NPA_IntegrationDetails.SrcSysAlt_Key
	   ,NPA_IntegrationDetails.MOC_Status
	   ,NPA_IntegrationDetails.MOC_AssetClassAlt_Key
	   ,NPA_IntegrationDetails.MOC_NPA_Date
	   ,NPA_IntegrationDetails.AstClsChngByUser
	   ,NPA_IntegrationDetails.ActualOutStanding,
		NPA_IntegrationDetails.PrincipleOutstanding,
		NPA_IntegrationDetails.DrawingPower,
		NPA_IntegrationDetails.ProductCode,
		NPA_IntegrationDetails.ProductDesc,
		NPA_IntegrationDetails.CUSTOMER_IDENTIFIER 

OPTION(RECOMPILE)  

SELECT * FROM

(

SELECT
 
ImpactedAccounts.NCIF_Id												AS  ENTCIF,

ImpactedSource.SourceName												AS  SOURCE ,
																		
ImpactedAccounts.ProductType											AS FACILITY,
																		
ImpactedAccounts.CustomerName											AS CUSTOMERNAME,
																		
ImpactedAccounts.CustomerId												AS ICustomerID

,ImpactedAccounts.PAN													AS IPAN
															
,case when len(ImpactedAccounts.CustomerACID)=16
				then '''' + ImpactedAccounts.CustomerACID + '''' 
				else ImpactedAccounts.CustomerACID
				end														AS IMPACTEDAccount


,DENSE_RANK() over(Partition by ImpactedAccounts.NCIF_Id order by ImpactedAccounts.CustomerACID	)	AS rank 
															
,ISNULL(ImpactedAccounts.SanctionedLimit,0)/@Cost						AS LIMIT,
															
ISNULL(ImpactedAccounts.Balance,0)/@Cost								AS BALANCE,

ISNULL(ImpactedAccounts.ActualPrincipleOutstanding,0)/@Cost				AS IPOS,

ISNULL(ImpactedAccounts.DrawingPower,0)/@Cost							AS IDP,

ImpactedAccounts.ProductCode											AS IProduct,

ImpactedAccounts.ProductDesc											AS IProductDescription,
															
ImpactedAccounts.MaxDPD													AS DPD,
	
ImpactedAccounts.DPD_Renewals											AS IDPD_Renewal,

ImpactedAccounts.SubSegment												AS ISegment,
																		
ImpactedAsset.AssetClassShortNameEnum									AS IAsset		
																		
,ImpactedAccounts.ChangedAssetClass										As IAssetAlt

,CONVERT(VARCHAR(25),ImpactedAccounts.ChangedNPADate,103)				AS IAC_NPA_Date

,convert(varchar(25),ImpactedAccounts.PreviousNPADate,103)				AS IPreviousNPA

,IPreviousAsset.AssetClassShortNameEnum									AS IPreviousAsset

,PerculatedSource.SourceName											AS  PSOURCE ,

PerculatedAccounts.ProductType											AS PFACILITY,

PerculatedAccounts.CustomerName											AS PCUSTOMERNAME,

PerculatedAccounts.CustomerId											AS PCustomerID

,PerculatedAccounts.PAN													AS PPAN

,case when len(PerculatedAccounts.CustomerACID)=16
				then '''' + PerculatedAccounts.CustomerACID + '''' 
				else PerculatedAccounts.CustomerACID
				end														AS PAccount

										
,ISNULL(PerculatedAccounts.SanctionedLimit,0)/@Cost						AS PLIMIT,

ISNULL(PerculatedAccounts.Balance,0)/@Cost								AS PBALANCE,

ISNULL(PerculatedAccounts.ActualPrincipleOutstanding,0)/@Cost			AS PPOS,

ISNULL(PerculatedAccounts.DrawingPower,0)/@Cost							AS pDP,

PerculatedAccounts.ProductCode											AS pProduct,

PerculatedAccounts.ProductDesc											AS pProductDescription,

PerculatedAccounts.MaxDPD												AS PDPD,

PerculatedAccounts.SubSegment											AS PSegment,

PerculatedAccounts.DPD_Renewals											AS PDPD_Renewal,

PerculatedAsset.AssetClassShortNameEnum									AS PAsset		---AS PER DISCUSSION WITH SHISHIR SIR			

,PerculatedAccounts.ChangedAssetClass									As PAssetAlt

,CONVERT(VARCHAR(25),PerculatedAccounts.ChangedNPADate,103)				AS PAC_NPA_Date

,ImpactedAccounts.MOC_Status											AS MOC_STATUS

,CONVERT(VARCHAR(25),ImpactedAccounts.MOC_NPA_Date,103)					AS MOC_NPA_Date

,MOCASSET.AssetClassName												AS MOC_ASSET_Class
	
,MOC_Freeze 

,convert(varchar(25),PerculatedAccounts.PreviousNPADate,103)			AS PPreviousNPA

,PPreviousAsset.AssetClassShortNameEnum									AS PPreviousAsset


,CASE WHEN PerculatedAsset.AssetClassAlt_Key=1
	  THEN 'STANDARD'
	  ELSE 'NPA'
	  END																AS SourceMainClassification

,CASE WHEN PerculatedAsset.AssetClassAlt_Key=1
	  THEN 'STD'
	  WHEN PerculatedAsset.AssetClassAlt_Key=2
	  THEN 'SUB'
	  WHEN PerculatedAsset.AssetClassAlt_Key=3
	  THEN 'DB1'
	  WHEN PerculatedAsset.AssetClassAlt_Key=4
	  THEN 'DB2'
	  WHEN PerculatedAsset.AssetClassAlt_Key=5
	  THEN 'DB3'
	  WHEN PerculatedAsset.AssetClassAlt_Key=6
	  THEN 'LOS'
	  END																AS SourceSubClassification

,CONVERT(VARCHAR(25),PerculatedAccounts.ChangedNPADate,105)				AS SourceNPADate


,CASE WHEN ImpactedAsset.AssetClassAlt_Key=1
	  THEN 'STANDARD'
	  ELSE 'NPA'
	  END																AS CrossMappedMainClassification

,CASE WHEN ImpactedAsset.AssetClassAlt_Key=1
	  THEN 'STD'
	  WHEN ImpactedAsset.AssetClassAlt_Key=2
	  THEN 'SUB'
	  WHEN ImpactedAsset.AssetClassAlt_Key=3
	  THEN 'DB1'
	  WHEN ImpactedAsset.AssetClassAlt_Key=4
	  THEN 'DB2'
	  WHEN ImpactedAsset.AssetClassAlt_Key=5
	  THEN 'DB3'
	  WHEN ImpactedAsset.AssetClassAlt_Key=6
	  THEN 'LOS'
	  END																AS CrossMappedSubClassification

,CONVERT(VARCHAR(25),ImpactedAccounts.ChangedNPADate,105)				AS CrossMappedNPADate

,CONVERT(VARCHAR(25),@DtEnter1,105)										AS DateofDate

FROM #Impacted  ImpactedAccounts               


INNER JOIN #Percolated PerculatedAccounts			ON ImpactedAccounts.NCIF_Id=PerculatedAccounts.NCIF_Id
													

INNER JOIN DimSourceSystem  ImpactedSource			ON ImpactedSource.SourceAlt_Key=ImpactedAccounts.SrcSysAlt_Key
													AND ImpactedSource.EffectiveFromTimeKey<=@TimeKey and ImpactedSource.EffectiveToTimeKey>=@TimeKey


INNER JOIN DimSourceSystem  PerculatedSource		ON PerculatedSource.SourceAlt_Key=PerculatedAccounts.SrcSysAlt_Key
													and PerculatedSource.EffectiveFromTimeKey<=@TimeKey and PerculatedSource.EffectiveToTimeKey>=@TimeKey
	
																											
INNER  jOIN DIMASSETCLASS	ImpactedAsset			ON ImpactedAsset.AssetClassAlt_Key=ImpactedAccounts.ChangedAssetClass
													and ImpactedAsset.EffectiveFromTimeKey<=@TimeKey and ImpactedAsset.EffectiveToTimeKey>=@TimeKey


INNER  JOIN DIMASSETCLASS	PerculatedAsset			ON PerculatedAsset.AssetClassAlt_Key=PerculatedAccounts.ChangedAssetClass
													and PerculatedAsset.EffectiveFromTimeKey<=@TimeKey and PerculatedAsset.EffectiveToTimeKey>=@TimeKey

LEFT JOIN	DimAssetClass	IPreviousAsset			ON IPreviousAsset.AssetClassAlt_Key=ImpactedAccounts.PreviousAssetClass	
													and IPreviousAsset.EffectiveFromTimeKey<=@TimeKey and IPreviousAsset.EffectiveToTimeKey>=@TimeKey

LEFT JOIN    DimAssetClass   PPreviousAsset			ON PPreviousAsset.AssetClassAlt_Key=PerculatedAccounts.PreviousAssetClass	
													and PPreviousAsset.EffectiveFromTimeKey<=@TimeKey and PPreviousAsset.EffectiveToTimeKey>=@TimeKey	

INNER JOIN	SysDataMatrix						    ON SysDataMatrix.TimeKey=@TimeKey						
													

LEFT JOIN DimAssetClass  MOCASSET					ON MOCASSET.AssetClassAlt_Key=ImpactedAccounts.MOC_AssetClassAlt_Key
													AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey

WHERE PerculatedAccounts.SrcSysAlt_Key=70	
AND PreProcessingFreeze='Y'
AND PreProcessingFreezeBy IS NOT NULL
AND PreProcessingFreezeDate IS NOT NULL
AND MOC_Freeze='Y'
AND MOC_FreezeBy IS NOT NULL
AND MOC_FreezeDate IS NOT NULL

UNION ALL

SELECT
 
#MOCDATA.NCIF_Id															AS  ENTCIF

,''																		AS  SOURCE ,
																		
''																		AS FACILITY,
																		
''																		AS CUSTOMERNAME,
																		
''																		AS ICustomerID

,''																		AS IPAN
															
,''																		AS IMPACTEDAccount


,1																		AS rank 
															
,''															           AS LIMIT
															
,''																		AS BALANCE,

''																		AS IPOS,

''																		AS IDP,

''																		AS IProduct,

''																		AS IProductDescription,
															
''																		AS DPD,
	
''																		AS IDPD_Renewal,

''																		AS ISegment,
																		
''																		AS IAsset		
																		
,''																		As IAssetAlt

,''																		AS IAC_NPA_Date

,''																		AS IPreviousNPA

,''																		AS IPreviousAsset

,PerculatedSource.SourceName											AS  PSOURCE ,

#MOCDATA.ProductType													AS PFACILITY,

#MOCDATA.CustomerName													AS PCUSTOMERNAME,

#MOCDATA.CustomerId														AS PCustomerID

,#MOCDATA.PAN															AS PPAN

,case when len(#MOCDATA.CustomerACID)=16
				then '''' + #MOCDATA.CustomerACID + '''' 
				else #MOCDATA.CustomerACID
				end														AS PAccount

										
,ISNULL(#MOCDATA.SanctionedLimit,0)/@Cost								AS PLIMIT,

ISNULL(#MOCDATA.Balance,0)/@Cost										AS PBALANCE,

ISNULL(#MOCDATA.ActualPrincipleOutstanding,0)/@Cost						AS PPOS,

ISNULL(#MOCDATA.DrawingPower,0)/@Cost									AS pDP,

#MOCDATA.ProductCode													AS pProduct,

#MOCDATA.ProductDesc													AS pProductDescription,
	
#MOCDATA.MaxDPD															AS PDPD,

#MOCDATA.SubSegment														AS PSegment,

#MOCDATA.DPD_Renewals													AS PDPD_Renewal,

PerculatedAsset.AssetClassShortNameEnum									AS PAsset		---AS PER DISCUSSION WITH SHISHIR SIR			

,PerculatedAsset.AssetClassAlt_Key										As PAssetAlt

,CONVERT(VARCHAR(25),#MOCDATA.AC_NPA_Date,103)							AS PAC_NPA_Date

,#MOCDATA.MOC_Status													AS MOC_STATUS

,CONVERT(VARCHAR(25),#MOCDATA.MOC_NPA_Date,103)							AS MOC_NPA_Date

,PerculatedAsset.AssetClassName											AS MOC_ASSET_Class
	
,MOC_Freeze 

,convert(varchar(25),#MOCDATA.NCIF_NPA_Date,103)						AS PPreviousNPA

,PerculatedAsset.AssetClassShortNameEnum								AS PPreviousAsset


,CASE WHEN PerculatedAsset.AssetClassAlt_Key=1
	  THEN 'STANDARD'
	  ELSE 'NPA'
	  END																AS SourceMainClassification

,CASE WHEN PerculatedAsset.AssetClassAlt_Key=1
	  THEN 'STD'
	  WHEN PerculatedAsset.AssetClassAlt_Key=2
	  THEN 'SUB'
	  WHEN PerculatedAsset.AssetClassAlt_Key=3
	  THEN 'DB1'
	  WHEN PerculatedAsset.AssetClassAlt_Key=4
	  THEN 'DB2'
	  WHEN PerculatedAsset.AssetClassAlt_Key=5
	  THEN 'DB3'
	  WHEN PerculatedAsset.AssetClassAlt_Key=6
	  THEN 'LOS'
	  END																AS SourceSubClassification

,CONVERT(VARCHAR(25),#MOCDATA.AC_NPA_Date,105)						    AS SourceNPADate

,CASE WHEN MOCASSET.AssetClassAlt_Key=1 
	  THEN 'STANDARD'
	  ELSE 'NPA'
	  END																AS CrossMappedMainClassification

,CASE WHEN MOCASSET.AssetClassAlt_Key=1
	  THEN 'STD'
	  WHEN MOCASSET.AssetClassAlt_Key=2
	  THEN 'SUB'
	  WHEN MOCASSET.AssetClassAlt_Key=3
	  THEN 'DB1'
	  WHEN MOCASSET.AssetClassAlt_Key=4
	  THEN 'DB2'
	  WHEN MOCASSET.AssetClassAlt_Key=5
	  THEN 'DB3'
	  WHEN MOCASSET.AssetClassAlt_Key=6
	  THEN 'LOS'
	  END																AS CrossMappedSubClassification

,CONVERT(VARCHAR(25),#MOCDATA.MOC_NPA_Date,105)				AS CrossMappedNPADate

,CONVERT(VARCHAR(25),@DtEnter1,105)										AS DateofDate
FROM 

 #MOCDATA															

INNER  jOIN DIMASSETCLASS	PerculatedAsset			ON PerculatedAsset.AssetClassAlt_Key=#MOCDATA.AC_AssetClassAlt_Key
													and PerculatedAsset.EffectiveFromTimeKey<=@TimeKey and PerculatedAsset.EffectiveToTimeKey>=@TimeKey

INNER JOIN DimSourceSystem  PerculatedSource		ON PerculatedSource.SourceAlt_Key=#MOCDATA.SrcSysAlt_Key
													and PerculatedSource.EffectiveFromTimeKey<=@TimeKey and PerculatedSource.EffectiveToTimeKey>=@TimeKey
	
INNER  jOIN DIMASSETCLASS	MOCASSET				ON MOCASSET.AssetClassAlt_Key=#MOCDATA.MOC_AssetClassAlt_Key
													and MOCASSET.EffectiveFromTimeKey<=@TimeKey and MOCASSET.EffectiveToTimeKey>=@TimeKey
																											
INNER JOIN	SysDataMatrix						    ON SysDataMatrix.TimeKey=@TimeKey						
													

WHERE #MOCDATA.SrcSysAlt_Key=70	
AND PreProcessingFreeze='Y'
AND PreProcessingFreezeBy IS NOT NULL
AND PreProcessingFreezeDate IS NOT NULL
AND MOC_Freeze='Y'
AND MOC_FreezeBy IS NOT NULL
AND MOC_FreezeDate IS NOT NULL

) A WHERE RANK=1

OPTION(RECOMPILE)

DROP TABLE #Impacted,#Percolated
GO