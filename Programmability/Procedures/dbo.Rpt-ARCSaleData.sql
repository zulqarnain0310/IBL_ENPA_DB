SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[Rpt-ARCSaleData]
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
CONVERT(VARCHAR(20),[DATE],103)                                             AS AsOnDate 
,SourceName
,NCIF_Id
,CustomerID
,AccountID
,CONVERT(VARCHAR(20),SARCF.DtofsaletoARC,103)               AS DtofsaletoARC
,SUM(ISNULL(POS,0)+ISNULL(InterestReceivable,0))/@Cost      AS [Total Sale Consideration]
,SUM(ISNULL(POS,0))/@Cost                                   AS POS
,SUM(ISNULL(InterestReceivable,0))/@Cost                    AS InterestReceivable
,SARCF.Action

FROM  [DBO].[SaletoARCFinalACFlagging]	SARCF
INNER JOIN DimSourceSystem	DSS					  ON  DSS.SourceAlt_Key=SARCF.SrcSysAlt_Key 
													  AND DSS.EffectiveToTimeKey=49999
												      AND SARCF.EffectiveToTimeKey=49999

INNER JOIN SysDayMatrix   SDM                     ON SARCF.EffectiveFromTimeKey=SDM.TimeKey

WHERE SARCF.EffectiveFromTimeKey BETWEEN @FromKey AND @ToKey

GROUP BY
SourceName
,NCIF_Id
,CustomerID
,AccountID
,SARCF.Action
,SARCF.DtofsaletoARC
,[DATE]

OPTION(RECOMPILE)


GO