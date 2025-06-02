SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[Rpt-Write_off_Data]
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
 					 		
CONVERT(VARCHAR(20),[DATE],103)                            AS AsOnDate, 
SourceName,
NCIF_Id                                                    AS DedupeID_UCIC_EnterpriseCIF,
CustomerID                                                 AS SourceSystem_CIF_CustomerIdentifier,
CustomerACID                                               AS AccountNo,
CONVERT(VARCHAR(20),WriteOffDt,103)                        AS WriteoffDate,
WO_PWO                                                     AS WriteoffType,
SUM(ISNULL(WriteOffAmt,0))/@Cost                           AS WriteoffamountInterest,
SUM(ISNULL(IntSacrifice,0))/@Cost                          AS WriteoffamountPrincipal,
ACWOD.Action

FROM  [dbo].[AdvAcWODetail]	ACWOD
INNER JOIN DimSourceSystem	DSS					ON  DSS.SourceAlt_Key=ACWOD.SrcSysAlt_Key
													AND DSS.EffectiveToTimeKey=49999
												    AND ACWOD.EffectiveToTimeKey=49999

INNER JOIN SysDayMatrix   SDM                   ON ACWOD.EffectiveFromTimeKey=SDM.TimeKey

WHERE ACWOD.EffectiveFromTimeKey BETWEEN @FromKey AND  @ToKey

GROUP BY
SourceName
,NCIF_Id
,CustomerID
,CustomerACID
,ACWOD.Action
,WriteOffDt
,WO_PWO
,[DATE]

OPTION(RECOMPILE)


GO