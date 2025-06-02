SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[Rpt-NPABankLevel_SUB]
 @DtEnter as varchar(20)
,@Cost as Float

AS


--DECLARE	
--@DtEnter as varchar(20)='30/09/2017'
--,@Cost AS FLOAT=1
--,@DimsourceSystem as int=10
--,@NCIFAssetClass as int=0

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)



SELECT 


DimSourceSystem.SourceName										AS 'SourceSystem'


,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'


,NPA_IntegrationDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,NPA_IntegrationDetails.CustomerACID							AS 'Account No.'

,ISnull(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISnull(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,ISnull(NPA_IntegrationDetails.DrawingPower,0)/@Cost			AS 'DP'

,NPA_IntegrationDetails.Segment									AS 'Segment'

,  DimAssetClass.AssetClassName	
													            AS 'ACASSET'

,convert(varchar(20),NPA_IntegrationDetails.AC_NPA_Date,103)	AS 'AC_NPADate'


,ISNULL(MOCASSET.AssetClassName ,NCIFASSET.AssetClassName)   	AS 'NCIFASSET'

,CONVERT(varchar(20),case when MOCASSET.AssetClassAlt_Key=1
	 then MOC_NPA_Date
	 else ISNULL(MOC_NPA_Date,NCIF_NPA_Date)
	 end
,103)	                                                        AS 'NCIF_NPADate'

FROM  NPA_IntegrationDetails		
										

INNER JOIN DimAssetClass				ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										AND DimAssetClass.AssetClassAlt_Key<>7
								
INNER JOIN DimAssetClass NCIFASSET		ON NCIFASSET.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND NCIFASSET.EffectiveFromTimeKey<=@TimeKey AND NCIFASSET.EffectiveToTimeKey>=@TimeKey
										AND NCIFASSET.AssetClassAlt_Key<>7

LEFT JOIN DimAssetClass  MOCASSET      ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey
                                        AND MOCASSET.AssetClassAlt_Key<>7
										
INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										--AND  ( DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)


INNER JOIN SysDataMatrix				 ON SysDataMatrix.TimeKey=@TimeKey



WHERE 
isnull(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key) IN (2,3,4,5,6)
--AND((Isnull(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NPA_IntegrationDetails.NCIF_AssetClassAlt_Key)=@NCIFAssetClass) OR @NCIFAssetClass=0)
AND	SysDataMatrix.PreProcessingFreeze='Y'
AND SysDataMatrix.PreProcessingFreezeBy IS NOT NULL
AND SysDataMatrix.PreProcessingFreezeDate IS NOT NULL
AND MOC_Freeze='Y'
AND MOC_FreezeBy IS NOT NULL
AND MOC_FreezeDate IS NOT NULL

OPTION(RECOMPILE)
GO