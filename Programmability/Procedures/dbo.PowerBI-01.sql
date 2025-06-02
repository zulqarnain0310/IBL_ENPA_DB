SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE Proc [dbo].[PowerBI-01]
@DtEnter as varchar(20)
AS

--DECLARE	
--@DtEnter as varchar(20)='30/09/2017'


DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)


--17322217

IF OBJECT_ID('TEMPDB..#TEMP') IS NOT NULL
 DroP TABLE #TEMP

SELECT 

ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)assetclassification,

ISNULL(MOCASSET.AssetClassName,NCIFASSET.AssetClassName)ASSET,

sum(ISNULL(Balance,0))TotalOutstanding,

sum(ISNULL(PrincipleOutstanding,0))PrincipalOutstanding

INTO #TEMP

FROM NPA_IntegrationDetails


LEFT JOIN DimAssetClass NCIFASSET		ON NCIFASSET.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND NCIFASSET.EffectiveFromTimeKey<=@TimeKey AND NCIFASSET.EffectiveToTimeKey>=@TimeKey
									

LEFT JOIN DimAssetClass  MOCASSET      ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey
                                  

WHERE ISNULL(AC_AssetClassAlt_Key,0)<>7

group by ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key),ISNULL(MOCASSET.AssetClassName,NCIFASSET.AssetClassName)


SELECT * FROM #TEMP
WHERE assetclassification IS NOT NULL
--ORDER BY assetclassification

OPTION (RECOMPILE)

DROP TABLE #TEMP

--SELECT DISTINCT AC_AssetClassAlt_Key FROM NPA_IntegrationDetails 

 --SELECT * FROM NPA_IntegrationDetails  WHERE AC_AssetClassAlt_Key IS NULL

 --exec [dbo].[PowerBI-01] '30/09/2017'
GO