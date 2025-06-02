SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By :- Vedika
Created Date:-26/09/2017
Report Name :- Single PAN multiple NCIF
      --17395
*/

CREATE  proc [dbo].[Rpt-SPMN]
@DtEnter as varchar(20)
,@Cost as Float
,@DimsourceSystem as int
,@NPA AS INT
AS


--DECLARE	
--@DtEnter as varchar(20)='31/03/2018'
--,@Cost AS FLOAT=1
--,@DimsourceSystem as int=0
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


,NCIF_MismatchDetails.NCIF										AS 'NCIF'


,NCIF_MismatchDetails.CustomerID								AS 'CustomerID'


,NCIF_MismatchDetails.CustomerName								AS 'CustomerName'


,NCIF_MismatchDetails.PAN										AS 'PAN'

,ISNULL(NPA_IntegrationDetails.ProductType,'')				   AS 'Facility'

,case when len(CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost			AS 'DP'

,ISNULL(NPA_IntegrationDetails.SubSegment,'NA')					AS 'Segment'

,NPA_IntegrationDetails.AC_AssetClassAlt_Key

,ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)           AS 'FinalAssetClass'

,ISNULL(MaxDPD,0)                                               AS MaxDPD
,ISNULL(DPD_Renewals,0)                                         AS DPD_Renewals
,ISNULL(MOCASSET.AssetClassName,DimAssetClass.AssetClassName)                                     AS AssetClassName

 from

NCIF_MismatchDetails 

