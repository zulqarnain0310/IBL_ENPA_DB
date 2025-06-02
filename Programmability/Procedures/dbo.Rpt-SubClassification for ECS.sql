SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

----------------/*
----------------ALTERd By :- Vedika
----------------ALTERd Date:-28/09/2017
----------------Report Name :-NPA Asset Sub-Classification for ECS (Derived Asset Classification)
----------------*/

CREATE  proc [dbo].[Rpt-SubClassification for ECS]
@DtEnter as varchar(20)
,@Cost as Float
,@NPA AS INT
AS

--DECLARE	
--@DtEnter as varchar(20)='31/01/2018'
--,@Cost AS FLOAT=1000
--,@NPA AS INT=0


DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
Print @TimeKey 


SELECT * FROM (SELECT 

NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


------------------------------Impact Source System-------------------------


,DimSourceSystem.SourceName										AS 'SourceSystem'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost					AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost							AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost					AS 'Drawingpower'

,NPA_IntegrationDetails.ProductCode		

,NPA_IntegrationDetails.ProductDesc

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost		AS 'POS'

,NPA_IntegrationDetails.MaxDPD									AS 'DP'

,NPA_IntegrationDetails.AC_AssetClassAlt_Key					AS 'ac_AssetClassAltKey'

,CONVERT(VARCHAR(20),NPA_IntegrationDetails.AC_NPA_Date,103)	AS 'NPADate'

,DimAssetClass.AssetClassName									AS 'DerivedAssetClassDesc'

,DimAssetClass.AssetClassShortNameEnum							AS 'AssetClassCode'

,case when 	 AgriFlag='N' 
	THEN  (CASE WHEN isnull(MaxDPD,0)>isnull(DPD_Renewals,0)	THEN (CASE WHEN isnull(MaxDPD,0)>90 
														THEN MaxDPD 
											END)
				WHEN isnull(MaxDPD,0)<isnull(DPD_Renewals,0) THEN (CASE WHEN isnull(DPD_Renewals,0)>180 
														THEN DPD_Renewals END)
	END )

	WHEN AgriFlag='Y' THEN  (  CASE WHEN isnull(MaxDPD,0)>isnull(DPD_Renewals,0) THEN  (CASE WHEN MaxDPD>365 THEN MaxDPD END)
								          WHEN isnull(DPD_Renewals,0)>isnull(MaxDPD,0) THEN (CASE WHEN isnull(DPD_Renewals,0)>180 THEN DPD_Renewals END)
									END )
	end												as dpd

FROM NPA_IntegrationDetails


INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										AND DimSourceSystem.SourceAlt_Key in (20,70)
										and (ISNULL(ActualOutStanding,0)>0 AND ISNULL(PrincipleOutstanding,0)<>0)
										----and ISNULL(NPA_IntegrationDetails.Balance,0)<>0

LEFT JOIN DimAssetClass				    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey



--WHERE CustomerId='1000004'

WHERE  (AC_AssetClassAlt_Key not in (1,7) and ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200)
)A

WHERE @NPA=0

UNION ALL

SELECT * FROM (SELECT 

NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'


------------------------------Impact Source System-------------------------


,DimSourceSystem.SourceName										AS 'SourceSystem'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost					AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost							AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost					AS 'Drawingpower'

,NPA_IntegrationDetails.ProductCode		

,NPA_IntegrationDetails.ProductDesc

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost		AS 'POS'

,NPA_IntegrationDetails.MaxDPD									AS 'DP'

,NPA_IntegrationDetails.AC_AssetClassAlt_Key					AS 'ac_AssetClassAltKey'

,CONVERT(VARCHAR(20),NPA_IntegrationDetails.AC_NPA_Date,103)	AS 'NPADate'

,DimAssetClass.AssetClassName									AS 'DerivedAssetClassDesc'

,DimAssetClass.AssetClassShortNameEnum							AS 'AssetClassCode'

,case when 	 AgriFlag='N' 
	THEN  (CASE WHEN isnull(MaxDPD,0)>isnull(DPD_Renewals,0)	THEN (CASE WHEN isnull(MaxDPD,0)>90 
														THEN MaxDPD 
											END)
				WHEN isnull(MaxDPD,0)<isnull(DPD_Renewals,0) THEN (CASE WHEN isnull(DPD_Renewals,0)>180 
														THEN DPD_Renewals END)
	END )

	WHEN AgriFlag='Y' THEN  (  CASE WHEN isnull(MaxDPD,0)>isnull(DPD_Renewals,0) THEN  (CASE WHEN MaxDPD>365 THEN MaxDPD END)
								          WHEN isnull(DPD_Renewals,0)>isnull(MaxDPD,0) THEN (CASE WHEN isnull(DPD_Renewals,0)>180 THEN DPD_Renewals END)
									END )
	end          as dpd

FROM NPA_IntegrationDetails


INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										AND DimSourceSystem.SourceAlt_Key in (20,70)
										and (ISNULL(ActualOutStanding,0)>0 AND ISNULL(PrincipleOutstanding,0)<>0)
										----and ISNULL(NPA_IntegrationDetails.Balance,0)<>0

LEFT JOIN DimAssetClass				    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

--WHERE CustomerId='1000004'

WHERE ( AC_AssetClassAlt_Key not in (1,7) and ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200)

AND (NPA_IntegrationDetails.AC_AssetClassAlt_Key<>7
AND (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)<>1
	  OR  (ISNULL(MOC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key)=1
     
	      AND 

 CASE WHEN  AgriFlag='N' and ( ISNULL(MaxDPD,0)>90  OR ISNULL(DPD_Renewals,0)>180) THEN 1
									
	   WHEN AgriFlag='Y' and	(ISNULL(MaxDPD,0)>365 OR   ISNULL(DPD_Renewals,0)>180) tHeN 1							
											
								END =1 
		)
     )
     )
)B

WHERE @NPA=1

ORDER BY NCIF

OPTION(RECOMPILE)



GO