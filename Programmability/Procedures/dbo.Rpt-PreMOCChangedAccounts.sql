SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By		:- VEDIKA
Created Date	:- 15/06/2018
Report Name		:- PreMOC Changed Accounts
*/

CREATE  proc [dbo].[Rpt-PreMOCChangedAccounts]
@TimeKey AS INT
,@Cost AS FLOAT
AS

--DECLARE	
--@TimeKey AS INT=24927,
--@Cost AS FLOAT=1000

IF OBJECT_ID('TEMPDB..#PreMOCChanged')IS NOT NULL
DROP TABLE #PreMOCChanged

SELECT * INTO #PreMOCChanged
FROM
(
SELECT NPA_IntegrationDetails.NCIF_Id,
	   NPA_IntegrationDetails.AccountEntityID , 
	   NPA_IntegrationDetails_MOD.AC_AssetClassAlt_Key,
	   NPA_IntegrationDetails_MOD.AC_NPA_Date,
	   NPA_IntegrationDetails_MOD.CustomerACID  
FROM NPA_IntegrationDetails
INNER JOIN NPA_IntegrationDetails_MOD		ON NPA_IntegrationDetails_MOD.CustomerACID=NPA_IntegrationDetails.CustomerACID
											AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
											AND NPA_IntegrationDetails_MOD.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails_MOD.EffectiveToTimeKey>=@TimeKey
											AND NPA_IntegrationDetails_MOD.AuthorisationStatus='O'
)DATA

OPTION(RECOMPILE)

SELECT 

DISTINCT 

NPA_IntegrationDetails.PAN													AS 'PAN'

,DimSourceSystem.SourceName													AS 'SourceSystem'

,NPA_IntegrationDetails.CustomerID											AS 'CustomerID'

,NPA_IntegrationDetails.CustomerName										AS 'CustomerName'

,NPA_IntegrationDetails.ProductType											AS 'Facility'

,CASE WHEN LEN(NPA_IntegrationDetails.CustomerACID)=16
				THEN '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				ELSE NPA_IntegrationDetails.CustomerACID
				END																					AS 'Account No.'

,NPA_IntegrationDetails.NCIF_Id																		AS 'NCIF'

,ISnull(NPA_IntegrationDetails.Balance,0)/@Cost														AS 'Outstanding'

,ISnull(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost									AS 'PrincipleOutstanding'

,ISnull(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost												AS 'Limit'

,ISnull(NPA_IntegrationDetails.DrawingPower,0)/@Cost												AS 'DP'

,ISNULL(NPA_IntegrationDetails.ProductType,'')														AS 'FacilityType'

,ISNULL(PrevAssetClass.AssetClassShortNameEnum,DimAssetClass.AssetClassShortNameEnum)				AS 'PreviousAssetClass'

,ISNULL(CONVERT(VARCHAR(25),#PreMOCChanged.AC_NPA_Date,103),CONVERT(varchar(25),NPA_IntegrationDetails.AC_NPA_Date,103)) AS 'PreviousNPADate',

ISNULL(FinalAssetClass.AssetClassShortNameEnum,'')													AS 'FinalAssetClass'

,CONVERT(varchar(25),NPA_IntegrationDetails.NCIF_NPA_Date,103)										AS 'FinalNPADate',

ISNULL(NPA_IntegrationDetails.ModifiedBy,'')														AS 'ModifiedBy',

ISNULL(CONVERT(VARCHAR(25),NPA_IntegrationDetails.DateModified,103),'')								AS 'DateModified'

,ISNULL(NPA_IntegrationDetails.AstClsChngRemark,'')													AS 'ModifierRemark',

ISNULL(NPA_IntegrationDetails.ApprovedBy,'')														AS 'ApprovedBy',

ISNULL(CONVERT(VARCHAR(25),NPA_IntegrationDetails.DateApproved,103),'')								AS 'DateApproved'

,ISNULL(NPA_IntegrationDetails.AstClsAppRemark,'')													AS 'ApprovedRemark'


FROM  NPA_IntegrationDetails		

LEFT JOIN #PreMOCChanged						ON #PreMOCChanged.AccountEntityID=NPA_IntegrationDetails.AccountEntityID
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationDetails.ProductAlt_Key<>3200
												AND NPA_IntegrationDetails.AC_AssetClassAlt_Key<>7

LEFT JOIN DimAssetClass	PrevAssetClass			ON  PrevAssetClass.EffectiveFromTimeKey<=@TimeKey AND PrevAssetClass.EffectiveToTimeKey>=@TimeKey 
												AND PrevAssetClass.AssetClassAlt_Key=#PreMOCChanged.AC_AssetClassAlt_Key
												
												
INNER JOIN NPA_IntegrationDetails_MOD			ON NPA_IntegrationDetails_MOD.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
												AND NPA_IntegrationDetails_MOD.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails_MOD.EffectiveToTimeKey>=@TimeKey									 
												AND NPA_IntegrationDetails_MOD.AuthorisationStatus='A'

LEFT JOIN DimAssetClass							ON  DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey 
												AND DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
												

INNER JOIN DimAssetClass FinalAssetClass		ON FinalAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.NCIF_AssetClassAlt_Key
												AND FinalAssetClass.EffectiveFromTimeKey<=@TimeKey AND FinalAssetClass.EffectiveToTimeKey>=@TimeKey
										
INNER JOIN DimSourceSystem						ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey

INNER JOIN SysDataMatrix						ON SysDataMatrix.TimeKey=@TimeKey
									
LEFT JOIN  DIMPRODUCT							ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
												AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

WHERE
 SysDataMatrix.PreProcessingFreeze='Y'
AND SysDataMatrix.PreProcessingFreezeBy IS NOT NULL
AND SysDataMatrix.PreProcessingFreezeDate IS NOT NULL
----AND NPA_IntegrationDetails.NCIF_Id='15673988'


OPTION(RECOMPILE)
DROP TABLE #PreMOCChanged
GO