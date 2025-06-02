SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[Final_Asset_Class_Report]
AS
DECLARE	
@DtEnter as varchar(20)='31/05/2021'
,@Cost as float=1

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDataMatrix where date=@DtEnter1)
Print @TimeKey 

-------Added on 11032020 for With out WriteOff
IF object_id('Tempdb..#NCIF_ID_New') IS NOT NULL
DROP TABLE #NCIF_ID_New

Select distinct NCIF_Id into #NCIF_ID_New from NPA_IntegrationDetails 
Where EffectiveFromTimeKey<=@Timekey
And EffectiveToTimeKey>=@Timekey
And ISNULL(WriteOffFlag,'N')='Y'
And ISNULL(WriteOffDate,'1900-01-01')>='2019-04-01'
--------

IF object_id('Tempdb..#NCIF_ID') IS NOT NULL

DROP TABLE #NCIF_ID

Select NCIF_Id,NCIF_EntityID,max(AC_AssetClassAlt_Key)AC_AssetClassAlt_Key 
INTO #NCIF_ID
from NPA_IntegrationDetails A where EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey
AND A.AC_AssetClassAlt_Key NOT IN(1,7)
AND Not Exists (Select * from #NCIF_ID_New B Where B.NCIF_Id=A.NCIF_Id)
GROUP BY NCIF_Id,NCIF_EntityID



IF OBJECT_ID('TEMPDB..#TEMP')IS NOT NULL
DROP TABLE #TEMP

-----------------------INSERTION OF NPAINTEGRATION TABLE INTO THE TEMP TABLE

SELECT * INTO #TEMP
FROM
(
SELECT
A.NCIF_Id,
A.ProductType,
A.CustomerName,
A.CustomerId,
A.PAN,
A.CustomerACID,
A.SanctionedLimit,
A.Balance,
A.DPD_Overdue_Loans,
A.DPD_OtherOverdueSince,
A.DPD_PrincOverdue,
A.DPD_Interest_Not_Serviced,
A.DPD_Overdrawn,
A.DPD_Renewals,
A.DPD_StockStmt,
A.DPD_IntService,
A.SubSegment,
A.AC_AssetClassAlt_Key  ,
A.AC_NPA_Date ,
A.MOC_Status,
A.MOC_AssetClassAlt_Key,
A.MOC_NPA_Date,
A.SrcSysAlt_Key,
A.AstClsChngByUser,
A.EffectiveFromTimeKey,
A.EffectiveToTimeKey,
A.AuthorisationStatus,
A.NCIF_AssetClassAlt_Key,
A.NCIF_NPA_Date,
C.ProductAlt_Key,
A.ActualOutStanding,
A.PrincipleOutstanding,
A.ActualPrincipleOutstanding,
A.DrawingPower,
A.CUSTOMER_IDENTIFIER 

FROM NPA_IntegrationDetails A
INNER JOIN #NCIF_ID B ON B.NCIF_Id=A.NCIF_Id
inner Join DIMPRODUCT C on C.ProductCode=a.ProductCode
And C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey
WHERE A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
AND A.AC_AssetClassAlt_Key NOT IN(7)  
  AND ISNULL(A.MOC_AssetClassAlt_Key,0)<>1
  	AND CASE        WHEN SrcSysAlt_Key = 10  --AND CUSTOMER_IDENTIFIER = 'R' 
	--AND ( ISNULL(SanctionedLimit,0)<>0        
	--                        OR ISNULL(DrawingPower,0)<>0 --OR ISNULL(PrincipleOutstanding,0)<>0 OR ISNULL(BALANCE,0)<>0 Commented dated 24022020as POS/TOS <> 0 condition removed
	--						)  
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key = 10  --AND CUSTOMER_IDENTIFIER = 'C'
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key = 20 --AND ISNULL(ActualPrincipleOutstanding,0)<>0 AND ISNULL(Balance,0)<>0 Commented dated 21022020as POS/TOS <> 0 condition removed
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key = 60 --AND ISNULL(PrincipleOutstanding,0)<>0 AND ISNULL(Balance,0)<>0 Commented dated 21022020as POS/TOS <> 0 condition removed
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key NOT IN (10, 20, 60)
	                                        THEN 1
	                        ELSE 0
	        END = 1
UNION 

SELECT
A.NCIF_Id,
A.ProductType,
A.CustomerName,
A.CustomerId,
A.PAN,
A.CustomerACID,
A.SanctionedLimit,
A.Balance,
A.DPD_Overdue_Loans,
A.DPD_OtherOverdueSince,
A.DPD_PrincOverdue,
A.DPD_Interest_Not_Serviced,
A.DPD_Overdrawn,
A.DPD_Renewals,
A.DPD_StockStmt,
A.DPD_IntService,
A.SubSegment,
A.AC_AssetClassAlt_Key  ,
A.AC_NPA_Date ,
A.MOC_Status,
A.MOC_AssetClassAlt_Key,
A.MOC_NPA_Date,
A.SrcSysAlt_Key,
A.AstClsChngByUser,
A.EffectiveFromTimeKey,
A.EffectiveToTimeKey,
A.AuthorisationStatus,
A.NCIF_AssetClassAlt_Key,
A.NCIF_NPA_Date,
C.ProductAlt_Key,
A.ActualOutStanding,
A.PrincipleOutstanding,
A.ActualPrincipleOutstanding,
A.DrawingPower,
A.CUSTOMER_IDENTIFIER 

FROM NPA_IntegrationDetails A
INNER JOIN NPA_IntegrationDetails_MOD B ON B.NCIF_Id=A.NCIF_Id AND A.CustomerACID=B.CustomerACID
inner Join DIMPRODUCT C on C.ProductCode=a.ProductCode
And C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey
WHERE A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
AND B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey
)A
CREATE  CLUSTERED INDEX IX_NCIF_ID1 ON #TEMP(CustomerACID)

CREATE NONCLUSTERED INDEX IX_ACC1 ON #TEMP(NCIF_ID)
							INCLUDE (ProductType,CustomerName,CustomerId,PAN,SanctionedLimit,Balance,DPD_Renewals,SubSegment,AC_AssetClassAlt_Key,AC_NPA_Date,MOC_Status,MOC_AssetClassAlt_Key
							,MOC_NPA_Date,SrcSysAlt_Key,AstClsChngByUser,EffectiveToTimeKey,EffectiveFromTimeKey,AuthorisationStatus,NCIF_AssetClassAlt_Key
							,NCIF_NPA_Date,ActualOutStanding,PrincipleOutstanding)

--SELECT * FROM #TEMP WHERE  NCIF_Id='10842148'
------------------------------------UPDATING CHANGED ACC ASSET AND NPA DATE WITH THE ORIGINAL DATA---------------------------
UPDATE A
SET A.AC_AssetClassAlt_Key=B.AC_AssetClassAlt_Key
	,A.AC_NPA_Date=B.AC_NPA_Date
FROM #TEMP A

INNER JOIN(  select NPA_IntegrationDetails_MOD.NCIF_Id,NPA_IntegrationDetails_MOD.CustomerId,NPA_IntegrationDetails_MOD.CustomerACID,NPA_IntegrationDetails_MOD.AC_AssetClassAlt_Key,NPA_IntegrationDetails_MOD.AC_NPA_Date FROM #TEMP
			INNER JOIN NPA_IntegrationDetails_MOD				ON NPA_IntegrationDetails_MOD.NCIF_Id=#TEMP.NCIF_Id
																AND NPA_IntegrationDetails_MOD.CustomerACID=#TEMP.CustomerACID
																AND #TEMP.AstClsChngByUser='Y'
																AND NPA_IntegrationDetails_MOD.AuthorisationStatus='O'
																AND NPA_IntegrationDetails_MOD.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails_MOD.EffectiveToTimeKey>=@TimeKey
)B																ON B.NCIF_Id=A.NCIF_Id
																AND B.CustomerACID=A.CustomerACID
																AND A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey



--Select * from #TEMP order by Customeracid
--SELECT * FROM #TEMP WHERE  NCIF_Id='10842148'
--------------------------------------FINDING THE MAXIMUM AC_ASSET FROM TEMP DATA-----------------------																

IF OBJECT_ID('TEMPDB..#NCIF_ASSET')IS NOT NULL
DROP TABLE #NCIF_ASSET

--SELECT  * FROM NPA_IntegrationDetails WHERE NCIF_AssetClassAlt_Key<>0
SELECT  MAX(AC_AssetClassAlt_Key)AC_AssetClassAlt_Key,NCIF_Id  INTO #NCIF_ASSET
FROM #TEMP
WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) 
AND ISNULL(AC_AssetClassAlt_Key,'')<>'' 
AND (AC_AssetClassAlt_Key NOT IN(7)    )----EXCLUDE LOSS AND WRITE OFF
AND ISNULL(AuthorisationStatus,'A')='A'
GROUP BY NCIF_Id
option(RECOMPILE)
--SELECT * FROM #NCIF_ASSET WHERE  NCIF_Id='10842148'
------------------------------------PERCOLATED DATA WITH MAX ASSET CLASS----------------------------