INNER JOIN NPA_IntegrationDetails		ON NPA_IntegrationDetails.NCIF_Id=NCIF_MismatchDetails.NCIF
										AND NPA_IntegrationDetails.CustomerId=NCIF_MismatchDetails.CustomerID
										AND NPA_IntegrationDetails.PAN=NCIF_MismatchDetails.PAN
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										and NCIF_MismatchDetails.TimeKey=@TimeKey
										and isnull(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7
										and isnull(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND DimSourceSystem.SourceAlt_Key=NCIF_MismatchDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass				   ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	




where ( NCIF_MismatchDetails.SrcSysAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)

----AND NCIF_MismatchDetails.PAN='AAACB8943J'
)temp2


OPTION(RECOMPILE)

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
#TEMP2.FinalAssetClass,

ISNULL(#TEMP2.MaxDPD,0)                                        AS MaxDPD 
,ISNULL(#TEMP2.DPD_Renewals,0)                                  AS DPD_Renewals 
,ISNULL(#TEMP2.AssetClassName,'')                                  AS AssetClassName
FROM #TEMP2

INNER JOIN NPA_IntegrationDetails		on NPA_IntegrationDetails.PAN=#TEMP2.PAN
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										and isnull(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7
										and isnull(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200

INNER JOIN NCIF_MismatchDetails			ON NCIF_MismatchDetails.PAN=#TEMP2.PAN
										AND NCIF_MismatchDetails.TimeKey=@TimeKey
LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey


union all 

SELECT

DISTINCT
 
DimSourceSystem.SourceName,

NPA_IntegrationDetails.NCIF_Id,

NPA_IntegrationDetails.CustomerID,

NPA_IntegrationDetails.CustomerName,

NPA_IntegrationDetails.ProductType,

case when len(CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end							CustomerACID,

ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost SanctionedLimit ,

ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost  Balance  ,

NPA_IntegrationDetails.PAN,

ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost DrawingPower ,

ISNULL(NPA_IntegrationDetails.SubSegment,'NA')   SubSegment

,NPA_IntegrationDetails.AC_AssetClassAlt_Key

,ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)           AS 'FinalAssetClass'


,ISNULL(NPA_IntegrationDetails.MaxDPD,0)                                        AS MaxDPD 
,ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)                                  AS DPD_Renewals
,ISNULL(#TEMP2.AssetClassName,'')                                  AS AssetClassName

FROM #TEMP2

INNER JOIN  NPA_IntegrationDetails		on NPA_IntegrationDetails.PAN=#TEMP2.PAN
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										and isnull(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7
										and isnull(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										--AND DimSourceSystem.SourceAlt_Key=NCIF_MismatchDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

INNER JOIN NCIF_MismatchDetails			ON NCIF_MismatchDetails.PAN=#TEMP2.PAN
										AND NCIF_MismatchDetails.TimeKey=@TimeKey
LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey



WHERE -- #TEMP2.PAN='AAAAA1111A' AND
 (NPA_IntegrationDetails.SrcSysAlt_Key<>@DimsourceSystem AND @DimsourceSystem<>0 )

 )A
WHERE @NPA=0

UNION ALL


SELECT Distinct  * FROM 
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
#TEMP2.FinalAssetClass

,ISNULL(#TEMP2.MaxDPD,0)                                        AS MaxDPD 
,ISNULL(#TEMP2.DPD_Renewals,0)                                  AS DPD_Renewals 
,ISNULL(#TEMP2.AssetClassName,'')                                  AS AssetClassName
FROM #TEMP2

INNER JOIN NPA_IntegrationDetails		on NPA_IntegrationDetails.PAN=#TEMP2.PAN
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey					
										and isnull(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7
										and isnull(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200

INNER JOIN NCIF_MismatchDetails			ON NCIF_MismatchDetails.PAN=#TEMP2.PAN
										AND NCIF_MismatchDetails.TimeKey=@TimeKey


LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

--WHERE #TEMP2.NCIF='10041368'

WHERE 
 --(ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key) <>1
 (NPA_IntegrationDetails.SrcSysAlt_Key<>@DimsourceSystem OR @DimsourceSystem<>0 )
   AND (#TEMP2.AC_AssetClassAlt_Key<>7
AND (FinalAssetClass<>1
	  OR  (FinalAssetClass=1
     
	   and 
	  (CASE WHEN  AgriFlag='N' and ( ISNULL(#TEMP2.MaxDPD,0)>90  OR ISNULL(#TEMP2.DPD_Renewals,0)>180) THEN 1
									
		   WHEN AgriFlag='Y' and	(ISNULL(#TEMP2.MaxDPD,0)>365 OR   ISNULL(#TEMP2.DPD_Renewals,0)>180) tHeN 1							
											
	END =1 )
		
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

NPA_IntegrationDetails.ProductType,

case when len(CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end		CustomerACID,

ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost SanctionedLimit ,

ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost  Balance  ,

NPA_IntegrationDetails.PAN,

ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost DrawingPower ,

ISNULL(NPA_IntegrationDetails.SubSegment,'NA')
,NPA_IntegrationDetails.AC_AssetClassAlt_Key

,ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)           AS 'FinalAssetClass'


,ISNULL(NPA_IntegrationDetails.MaxDPD,0)                                        AS MaxDPD 
,ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)                                  AS DPD_Renewals
,ISNULL(#TEMP2.AssetClassName,'')                                  AS AssetClassName 


FROM #TEMP2

INNER JOIN  NPA_IntegrationDetails		on NPA_IntegrationDetails.PAN=#TEMP2.PAN
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										and isnull(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7
										and isnull(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200


INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										--AND DimSourceSystem.SourceAlt_Key=NCIF_MismatchDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

INNER JOIN NCIF_MismatchDetails			ON NCIF_MismatchDetails.PAN=#TEMP2.PAN
										AND NCIF_MismatchDetails.TimeKey=@TimeKey

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey



WHERE -- #TEMP2.PAN='AAAAA1111A' AND
 (NPA_IntegrationDetails.SrcSysAlt_Key<>@DimsourceSystem OR @DimsourceSystem<>0 )
   AND (#TEMP2.AC_AssetClassAlt_Key<>7
AND (FinalAssetClass<>1
	  OR  (FinalAssetClass=1
     and 
	    (  CASE WHEN  AgriFlag='N' and ( ISNULL(#TEMP2.MaxDPD,0)>90  OR ISNULL(#TEMP2.DPD_Renewals,0)>180) THEN 1
									
	   WHEN AgriFlag='Y' and	(ISNULL(#TEMP2.MaxDPD,0)>365 OR   ISNULL(#TEMP2.DPD_Renewals,0)>180) tHeN 1							
											
								END =1 )
		)
    )
	)
 )B

WHERE @NPA=1

order by PAN

OPTION(RECOMPILE)

DROP TABLE #TEMP2






GO