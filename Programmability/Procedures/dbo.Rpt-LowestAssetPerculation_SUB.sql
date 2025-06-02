SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
ALTERd By :- Vedika
ALTERd Date:-28/09/2017
Report Name :- Lowest Asset Classification Percolation Report
*/

CREATE PROC [dbo].[Rpt-LowestAssetPerculation_SUB]
@DtEnter as varchar(20)
,@Cost as float
AS


--DECLARE	
--@DtEnter as varchar(20)='28/02/2021'
--,@Cost as float=1

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
Print @TimeKey 



select * into #Temp
From 
(
select COUNT(CustomerACID)CustomerACID,

min(AC_AssetClassAlt_Key)AC_AssetClassAlt_Key,

max(NCIF_AssetClassAlt_Key)NCIF_AssetClassAlt_Key,

CustomerId 

from NPA_IntegrationDetails

group by CustomerId
having COUNT(CustomerACID)>1
and min(AC_AssetClassAlt_Key)<>MAX(NCIF_AssetClassAlt_Key)
)Demo

OPTION(RECOMPILE)

SELECT


NPAID.NCIF_Id					                 AS  ENTCIF,

--------------------------------------IMPACTED ACCOUNTS-----------------------------------------

DSS.SourceName						             AS  SOURCE ,
									             
NPAID.ProductType				                 AS FACILITY,
								                 
NPAID.CustomerName				                 AS CUSTOMERNAME,

NPAID.CustomerId				                 AS ICustomerID

,NPAID.CustomerACID			                     AS IMPACTEDAccount
										         
,ISNULL(NPAID.SanctionedLimit,0)/@Cost	         AS LIMIT,
										         
ISNULL(NPAID.Balance,0)/@Cost			         AS BALANCE,

''						                         AS DPD,

NPAID.AC_AssetClassAlt_Key

,DAC.AssetClassName				
 
,CONVERT(VARCHAR(25),NPAID.AC_NPA_Date ,103)     AS AC_NPA_Date
 


FROM #Temp
	
INNER JOIN NPA_IntegrationDetails  NPAID       ON NPAID.CustomerId=#Temp.CustomerId
										          AND NPAID.EffectiveFromTimeKey<=@TimeKey AND NPAID.EffectiveToTimeKey>=@TimeKey

INNER JOIN DimSourceSystem	DSS		           ON DSS.SourceAlt_Key=NPAID.SrcSysAlt_Key
									              AND DSS.EffectiveFromTimeKey<=@TimeKey AND DSS.EffectiveToTimeKey>=@TimeKey
																											
LEFT JOIN DIMASSETCLASS	DAC			           ON DAC.AssetClassAlt_Key=NPAID.AC_AssetClassAlt_Key
										          AND DAC.EffectiveFromTimeKey<=@TimeKey AND DAC.EffectiveToTimeKey>=@TimeKey
										
LEFT JOIN DimAssetClass DIMASSETCLASS1         ON DimAssetClass1.AssetClassAlt_Key=NPAID.NCIF_AssetClassAlt_Key
									              AND DIMASSETCLASS1.EffectiveFromTimeKey<=@TimeKey AND DIMASSETCLASS1.EffectiveToTimeKey>=@TimeKey


WHERE ISNULL(AC_NPA_Date,'')=ISNULL(NCIF_NPA_Date,'')


ORDER BY ENTCIF

OPTION(RECOMPILE)

DROP TABLE #Temp

GO