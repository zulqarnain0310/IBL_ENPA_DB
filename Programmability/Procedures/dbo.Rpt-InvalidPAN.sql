SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



CREATE  proc [dbo].[Rpt-InvalidPAN]
@DtEnter as varchar(20)
,@Cost AS FLOAT
,@DimsourceSystem as int
,@NPA AS INT
AS

--DECLARE	

--@DtEnter as varchar(20)='30/09/2017'
--,@Cost AS FLOAT=1000
--,@DimsourceSystem as int=40
--,@NPA AS INT=0


DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 

SELECT * FROM 

(

SELECT 


DimSourceSystem.SourceName													AS 'SourceSystem'


,NPA_IntegrationDetails.NCIF_Id												AS 'NCIF'


,NPA_IntegrationDetails.CustomerID											AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName										AS 'CustomerName'


,NPA_IntegrationDetails.PAN													AS 'PAN'

,NPA_IntegrationDetails.ProductType											AS 'Facility'

,case when len(CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end											AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost						AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost								AS 'Outstanding'

,NPA_IntegrationDetails.AC_AssetClassAlt_Key

,ISNULL(MOCASSET.AssetClassName,DimAssetClass.AssetClassName)				AS 'ASSETCLASS'

,ISNULL(CAST(NPA_IntegrationDetails.NCIF_NPA_Date AS varchar(25)),'NA')		AS 'NPADATE'

,ISNULL(NPA_IntegrationDetails.DrawingPower	,0)/@Cost						AS 'DP'

,ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)                              AS 'DPD_Renewals'
 
,ISNULl(NPA_IntegrationDetails.MaxDPD,0)                                    AS 'MaxDPD'

,ISNULL(NPA_IntegrationDetails.SubSegment,'NA')											AS 'SEGMENT'

,NPA_IntegrationDetails.ProductAlt_Key

FROM NPA_IntegrationDetails


INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										AND isnull(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'') <>7 
										and isnull(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200

LEFT JOIN DimAssetClass				   ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey




WHERE 

(DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)

AND 

((len(PAN)=10 AND (left(PAN,5 ) NOT like'%[A-Z]%' OR substring(PAN,6,4) NOT  like'%[0-9]%'OR  right(PAN,1)NOT  like'%[A-Z]%' )))

and ( PAN NOT LIKE 'form%'  AND Pan Not like 'from%' )-------------------------as per discussion with shishir sir --26/10/2017                           


)A
WHERE  @NPA=0

UNION ALL


SELECT * FROM 

(

SELECT 


DimSourceSystem.SourceName													AS 'SourceSystem'


,NPA_IntegrationDetails.NCIF_Id												AS 'NCIF'


,NPA_IntegrationDetails.CustomerID											AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName										AS 'CustomerName'


,NPA_IntegrationDetails.PAN													AS 'PAN'

,NPA_IntegrationDetails.ProductType											AS 'Facility'

,case when len(CustomerACID)=16
				then '''' +NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end											AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost						AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost								AS 'Outstanding'

,NPA_IntegrationDetails.AC_AssetClassAlt_Key

,ISNULL(MOCASSET.AssetClassName,DimAssetClass.AssetClassName)				AS 'ASSETCLASS'

,ISNULL(CAST(NPA_IntegrationDetails.NCIF_NPA_Date AS varchar(25)),'NA')		AS 'NPADATE'

,ISNULL(NPA_IntegrationDetails.DrawingPower	,0)/@Cost						AS 'DP'

,ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)                              AS 'DPD_Renewals'
 
,ISNULL(NPA_IntegrationDetails.MaxDPD,0)                                      AS 'MaxDPD'

,NPA_IntegrationDetails.SubSegment											AS 'SEGMENT'

,NPA_IntegrationDetails.ProductAlt_Key			
FROM NPA_IntegrationDetails


INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										AND isnull(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'') <>7 
										AND isnull(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200

LEFT JOIN DimAssetClass				    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey



WHERE 

(DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)
AND 

((len(PAN)=10 AND (left(PAN,5 ) NOT like'%[A-Z]%' OR substring(PAN,6,4) NOT  like'%[0-9]%'OR  right(PAN,1)NOT  like'%[A-Z]%' )))

and ( PAN NOT LIKE 'form%'  AND Pan Not like 'from%' )-------------------------as per discussion with shishir sir --26/10/2017                           
AND (NPA_IntegrationDetails.AC_AssetClassAlt_Key<>7
AND (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)<>1
	  OR  (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)=1
     
	      and 
	    (  CASE WHEN  AgriFlag='N' and ( ISNULL(NPA_IntegrationDetails.MaxDPD,0)>90  OR ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)>180) THEN 1
									
	   WHEN AgriFlag='Y' and	(ISNULL(NPA_IntegrationDetails.MaxDPD,0)>365 OR   ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)>180) tHeN 1							
											
								END =1 )
		)
     )
     )

)A
WHERE  @NPA=1

 

ORDER BY NCIF

option(recompile)


GO