SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By		:- Baijayanti
Created Date	:- 18/06/2021
Report Name		:- Write off Exception Report
*/

CREATE PROC [dbo].[Rpt-WriteoffExceptionReport]
@TimeKey AS INT
,@Cost AS FLOAT
AS

--DECLARE	
--@TimeKey AS INT=24927,
--@Cost AS FLOAT=1



---------------------------------------------------

SELECT 
DSS.SourceName,
NPAID.NCIF_Id                                                     AS DedupeID,
NPAID.CustomerID                                                  AS CIF,
NPAID.CustomerName,
NPAID.CustomerACID                                                AS AccountNo,	
CONVERT(VARCHAR(20),NPAID.WriteOffDate,103)                       AS WriteOffDate,
SUM(ISNULL(Balance,0))/@Cost                                      AS Balance,
SUM(ISNULL(PrincipleOutstanding,0))/@Cost                         AS PrincipleOutstanding



FROM  NPA_IntegrationDetails	NPAID	


INNER JOIN DimSourceSystem	DSS					ON  DSS.SourceAlt_Key=NPAID.SrcSysAlt_Key
												    AND DSS.EffectiveFromTimeKey<=@TimeKey 
													AND DSS.EffectiveToTimeKey>=@TimeKey
												    AND NPAID.EffectiveFromTimeKey<=@TimeKey 
													AND NPAID.EffectiveToTimeKey>=@TimeKey	


WHERE WriteOffFlag='Y' AND  (ISNULL(Balance,0)<> 0 OR  ISNULL(PrincipleOutstanding,0) <> 0)			

GROUP BY
DSS.SourceName,
NPAID.NCIF_Id,      
NPAID.CustomerID ,  
NPAID.CustomerName ,
NPAID.WriteOffDate,
NPAID.CustomerACID


ORDER BY NPAID.CustomerName


OPTION(RECOMPILE)

GO