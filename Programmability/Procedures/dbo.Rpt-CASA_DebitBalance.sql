SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
--USE [IndusInd_New]
--GO
--/****** Object:  StoredProcedure [dbo].[Rpt-CASA]    Script Date: 11/18/2017 10:18:44 AM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

------/*
------ALTERD BY :- Vedika
------ALTERD DATE:-18/11/2017
------Report Name :- CASA
------*/


CREATE PROC [dbo].[Rpt-CASA_DebitBalance]
@DtEnter as varchar(20)
,@Cost as Float

AS

--DECLARE	
--@DtEnter as varchar(20)='30/09/2017'
--,@Cost AS FLOAT=1

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)


SELECT * INTO #TEMP
FROM 
(
(select 
			 NPA_IntegrationDetails.NCIF_Id ,
			 NPA_IntegrationDetails.CustomerId ,
			 NPA_IntegrationDetails.CustomerName ,
			 NPA_IntegrationDetails.CustomerACID ,
			 NPA_IntegrationDetails.ProductType ,
			 NPA_IntegrationDetails.NCIF_AssetClassAlt_Key,
			 MOC_AssetClassAlt_Key,
			 ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost  SanctionedLimit,
			 ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost	 Balance  ,
			 NPA_IntegrationDetails.SrcSysAlt_Key,
			 convert( varchar(25),ISNULL(MOC_NPA_Date,NPA_IntegrationDetails.NCIF_NPA_Date),103) NPA_Date 
      FROM NPA_IntegrationDetails
	  WHERE  NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
	  AND isnull(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NPA_IntegrationDetails.NCIF_AssetClassAlt_Key)=1  -------6 is removed As per Discussion with Shishir sir---16-11-2017
	  AND NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7)   -----6 is removed As per Discussion with Shishir sir---16-11-2017
	  )    

)TEMP


SELECT * INTO #TEMP2
FROM
(
SELECT 
NPA_IntegrationDetails.NCIF_Id,
NPA_IntegrationDetails.NCIF_AssetClassAlt_Key,
NPA_IntegrationDetails.MOC_AssetClassAlt_Key,
convert( varchar(25),ISNULL(MOC_NPA_Date,NPA_IntegrationDetails.NCIF_NPA_Date),103)NPADATE
FROM NPA_IntegrationDetails
WHERE  NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
AND NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7)
AND isnull(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NPA_IntegrationDetails.NCIF_AssetClassAlt_Key)=1
)TEMP2

SELECT * INTO #TEMP3
FROM
(

SELECT
CASA_NPA_IntegrationDetails.NCIF_Id,
 CASA_NPA_IntegrationDetails.CustomerId,
CASA_NPA_IntegrationDetails.CustomerName,
CASA_NPA_IntegrationDetails.CustomerACID,
CASA_NPA_IntegrationDetails.ProductType	,
ISNULL(CASA_NPA_IntegrationDetails.SanctionedLimit,0)/@Cost SanctionedLimit ,
ISNULL(CASA_NPA_IntegrationDetails.ActualOutStanding,0)/@Cost ActualOutStanding,
CASA_NPA_IntegrationDetails.SrcSysAlt_Key
FROM CASA_NPA_IntegrationDetails
WHERE  CASA_NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND CASA_NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
)TEMP3


SELECT * INTO #NPA_Integration

FROM

