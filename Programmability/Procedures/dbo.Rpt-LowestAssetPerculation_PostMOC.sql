SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
ALTERd By :- Vedika
ALTERd Date:-28/09/2017
Report Name :- Lowest Asset Classification Percolation Report-Post MOC
*/

CREATE  proc [dbo].[Rpt-LowestAssetPerculation_PostMOC]
@DtEnter as varchar(20)
,@Cost as float
AS

--DECLARE	
--@DtEnter as varchar(20)='31/05/2021'
--,@Cost as float=1

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
Print @TimeKey 


IF OBJECT_ID('TEMPDB..#TEMP1') IS NOT NULL
 DroP TABLE #TEMP1


IF OBJECT_ID('TEMPDB..#TEMP') IS NOT NULL
 DroP TABLE #TEMP


SELECT * INTO #TEMP
FROM (
select 
DISTINCT 
NPA_IntegrationDetails.NCIF_Id,
		NPA_IntegrationDetails.ProductType,
		NPA_IntegrationDetails.CustomerName,
		NPA_IntegrationDetails.CustomerId,
		NPA_IntegrationDetails.PAN,
		NPA_IntegrationDetails.CustomerACID,
		NPA_IntegrationDetails.SanctionedLimit,
		NPA_IntegrationDetails.Balance,
		NPA_IntegrationDetails.MaxDPD,
		NPA_IntegrationDetails.DPD_Renewals,
		NPA_IntegrationDetails.SubSegment,
		NPA_IntegrationDetails_MOD.AC_AssetClassAlt_Key PreviousAssetClass,
		NPA_IntegrationDetails.AC_AssetClassAlt_Key ChangedAssetClass,
		NPA_IntegrationDetails_MOD.AC_NPA_Date PreviousNPADate
	   ,NPA_IntegrationDetails.AC_NPA_Date  ChangedNPADate
	   ,NPA_IntegrationDetails.SrcSysAlt_Key
	   ,NPA_IntegrationDetails.MOC_Status
	   ,NPA_IntegrationDetails.MOC_AssetClassAlt_Key
	   ,NPA_IntegrationDetails.MOC_NPA_Date 
		,NPA_IntegrationDetails.AstClsChngByUser
		,NPA_IntegrationDetails.ActualOutStanding
		,NPA_IntegrationDetails.PrincipleOutstanding
		,NPA_IntegrationDetails.ActualPrincipleOutstanding
		,NPA_IntegrationDetails.DrawingPower
		,NPA_IntegrationDetails.ProductCode
		,NPA_IntegrationDetails.CUSTOMER_IDENTIFIER
			
		from  NPA_IntegrationDetails

			LEFT JOIN NPA_IntegrationDetails_MOD		ON NPA_IntegrationDetails_MOD.NCIF_Id=NPA_IntegrationDetails.NCIF_Id	
														AND NPA_IntegrationDetails_MOD.CustomerACID=NPA_IntegrationDetails.CustomerACID
														AND NPA_IntegrationDetails_MOD.AuthorisationStatus='O'
														AND NPA_IntegrationDetails.AuthorisationStatus='A'
														AND NPA_IntegrationDetails_MOD.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
		where NPA_IntegrationDetails.AC_AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
		and NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey and NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
		and ISNULL(NPA_IntegrationDetails.AC_NPA_Date,'')=ISNULL(NPA_IntegrationDetails.NCIF_NPA_Date,'')
		AND NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7)
		AND ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200
		  AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
		  AND (NPA_IntegrationDetails.NCIF_AssetClassAlt_Key IS NOT NULL AND NPA_IntegrationDetails.NCIF_AssetClassAlt_Key<>1)
		--AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0
		----AND NPA_IntegrationDetails.ActualOutStanding>0
		----AND NPA_IntegrationDetails.PrincipleOutstanding<>0
		----and NPA_IntegrationDetails.NCIF_Id='165513'
			
)A


option(recompile)

--CREATE  CLUSTERED INDEX IX_NCIF_ID1 ON #TEMP(CustomerACID)

