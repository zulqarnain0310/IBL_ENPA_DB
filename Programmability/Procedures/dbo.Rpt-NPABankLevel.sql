SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By   :- Vedika
Created Date :- 02/11/2017
Modified DataL- 14/06/2018
Report Name :- BANK LEVEL NPA
*/

CREATE PROC [dbo].[Rpt-NPABankLevel]
@DtEnter as varchar(20)
,@Cost as Float
,@DimsourceSystem as int
,@NCIFAssetClass as int
AS


--DECLARE	
--@DtEnter as varchar(20)='31/05/2021'
--,@Cost AS FLOAT=1
--,@DimsourceSystem as int=0
--,@NCIFAssetClass as int=0


DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)


IF OBJECT_ID('TEMPDB..#BANK')IS NOT NULL
DROP TABLE #BANK

SELECT 
 
DimSourceSystem.SourceName										AS 'SourceSystem'


,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'


,NPA_IntegrationDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(NPA_IntegrationDetails.CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISnull(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISnull(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,ISnull(NPA_IntegrationDetails.DrawingPower,0)/@Cost			AS 'DP'

,DimProduct.ProductCode											AS 'ProductCode'

,DimProduct.ProductName										    AS 'ProudctDescription'

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost	as 'POS'

,NPA_IntegrationDetails.MaxDPD                                  AS  'MaxDPD'

,NPA_IntegrationDetails.DPD_Renewals                            AS  'DPD_Renewals'

,NPA_IntegrationDetails.SubSegment								AS 'Segment'

,DimAssetClass.AssetClassName	                                AS 'ACASSET'

,convert(varchar(20),NPA_IntegrationDetails.AC_NPA_Date,103)	AS 'AC_NPADate'


,ISNULL(MOCASSET.AssetClassName ,NCIFASSET.AssetClassName)   	AS 'NCIFASSET'

,CONVERT(varchar(20),case when MOCASSET.AssetClassAlt_Key=1
	 then MOC_NPA_Date
	 else ISNULL(MOC_NPA_Date,NCIF_NPA_Date)
	 end
,103)	                                                        AS 'NCIF_NPADate'

,NPA_IntegrationDetails.SrcSysAlt_Key
,ActualOutStanding
,PrincipleOutstanding
,ActualPrincipleOutstanding
,CUSTOMER_IDENTIFIER
,Balance
FROM  NPA_IntegrationDetails		
										

INNER JOIN DimAssetClass				ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										AND DimAssetClass.AssetClassAlt_Key<>7
										and ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200
										----AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0

INNER JOIN DimAssetClass NCIFASSET		ON NCIFASSET.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND NCIFASSET.EffectiveFromTimeKey<=@TimeKey AND NCIFASSET.EffectiveToTimeKey>=@TimeKey
										AND NCIFASSET.AssetClassAlt_Key<>7

LEFT JOIN DimAssetClass  MOCASSET      ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey
                                        AND MOCASSET.AssetClassAlt_Key<>7
										
INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										AND  ( DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)


INNER JOIN SysDataMatrix				 ON SysDataMatrix.TimeKey=@TimeKey

LEFT JOIN DimProduct				  ON DimProduct.ProductCode=NPA_IntegrationDetails.ProductCode
										AND DimProduct.EffectiveFromTimeKey<=@TimeKey AND DimProduct.EffectiveToTimeKey>=@TimeKey

WHERE 
isnull(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key) IN (2,3,4,5,6)
AND((Isnull(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NPA_IntegrationDetails.NCIF_AssetClassAlt_Key)=@NCIFAssetClass) OR @NCIFAssetClass=0)
----AND NCIF_Id='13420751'
AND	SysDataMatrix.PreProcessingFreeze='Y'
AND SysDataMatrix.PreProcessingFreezeBy IS NOT NULL
AND SysDataMatrix.PreProcessingFreezeDate IS NOT NULL
AND MOC_Freeze='Y'
AND MOC_FreezeBy IS NOT NULL
AND MOC_FreezeDate IS NOT NULL

UNION ALL

SELECT 
 
DimSourceSystem.SourceName										AS 'SourceSystem'


,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'


,NPA_IntegrationDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(NPA_IntegrationDetails.CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISnull(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISnull(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,ISnull(NPA_IntegrationDetails.DrawingPower,0)/@Cost			AS 'DP'

,DimProduct.ProductCode											AS 'ProductCode'

,DimProduct.ProductName										    AS 'ProudctDescription'

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost	as 'POS'

,NPA_IntegrationDetails.MaxDPD                                  AS  'MaxDPD'

,NPA_IntegrationDetails.DPD_Renewals                            AS  'DPD_Renewals'

,NPA_IntegrationDetails.SubSegment								AS 'Segment'

,DimAssetClass.AssetClassName	                                AS 'ACASSET'

,convert(varchar(20),NPA_IntegrationDetails.AC_NPA_Date,103)	AS 'AC_NPADate'


,ISNULL(MOCASSET.AssetClassName ,NCIFASSET.AssetClassName)   	AS 'NCIFASSET'

,CONVERT(varchar(20),case when MOCASSET.AssetClassAlt_Key=1
	 then MOC_NPA_Date
	 else ISNULL(MOC_NPA_Date,NCIF_NPA_Date)
	 end
,103)	                                                        AS 'NCIF_NPADate'

,NPA_IntegrationDetails.SrcSysAlt_Key
,ActualOutStanding
,PrincipleOutstanding
,ActualPrincipleOutstanding
,CUSTOMER_IDENTIFIER
,Balance
FROM  NPA_IntegrationDetails		
										

INNER JOIN DimAssetClass				ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										AND DimAssetClass.AssetClassAlt_Key<>7
										and ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200
										----AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0
										AND CUSTOMER_IDENTIFIER='C'

INNER JOIN DimAssetClass NCIFASSET		ON NCIFASSET.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND NCIFASSET.EffectiveFromTimeKey<=@TimeKey AND NCIFASSET.EffectiveToTimeKey>=@TimeKey
										AND NCIFASSET.AssetClassAlt_Key<>7

LEFT JOIN DimAssetClass  MOCASSET      ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey
                                        AND MOCASSET.AssetClassAlt_Key<>7
										
INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										AND   ( @DimsourceSystem=11 )


INNER JOIN SysDataMatrix				 ON SysDataMatrix.TimeKey=@TimeKey

LEFT JOIN DimProduct				  ON DimProduct.ProductCode=NPA_IntegrationDetails.ProductCode
										AND DimProduct.EffectiveFromTimeKey<=@TimeKey AND DimProduct.EffectiveToTimeKey>=@TimeKey

WHERE 
isnull(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key) IN (2,3,4,5,6)
AND((Isnull(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NPA_IntegrationDetails.NCIF_AssetClassAlt_Key)=@NCIFAssetClass) OR @NCIFAssetClass=0)
----AND NCIF_Id='13420751'
AND	SysDataMatrix.PreProcessingFreeze='Y'
AND SysDataMatrix.PreProcessingFreezeBy IS NOT NULL
AND SysDataMatrix.PreProcessingFreezeDate IS NOT NULL
AND MOC_Freeze='Y'
AND MOC_FreezeBy IS NOT NULL
AND MOC_FreezeDate IS NOT NULL

UNION ALL

SELECT 
 
DimSourceSystem.SourceName										AS 'SourceSystem'


,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'


,NPA_IntegrationDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(NPA_IntegrationDetails.CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISnull(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISnull(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,ISnull(NPA_IntegrationDetails.DrawingPower,0)/@Cost			AS 'DP'

,DimProduct.ProductCode											AS 'ProductCode'

,DimProduct.ProductName										    AS 'ProudctDescription'

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost	as 'POS'

,NPA_IntegrationDetails.MaxDPD                                  AS  'MaxDPD'

,NPA_IntegrationDetails.DPD_Renewals                            AS  'DPD_Renewals'

,NPA_IntegrationDetails.SubSegment								AS 'Segment'

,DimAssetClass.AssetClassName	                                AS 'ACASSET'

,convert(varchar(20),NPA_IntegrationDetails.AC_NPA_Date,103)	AS 'AC_NPADate'


,ISNULL(MOCASSET.AssetClassName ,NCIFASSET.AssetClassName)   	AS 'NCIFASSET'

,CONVERT(varchar(20),case when MOCASSET.AssetClassAlt_Key=1
	 then MOC_NPA_Date
	 else ISNULL(MOC_NPA_Date,NCIF_NPA_Date)
	 end
,103)	                                                        AS 'NCIF_NPADate'

,NPA_IntegrationDetails.SrcSysAlt_Key
,ActualOutStanding
,PrincipleOutstanding
,ActualPrincipleOutstanding
,CUSTOMER_IDENTIFIER
,Balance
FROM  NPA_IntegrationDetails		
										

INNER JOIN DimAssetClass				ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										AND DimAssetClass.AssetClassAlt_Key<>7
										and ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200
										----AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0
										AND CUSTOMER_IDENTIFIER='R'

INNER JOIN DimAssetClass NCIFASSET		ON NCIFASSET.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND NCIFASSET.EffectiveFromTimeKey<=@TimeKey AND NCIFASSET.EffectiveToTimeKey>=@TimeKey
										AND NCIFASSET.AssetClassAlt_Key<>7

LEFT JOIN DimAssetClass  MOCASSET      ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey
                                        AND MOCASSET.AssetClassAlt_Key<>7
										
INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										AND   ( @DimsourceSystem=12 )


INNER JOIN SysDataMatrix				 ON SysDataMatrix.TimeKey=@TimeKey

LEFT JOIN DimProduct				  ON DimProduct.ProductCode=NPA_IntegrationDetails.ProductCode
										AND DimProduct.EffectiveFromTimeKey<=@TimeKey AND DimProduct.EffectiveToTimeKey>=@TimeKey

WHERE 
isnull(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key) IN (2,3,4,5,6)
AND((Isnull(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NPA_IntegrationDetails.NCIF_AssetClassAlt_Key)=@NCIFAssetClass) OR @NCIFAssetClass=0)
----AND NCIF_Id='13420751'
AND	SysDataMatrix.PreProcessingFreeze='Y'
AND SysDataMatrix.PreProcessingFreezeBy IS NOT NULL
AND SysDataMatrix.PreProcessingFreezeDate IS NOT NULL
AND MOC_Freeze='Y'
AND MOC_FreezeBy IS NOT NULL
AND MOC_FreezeDate IS NOT NULL

OPTION(RECOMPILE)
GO