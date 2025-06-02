SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/*
Created By		:- Baijayanti
Created Date	:- 07/06/2021
Report Name		:- Account wise NPA Listing
*/

CREATE PROC [dbo].[Rpt-AccountwiseNPAListing]
@TimeKey AS INT
,@Cost AS FLOAT
AS

--DECLARE	
--@TimeKey AS INT=26084,
--@Cost AS FLOAT=1

------------------------------------
IF OBJECT_ID('tempdb..#AdvSecurityDetail') IS NOT NULL 
	DROP TABLE #AdvSecurityDetail	

SELECT 
DISTINCT
--AccountEntityId,
RefSystemAcId,
ValuationDate
INTO #AdvSecurityDetail
FROM AdvSecurityDetail ASD  
INNER JOIN AdvSecurityValueDetail  ASVD       ON ASD.SecurityEntityID=ASVD.SecurityEntityID
												 AND ASD.EffectiveFromTimeKey<=@TimeKey 
												 AND ASD.EffectiveToTimeKey>=@TimeKey 
												 AND ASVD.EffectiveFromTimeKey<=@TimeKey 
												 AND ASVD.EffectiveToTimeKey>=@TimeKey

OPTION(RECOMPILE)

---------------------------------------------------

SELECT 
DSS.SourceName,
NPAID.BranchCode                                                  AS Sol_ID,
NPAID.State                                                       AS [State],
DB.BranchName                                                     AS Branch,
NPAID.Zone                                                        AS Zone,
NPAID.NCIF_Id                                                     AS DedupeID,
NPAID.CustomerID                                                  AS CIF,
NPAID.CustomerACID                                                AS AccountNo,	
NPAID.FacilityType                                                AS Facility,
CONVERT(VARCHAR(20),NPAID.SancDate,103)                           AS SanctionDate,
''                                                                AS AccountOpenDate,
NPAID.CustomerName                                                AS Nameoftheborrower,
''                                                                AS NewduringQuarterYes_No,
CONVERT(VARCHAR(20),NPAID.NCIF_NPA_Date,103)                      AS DateofNPA,
DAC.AssetClassName                                                AS IRAC,
SUM(ISNULL(Balance,0))/@Cost                                      AS OS_onProcessingDate,
SUM(ISNULL(UNSERVED_INTEREST,0))/@Cost                            AS UnrealisedInterest,
SUM(ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))/@Cost          AS GNPA,
SUM(ISNULL(NPAID.TotalProvision,0))/@Cost                         AS TotalNPAProvision,
''                                                                AS MOCProvision,
''                                                                AS TotalProvision,
''                                                                AS NNPA,
''                                                                AS ProvisionPercentage,
SUM(ISNULL(NPAID.ApprRV,0))/@Cost                                 AS SecurityValueappropriated,	
''                                                                AS SecurityType,
CONVERT(VARCHAR(20),MIN(ValuationDate),103)                       AS SecurityValuedate,	
SUM(ISNULL(NPAID.SecuredAmt,0))/@Cost                             AS SecuredGNPA,	
SUM(ISNULL(NPAID.UnSecuredAmt,0))/@Cost                           AS UnsecuredGNPA,	
SUM(ISNULL(NPAID.Provsecured,0))/@Cost                            AS SecuredProvision,	
SUM(ISNULL(NPAID.ProvUnsecured,0))/@Cost                          AS UnsecuredProvision,
NPAID.Segment                                                     AS Segment,
''                                                                AS NPAimpactingaccountid,	
''                                                                AS NPAimpactingsourcesystem,	
NPAID.MOC_ReasonAlt_Key                                           AS MOCReason,
NPAID.ProductCode                                                 AS SchemeCode,	
NPAID.ProductDesc                                                 AS SchemeDescritpion,	
NPAID.PAN                                                         AS PAN,	
PS_NPS                                                            AS Priority_NonPriority,	
NPAID.SECTOR                                                      AS SectorClassification,	
''                                                                AS Agri,	
''                                                                AS Industry_Service_Retail_Description


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

LEFT JOIN DimBranch	DB					        ON  DB.BranchCode=NPAID.BranchCode
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
NPAID.CustomerACID,
DAC.AssetClassName,
NPAID.PAN ,
NPAID.MOC_ReasonAlt_Key,
NPAID.ProductCode,
NPAID.ProductDesc,
NPAID.BranchCode,   
NPAID.State,        
DB.BranchName ,     
NPAID.Zone,         
NPAID.SECTOR,
NPAID.FacilityType,
NPAID.SancDate,
PS_NPS

ORDER BY NPAID.CustomerName


OPTION(RECOMPILE)

DROP TABLE #AdvSecurityDetail
GO