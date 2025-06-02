SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By :- Vedika
Created Date:-26/09/2017
Report Name :- ENTCIF Missing in Source, Available in Dedup – Replace in Source
*/    
              
CREATE  proc [dbo].[Rpt-ENTCIFMissingSource_AvailableDedup] 
@DtEnter as varchar(20)
,@Cost as Float
,@ReportFilter As int
,@DimsourceSystem as int
,@NPA AS INT
AS

--DECLARE	
--@DtEnter as varchar(20)='31/03/2018'
--,@Cost AS FLOAT=1000
--,@ReportFilter As int=1
--,@DimsourceSystem as int=0
--,@NPA AS INT=0


DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 

IF(OBJECT_ID('tempdb..#UPDATED') is not null)
DROP TABLE #UPDATED


SELECT * INTO #UPDATED
FROM
(
SELECT DISTINCT Client_ID,Source_NCIF,ChangedNCIF,NCIF_ValFlag,Timekey
	   FROM NCIF_VALIDATION
	   where NCIF_ValFlag='U'
	   and SrcSysAlt_Key not in(30,50)
	   --AND ChangedNCIF='11341172'
	   AND Timekey=@TimeKey
)TEMP
option(recompile)
CREATE  CLUSTERED INDEX IX_UPDATED ON #UPDATED(ChangedNCIF)

CREATE NONCLUSTERED INDEX IX_UPDATED1 ON #UPDATED(ChangedNCIF)
INCLUDE (Client_ID,Source_NCIF,NCIF_ValFlag,Timekey)



IF(OBJECT_ID('tempdb..#DIFFER') is not null)
DROP TABLE #DIFFER


SELECT * INTO #DIFFER
FROM
(
(SELECT DISTINCT Client_ID,NCIF_ValFlag,Source_NCIF, ChangedNCIF,Timekey
	   FROM NCIF_VALIDATION
	  where NCIF_ValFlag='D' and NCIF_VALIDATION.Timekey=@TimeKey 
	  and SrcSysAlt_Key not in(30,50)
	   )
)TEMP
option(recompile)
CREATE  CLUSTERED INDEX IX_DIFFER ON #DIFFER(ChangedNCIF)

CREATE NONCLUSTERED INDEX IX_DIFFER1 ON #DIFFER(ChangedNCIF)
INCLUDE (Client_ID,Source_NCIF,NCIF_ValFlag,Timekey)



IF(OBJECT_ID('tempdb..#CHANGED') is not null)
DROP TABLE #CHANGED

SELECT * INTO #CHANGED
FROM
(
(SELECT DISTINCT Client_ID,NCIF_ValFlag,Timekey,Source_NCIF, ChangedNCIF
	   FROM NCIF_VALIDATION 
	   where NCIF_ValFlag='C'  	AND NCIF_VALIDATION.Timekey=@TimeKey
	   and SrcSysAlt_Key not in(30,50)
	   )
)TEMP
option(recompile)
CREATE  CLUSTERED INDEX IX_CHANGED ON #CHANGED(ChangedNCIF)

CREATE NONCLUSTERED INDEX IX_CHANGED1 ON #CHANGED(ChangedNCIF)
INCLUDE (Client_ID,Source_NCIF,NCIF_ValFlag,Timekey)


select * into #npa_Integration
From
(
select NCIF_Id,CustomerID,CustomerName,PAN,ProductType,CustomerACID,SanctionedLimit,DrawingPower,MaxDPD,SubSegment,AC_AssetClassAlt_Key
,MOC_AssetClassAlt_Key,SrcSysAlt_Key,Balance,
NCIF_AssetClassAlt_Key,NPA_IntegrationDetails.ProductAlt_Key,DPD_Renewals
 from NPA_IntegrationDetails
 where EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey
)npa_Integration

option(recompile)
--------------------------AVAILABLE IN DEDUP SYSTEM & MISSING IN SOURCE SYSTEM-------------

SELECT * FROM (
SELECT 
DISTINCT

DimSourceSystem.SourceName										AS 'SourceSystem'

,Source_NCIF													AS 'SOURCEENTCIF'

,ChangedNCIF													AS 'CHANGEDENTCIF'

,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'


,NPA_IntegrationDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,NCIF_ValFlag

,ISNULL(MOCASSET.AssetClassName,DimAssetClass.AssetClassName)	AS 'ASSETCLASS'

,isnull(NPA_IntegrationDetails.DrawingPower,0)/@Cost	        AS 'DP'

,ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)                  AS 'DPDRenewals'  

,ISNULL(NPA_IntegrationDetails.MaxDPD,0)                        AS 'MaxDPD'

,ISNULL(NPA_IntegrationDetails.SubSegment,'NA')                 AS  'Segment'
,AC_AssetClassAlt_Key
,MOC_AssetClassAlt_Key,
NCIF_AssetClassAlt_Key

,'Populated from Dedup System to Source System'					AS 'Action'

FROM  #UPDATED NCIF_VALIDATION

