SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROC [dbo].[Fraud Accounts Report]
	@TimeKey AS int
	AS 
    SET NOCOUNT ON;


--DECLARE @TIMEKEY INT
--SET @TIMEKEY=25929

SELECT 
 DIMSOU.[SourceName] [Source System Name]
,NPA_INTGD.NCIF_Id   [Dedupe ID]
,NPA_INTGD.CustomerId    [CIF ID]
,NPA_INTGD.CustomerName  [Customer Name]
,NPA_INTGD.CustomerACID  [Account No]
,NPA_INTGD.FraudDate     [Fraud detection date]
,NPA_INTGD.FraudAmt      [Fraud Amount] 
,DimAssetClass.[AssetClassName] [IRAC Classification]
,NPA_INTGD.NCIF_NPA_Date        [Npa Date]
,NPA_INTGD.Balance-NPA_INTGD.UNSERVED_INTEREST [GNPA]
,NPA_INTGD.TotalProvision                      [Provision Amount]

										

--,NCIF_AssetClassAlt_Key
--,NPA_INTGD.IsFraud
 
FROM  DBO.NPA_IntegrationDetails NPA_INTGD
INNER JOIN [DimSourceSystem] DIMSOU ON NPA_INTGD.SrcSysAlt_Key=DIMSOU.[SourceAlt_Key]
AND NPA_INTGD.EFFECTIVEFROMTIMEKEY<=@TIMEKEY AND NPA_INTGD.EFFECTIVETOTIMEKEY>=@TIMEKEY
AND DIMSOU.EFFECTIVEFROMTIMEKEY<=@TIMEKEY AND DIMSOU.EFFECTIVETOTIMEKEY>=@TIMEKEY
LEFT  JOIN   DimAssetClass DimAssetClass ON NPA_INTGD.NCIF_AssetClassAlt_Key=DimAssetClass.[AssetClassAlt_Key] 
AND DimAssetClass.EFFECTIVEFROMTIMEKEY<=@TIMEKEY AND DimAssetClass.EFFECTIVETOTIMEKEY>=@TIMEKEY
WHERE NPA_INTGD.IsFraud='Y'



GO