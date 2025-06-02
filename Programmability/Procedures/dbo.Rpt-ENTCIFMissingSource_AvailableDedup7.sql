SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


------/*
------Created By :- Vedika
------Created Date:-26/09/2017
------Report Name :- ENTCIF Missing in Source, Available in Dedup – Replace in Source
------*/
                    
CREATE Proc [dbo].[Rpt-ENTCIFMissingSource_AvailableDedup7] 
@DtEnter as varchar(20)
,@Cost as Float
,@DimsourceSystem as int
,@NPA AS INT
AS


----DECLARE	
----@DtEnter as varchar(20)='30/09/2017'
----,@Cost AS FLOAT=1000
----,@DimsourceSystem as int=0
----,@NPA AS INT=1

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

OPTION(RECOMPILE)

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
OPTION(RECOMPILE)

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
OPTION(RECOMPILE)
--------------------------AVAILABLE IN DEDUP SYSTEM & MISSING IN SOURCE SYSTEM-------------

IF(OBJECT_ID('tempdb..#ENTCIFMiss1') is not null)
DROP TABLE #ENTCIFMiss1





SELECT * INTO #ENTCIFMiss1 FROM (
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

,NPA_IntegrationDetails.CustomerACID							AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,0				                                                AS 'Outstanding'

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

INNER JOIN NPA_IntegrationDetails		ON NPA_IntegrationDetails.NCIF_Id=NCIF_VALIDATION.ChangedNCIF
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										AND (NPA_IntegrationDetails.AC_AssetClassAlt_Key<>7)
									
INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass				    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	

INNER JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

WHERE (  @NPA=0 AND NPA_IntegrationDetails.AC_AssetClassAlt_Key<>7
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0))

OR ( @NPA=1
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)

AND (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)<>1
	  OR  (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)=1
     
	      AND 

           CASE WHEN  AgriFlag='N' THEN  (  CASE WHEN isnull(MaxDPD,0)>isnull(DPD_Renewals,0) THEN  (CASE WHEN isnull(MaxDPD,0)>90 THEN 1 END)
								          WHEN isnull(DPD_Renewals,0)>isnull(MaxDPD,0) THEN (CASE WHEN ISNULL(DPD_Renewals,0)>180 THEN 1 END)
									END )
									
                WHEN AgriFlag='Y' THEN  (  CASE WHEN isnull(MaxDPD,0)>isnull(DPD_Renewals,0) THEN  (CASE WHEN isnull(MaxDPD,0)>365 THEN 1 END)
								          WHEN isnull(DPD_Renewals,0)>isnull(MaxDPD,0) THEN (CASE WHEN ISNULL(DPD_Renewals,0)>180 THEN 1 END)
									END )							
											
										END =1 
		)
     )
     




))A

SELECT * From  #ENTCIFMiss1

option(Recompile)

DROP TABLE #CHANGED
DROP TABLE #DIFFER
DROP TABLE #UPDATED
DROP TABLE #ENTCIFMiss1
GO