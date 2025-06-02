SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



/*
Created By		:- Baijayanti
Created Date	:- 18/06/2021
Report Name		:- List of Restructured Accounts
*/

CREATE PROC [dbo].[Rpt-RestructuredAccounts]
@TimeKey AS INT
,@Cost AS FLOAT
AS

--DECLARE	
--@TimeKey AS INT=26108,
--@Cost AS FLOAT=1


---------------------------------------------------

SELECT 
DSS.SourceName,
NPAID.NCIF_Id                                                     AS DedupeID,
NPAID.CustomerID                                                  AS CIF,
NPAID.CustomerName,
NPAID.CustomerACID                                                AS AccountNo,	
CONVERT(VARCHAR(20),ACRD.RestructureDt,103)                       AS RestructuredDate,	
''                                                                AS RestructuredType,		
SUM(ISNULL(ACRD.RestructureAmt,0))/@Cost                          AS RestructuredAmount,
SUM(ISNULL(ACRD.DiminutionAmount,0))/@Cost                        AS DFVAmount,
''                                                                AS TakeoutFinance,
CONVERT(VARCHAR(20),ACRD.RepaymentStartDate,103)                  AS LatestRepaymentDate,
DAC.AssetClassName                                                AS IRAC,
CONVERT(VARCHAR(20),NPAID.NCIF_NPA_Date,103)                      AS DateofNPA,
SUM(ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))/@Cost          AS GNPA,
SUM(ISNULL(NPAID.TotalProvision,0))/@Cost                         AS ProvisionAmount


FROM  NPA_IntegrationDetails	NPAID	

INNER JOIN AdvAcRestructureDetail  ACRD         ON ACRD.RefSystemAcId=NPAID.CustomerACID 						
												    AND NPAID.EffectiveFromTimeKey<=@TimeKey 
													AND NPAID.EffectiveToTimeKey>=@TimeKey
												    AND ACRD.EffectiveFromTimeKey<=@TimeKey 
													AND ACRD.EffectiveToTimeKey>=@TimeKey																			

INNER JOIN DimAssetClass DAC					ON  DAC.AssetClassAlt_Key=NPAID.NCIF_AssetClassAlt_Key 
												    AND DAC.EffectiveFromTimeKey<=@TimeKey 
													AND DAC.EffectiveToTimeKey>=@TimeKey 

INNER JOIN DimSourceSystem	DSS					ON  DSS.SourceAlt_Key=NPAID.SrcSysAlt_Key
												    AND DSS.EffectiveFromTimeKey<=@TimeKey 
													AND DSS.EffectiveToTimeKey>=@TimeKey

										

GROUP BY
DSS.SourceName,
NPAID.NCIF_Id ,      
NPAID.CustomerID,    
NPAID.CustomerName,
NPAID.CustomerACID,  
ACRD.RestructureDt,
ACRD.RepaymentStartDate,
NPAID.NCIF_NPA_Date,
DAC.AssetClassName



ORDER BY NPAID.CustomerName


OPTION(RECOMPILE)

GO