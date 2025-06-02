SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
----------------/*
----------------Created By :- Vedika
----------------Created Date:-26/09/2017
----------------Report Name :-Written OFF and Loss Accounts
----------------*/
CREATE   Proc [dbo].[Rpt-WrittenOFF_Loss]
@DtEnter as varchar(20)
,@Cost AS FLOAT
AS

----DECLARE	
----@DtEnter as varchar(20)='31/12/2017'
----,@Cost AS FLOAT=1000

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
 (( AC_AssetClassAlt_Key=7 or ProductAlt_Key=3200) 
 and NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey and NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
--OR ( AC_AssetClassAlt_Key <>6 and NCIF_AssetClassAlt_Key=6)
)
	  
   --order by NCIF_Id   --106024
)TEMP


select 

ImpactedAccounts.NCIF_Id									AS  ENTCIF,

--------------------------------------IMPACTED ACCOUNTS-----------------------------------------

ImpactedAccounts.SourceName									AS  SOURCE ,
															
ImpactedAccounts.ProductType								AS FACILITY,
															
ImpactedAccounts.CustomerName								AS CUSTOMERNAME,
															
+'''' + ImpactedAccounts.CustomerId	+''''					AS ICustomerID

,ImpactedAccounts.PAN										AS IPAN
															
,case when len(ImpactedAccounts.CustomerACID)=16
				then '''' + ImpactedAccounts.CustomerACID + '''' 
				else ImpactedAccounts.CustomerACID
				end									AS IMPACTEDAccount
															
,ISNULL(ImpactedAccounts.SanctionedLimit,0)/@Cost			AS LIMIT,
															
ISNULL(ImpactedAccounts.Balance,0)/@Cost					AS BALANCE,

ISNULL(ImpactedAccounts.DrawingPower,0)/@Cost				AS IDP,

ImpactedAccounts.ProductCode								AS IPRODUCTCODE,

ImpactedAccounts.ProductDesc								AS IPRODUCTDESCRIPTION,

ISNULL(ImpactedAccounts.ActualPrincipleOutstanding,0)/@Cost		AS 'IPOS',
															
ImpactedAccounts.MaxDPD										AS DPD,

ImpactedAccounts.DPD_Renewals								AS DPD_Renewals,

ImpactedAccounts.SubSegment									AS ISegment,
															
ImpactedAccounts.AssetClassName								AS IAsset			
															
,ImpactedAccounts.AC_AssetClassAlt_Key						As IAssetAlt

,CONVERT(VARCHAR(25),ImpactedAccounts.AC_NPA_Date,103)		AS IAC_NPA_Date

-------------------------------------PERCULATED Accounts----------------------------

,PercolatedAccounts.SourceName								AS  PSOURCE ,

PercolatedAccounts.ProductType								AS PFACILITY,

PercolatedAccounts.CustomerName								AS PCUSTOMERNAME,

+''''+ PercolatedAccounts.CustomerId	 +''''				AS PCustomerID

,PercolatedAccounts.PAN										AS PPAN

,case when len(PercolatedAccounts.CustomerACID)=16
				then '''' + PercolatedAccounts.CustomerACID + '''' 
				else PercolatedAccounts.CustomerACID
				end											AS PAccount
										
,ISNULL(PercolatedAccounts.SanctionedLimit,0)/@Cost			AS PLIMIT,

ISNULL(PercolatedAccounts.Balance,0)/@Cost					AS PBALANCE,

ISNULL(PercolatedAccounts.DrawingPower,0)/@Cost				AS PDP,

PercolatedAccounts.ProductCode								AS PPRODUCTCODE,

PercolatedAccounts.ProductDesc								AS PPRODUCTDESCRIPTION,

ISNULL(PercolatedAccounts.ActualPrincipleOutstanding,0)/@Cost AS 'PPOS',

PercolatedAccounts.MaxDPD									AS PDPD,

PercolatedAccounts.DPD_Renewals								AS PDPD_Renewals,

PercolatedAccounts.SubSegment								AS PSegment,

PercolatedAccounts.AssetClassName							AS PAsset			

,PercolatedAccounts.AC_AssetClassAlt_Key					As PAssetAlt

,CONVERT(VARCHAR(25),PercolatedAccounts.AC_NPA_Date,103)	AS PAC_NPA_Date


 from  (SELECT 
		#TEMP.NCIF_Id,
		SourceName,
		ProductType,
		CustomerName,
		CustomerId,
		PAN,
		NPA_IntegrationDetails.CustomerACID,
		SanctionedLimit ,
		Balance,
		MaxDPD,
		SubSegment,
		DPD_Renewals,
		AssetClassName,
		NPA_IntegrationDetails.AC_AssetClassAlt_Key,
		AC_NPA_Date,
		ActualPrincipleOutstanding,
		DrawingPower,
		ProductCode,
		ProductDesc
 
		FROM #TEMP
 
		INNER JOIN NPA_IntegrationDetails				ON NPA_IntegrationDetails.NCIF_Id=#TEMP.NCIF_Id
														AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												

		INNER JOIN DimSourceSystem						ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
														AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
		
		INNER JOIN DimAssetClass						ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
														--AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

		WHERE (NPA_IntegrationDetails.AC_AssetClassAlt_Key=7 or NPA_IntegrationDetails.ProductAlt_Key=3200)
 
		)IMPACTEDACCOUNTS
 

INNER JOIN (SELECT 
		#TEMP.NCIF_Id,
		SourceName,
		ProductType,
		CustomerName,
		CustomerId,
		PAN,
		NPA_IntegrationDetails.CustomerACID,
		SanctionedLimit ,
		Balance,
		MaxDPD,
		SubSegment,
		DPD_Renewals,
		AssetClassName,
		NPA_IntegrationDetails.AC_AssetClassAlt_Key,
		AC_NPA_Date,
		ActualPrincipleOutstanding,
		DrawingPower,
		ProductCode,
		ProductDesc
 
		FROM #TEMP
 
		INNER JOIN NPA_IntegrationDetails				ON NPA_IntegrationDetails.NCIF_Id=#TEMP.NCIF_Id
														AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												

		INNER JOIN DimSourceSystem						ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
														AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
		
		INNER JOIN DimAssetClass						ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
														--AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

		 WHERE NPA_IntegrationDetails.AC_AssetClassAlt_Key  not in (7) and ProductAlt_Key<>3200
 
		)PercolatedAccounts							ON PercolatedAccounts.NCIF_Id=IMPACTEDACCOUNTS.NCIF_Id


--where PercolatedAccounts.NCIF_Id='1108173'

ORDER BY IMPACTEDACCOUNTS.NCIF_Id,IMPACTEDACCOUNTS.AC_AssetClassAlt_Key

OPTION (RECOMPILE)


DROP TABLE #TEMP



GO