--CREATE NONCLUSTERED INDEX IX_ACC1 ON #TEMP(NCIF_ID)
--							INCLUDE (ProductType,CustomerName,CustomerId,PAN,SanctionedLimit,Balance,MaxDPD,DPD_Renewals,SubSegment,PreviousAssetClass,ChangedAssetClass,MOC_Status,MOC_AssetClassAlt_Key
--							,MOC_NPA_Date,SrcSysAlt_Key,AstClsChngByUser,ChangedNPADate
--							,PreviousNPADate,ProductAlt_Key,ActualOutStanding,PrincipleOutstanding,ActualPrincipleOutstanding,CUSTOMER_IDENTIFIER)

SELECT * INTO #TEMP1
FROM (
select  DISTINCT NPA_IntegrationDetails.NCIF_Id,
		NPA_IntegrationDetails.ProductType,
		NPA_IntegrationDetails.CustomerName,
		NPA_IntegrationDetails.CustomerId,
		NPA_IntegrationDetails.PAN,
		NPA_IntegrationDetails.CustomerACID,
		NPA_IntegrationDetails.SanctionedLimit,
		NPA_IntegrationDetails.Balance,
		NPA_IntegrationDetails.MaxDPD,
		NPA_IntegrationDetails.DPD_Renewals,
		NPA_IntegrationDetails.SubSegment,
		NPA_IntegrationDetails_MOD.AC_AssetClassAlt_Key PreviousAssetClass,
		NPA_IntegrationDetails.AC_AssetClassAlt_Key ChangedAssetClass,
		NPA_IntegrationDetails_MOD.AC_NPA_Date PreviousNPADate
	   ,NPA_IntegrationDetails.AC_NPA_Date  ChangedNPADate
	   ,NPA_IntegrationDetails.SrcSysAlt_Key
	   ,NPA_IntegrationDetails.MOC_Status
	   ,NPA_IntegrationDetails.MOC_AssetClassAlt_Key
	   ,NPA_IntegrationDetails.MOC_NPA_Date
	   ,NPA_IntegrationDetails.AstClsChngByUser
	   ,NPA_IntegrationDetails.ActualOutStanding
	   ,NPA_IntegrationDetails.PrincipleOutstanding
	   ,NPA_IntegrationDetails.ActualPrincipleOutstanding
	   ,NPA_IntegrationDetails.DrawingPower
	   ,NPA_IntegrationDetails.ProductCode
	   ,NPA_IntegrationDetails.CUSTOMER_IDENTIFIER
		FROM NPA_IntegrationDetails NPA_IntegrationDetails
		LEFT JOIN NPA_IntegrationDetails_MOD		ON NPA_IntegrationDetails_MOD.NCIF_Id=NPA_IntegrationDetails.NCIF_Id	
													AND NPA_IntegrationDetails_MOD.CustomerACID=NPA_IntegrationDetails.CustomerACID
													AND NPA_IntegrationDetails_MOD.AuthorisationStatus='O'
														AND NPA_IntegrationDetails.AuthorisationStatus='A'
														AND NPA_IntegrationDetails_MOD.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
		


		WHERE( (NPA_IntegrationDetails.AC_AssetClassAlt_Key<>NPA_IntegrationDetails.NCIF_AssetClassAlt_Key  
		  OR ISNULL(NPA_IntegrationDetails.AC_NPA_Date,'')<>ISNULL(NPA_IntegrationDetails.NCIF_NPA_Date,''))
		  and NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey and NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
			  AND NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7)---6 is removed----16_11_2017
			  AND ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200
			    AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
				AND NPA_IntegrationDetails.NCIF_AssetClassAlt_Key IS NOT NULL
			--AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0
		----	  AND NPA_IntegrationDetails.ActualOutStanding>0
		----AND NPA_IntegrationDetails.PrincipleOutstanding<>0
				 ) 
			
)B



OPTION(RECOMPILE)


--CREATE  CLUSTERED INDEX IX_NCIF_ID1 ON #TEMP1(CustomerACID)