INNER JOIN  #npa_Integration NPA_IntegrationDetails		ON NPA_IntegrationDetails.NCIF_Id=NCIF_VALIDATION.ChangedNCIF
													--AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
														AND  ISNULL(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200
														AND ISNULL(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7
														 
INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass				    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

WHERE (@ReportFilter=1 AND  @NPA=0 AND ( ISNULL(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200)
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0))

OR (@ReportFilter=1 AND @NPA=1
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)

AND (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)<>1
	  OR  (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)=1
     
	      AND 
	  (CASE WHEN  AgriFlag='N' and ( ISNULL(MaxDPD,0)>90  OR ISNULL(DPD_Renewals,0)>180) THEN 1
									
		   WHEN AgriFlag='Y' and	(ISNULL(MaxDPD,0)>365 OR   ISNULL(DPD_Renewals,0)>180) tHeN 1							
											
	END =1 )
		)
     )
     




))A

-----/*
UNION ALL

------------------------------------D Flag---------------------------------------

SELECT * FROM(
SELECT 
DISTINCT

DimSourceSystem.SourceName										AS 'SourceSystem'

,Source_NCIF													AS 'SOURCEENTCIF'

,ChangedNCIF													AS 'CHANGEDENTCIF'

,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'


,NPA_IntegrationDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,NCIF_ValFlag

,ISNULL(MOCASSET.AssetClassName,DimAssetClass.AssetClassName)	AS 'ASSETCLASS'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost	        AS 'DP'

,ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)                  AS 'DPDRenewals'  

,ISNULL(NPA_IntegrationDetails.MaxDPD,0)                        AS 'MaxDPD'

,ISNULL(NPA_IntegrationDetails.SubSegment,'NA')                 AS  'Segment'
,AC_AssetClassAlt_Key
,MOC_AssetClassAlt_Key,
NCIF_AssetClassAlt_Key
,'Replaced from Dedup System in Source System'					AS 'Action'

FROM #DIFFER NCIF_VALIDATION

INNER JOIN  #npa_Integration NPA_IntegrationDetails		ON NPA_IntegrationDetails.NCIF_Id=NCIF_VALIDATION.ChangedNCIF
										             --AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
														AND  ISNULL(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200
														AND ISNULL(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7  

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass				   ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey


WHERE (@ReportFilter=2 AND  @NPA=0 AND (ISNULL(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200)
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0))

OR (@ReportFilter=2 AND @NPA=1
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)
AND ( ISNULL(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200)
AND (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)<>1
	  OR  (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)=1
     
	      AND 

	  (CASE WHEN  AgriFlag='N' and ( ISNULL(MaxDPD,0)>90  OR ISNULL(DPD_Renewals,0)>180) THEN 1
									
		   WHEN AgriFlag='Y' and	(ISNULL(MaxDPD,0)>365 OR   ISNULL(DPD_Renewals,0)>180) tHeN 1							
											
	END =1 )
		)
     )
     




)
)C

UNION ALL
-------------------------------------C Flag--------------------------------
SELECT * FROM (SELECT 
DISTINCT

DimSourceSystem.SourceName										AS 'SourceSystem'


,Source_NCIF													AS 'SOURCEENTCIF'

,ChangedNCIF													AS 'CHANGEDENTCIF'


,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'


,NPA_IntegrationDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,NCIF_ValFlag


,ISNULL(MOCASSET.AssetClassName,DimAssetClass.AssetClassName)	AS 'ASSETCLASS'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost            AS 'DP'

,ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)                  AS 'DPDRenewals'  

,ISNULL(NPA_IntegrationDetails.MaxDPD,0)                        AS 'MaxDPD'

,ISNULL(NPA_IntegrationDetails.SubSegment,'NA')                 AS  'Segment'

,AC_AssetClassAlt_Key
,MOC_AssetClassAlt_Key,
NCIF_AssetClassAlt_Key

,'To be alloted by Dedup System'								AS 'Action'

 FROM #CHANGED NCIF_VALIDATION

INNER JOIN #npa_Integration NPA_IntegrationDetails		ON NPA_IntegrationDetails.CustomerID=NCIF_VALIDATION.Client_ID
														--AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
														AND  ISNULL(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200
														AND ISNULL(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key


LEFT JOIN DimAssetClass				    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey


WHERE(@ReportFilter=3 AND  @NPA=0 AND ( ISNULL(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200)
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0))

OR (@ReportFilter=3 AND @NPA=1
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)
AND ( ( ISNULL(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200)
AND (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)<>1
	  OR  (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)=1
     
	      AND 

	  (CASE WHEN  AgriFlag='N' and ( ISNULL(MaxDPD,0)>90  OR ISNULL(DPD_Renewals,0)>180) THEN 1
									
		   WHEN AgriFlag='Y' and	(ISNULL(MaxDPD,0)>365 OR   ISNULL(DPD_Renewals,0)>180) tHeN 1							
											
	END =1 )
		)
     )
     )




)
)E 

OPTION(RECOMPILE)


DROP TABLE #CHANGED,#DIFFER,#UPDATED,#npa_Integration


GO