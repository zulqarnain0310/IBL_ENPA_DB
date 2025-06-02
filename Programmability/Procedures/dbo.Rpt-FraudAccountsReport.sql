SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[Rpt-FraudAccountsReport]
	@TimeKey AS INT,
	@Cost AS FLOAT
	AS 


--DECLARE 
--     @TimeKey  AS INT=26084,
--	 @Cost AS FLOAT=1

SET NOCOUNT ON ;

SELECT 
 DIMSOU.SourceName                                                                 AS [Source System Name]
,NPA_INTGD.NCIF_Id                                                                 AS [Dedupe ID]
,NPA_INTGD.CustomerId                                                              AS [CIF ID]
,NPA_INTGD.CustomerName                                                            AS [Customer Name]
,NPA_INTGD.CustomerACID                                                            AS [Account No]
,CONVERT(VARCHAR(20),NPA_INTGD.FraudDate,103)                                      AS [Fraud detection date]
,SUM(ISNULL(NPA_INTGD.FraudAmt,0))/@Cost                                           AS [Fraud Amount] 
,DAC.AssetClassName                                                                AS [IRAC Classification]
,CONVERT(VARCHAR(20),NPA_INTGD.NCIF_NPA_Date ,103)                                 AS [Npa Date]
,SUM(ISNULL(NPA_INTGD.Balance,0)-ISNULL(NPA_INTGD.UNSERVED_INTEREST,0))/@Cost      AS [GNPA]
,SUM(ISNULL(NPA_INTGD.TotalProvision,0))/@Cost                                     AS [Provision Amount]

 
FROM  DBO.NPA_IntegrationDetails NPA_INTGD
INNER JOIN [DimSourceSystem] DIMSOU                ON NPA_INTGD.SrcSysAlt_Key=DIMSOU.SourceAlt_Key
                                                      AND NPA_INTGD.EffectiveFromTimeKey<=@TimeKey 
													  AND NPA_INTGD.EffectiveToTimeKey>=@TimeKey
                                                      AND DIMSOU.EffectiveFromTimeKey<=@TimeKey 
													  AND DIMSOU.EffectiveToTimeKey>=@TimeKey

INNER JOIN   DimAssetClass DAC                     ON NPA_INTGD.NCIF_AssetClassAlt_Key=DAC.AssetClassAlt_Key
                                                      AND DAC.EffectiveFromTimeKey<=@TimeKey AND DAC.EffectiveToTimeKey>=@TimeKey
WHERE ISNULL(NPA_INTGD.IsFraud,'')='Y'

GROUP BY

 DIMSOU.SourceName           
,NPA_INTGD.NCIF_Id           
,NPA_INTGD.CustomerId        
,NPA_INTGD.CustomerName      
,NPA_INTGD.CustomerACID      
,NPA_INTGD.FraudDate                   
,DAC.AssetClassName  
,NPA_INTGD.NCIF_NPA_Date  

OPTION(RECOMPILE)      

GO