--CREATE NONCLUSTERED INDEX IX_ACC1 ON #TEMP1(NCIF_ID)
--							INCLUDE (ProductType,CustomerName,CustomerId,PAN,SanctionedLimit,Balance,MaxDPD,DPD_Renewals,SubSegment,PreviousAssetClass,ChangedAssetClass,MOC_Status,MOC_AssetClassAlt_Key
--							,MOC_NPA_Date,SrcSysAlt_Key,AstClsChngByUser,ChangedNPADate
--							,PreviousNPADate,ProductAlt_Key,ActualOutStanding,PrincipleOutstanding,ActualPrincipleOutstanding,CUSTOMER_IDENTIFIER)



;WITH CTE2 AS
(
SELECT * FROM
(


select


ImpactedAccounts.NCIF_Id									AS  ENTCIF,

--------------------------------------IMPACTED ACCOUNTS-----------------------------------------

ImpactedSource.SourceName									AS  SOURCE ,
															
ImpactedAccounts.ProductType								AS FACILITY,
															
ImpactedAccounts.CustomerName								AS CUSTOMERNAME,
															
ImpactedAccounts.CustomerId									AS ICustomerID

,ImpactedAccounts.PAN										AS IPAN
															
,case when len(ImpactedAccounts.CustomerACID)=16
				then '''' + ImpactedAccounts.CustomerACID + '''' 
				else ImpactedAccounts.CustomerACID
				end											AS IMPACTEDAccount

,DENSE_RANK() over(Partition by ImpactedAccounts.NCIF_Id order by ImpactedAccounts.CustomerACID	)	AS rank 
															
,ISNULL(ImpactedAccounts.SanctionedLimit,0)/@Cost			AS LIMIT,
															
ISNULL(ImpactedAccounts.Balance,0)/@Cost					AS BALANCE,
ISNULL(ImpactedAccounts.ActualPrincipleOutstanding,0)/@Cost AS IPOS,	
	
ISNULL(ImpactedAccounts.DrawingPower,0)/@Cost				AS IDP,

IDimproduct.ProductCode									    AS IProduct,

IDimproduct.ProductName										AS IProductDescription,	
															
ImpactedAccounts.MaxDPD										AS DPD,
															
ImpactedAsset.AssetClassShortNameEnum						AS IAsset	---- as per discussion with shishir sir-03-11-2017		
															
,ImpactedAccounts.ChangedAssetClass						As IAssetAlt

,CONVERT(VARCHAR(25),ImpactedAccounts.ChangedNPADate,103)		AS IAC_NPA_Date

,convert(varchar(25),ImpactedAccounts.PreviousNPADate,103)	AS IPreviousNPA

,IPreviousAsset.AssetClassShortNameEnum						AS IPreviousAsset

,ImpactedAccounts.SubSegment								AS ISubSegment							
-------------------------------------PERCULATED Accounts----------------------------

,PerculatedSource.SourceName								AS  PSOURCE ,

PerculatedAccounts.ProductType								AS PFACILITY,

PerculatedAccounts.CustomerName								AS PCUSTOMERNAME,

PerculatedAccounts.CustomerId								AS PCustomerID

,PerculatedAccounts.PAN										AS PPAN

,case when len(PerculatedAccounts.CustomerACID)=16
				then '''' + PerculatedAccounts.CustomerACID + '''' 
				else PerculatedAccounts.CustomerACID
				end											AS PAccount
										
,ISNULL(PerculatedAccounts.SanctionedLimit,0)/@Cost			AS PLIMIT,

ISNULL(PerculatedAccounts.Balance,0)/@Cost					AS PBALANCE,
ISNULL(PerculatedAccounts.ActualPrincipleOutstanding,0)/@Cost AS PPOS,

PerculatedAccounts.MaxDPD										AS PDPD,

ISNULL(PerculatedAccounts.DrawingPower,0)/@Cost				AS PDP,

PDimproduct.ProductCode									    AS PProduct,

PDimproduct.ProductName										AS PProductDescription,

PerculatedAsset.AssetClassShortNameEnum						AS PAsset		---AS PER DISCUSSION WITH SHISHIR SIR			

,PerculatedAccounts.ChangedAssetClass					As PAssetAlt

,CONVERT(VARCHAR(25),PerculatedAccounts.ChangedNPADate,103)	AS PAC_NPA_Date

,ImpactedAccounts.MOC_Status								AS MOC_STATUS

,CONVERT(VARCHAR(25),ImpactedAccounts.MOC_NPA_Date,103)		AS MOC_NPA_Date

,MOCASSET.AssetClassName									AS MOC_ASSET_Class
	
,PerculatedAccounts.SubSegment								AS PSubSegment

,MOC_Freeze 
,convert(varchar(25),PerculatedAccounts.PreviousNPADate,103)	AS PPreviousNPA

,PPreviousAsset.AssetClassShortNameEnum						AS PPreviousAsset

fROM #TEMP ImpactedAccounts                 --ON ImpactedAccounts.NCIF_Id=#Temp.NCIF_Id


INNER JOIN  #TEMP1 PerculatedAccounts					ON ImpactedAccounts.NCIF_Id=PerculatedAccounts.NCIF_Id
														----AND #Temp.NCIF_Id=PerculatedAccounts.NCIF_Id
														--AND ISNULL(PerculatedAccounts.ActualPrincipleOutstanding,0)<>0
			     
		

INNER JOIN DimSourceSystem  ImpactedSource			ON ImpactedSource.SourceAlt_Key=ImpactedAccounts.SrcSysAlt_Key
													and ImpactedSource.EffectiveFromTimeKey<=@TimeKey and ImpactedSource.EffectiveToTimeKey>=@TimeKey


INNER JOIN DimSourceSystem  PerculatedSource		ON PerculatedSource.SourceAlt_Key=PerculatedAccounts.SrcSysAlt_Key
													and PerculatedSource.EffectiveFromTimeKey<=@TimeKey and PerculatedSource.EffectiveToTimeKey>=@TimeKey
	
																											
INNER  jOIN DIMASSETCLASS	ImpactedAsset			ON ImpactedAsset.AssetClassAlt_Key=ImpactedAccounts.ChangedAssetClass
													and ImpactedAsset.EffectiveFromTimeKey<=@TimeKey and ImpactedAsset.EffectiveToTimeKey>=@TimeKey


INNER  JOIN DIMASSETCLASS	PerculatedAsset			ON PerculatedAsset.AssetClassAlt_Key=PerculatedAccounts.ChangedAssetClass
													and PerculatedAsset.EffectiveFromTimeKey<=@TimeKey and PerculatedAsset.EffectiveToTimeKey>=@TimeKey

INNER JOIN	SysDataMatrix						    ON SysDataMatrix.TimeKey=@TimeKey
																
LEFT JOIN	DimAssetClass	IPreviousAsset			ON IPreviousAsset.AssetClassAlt_Key=ImpactedAccounts.PreviousAssetClass	
													and IPreviousAsset.EffectiveFromTimeKey<=@TimeKey and IPreviousAsset.EffectiveToTimeKey>=@TimeKey

LEFT JOIN    DimAssetClass   PPreviousAsset			ON PPreviousAsset.AssetClassAlt_Key=PerculatedAccounts.PreviousAssetClass	
													and PPreviousAsset.EffectiveFromTimeKey<=@TimeKey and PPreviousAsset.EffectiveToTimeKey>=@TimeKey	
											

LEFT JOIN DimAssetClass  MOCASSET					ON MOCASSET.AssetClassAlt_Key=ImpactedAccounts.MOC_AssetClassAlt_Key
													AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimProduct	IDimproduct					ON IDimproduct.ProductCode=ImpactedAccounts.ProductCode
													AND IDimproduct.EffectiveFromTimeKey<=@TimeKey AND IDimproduct.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimProduct	PDimproduct					 ON PDimproduct.ProductCode=PerculatedAccounts.ProductCode
													 AND PDimproduct.EffectiveFromTimeKey<=@TimeKey AND PDimproduct.EffectiveToTimeKey>=@TimeKey													


WHERE MOC_Freeze='Y'
AND MOC_FreezeBy IS NOT NULL
AND MOC_FreezeDate IS NOT NULL
--and ImpactedAccounts.NCIF_Id='10127283'															  
)A
	
)

SELECT * FROM CTE2
where rank=1
ORDER BY ENTCIF

OPTION(RECOMPILE)
DROP TABLE #TEMP
DROP TABLE #TEMP1



GO