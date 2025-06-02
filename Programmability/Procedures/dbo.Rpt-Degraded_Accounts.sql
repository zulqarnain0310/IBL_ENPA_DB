SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By :- Vedika
Created Date:-26/10/2017
Report Name :- Degradation of Accounts
*/

CREATE PROC [dbo].[Rpt-Degraded_Accounts]
@DtEnter as varchar(20)
,@Cost as Float
,@DimsourceSystem as int
AS

--DECLARE	
--@DtEnter as varchar(20)='31/05/2021'
--,@Cost AS FLOAT=1000
--,@DimsourceSystem as int=0


DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 

SELECT * INTO #TEMP

FROM 
(
select COUNT(DISTINCT CustomerACID)CustomerACID,NCIF_Id
 from NPA_IntegrationDetails
 WHERE AC_AssetClassAlt_Key<isnull(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)
 AND NCIF_AssetClassAlt_Key NOT IN (7,0)  ---6 is removed as per the discussion with shishir sir-16_11_2017
 AND AC_AssetClassAlt_Key NOT IN (7) ---6 is removed as per the discussion with shishir sir-16_11_2017
 and ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200
 GROUP BY NCIF_Id
 HAVING COUNT(DISTINCT CustomerACID)>=1)TEMP

OPTION(RECOMPILE)

SELECT 


DimSourceSystem.SourceName										AS 'SourceSystem'


,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'


,NPA_IntegrationDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'
,NPA_IntegrationDetails.CustomerACID

,case when len(NPA_IntegrationDetails.CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost			AS 'DP'

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost			AS 'POS'
,CASE WHEN NPA_IntegrationDetails.SubSegment IS NULL THEN 'NA'
      ELSE NPA_IntegrationDetails.SubSegment	END				AS 'SubSegment'

,NPA_IntegrationDetails.ProductCode								AS 'ProductCode'

,NPA_IntegrationDetails.ProductDesc                             AS 'ProductDesc'


,CASE WHEN DimAssetClass.AssetClassAlt_Key=7
	  THEN ''
	  ELSE  DimAssetClass.AssetClassName	
	  END														AS 'ACASSET'

,convert(varchar(20),NPA_IntegrationDetails.AC_NPA_Date,103)	AS 'AC_NPADate'


,CASE WHEN DimAssetClass.AssetClassAlt_Key=7
	  THEN ''
	  ELSE ISNULL(MOCASSET.AssetClassName ,NCIFASSET.AssetClassName)
	  END														      AS 'NCIFASSET'


----,convert(varchar(20),NPA_IntegrationDetails.NCIF_NPA_Date,103)	     AS 'NCIF_NPADate'

,CONVERT(varchar(20),
CASE WHEN MOCASSET.AssetClassAlt_Key=1
	 THEN MOC_NPA_Date
	 ELSE ISNULL(MOC_NPA_Date,NCIF_NPA_Date)
	 END
,103)	                                                                AS 'NCIF_NPADate'

,SrcSysAlt_Key
,ActualOutStanding
,PrincipleOutstanding
,ActualPrincipleOutstanding
,CUSTOMER_IDENTIFIER

FROM #temp

INNER JOIN NPA_IntegrationDetails		ON NPA_IntegrationDetails.NCIF_Id=#temp.NCIF_Id
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										 and ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200
										 and NPA_IntegrationDetails.AC_AssetClassAlt_Key<>7

INNER JOIN DimAssetClass				ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

INNER JOIN DimAssetClass NCIFASSET		ON NCIFASSET.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass  MOCASSET      ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey

										
INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										AND  ( DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)

INNER JOIN SysDataMatrix				ON SysDataMatrix.TimeKey=@TimeKey

LEFT JOIN DimProduct				  ON DimProduct.ProductCode=NPA_IntegrationDetails.ProductCode
										AND DimProduct.EffectiveFromTimeKey<=@TimeKey AND DimProduct.EffectiveToTimeKey>=@TimeKey

WHERE 
MOC_Freeze='Y'
AND MOC_FreezeBy IS NOT NULL
AND MOC_FreezeDate IS NOT NULL

OPTION(RECOMPILE)

drop table #TEMP
GO