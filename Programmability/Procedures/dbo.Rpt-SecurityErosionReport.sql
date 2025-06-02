SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By		:- Baijayanti
Created Date	:- 11/06/2021
Report Name		:- Security Erosion Validation Report
*/

CREATE PROC [dbo].[Rpt-SecurityErosionReport]
@TimeKey AS INT
,@Cost AS FLOAT
AS

--DECLARE	
--@TimeKey AS INT=26108,
--@Cost AS FLOAT=1

SET NOCOUNT ON;
---------------------------------------------
IF OBJECT_ID('tempdb..#AdvSecurityDetail') IS NOT NULL 
	DROP TABLE #AdvSecurityDetail	

SELECT 
DISTINCT
ASD.RefSystemAcId,
ASVD.CollateralID,
CollateralType,
SUM(ISNULL(Prev_Value,0))       AS Prev_Value,
MAX(Prev_ValuationDate)         AS Prev_ValuationDate,
SUM(ISNULL(CurrentValue,0))     AS CurrentValue,
MAX(ValuationDate)              AS ValuationDate
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
CollateralType

OPTION(RECOMPILE)

--------------------------------

				


SELECT 
DSS.SourceName,
NPAID.NCIF_Id                                                                                          AS DedupeID,
ASD.CollateralID,
ASD.CollateralType,
SUM(ISNULL(ASD.Prev_Value,0))/@Cost                                                                    AS OldCollateralAmount,
CONVERT(VARCHAR(20),ASD.Prev_ValuationDate,103)                                                        AS OldCollateralValuationDate,
SUM(ISNULL(ASD.CurrentValue,0))/@Cost                                                                  AS NewCollateralAmount,
CONVERT(VARCHAR(20),ASD.ValuationDate,103)                                                             AS NewCollateralValuationDate,
((SUM(ISNULL(ASD.Prev_Value,0))/@Cost-SUM(ISNULL(ASD.CurrentValue,0))/@Cost)/NULLIF(SUM(ISNULL(ASD.Prev_Value,0)),0)/@Cost)*100    AS Security_Erosion_PerC,
CONVERT(VARCHAR(20),NPAID.ErosionDT,103)                                                               AS ErosionDate,
NPAID.CustomerID                                                                                       AS CIFID,
NPAID.CustomerName,
NPAID.CustomerACID                                                                                     AS AccountNo,
DAC.AssetClassName                                                                                     AS IRAC,
CONVERT(VARCHAR(20),NPAID.NCIF_NPA_Date,103)                                                           AS NPADate,
SUM(ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))/@Cost                                               AS GNPA,
SUM(ISNULL(TotalProvision,0))/@Cost                                                                    AS ProvisionAmount


FROM  NPA_IntegrationDetails	NPAID	

INNER JOIN DimAssetClass DAC					ON  DAC.AssetClassAlt_Key=NPAID.NCIF_AssetClassAlt_Key 
												    AND DAC.EffectiveFromTimeKey<=@TimeKey 
													AND DAC.EffectiveToTimeKey>=@TimeKey
												    AND NPAID.EffectiveFromTimeKey<=@TimeKey 
													AND NPAID.EffectiveToTimeKey>=@TimeKey

LEFT JOIN #AdvSecurityDetail  ASD               ON ASD.RefSystemAcId=NPAID.CustomerACID 						
 

INNER JOIN DimSourceSystem	DSS					ON  DSS.SourceAlt_Key=NPAID.SrcSysAlt_Key
												    AND DSS.EffectiveFromTimeKey<=@TimeKey 
													AND DSS.EffectiveToTimeKey>=@TimeKey

										
WHERE ISNULL(NPAID.FlgErosion,'')='Y'

GROUP BY
NPAID.CustomerACID,
DSS.SourceName,
NPAID.NCIF_Id,      
NPAID.CustomerID ,  
NPAID.CustomerName ,
NPAID.NCIF_NPA_Date,
NPAID.ErosionDT,
DAC.AssetClassName,
ASD.CollateralID,
ASD.CollateralType,
ASD.Prev_ValuationDate,     
ASD.ValuationDate 

ORDER BY NPAID.CustomerName


OPTION(RECOMPILE)

DROP TABLE #AdvSecurityDetail
GO