SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By		:- Baijayanti
Created Date	:- 07/06/2021
Report Name		:- CIF ID ID wise NPA Listing of all Accounts
*/

CREATE PROC [dbo].[Rpt-CIFID_IDwiseNPAListingofallAccounts_--]
@TimeKey AS INT
,@Cost AS FLOAT
AS

--DECLARE	
--@TimeKey AS INT=26084,
--@Cost AS FLOAT=1


---------------------------------------------
IF OBJECT_ID('tempdb..#AdvSecurityDetail') IS NOT NULL 
	DROP TABLE #AdvSecurityDetail	

SELECT 
DISTINCT
--AccountEntityId,
RefCustomerId,
ValuationDate
INTO #AdvSecurityDetail
FROM AdvSecurityDetail ASD  
INNER JOIN AdvSecurityValueDetail  ASVD       ON ASD.SecurityEntityID=ASVD.SecurityEntityID
												 AND ASD.EffectiveFromTimeKey<=@TimeKey 
												 AND ASD.EffectiveToTimeKey>=@TimeKey 
												 AND ASVD.EffectiveFromTimeKey<=@TimeKey 
												 AND ASVD.EffectiveToTimeKey>=@TimeKey

OPTION(RECOMPILE)

--------------------------------

SELECT 
DSS.SourceName,
NPAID.BranchCode                                                      AS Sol_ID,
NPAID.State                                                           AS [State],
DB.BranchName                                                         AS Branch,
NPAID.Zone                                                            AS Zone,
NPAID.NCIF_Id                                                         AS DedupeID,
NPAID.CustomerID                                                      AS CIF,
NPAID.CustomerName                                                    AS Nameoftheborrower,
''                                                                    AS NewduringQuarterYes_No,
CONVERT(VARCHAR(20),NPAID.NCIF_NPA_Date,103)                          AS DateofNPA,
DAC.AssetClassName                                                    AS IRAC,
SUM(ISNULL(Balance,0))/@Cost                                          AS OS_onProcessingDate,
SUM(ISNULL(UNSERVED_INTEREST,0))/@Cost                                AS UnrealisedInterest,
SUM(ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))/@Cost              AS GNPA,
SUM(ISNULL(TotalProvision,0)-ISNULL(AddlProvision,0))/@Cost           AS SystemProvision,
SUM(ISNULL(AddlProvision,0))/@Cost                                    AS AcceleratedProvision,
SUM(ISNULL(TotalProvision,0))/@Cost                                   AS TotalProvision,
''                                                                    AS NNPA,
SUM(ISNULL(SecurityValue,0))/@Cost                                    AS SecurityValue,	
CONVERT(VARCHAR(20),MIN(ValuationDate),103)                           AS ValuationDate,	
SUM(ISNULL(SecuredAmt,0))/@Cost                                       AS SecuredGNPA,	
SUM(ISNULL(UnSecuredAmt,0))/@Cost                                     AS UnsecuredGNPA,	
NPAID.Segment                                                         AS Segment


FROM  NPA_IntegrationDetails	NPAID	
INNER JOIN DimAssetClass DAC					ON  DAC.AssetClassAlt_Key=NPAID.NCIF_AssetClassAlt_Key 
												    AND DAC.EffectiveFromTimeKey<=@TimeKey 
													AND DAC.EffectiveToTimeKey>=@TimeKey 
												    AND NPAID.EffectiveFromTimeKey<=@TimeKey 
													AND NPAID.EffectiveToTimeKey>=@TimeKey

LEFT JOIN #AdvSecurityDetail  ASD               ON ASD.RefCustomerId=NPAID.CustomerID 						


INNER JOIN DimSourceSystem	DSS					ON  DSS.SourceAlt_Key=NPAID.SrcSysAlt_Key
												    AND DSS.EffectiveFromTimeKey<=@TimeKey 
													AND DSS.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimBranch   DB                        ON  DB.BranchCode=NPAID.BranchCode
												    AND DB.EffectiveFromTimeKey<=@TimeKey 
													AND DB.EffectiveToTimeKey>=@TimeKey

										
WHERE DAC.AssetClassSubGroup IN('SUB STANDARD','DOUBTFUL','LOSS') 

GROUP BY
DSS.SourceName,
NPAID.NCIF_Id,      
NPAID.CustomerID ,  
NPAID.CustomerName ,
NPAID.NCIF_NPA_Date,
NPAID.Segment,
DAC.AssetClassName,
NPAID.BranchCode,  
NPAID.State ,      
DB.BranchName ,    
NPAID.Zone    


ORDER BY NPAID.CustomerName


OPTION(RECOMPILE)

DROP TABLE #AdvSecurityDetail
GO