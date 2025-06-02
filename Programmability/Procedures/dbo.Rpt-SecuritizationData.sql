SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[Rpt-SecuritizationData]
	@FromDate  AS VARCHAR(20),
	@ToDate  AS VARCHAR(20),
	@Cost AS FLOAT

	AS 

--DECLARE 
--	@FromDate  AS VARCHAR(20)='01-06-2021',
--	@ToDate  AS VARCHAR(20)='10-06-2021',
--	@Cost AS FLOAT=1


DECLARE	@From1		DATE=(SELECT Rdate FROM dbo.DateConvert(@FromDate))
DECLARE @To1		DATE=(SELECT Rdate FROM dbo.DateConvert(@ToDate))

DECLARE @FromKey AS INT=(SELECT TimeKey FROM SysDayMatrix WHERE [DATE]=@From1)
DECLARE @ToKey  AS INT=(SELECT TimeKey FROM SysDayMatrix WHERE [DATE]=@To1)


SELECT
CONVERT(VARCHAR(20),[DATE],103)                                             AS AsOnDate,
PAN,
NCIF_Id                                                                     AS DedupeID_UCICEnterpriseCIF,
CustomerName,
CustomerACID                                                                AS CustomerAccountNo,
LoanAgreementNo,
BuyoutPartyLoanNo                                                           AS IndusindLoanAccountNo,
SUM(ISNULL(InterestReceivable,0)+ISNULL(PrincipalOutstanding,0))/@Cost      AS TotalOutstanding,
SUM(ISNULL(InterestReceivable,0))/@Cost                                     AS UnrealizedInterest,
SUM(ISNULL(PrincipalOutstanding,0))/@Cost                                   AS PrincipalOutstanding,
DAC.AssetClassName                                                          AS AssetClassification,
CONVERT(VARCHAR(20),FinalNpaDt,103)                                         AS NPADate,
DPD,
SUM(ISNULL(SecurityValue,0))/@Cost                                          AS SecurityAmount,
BFD.Action

FROM  [dbo].[BuyoutFinalDetails]	BFD
INNER JOIN SysDayMatrix   SDM                          ON BFD.EffectiveFromTimeKey=SDM.TimeKey
                                                          AND BFD.EffectiveToTimeKey=49999

INNER JOIN DimAssetClass DAC                           ON BFD.FinalAssetClassAlt_Key=DAC.AssetClassAlt_Key
                                                          AND DAC.EffectiveToTimeKey=49999
       

WHERE BFD.EffectiveFromTimeKey BETWEEN @FromKey AND  @ToKey

GROUP BY
[DATE],
PAN,
NCIF_Id,           
CustomerName,
CustomerACID,      
LoanAgreementNo,
BuyoutPartyLoanNo, 
AssetClass,
FinalNpaDt,
DPD,
BFD.Action,
DAC.AssetClassName

OPTION(RECOMPILE)


GO