SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By		:- Baijayanti
Created Date	:- 05/06/2021
Report Name		:- Provision Reverse Feed
*/

CREATE PROC [dbo].[Rpt-ProvisionReverseFeed]
@TimeKey AS INT
,@Cost AS FLOAT
AS

--DECLARE	
--@TimeKey AS INT=24927,
--@Cost AS FLOAT=1000


SELECT 
DSS.SourceName,
NPAID.NCIF_Id                                     AS DedupeIDUCICEnterpriseCIF,
NPAID.CustomerID                                  AS SourceSystemCIFCustomerIdentifier,
CustomerACID                                      AS AccountNo,
BranchCode                                        AS SolID,
ProductType                                       AS SchemeType,
ProductCode                                       AS SchemeCode,
SUM(ISNULL(TotalProvision,0))/@Cost               AS Provision


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
DSS.SourceName,
NPAID.NCIF_Id,     
NPAID.CustomerID,  
CustomerACID,      
BranchCode,        
ProductType,       
ProductCode       

ORDER BY NPAID.CustomerID


OPTION(RECOMPILE)
GO