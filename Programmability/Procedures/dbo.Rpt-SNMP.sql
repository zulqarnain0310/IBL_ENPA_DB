SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

--------------------------------------------NEED TO DEPLOY---------------
----------------------/*
----------------------Created By :- Vedika
----------------------Created Date:-26/09/2017
----------------------Report Name :- Single NCIF multiple PAN
----------------------*/

CREATE Proc [dbo].[Rpt-SNMP]
@DtEnter as varchar(20)
,@Cost as Float
,@DimsourceSystem as int
,@NPA AS INT
AS

--DECLARE	
--@DtEnter as varchar(20)='30/09/2017'
--,@Cost AS FLOAT=1
--,@DimsourceSystem as int=40
--,@NPA AS INT=0

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 

select * into #TEMP2
from
(
select 

DISTINCT 
DimSourceSystem.SourceName										AS 'SourceSystem'


,PAN_MismatchDetails.NCIF										AS 'NCIF'


,PAN_MismatchDetails.CustomerID									AS 'CustomerID'


,PAN_MismatchDetails.CustomerName								AS 'CustomerName'


,PAN_MismatchDetails.PAN										AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(CustomerACID)=16
				then  + '''' +NPA_IntegrationDetails.CustomerACID+ '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost			AS 'DP'

,ISNULL(NPA_IntegrationDetails.SubSegment,'NA')					AS 'Segment'

,NPA_IntegrationDetails.AC_AssetClassAlt_Key
,ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)           AS 'FinalAsset'

,ISNULL(MOCASSET.AssetClassName,DimAssetClass.AssetClassName)	AS 'ASSETCLASS'

,ISNULL(MaxDPD,0)                                               AS 'MaxDPD'
,ISNULL(DPD_Renewals,0)                                         AS 'DPD_Renewals'
 from

PAN_MismatchDetails 

INNER JOIN NPA_IntegrationDetails		ON NPA_IntegrationDetails.NCIF_Id=PAN_MismatchDetails.NCIF
										AND NPA_IntegrationDetails.CustomerId=PAN_MismatchDetails.CustomerID
										AND NPA_IntegrationDetails.PAN=PAN_MismatchDetails.PAN
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										and PAN_MismatchDetails.TimeKey=@TimeKey
										--and isnull(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7   Commented on 27022020 for New modifications
										--and isnull(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200
										AND (Case When NPA_IntegrationDetails.AC_AssetClassAlt_Key in (1,2,3,4,5,6) Then 1
												  When  isnull(NPA_IntegrationDetails.writeoffdate,'1900-01-01')>='2019-04-01' and isnull(NPA_IntegrationDetails.WriteOffFlag,'N')='Y' then 1 else 0 end)=1

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.SourceAlt_Key=PAN_MismatchDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass				   ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey



where ( PAN_MismatchDetails.SrcSysAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)

--AND NCIF_Id='1308854'
)temp2



SELECT * into #ALL FROM 

(

SELECT  DISTINCT  
#TEMP2.SourceSystem,
#TEMP2.NCIF,
#TEMP2.CustomerID,
#TEMP2.CustomerName,
#TEMP2.Facility,
#TEMP2.[Account No.],
#TEMP2.Limit,
#TEMP2.Outstanding,
#TEMP2.PAN,
#TEMP2.DP,
#TEMP2.Segment,
#TEMP2.AC_AssetClassAlt_Key,
#TEMP2.FinalAsset,
#TEMP2.MaxDPD,
#TEMP2.DPD_Renewals,
#TEMP2.ASSETCLASS

FROM #TEMP2

INNER JOIN NPA_IntegrationDetails		on NPA_IntegrationDetails.NCIF_Id=#TEMP2.NCIF
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										--and isnull(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7
										--and isnull(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200
										AND (Case When NPA_IntegrationDetails.AC_AssetClassAlt_Key in (1,2,3,4,5,6) Then 1
												  When  isnull(NPA_IntegrationDetails.writeoffdate,'1900-01-01')>='2019-04-01' and isnull(NPA_IntegrationDetails.WriteOffFlag,'N')='Y' then 1 else 0 end)=1

INNER JOIN PAN_MismatchDetails			ON PAN_MismatchDetails.NCIF=#TEMP2.NCIF
										and PAN_MismatchDetails.TimeKey=@TimeKey

--WHERE #TEMP2.NCIF='10041368'
INNER JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

union all 

SELECT

DISTINCT
 
DimSourceSystem.SourceName,

NPA_IntegrationDetails.NCIF_Id,

NPA_IntegrationDetails.CustomerID,

NPA_IntegrationDetails.CustomerName,

NPA_IntegrationDetails.ProductType  Facility,

NPA_IntegrationDetails.CustomerACID    [Account No.],

ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost  Limit ,

ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost   Outstanding  ,

NPA_IntegrationDetails.PAN,

ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost    DP ,

NPA_IntegrationDetails.SubSegment  Segment,
NPA_IntegrationDetails.AC_AssetClassAlt_Key,

ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)    AS FinalAsset,
NPA_IntegrationDetails.MaxDPD,
NPA_IntegrationDetails.DPD_Renewals,
ISNULL(MOCASSET.AssetClassName,DimAssetClass.AssetClassName)	    ASSETCLASS
					

FROM #TEMP2

INNER JOIN  NPA_IntegrationDetails		on NPA_IntegrationDetails.NCIF_Id=#TEMP2.NCIF
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										--and isnull(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7
										--and isnull(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200
										AND (Case When NPA_IntegrationDetails.AC_AssetClassAlt_Key in (1,2,3,4,5,6) Then 1
												  When  isnull(NPA_IntegrationDetails.writeoffdate,'1900-01-01')>='2019-04-01' and isnull(NPA_IntegrationDetails.WriteOffFlag,'N')='Y' then 1 else 0 end)=1

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										--AND DimSourceSystem.SourceAlt_Key=PAN_MismatchDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

INNER JOIN PAN_MismatchDetails			ON PAN_MismatchDetails.NCIF=#TEMP2.NCIF
										AND PAN_MismatchDetails.TimeKey=@TimeKey


LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass				   ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	



WHERE --#TEMP2.NCIF='10017281' AND
 (NPA_IntegrationDetails.SrcSysAlt_Key<>@DimsourceSystem AND @DimsourceSystem<>0 )

--ORDER BY #TEMP2.NCIF

)A

select * from #ALL
WHERE @NPA=0

UNION ALL

SELECT * FROM 

(

SELECT  DISTINCT  
#TEMP2.SourceSystem,
#TEMP2.NCIF,
#TEMP2.CustomerID,
#TEMP2.CustomerName,
#TEMP2.Facility,
#TEMP2.[Account No.],
#TEMP2.Limit,
#TEMP2.Outstanding,
#TEMP2.PAN,
#TEMP2.DP,
#TEMP2.Segment,
#TEMP2.AC_AssetClassAlt_Key,
#TEMP2.FinalAsset,
#TEMP2.MaxDPD,
#TEMP2.DPD_Renewals,
#TEMP2.ASSETCLASS

FROM #TEMP2

INNER JOIN NPA_IntegrationDetails		on NPA_IntegrationDetails.NCIF_Id=#TEMP2.NCIF
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										--and isnull(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7
										--and isnull(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200
										AND (Case When NPA_IntegrationDetails.AC_AssetClassAlt_Key in (1,2,3,4,5,6) Then 1
												  When  isnull(NPA_IntegrationDetails.writeoffdate,'1900-01-01')>='2019-04-01' and isnull(NPA_IntegrationDetails.WriteOffFlag,'N')='Y' then 1 else 0 end)=1

INNER JOIN PAN_MismatchDetails			ON PAN_MismatchDetails.NCIF=#TEMP2.NCIF
										AND PAN_MismatchDetails.TimeKey=@TimeKey

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey



WHERE 
 --(ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key) <>1
  (#TEMP2.AC_AssetClassAlt_Key=7
OR (FinalAsset<>1
	  OR  (FinalAsset=1
     
		and 
	  (CASE WHEN  AgriFlag='N' and ( ISNULL(#TEMP2.MaxDPD,0)>90  OR ISNULL(#TEMP2.DPD_Renewals,0)>180) THEN 1
									
		   WHEN AgriFlag='Y' and	(ISNULL(#TEMP2.MaxDPD,0)>365 OR   ISNULL(#TEMP2.DPD_Renewals,0)>180) tHeN 1							
											
	    END =1) 
		)
     )
	 )
	 
UNION ALL 

SELECT

DISTINCT
 
 
DimSourceSystem.SourceName,

NPA_IntegrationDetails.NCIF_Id,

NPA_IntegrationDetails.CustomerID,

NPA_IntegrationDetails.CustomerName,

NPA_IntegrationDetails.ProductType  Facility,

NPA_IntegrationDetails.CustomerACID   [Account No.],

ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost   Limit ,

ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost   Outstanding  ,

NPA_IntegrationDetails.PAN,

ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost     DP,

NPA_IntegrationDetails.SubSegment    Segment,

NPA_IntegrationDetails.AC_AssetClassAlt_Key,

ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)    AS FinalAsset,

NPA_IntegrationDetails.MaxDPD,

NPA_IntegrationDetails.DPD_Renewals,

#TEMP2.ASSETCLASS
					
FROM #TEMP2

INNER JOIN  NPA_IntegrationDetails		on NPA_IntegrationDetails.NCIF_Id=#TEMP2.NCIF
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										--and isnull(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7
										--and isnull(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200
										AND (Case When NPA_IntegrationDetails.AC_AssetClassAlt_Key in (1,2,3,4,5,6) Then 1
												  When  isnull(NPA_IntegrationDetails.writeoffdate,'1900-01-01')>='2019-04-01' and isnull(NPA_IntegrationDetails.WriteOffFlag,'N')='Y' then 1 else 0 end)=1

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										--AND DimSourceSystem.SourceAlt_Key=PAN_MismatchDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

INNER JOIN PAN_MismatchDetails			ON PAN_MismatchDetails.NCIF=#TEMP2.NCIF
										AND PAN_MismatchDetails.TimeKey=@TimeKey

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey


LEFT JOIN DimAssetClass				   ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	



WHERE --#TEMP2.NCIF='10017281' AND
 (NPA_IntegrationDetails.SrcSysAlt_Key<>@DimsourceSystem AND @DimsourceSystem<>0 ) 

 --AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key) <>1
 AND (#TEMP2.AC_AssetClassAlt_Key=7
OR FinalAsset<>1
	  OR  (FinalAsset=1
     
	    	and 
	  (CASE WHEN  AgriFlag='N' and ( ISNULL(#TEMP2.MaxDPD,0)>90  OR ISNULL(#TEMP2.DPD_Renewals,0)>180) THEN 1
									
		   WHEN AgriFlag='Y' and	(ISNULL(#TEMP2.MaxDPD,0)>365 OR   ISNULL(#TEMP2.DPD_Renewals,0)>180) tHeN 1							
											
	    END =1) 
	)
    )
	

)B


WHERE @NPA=1

ORDER BY NCIF,PAN

OPTION(RECOMPILE)
drop table #TEMP2
DROP TABLE #ALL





GO