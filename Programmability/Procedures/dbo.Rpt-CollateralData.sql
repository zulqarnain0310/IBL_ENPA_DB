SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By		:- Baijayanti
Created Date	:- 11/06/2021
Report Name		:- Collateral Data where Stock Statement Date not available
*/

CREATE PROC [dbo].[Rpt-CollateralData]
@TimeKey AS INT
,@Cost AS FLOAT
AS

--DECLARE	
--@TimeKey AS INT=26108,
--@Cost AS FLOAT=1000


---------------------------------------------
IF OBJECT_ID('tempdb..#AdvSecurityDetail') IS NOT NULL 
	DROP TABLE #AdvSecurityDetail	

SELECT 
ASD.RefSystemAcId,
ASVD.CollateralID,
CollateralType,
SUM(ISNULL(CurrentValue,0))     AS CurrentValue,
ValuationDate,
ValuationExpiryDate
INTO #AdvSecurityDetail
FROM AdvSecurityDetail ASD  
INNER JOIN AdvSecurityValueDetail  ASVD       ON ASD.SecurityEntityID=ASVD.SecurityEntityID
												 AND ASD.EffectiveFromTimeKey<=@TimeKey 
												 AND ASD.EffectiveToTimeKey>=@TimeKey 
												 AND ASVD.EffectiveFromTimeKey<=@TimeKey 
												 AND ASVD.EffectiveToTimeKey>=@TimeKey

GROUP BY 
ASD.RefSystemAcId,
ASVD.CollateralID,
CollateralType,
ValuationDate,
ValuationExpiryDate

OPTION(RECOMPILE)

--------------------------------


SELECT 
DSS.SourceName,
NPAID.NCIF_Id                                                                                          AS DedupeID,
NPAID.CustomerID                                                                                       AS CIFID,
NPAID.CustomerName,
NPAID.CustomerACID                                                                                     AS AccountNo,
SUM(ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))/@Cost                                               AS Balance,
ASD.CollateralID,
ASD.CollateralType,
SUM(ISNULL(ASD.CurrentValue,0))/@Cost                                                                  AS CollateralAmount,
CONVERT(VARCHAR(20),ASD.ValuationDate,103)                                                             AS CollateralValuationDate,
CONVERT(VARCHAR(20),ASD.ValuationExpiryDate,103)                                                       AS CollateralValuationExpiryDate


FROM  NPA_IntegrationDetails	NPAID	

INNER JOIN #AdvSecurityDetail  ASD              ON ASD.RefSystemAcId=NPAID.CustomerACID 						
												    AND NPAID.EffectiveFromTimeKey<=@TimeKey 
													AND NPAID.EffectiveToTimeKey>=@TimeKey

INNER JOIN DimSourceSystem	DSS					ON  DSS.SourceAlt_Key=NPAID.SrcSysAlt_Key
												    AND DSS.EffectiveFromTimeKey<=@TimeKey 
													AND DSS.EffectiveToTimeKey>=@TimeKey

										

GROUP BY
NPAID.CustomerACID,
DSS.SourceName,
NPAID.NCIF_Id,      
NPAID.CustomerID ,  
NPAID.CustomerName ,
ASD.CollateralID,
ASD.CollateralType,   
ASD.ValuationDate ,
ASD.ValuationExpiryDate

ORDER BY NPAID.CustomerName


OPTION(RECOMPILE)

DROP TABLE #AdvSecurityDetail
GO