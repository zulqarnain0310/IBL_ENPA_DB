SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE Proc [dbo].[Rpt-WrittenOFF_Loss_SUB]
@DtEnter as varchar(20)
,@Cost AS FLOAT
,@NCIF as Varchar(25)
AS


--DECLARE	
--@DtEnter as varchar(20)='30/09/2017'
--,@Cost AS FLOAT=1000
--,@NCIF as Varchar(25)='4175283'

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 

SELECT * INTO #TEMP
 FROM

 (
 select NCIF_Id ,customeracid,AC_AssetClassAlt_Key,NCIF_AssetClassAlt_Key 
 from   NPA_IntegrationDetails
where 
 --(NCIF_Id='1068385') AND
 (( AC_AssetClassAlt_Key=7 and NCIF_AssetClassAlt_Key<>0) 
OR ( AC_AssetClassAlt_Key <>6 and NCIF_AssetClassAlt_Key=6))
	  
   --order by NCIF_Id   --106024
)TEMP

select

PercolatedAccounts.NCIF_Id									AS NCIF,

PercolatedAccounts.SourceName								AS  PSOURCE ,

PercolatedAccounts.ProductType								AS PFACILITY,

PercolatedAccounts.CustomerName								AS PCUSTOMERNAME,

PercolatedAccounts.CustomerId								AS PCustomerID

,PercolatedAccounts.PAN										AS PPAN

,PercolatedAccounts.CustomerACID							AS PAccount
										
,PercolatedAccounts.SanctionedLimit/@Cost					AS PLIMIT,

PercolatedAccounts.Balance/@Cost							AS PBALANCE,

PercolatedAccounts.DPD										AS PDPD,

PercolatedAccounts.AssetClassName								AS PAsset			

,PercolatedAccounts.AC_AssetClassAlt_Key					As PAssetAlt

,CONVERT(VARCHAR(25),PercolatedAccounts.AC_NPA_Date,103)	AS PAC_NPA_Date

From

(SELECT 
		#TEMP.NCIF_Id,
		SourceName,
		ProductType,
		CustomerName,
		CustomerId,
		PAN,
		NPA_IntegrationDetails.CustomerACID,
		SanctionedLimit ,
		Balance,
		DPD,
		AssetClassName,
		NPA_IntegrationDetails.AC_AssetClassAlt_Key,
		AC_NPA_Date
 
		FROM #TEMP
 
		INNER JOIN NPA_IntegrationDetails				ON NPA_IntegrationDetails.NCIF_Id=#TEMP.NCIF_Id
														AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												

		INNER JOIN DimSourceSystem						ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
														AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
		
		INNER JOIN DimAssetClass						ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
														AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

		 WHERE NPA_IntegrationDetails.AC_AssetClassAlt_Key  not in (6,7)
 
		)PercolatedAccounts							


where PercolatedAccounts.NCIF_Id=@NCIF

ORDER BY PercolatedAccounts.NCIF_Id,PercolatedAccounts.AC_AssetClassAlt_Key
GO