UPDATE A
SET A.NCIF_AssetClassAlt_Key=B.AC_AssetClassAlt_Key
	,A.NCIF_NPA_Date=B.AC_NPA_Date
FROM #TEMP A
INNER JOIN
(
		
		SELECT MIN(AC_NPA_Date)AC_NPA_Date,A.NCIF_Id,A.AC_AssetClassAlt_Key
		 FROM #TEMP A  
		 INNER JOIN #NCIF_ASSET  B ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
		 AND A.NCIF_Id=B.NCIF_Id
		 AND A.AC_AssetClassAlt_Key=B.AC_AssetClassAlt_Key	
		 AND ISNULL(A.AC_AssetClassAlt_Key,'')<>''
		 AND (A.AC_AssetClassAlt_Key NOT IN(7))
		 AND ISNULL(A.AuthorisationStatus,'A')='A' 
		 GROUP BY A.NCIF_Id,A.AC_AssetClassAlt_Key

)B  ON		(EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
		AND (A.NCIF_Id=B.NCIF_Id)
		--AND ISNULL(A.AC_AssetClassAlt_Key,'')<>''
		AND ( A.AC_AssetClassAlt_Key NOT IN(7) )
		AND ISNULL(A.AuthorisationStatus,'A')='A'
		
--SELECT * FROM #TEMP WHERE  NCIF_Id='10842148'

--CREATE  CLUSTERED INDEX IX_NCIF_ID2 ON #TEMP(NCIF_ID)

--CREATE NONCLUSTERED INDEX IX_ACC2 ON #TEMP(NCIF_ID)
--								INCLUDE (AC_AssetClassAlt_Key,AC_NPA_DATE,NCIF_AssetClassAlt_Key,NCIF_NPA_Date,AuthorisationStatus,EffectiveToTimeKey,EffectiveFromTimeKey)
		  
---------------------------------------------------------------------------------------

IF OBJECT_ID('TEMPDB..#IMPACTED')IS NOT NULL
DROP TABLE #IMPACTED



SELECT * INTO #IMPACTED FROM
(
select *  
			from #TEMP NPA_IntegrationDetails
			where AC_AssetClassAlt_Key=NCIF_AssetClassAlt_Key
			and NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey and NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
			and iSnulL(AC_NPA_Date,'')=iSnULl(NCIF_NPA_Date,'')
			AND  NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7) 
			  AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
			  AND (NPA_IntegrationDetails.NCIF_AssetClassAlt_Key IS NOT NULL AND NCIF_AssetClassAlt_Key<>1)
)A