(

SELECT 

DISTINCT

NPA_IntegrationDetails.NCIF_Id										AS 'NCIF'

---------------------------------SOURCE SYSTEM----------------------------------------
,DimSourceSystem1.SourceName										AS 'SourceSystem'

,NPA_IntegrationDetails.CustomerId									AS 'NPA_CustomerID'

,NPA_IntegrationDetails.CustomerName								AS 'CustomerName'

,NPA_IntegrationDetails.CustomerACID								AS 'NPA_ACID'

--,NPA_IntegrationDetails.PAN	 										AS 'PAN'

,NPA_IntegrationDetails.ProductType									AS 'Facility'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost				AS 'Limit'

,ISNULL(MOCASSET.AssetClassName ,NCIFASSET.AssetClassName)			AS 'AssetClass'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost						AS 'Outstanding'

,NPA_Date		as 'NPA_Date'							

, 1																AS  'NPAFlag'
FROM  #TEMP   NPA_IntegrationDetails

INNER JOIN  CASA_NPA_IntegrationDetails				ON CASA_NPA_IntegrationDetails.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
													AND CASA_NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND CASA_NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
													


LEFT JOIN DimAssetClass NCIFASSET					ON NCIFASSET.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
													AND NCIFASSET.EffectiveFromTimeKey<=@TimeKey AND NCIFASSET.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass  MOCASSET                  ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										            AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey

INNER JOIN DimSourceSystem	DimSourceSystem1		ON  DimSourceSystem1.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
													AND DimSourceSystem1.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem1.EffectiveToTimeKey>=@TimeKey

INNER JOIN SysDataMatrix				          ON SysDataMatrix.TimeKey=@TimeKey

WHERE  
SysDataMatrix.PreProcessingFreeze='Y'
AND SysDataMatrix.PreProcessingFreezeBy IS NOT NULL
AND SysDataMatrix.PreProcessingFreezeDate IS NOT NULL
AND MOC_Freeze='Y'
AND MOC_FreezeBy IS NOT NULL
AND MOC_FreezeDate IS NOT NULL



--AND NPA_IntegrationDetails.NCIF_Id='1001252'

UNION ALL

SELECT 

DISTINCT

NPA_IntegrationDetails.NCIF_Id										AS 'NCIF'


--------------------------------------CASA SYSTEM-----------------------------------------

,DimSourceSystem2.SourceName										AS 'CASA_SourceSystem'

,CASA_NPA_IntegrationDetails.CustomerId								AS 'CASA_CustomerID'

,CASA_NPA_IntegrationDetails.CustomerName							AS 'CASA_CustomerName'

,CASA_NPA_IntegrationDetails.CustomerACID							AS 'CASA_ACID'

,CASA_NPA_IntegrationDetails.ProductType							AS 'CASA_Facility'

,ISNULL(CASA_NPA_IntegrationDetails.SanctionedLimit,0)/@Cost		AS 'CASA_Limit'

,ISNULL(MOCASSET.AssetClassName ,CASA_DimAssetClass.AssetClassName) AS 'CASA_AssetClass'

,ISNULL(CASA_NPA_IntegrationDetails.ActualOutStanding,0)/@Cost		AS 'CASA_Outstanding'

--,CASA_NPA_IntegrationDetails.PAN 									AS 'PAN'

,NPADATE															as 'NPA_Date'

,2																	AS 'CasaFlag'
FROM  #TEMP2 NPA_IntegrationDetails

 INNER JOIN  #TEMP3	CASA_NPA_IntegrationDetails			ON CASA_NPA_IntegrationDetails.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
														
													


LEFT JOIN DimAssetClass  CASA_DimAssetClass			ON CASA_DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
														AND CASA_DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND CASA_DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass  MOCASSET                        ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										                AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey


INNER JOIN DimSourceSystem	DimSourceSystem2			ON  DimSourceSystem2.SourceAlt_Key=CASA_NPA_IntegrationDetails.SrcSysAlt_Key
														AND DimSourceSystem2.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem2.EffectiveToTimeKey>=@TimeKey


INNER JOIN SysDataMatrix				                ON SysDataMatrix.TimeKey=@TimeKey

WHERE 	SysDataMatrix.PreProcessingFreeze='Y'
AND SysDataMatrix.PreProcessingFreezeBy IS NOT NULL
AND SysDataMatrix.PreProcessingFreezeDate IS NOT NULL
AND MOC_Freeze='Y'
AND MOC_FreezeBy IS NOT NULL
AND MOC_FreezeDate IS NOT NULL

)NPAINTEGRATION

SELECT * FROM #NPA_Integration
ORDER BY #NPA_Integration.NCIF,NPAFlag
----AND NPA_IntegrationDetails.NCIF_Id='1001252'
OPTION (RECOMPILE)

DROP TABLE #TEMP
DROP TABLE #TEMP2
DROP TABLE #TEMP3
DROP TABLE #NPA_Integration
GO