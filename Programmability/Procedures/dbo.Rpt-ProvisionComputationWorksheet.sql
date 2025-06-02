SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



/*
Created By		:- Baijayanti
Created Date	:- 09/06/2021
Report Name		:- Provision Computation worksheet
*/

CREATE PROC [dbo].[Rpt-ProvisionComputationWorksheet]
@TimeKey AS INT
,@Cost AS FLOAT
AS

--DECLARE	
--@TimeKey AS INT=24927,
--@Cost AS FLOAT=1



SELECT 
NPAID.CustomerID                                                  AS CustomerID,
NPAID.CustomerName                                                AS CustomerName,
NPAID.CustomerACID                                                AS AccountID,	
SUM(ISNULL(SanctionedLimit,0))/@Cost                              AS LimitSanctioned,
''                                                                AS AccountOpenDate,
DAC.AssetClassName                                                AS AssetClassification,
CONVERT(VARCHAR(20),NPAID.NCIF_NPA_Date,103)                      AS NPADate,
SUM(ISNULL(Balance,0))/@Cost                                      AS GrossBalanceAson,
SUM(ISNULL(UNSERVED_INTEREST,0))/@Cost                            AS UnservicedInterest,
SUM(ISNULL(PrincipleOutstanding,0))/@Cost                         AS PrincipalOutstandingBalance,
SUM(ISNULL(WriteOffAmount,0))/@Cost                               AS WriteOffAmount,
CONVERT(VARCHAR(20),WriteOffDate,103)                             AS WriteOffDate,

SUM(ISNULL(NetBalance,0))/@Cost                                   AS NetBalanceforProvisionComputation ,
SUM(ISNULL(SecurityValue,0))/@Cost                                AS CustomerTotalSecurity,	
NPAID.SecApp                                                      AS SecurityAppropriatedtoAccount,
SUM(ISNULL(NPAID.SecuredAmt,0))/@Cost                             AS SecuredExposure,	
SUM(ISNULL(NPAID.UnSecuredAmt,0))/@Cost                           AS UnsecuredExposure,	
SUM(ISNULL(ProvPerSecured,0))                                     AS ProvisionPercentApplied,	
SUM(ISNULL(NPAID.Provsecured,0))/@Cost                            AS ProvisionofSecuredExposure,	
SUM(ISNULL(NPAID.ProvUnsecured,0))/@Cost                          AS ProvisiononUnSecuredExposure,	
SUM(ISNULL(TotalProvision,0))/@Cost                               AS TotalComputedProvision,	
SUM(ISNULL(AddlProvision,0))/@Cost                                AS AdditionalProvisionthroughMOCDetails,	
''                                                                AS AdditionalProvisiononCustomer_Account,	
SUM(ISNULL(AddlProvisionPer,0))                                   AS [AdditionaprovisionType_%_Amount],	
SUM(ISNULL(AddlProvision,0))/@Cost                                AS AdditionalProvisionAmount,
SUM(ISNULL(TotalProvision,0))/@Cost                               AS TotalProvision_ComputedProvision_AdditionalProvision


FROM  NPA_IntegrationDetails	NPAID							
					

INNER JOIN DimAssetClass DAC					ON  DAC.AssetClassAlt_Key=NPAID.NCIF_AssetClassAlt_Key 
												    AND DAC.EffectiveFromTimeKey<=@TimeKey 
													AND DAC.EffectiveToTimeKey>=@TimeKey 
												    AND NPAID.EffectiveFromTimeKey<=@TimeKey 
													AND NPAID.EffectiveToTimeKey>=@TimeKey	

INNER JOIN DimSourceSystem	DSS					ON  DSS.SourceAlt_Key=NPAID.SrcSysAlt_Key
												    AND DSS.EffectiveFromTimeKey<=@TimeKey 
													AND DSS.EffectiveToTimeKey>=@TimeKey
										
WHERE DAC.AssetClassSubGroup IN('SUB STANDARD','DOUBTFUL','LOSS')

GROUP BY
NPAID.SecApp,    
NPAID.CustomerID ,  
NPAID.CustomerName ,
NPAID.NCIF_NPA_Date,
NPAID.CustomerACID,
DAC.AssetClassName,
WriteOffDate

ORDER BY NPAID.CustomerName


OPTION(RECOMPILE)


GO