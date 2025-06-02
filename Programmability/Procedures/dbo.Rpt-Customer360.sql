SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By		:- Baijayanti
Created Date	:- 18/06/2021
Report Name		:- Customer 360 Report
*/

CREATE PROC [dbo].[Rpt-Customer360]
@TimeKey AS INT
,@NCIF_ID AS VARCHAR(500)
,@CustomerID AS VARCHAR(500)
,@PAN AS VARCHAR(500)
,@Cost AS FLOAT
AS

--DECLARE	
--@TimeKey AS INT=26084,
--@NCIF_ID AS VARCHAR(500)='11464444',
--@CustomerID AS VARCHAR(500)='',
--@PAN AS VARCHAR(500)=NULL,
--@Cost AS FLOAT=1


---------------------------------------------------

SELECT 

NPAID.NCIF_Id                                                     AS UCIF,
NPAID.CustomerID,
NPAID.PAN,
NPAID.CustomerName,
DSS.SourceName,
NPAID.CustomerACID                                                AS AccountID,
NPAID.SubSegment                                                  AS SubSegment,		
NPAID.ProductCode                                                 AS SchemeProductCode,
NPAID.ProductDesc	                                              AS SchemeProductCodeDescription,
SUM(ISNULL(SanctionedLimit,0))/@Cost                              AS LimitSanctioned,
SUM(ISNULL(Balance,0))/@Cost                                      AS Balance,
SUM(ISNULL(PrincipleOutstanding,0))/@Cost                         AS PrincipleOutstanding,
DAC.AssetClassName                                                AS AC_AssetClass,
CONVERT(VARCHAR(20),NPAID.AC_NPA_Date,103)                        AS NPA_Date,
DANCIF.AssetClassName                                             AS NCIF_AssetClass,
CONVERT(VARCHAR(20),NPAID.NCIF_NPA_Date,103)                      AS UCIF_NPADate,
NPAID.PNPA_Status                                                 AS PotentialNPA,
CONVERT(VARCHAR(20),NPAID.PNPA_Date,103)                          AS PotentialNPA_Date,
''                                                                AS Ispercolated,
NPAID.MaxDPD                                                      AS DPD,
SUM(ISNULL(PrincOverdue,0))/@Cost                                 AS OverduePrincipal,
SUM(ISNULL(OtherOverdue,0))/@Cost                                 AS OtherOverdue,

''                                                                AS TableName 


FROM  NPA_IntegrationDetails	NPAID	
		

INNER JOIN DimAssetClass DAC					ON  DAC.AssetClassAlt_Key=NPAID.AC_AssetClassAlt_Key 
												    AND DAC.EffectiveFromTimeKey<=@TimeKey 
													AND DAC.EffectiveToTimeKey>=@TimeKey 
												    AND NPAID.EffectiveFromTimeKey<=@TimeKey 
													AND NPAID.EffectiveToTimeKey>=@TimeKey	

INNER JOIN DimAssetClass DANCIF				    ON  DANCIF.AssetClassAlt_Key=NPAID.NCIF_AssetClassAlt_Key 
												    AND DANCIF.EffectiveFromTimeKey<=@TimeKey 
													AND DANCIF.EffectiveToTimeKey>=@TimeKey

INNER JOIN DimSourceSystem	DSS					ON  DSS.SourceAlt_Key=NPAID.SrcSysAlt_Key
												    AND DSS.EffectiveFromTimeKey<=@TimeKey 
													AND DSS.EffectiveToTimeKey>=@TimeKey

WHERE (@NCIF_ID=NPAID.NCIF_Id  OR  @CustomerID=NPAID.CustomerID  OR  NPAID.PAN=@PAN)
	  
GROUP BY
NPAID.NCIF_Id,       
NPAID.CustomerID,
NPAID.PAN,
NPAID.CustomerName,
DSS.SourceName,
NPAID.CustomerACID,  
NPAID.SubSegment,    
NPAID.ProductCode ,  
NPAID.ProductDesc,	
DAC.AssetClassName,
NPAID.AC_NPA_Date,
DANCIF.AssetClassName,
NPAID.NCIF_NPA_Date,
NPAID.PNPA_Status ,
NPAID.PNPA_Date,
NPAID.MaxDPD




ORDER BY NPAID.CustomerName


OPTION(RECOMPILE)


GO