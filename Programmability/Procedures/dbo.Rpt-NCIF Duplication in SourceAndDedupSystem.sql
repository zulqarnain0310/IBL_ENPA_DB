SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE  proc [dbo].[Rpt-NCIF Duplication in SourceAndDedupSystem]
@DtEnter as varchar(20)
,@Cost as Float
,@NPA AS INT
AS

--DECLARE	
--@DtEnter as varchar(20)='31/03/2018'
--,@Cost AS FLOAT=1000
--,@NPA AS INT=0

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 

IF OBJECT_ID('TEMPDB..#TEMP')IS NOT NULL
DROP TABLE #TEMP

select * into #temp from
(
SELECT 
distinct 

DimSourceSystem.SourceName                                      AS SourceName

,NCIF															AS 'NCIF'

,ClientID_NCIF_MismatchDetails.CustomerID						AS 'CustomerID'

,NPA_IntegrationDetails.CustomerName                            as 'CustomerName'

,ClientID_NCIF_MismatchDetails.PAN								AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost			AS 'DP'

,ISNULL(NPA_IntegrationDetails.SubSegment,'NA')					AS 'Segment'

,NPA_IntegrationDetails.AC_AssetClassAlt_Key                    AS 'FinalAsset'

,CONVERT(VARCHAR(20),isnull(NPA_IntegrationDetails.MOC_NPA_Date,NCIF_NPA_Date),105)  AS 'NCIF_NPA_Date'

,ISNULL(MOCASSET.AssetClassName,DimAssetClass.AssetClassName)	AS 'ASSETCLASS'

,ISNULL(MaxDPD,0)                                               AS 'MaxDPD'
,ISNULL(DPD_Renewals,0)                                         AS 'DPD_Renewals'



FROM ClientID_NCIF_MismatchDetails

INNER JOIN NPA_IntegrationDetails		 ON --NPA_IntegrationDetails.NCIF_Id=ClientID_NCIF_MismatchDetails.NCIF 
										 NPA_IntegrationDetails.CustomerId=ClientID_NCIF_MismatchDetails.CustomerID
										 AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey 
										 AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										 and NPA_IntegrationDetails.NCIF_AssetClassAlt_Key IS NOT NULL
										 and ISNULL(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7  
										 and ISNULL(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200

LEFT JOIN DimSourceSystem				ON  --DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
									    DimSourceSystem.SourceAlt_Key=ClientID_NCIF_MismatchDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass				    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey



where  ClientID_NCIF_MismatchDetails.TimeKey=@TimeKey


AND ((ISNULL(MOC_AssetClassAlt_Key,'')<>1 OR ISNULL(NCIF_AssetClassAlt_Key,'')<>1)
	  OR  (ISNULL(MOC_AssetClassAlt_Key,'')=1 or ISNULL(NCIF_AssetClassAlt_Key,'')=1
     
	      AND 

	  (CASE WHEN  AgriFlag='N' and ( ISNULL(MaxDPD,0)>90  OR ISNULL(DPD_Renewals,0)>180) THEN 1
									
		   WHEN AgriFlag='Y' and	(ISNULL(MaxDPD,0)>365 OR   ISNULL(DPD_Renewals,0)>180) tHeN 1							
											
	END =1 )
		)
     )
)A

OPTION(RECOMPILE)

select * from #temp  where FinalAsset is not null and FinalAsset <>1 and @NPA=1


union all



SELECT 
distinct 

DimSourceSystem.SourceName                                      AS SourceName

,NCIF															AS 'NCIF'

,ClientID_NCIF_MismatchDetails.CustomerID						AS 'CustomerID'

,NPA_IntegrationDetails.CustomerName                            as 'CustomerName'

,ClientID_NCIF_MismatchDetails.PAN								AS 'PAN'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost			AS 'DP'

,ISNULL(NPA_IntegrationDetails.SubSegment,'NA')					AS 'Segment'

,NPA_IntegrationDetails.AC_AssetClassAlt_Key                    AS 'FinalAsset'

,CONVERT(VARCHAR(20),isnull(NPA_IntegrationDetails.MOC_NPA_Date,NCIF_NPA_Date),105)  AS 'NCIF_NPA_Date'

,ISNULL(MOCASSET.AssetClassName,DimAssetClass.AssetClassName)	AS 'ASSETCLASS'

,ISNULL(MaxDPD,0)                                               AS 'MaxDPD'
,ISNULL(DPD_Renewals,0)                                         AS 'DPD_Renewals'



FROM ClientID_NCIF_MismatchDetails

INNER JOIN NPA_IntegrationDetails		 ON --NPA_IntegrationDetails.NCIF_Id=ClientID_NCIF_MismatchDetails.NCIF 
										 NPA_IntegrationDetails.CustomerId=ClientID_NCIF_MismatchDetails.CustomerID
										 AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey 
										 AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										 and NPA_IntegrationDetails.NCIF_AssetClassAlt_Key IS NOT NULL
										and ISNULL(NPA_IntegrationDetails.AC_AssetClassAlt_Key,'')<>7  
										 and ISNULL(NPA_IntegrationDetails.ProductAlt_Key,'')<>3200


LEFT JOIN DimSourceSystem				ON  --DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
									    DimSourceSystem.SourceAlt_Key=ClientID_NCIF_MismatchDetails.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass				    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass MOCASSET	    ON MOCASSET.AssetClassAlt_Key=NPA_IntegrationDetails.MOC_AssetClassAlt_Key
										AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey	

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

where  ClientID_NCIF_MismatchDetails.TimeKey=@TimeKey and  @NPA=0
order by CustomerID

OPTION(RECOMPILE)

drop table #temp

GO