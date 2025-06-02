SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



/*
Created By		:- Baijayanti
Created Date	:- 05/06/2021
Report Name		:- Segment wise NPA Summary
*/

CREATE PROC [dbo].[Rpt-SegmentwiseNPASummary]
@TimeKey AS INT
,@Cost AS FLOAT
AS

--DECLARE	
--@TimeKey AS INT=24927,
--@Cost AS FLOAT=1000


SELECT 
DAC.AssetClassAlt_Key,
DAC.AssetClassShortNameEnum           AS IRAC_Clasification,

-----------------Consolidated-------------------------------

0   Consolidated_Outstanding,
0   Consolidated_UnrealisedInterest,
0   Consolidated_GrossNPA,
0   Consolidated_Provision,

----------------Finacle-------------------
		
SUM(CASE WHEN SourceShortNameEnum='Finacle'
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS Finacle_Outstanding,

SUM(CASE WHEN SourceShortNameEnum='Finacle'
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS Finacle_UnrealisedInterest,

SUM(CASE WHEN SourceShortNameEnum='Finacle'
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS Finacle_GrossNPA,

SUM(CASE WHEN SourceShortNameEnum='Finacle'
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS Finacle_Provision,

---------------------Prolendz (excluding LAP)-----------------

SUM(CASE WHEN SourceShortNameEnum='Prolendz'
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS Prolendz_Outstanding,

SUM(CASE WHEN SourceShortNameEnum='Prolendz'
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS Prolendz_UnrealisedInterest,

SUM(CASE WHEN SourceShortNameEnum='Prolendz'
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS Prolendz_GrossNPA,

SUM(CASE WHEN SourceShortNameEnum='Prolendz'
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS Prolendz_Provision,

------------------------PT Smart--------------------	

0   AS PTSmart_Outstanding,
0   AS PTSmart_UnrealisedInterest,
0   AS PTSmart_GrossNPA,
0   AS PTSmart_Provision,
			
-----------------------Credit cards (VP exclusion commercial card)------------------

0   AS Creditcards_Outstanding,
0   AS Creditcards_UnrealisedInterest,
0   AS Creditcards_GrossNPA,
0   AS Creditcards_Provision,
				
--------------------LAP	--------------------------------

SUM(CASE WHEN SourceShortNameEnum='CFD'
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                   AS LAP_Outstanding,

SUM(CASE WHEN SourceShortNameEnum='CFD'
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                   AS LAP_UnrealisedInterest,

SUM(CASE WHEN SourceShortNameEnum='CFD'
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                   AS LAP_GrossNPA,

SUM(CASE WHEN SourceShortNameEnum='CFD'
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                   AS LAP_Provision,	
		
--------------------Commercial Card	----------------------------	

0   AS CommercialCard_Outstanding,
0   AS CommercialCard_UnrealisedInterest,
0   AS CommercialCard_GrossNPA,
0   AS CommercialCard_Provision,
		
----------------------Ganaseva-----------------------------	

SUM(CASE WHEN SourceShortNameEnum='Gan Seva'
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS Ganaseva_Outstanding,

SUM(CASE WHEN SourceShortNameEnum='Gan Seva'
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS Ganaseva_UnrealisedInterest,

SUM(CASE WHEN SourceShortNameEnum='Gan Seva'
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS Ganaseva_GrossNPA,

SUM(CASE WHEN SourceShortNameEnum='Gan Seva'
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS Ganaseva_Provision,
			
-----------------------ECBF	----------------------------

SUM(CASE WHEN SourceShortNameEnum='ECBF'
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS ECBF_Outstanding,

SUM(CASE WHEN SourceShortNameEnum='ECBF'
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS ECBF_UnrealisedInterest,

SUM(CASE WHEN SourceShortNameEnum='ECBF'
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS ECBF_GrossNPA,

SUM(CASE WHEN SourceShortNameEnum='ECBF'
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS ECBF_Provision

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
DAC.AssetClassAlt_Key,
DAC.AssetClassShortNameEnum

ORDER BY DAC.AssetClassAlt_Key


OPTION(RECOMPILE)
GO