--SELECT * FROM #IMPACTED 


IF OBJECT_ID('TEMPDB..#PERCOLATED')IS NOT NULL
DROP TABLE #PERCOLATED


SELECT * INTO #PERCOLATED FROM
( 
select * 
			from  #TEMP NPA_IntegrationDetails
			where( (AC_AssetClassAlt_Key<>NCIF_AssetClassAlt_Key  
				  OR
				  isnuLL(AC_NPA_Date,'')<>isNUlL(NCIF_NPA_Date,'') )
				  and NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey and NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
				  AND NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7)  
				    AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
					  AND NPA_IntegrationDetails.NCIF_AssetClassAlt_Key IS NOT NULL

				 ) 
			
)B


--SELECT * FROM #PERCOLATED

;WITH CTE2 AS
(
SELECT * FROM
(

SELECT


ImpactedAccounts.NCIF_Id									AS  ENTCIF,

--------------------------------------IMPACTED ACCOUNTS-----------------------------------------

ImpactedSource.SourceName									AS  SOURCE ,
															
ImpactedAccounts.ProductType								AS FACILITY,
															
ImpactedAccounts.CustomerName								AS CUSTOMERNAME,
															
ImpactedAccounts.CustomerId									AS ICustomerID

,ImpactedAccounts.PAN										AS IPAN
															
,case when len(ImpactedAccounts.CustomerACID)=16
				then '''' + ImpactedAccounts.CustomerACID + '''' 
				else ImpactedAccounts.CustomerACID
				end											AS IMPACTEDAccount

,ISNULL(ImpactedAccounts.PrincipleOutstanding,0)/@Cost AS IPOS

,DENSE_RANK() over(Partition by ImpactedAccounts.NCIF_Id order by ImpactedAccounts.CustomerACID	)	AS rank
															
,ISNULL(ImpactedAccounts.SanctionedLimit,0)/@Cost			AS LIMIT,
															
ISNULL(ImpactedAccounts.Balance,0)/@Cost					AS BALANCE,

ISNULL(ImpactedAccounts.DrawingPower,0)/@Cost				AS IDP,

IDimproduct.ProductCode									    AS IProduct,

IDimproduct.ProductName										AS IProductDescription,
															
ImpactedAccounts.DPD_Overdue_Loans										AS DPD_OverdueLoans,

ImpactedAccounts.DPD_PrincOverdue										AS DPD_PrincOverdue,

ImpactedAccounts.DPD_OtherOverdueSince										AS DPD_OtherOverdue,

ImpactedAccounts.DPD_IntService										AS DPD_IntService,

ImpactedAccounts.DPD_Interest_Not_Serviced										AS DPD_Interest_Not_Serviced,

ImpactedAccounts.DPD_Overdrawn										AS DPD_Overdrawn,

ImpactedAccounts.DPD_StockStmt										AS DPD_StockStmt,

ImpactedAccounts.DPD_Renewals								AS IDPD_Renewal,

ImpactedAccounts.SubSegment									AS ISegment,
															
ImpactedAsset.AssetClassShortNameEnum						AS IAsset	---- as per discussion with shishir sir-03-11-2017		
															
,ImpactedAccounts.AC_AssetClassAlt_Key						As IAssetAlt

,CONVERT(VARCHAR(25),ImpactedAccounts.AC_NPA_Date,103)		AS IAC_NPA_Date

-------------------------------------PERCULATED Accounts----------------------------

,PerculatedSource.SourceName								AS  PSOURCE ,

PerculatedAccounts.ProductType								AS PFACILITY,

PerculatedAccounts.CustomerName								AS PCUSTOMERNAME,

PerculatedAccounts.CustomerId								AS PCustomerID

,PerculatedAccounts.PAN										AS PPAN

,case when len(PerculatedAccounts.CustomerACID)=16
				then '''' + PerculatedAccounts.CustomerACID + '''' 
				else PerculatedAccounts.CustomerACID
				end											AS PAccount

,ISNULL(PerculatedAccounts.PrincipleOutstanding,0)/@Cost	AS PPOS
										
,ISNULL(PerculatedAccounts.SanctionedLimit,0)/@Cost			AS PLIMIT,

ISNULL(PerculatedAccounts.Balance,0)/@Cost					AS PBALANCE,

ISNULL(PerculatedAccounts.DrawingPower,0)/@Cost				AS PDP,

PDimproduct.ProductCode									    AS PProduct,

PDimproduct.ProductName										AS PProductDescription,
		
PerculatedAccounts.DPD_Overdue_Loans									AS PDPD_Overdue_Loans,

PerculatedAccounts.DPD_OtherOverdueSince									AS PDPD_OtherOverdueSince,

PerculatedAccounts.DPD_PrincOverdue									AS PDPD_PrincOverdue,
PerculatedAccounts.DPD_IntService									AS PDPD_IntService,

PerculatedAccounts.DPD_Interest_Not_Serviced									AS PDPD_Interest_Not_Serviced,

PerculatedAccounts.DPD_Overdrawn									AS PDPD_Overdrawn,

PerculatedAccounts.DPD_StockStmt									AS PDPD_StockStmt,

PerculatedAccounts.SubSegment								AS PSegment,

PerculatedAccounts.DPD_Renewals								AS PDPD_Renewal,

PerculatedAsset.AssetClassShortNameEnum						AS OAsset		---AS PER DISCUSSION WITH SHISHIR SIR			

,PerculatedAccounts.AC_AssetClassAlt_Key					As OAssetAlt

,CONVERT(VARCHAR(25),PerculatedAccounts.AC_NPA_Date,103)	AS OAC_NPA_Date

,ImpactedAsset.AssetClassShortNameEnum						AS PAsset

,ImpactedAccounts.AC_AssetClassAlt_Key					As PAssetAlt

,CONVERT(VARCHAR(25),ImpactedAccounts.AC_NPA_Date,103)	AS PAC_NPA_Date

,ImpactedAccounts.MOC_Status								AS MOC_STATUS

,CONVERT(VARCHAR(25),ImpactedAccounts.MOC_NPA_Date,103)		AS MOC_NPA_Date

,MOCASSET.AssetClassName									AS MOC_ASSET_Class
	

,MOC_Freeze 

fROM #IMPACTED   ImpactedAccounts                 --ON ImpactedAccounts.NCIF_Id=#Temp.NCIF_Id


INNER JOIN  #PERCOLATED PerculatedAccounts			ON ImpactedAccounts.NCIF_Id=PerculatedAccounts.NCIF_Id
													----AND #Temp.NCIF_Id=PerculatedAccounts.NCIF_Id
												 -- AND (ISNULL(PerculatedAccounts.ActualPrincipleOutstanding,0)<>0)
		

INNER JOIN DimSourceSystem  ImpactedSource			ON ImpactedSource.SourceAlt_Key=ImpactedAccounts.SrcSysAlt_Key
													and ImpactedSource.EffectiveFromTimeKey<=@TimeKey and ImpactedSource.EffectiveToTimeKey>=@TimeKey


INNER JOIN DimSourceSystem  PerculatedSource		ON PerculatedSource.SourceAlt_Key=PerculatedAccounts.SrcSysAlt_Key
													and PerculatedSource.EffectiveFromTimeKey<=@TimeKey and PerculatedSource.EffectiveToTimeKey>=@TimeKey
	
																											
INNER  jOIN DIMASSETCLASS	ImpactedAsset			ON ImpactedAsset.AssetClassAlt_Key=ImpactedAccounts.AC_AssetClassAlt_Key
													and ImpactedAsset.EffectiveFromTimeKey<=@TimeKey and ImpactedAsset.EffectiveToTimeKey>=@TimeKey


INNER  JOIN DIMASSETCLASS	PerculatedAsset			ON PerculatedAsset.AssetClassAlt_Key=PerculatedAccounts.AC_AssetClassAlt_Key
													and PerculatedAsset.EffectiveFromTimeKey<=@TimeKey and PerculatedAsset.EffectiveToTimeKey>=@TimeKey

INNER JOIN	SysDataMatrix						    ON SysDataMatrix.TimeKey=@TimeKey						

LEFT JOIN DimProduct	IDimproduct					ON IDimproduct.ProductAlt_Key=ImpactedAccounts.ProductAlt_Key
													AND IDimproduct.EffectiveFromTimeKey<=@TimeKey AND IDimproduct.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimProduct	PDimproduct					 ON PDimproduct.ProductAlt_Key=PerculatedAccounts.ProductAlt_Key
													 AND PDimproduct.EffectiveFromTimeKey<=@TimeKey AND PDimproduct.EffectiveToTimeKey>=@TimeKey													

left JOIN DimAssetClass  MOCASSET					ON MOCASSET.AssetClassAlt_Key=ImpactedAccounts.MOC_AssetClassAlt_Key
													AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey

		  
)A
	
)

SELECT * FROM CTE2
where rank=1
--and ENTCIF='10123783'
ORDER BY ENTCIF

OPTION(RECOMPILE)

--Select * from #TEMP

--DROP TABLE #TEMP
--DROP TABLE #IMPACTED
--DROP TABLE #NCIF_ASSET
--DROP TABLE #PERCOLATED


GO