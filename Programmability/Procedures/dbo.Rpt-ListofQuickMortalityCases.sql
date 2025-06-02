SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



/*
Created By		:- Baijayanti
Created Date	:- 05/06/2021
Report Name		:- List of Quick Mortality Cases
*/

CREATE PROC [dbo].[Rpt-ListofQuickMortalityCases]
@TimeKey AS INT
,@Cost AS FLOAT
AS

--DECLARE	
--@TimeKey AS INT=24927,
--@Cost AS FLOAT=1000


SELECT 
CustomerId                                                         AS CIFID,
CustomerACID                                                       AS AccountNo,
CustomerName                                                       AS BorrowerName,
CONVERT(VARCHAR(20),SancDate,103)                                  AS SanctionDate,
CONVERT(VARCHAR(20),NCIF_NPA_Date,103)                             AS NPADate,
SUM(ISNULL(Balance,0))/@Cost                                       AS Outstanding,
SUM(ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))/@Cost           AS GNPA,
SUM(ISNULL(TotalProvision,0))/@Cost                                AS Provision


FROM  NPA_IntegrationDetails	NPAID	
						

INNER JOIN DimAssetClass DAC					ON  DAC.AssetClassAlt_Key=NPAID.NCIF_AssetClassAlt_Key 
												    AND DAC.EffectiveFromTimeKey<=@TimeKey 
													AND DAC.EffectiveToTimeKey>=@TimeKey 
												    AND NPAID.EffectiveFromTimeKey<=@TimeKey 
													AND NPAID.EffectiveToTimeKey>=@TimeKey
												
										
WHERE DAC.AssetClassSubGroup IN('SUB STANDARD','DOUBTFUL','LOSS') AND DATEDIFF(MM,SancDate,NCIF_NPA_Date) BETWEEN 1 AND 12

GROUP BY
CustomerId ,
CustomerACID,
CustomerName,
SancDate,
NCIF_NPA_Date

ORDER BY BorrowerName


OPTION(RECOMPILE)
GO