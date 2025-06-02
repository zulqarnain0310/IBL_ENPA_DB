SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROC [dbo].[Rpt-LowestAssetPerculation_Validation]
@DtEnter as varchar(20)
,@Cost as float
AS

--DECLARE	
--@DtEnter as varchar(20)='31/05/2021'
--,@Cost as float=1

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
Print @TimeKey 

IF OBJECT_ID('TEMPDB..#TEMP')IS NOT NULL
DROP TABLE #TEMP

-----------------------INSERTION OF NPAINTEGRATION TABLE INTO THE TEMP TABLE

SELECT * INTO #TEMP
FROM
(
SELECT
NPA_IntegrationDetails.NCIF_Id,
NPA_IntegrationDetails.ProductType,
NPA_IntegrationDetails.CustomerName,
NPA_IntegrationDetails.CustomerId,
NPA_IntegrationDetails.PAN,
NPA_IntegrationDetails.CustomerACID,
NPA_IntegrationDetails.SanctionedLimit,
NPA_IntegrationDetails.Balance,
NPA_IntegrationDetails.MaxDPD,
NPA_IntegrationDetails.DPD_Renewals,
NPA_IntegrationDetails.SubSegment,
NPA_IntegrationDetails.AC_AssetClassAlt_Key  ,
NPA_IntegrationDetails.AC_NPA_Date ,
NPA_IntegrationDetails.MOC_Status,
NPA_IntegrationDetails.MOC_AssetClassAlt_Key,
NPA_IntegrationDetails.MOC_NPA_Date,
NPA_IntegrationDetails.SrcSysAlt_Key,
NPA_IntegrationDetails.AstClsChngByUser,
NPA_IntegrationDetails.EffectiveFromTimeKey,
NPA_IntegrationDetails.EffectiveToTimeKey,
NPA_IntegrationDetails.AuthorisationStatus,
NPA_IntegrationDetails.NCIF_AssetClassAlt_Key,
NPA_IntegrationDetails.NCIF_NPA_Date,
NPA_IntegrationDetails.ProductAlt_Key,
NPA_IntegrationDetails.ActualOutStanding,
NPA_IntegrationDetails.PrincipleOutstanding,
NPA_IntegrationDetails.ActualPrincipleOutstanding,
NPA_IntegrationDetails.DrawingPower,
CUSTOMER_IDENTIFIER 

FROM NPA_IntegrationDetails 
WHERE EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey
AND NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN(7) and  ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200 
  AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
  	AND CASE        WHEN SrcSysAlt_Key = 10  AND CUSTOMER_IDENTIFIER = 'R' AND ( ISNULL(SanctionedLimit,0)<>0        
	                        OR ISNULL(DrawingPower,0)<>0 OR ISNULL(PrincipleOutstanding,0)<>0 OR ISNULL(BALANCE,0)<>0)  
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key = 10  AND CUSTOMER_IDENTIFIER = 'C'
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key = 20 AND ISNULL(ActualPrincipleOutstanding,0)<>0 AND ISNULL(Balance,0)<>0
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key = 60 AND ISNULL(PrincipleOutstanding,0)<>0 AND ISNULL(Balance,0)<>0
	                                        THEN 1
	
	                        WHEN SrcSysAlt_Key NOT IN (10, 20, 60)
	                                        THEN 1
	                        ELSE 0
	        END = 1

)A

OPTION(RECOMPILE)

CREATE  CLUSTERED INDEX IX_NCIF_ID1 ON #TEMP(CustomerACID)

CREATE NONCLUSTERED INDEX IX_ACC1 ON #TEMP(NCIF_ID)
							INCLUDE (ProductType,CustomerName,CustomerId,PAN,SanctionedLimit,Balance,MaxDPD,DPD_Renewals,SubSegment,AC_AssetClassAlt_Key,AC_NPA_Date,MOC_Status,MOC_AssetClassAlt_Key
							,MOC_NPA_Date,SrcSysAlt_Key,AstClsChngByUser,EffectiveToTimeKey,EffectiveFromTimeKey,AuthorisationStatus,NCIF_AssetClassAlt_Key
							,NCIF_NPA_Date,ProductAlt_Key,ActualOutStanding,PrincipleOutstanding)

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

OPTION(RECOMPILE)

--------------------------------------FINDING THE MAXIMUM AC_ASSET FROM TEMP DATA-----------------------																

IF OBJECT_ID('TEMPDB..#NCIF_ASSET')IS NOT NULL
DROP TABLE #NCIF_ASSET

--SELECT  * FROM NPA_IntegrationDetails WHERE NCIF_AssetClassAlt_Key<>0
SELECT  MAX(AC_AssetClassAlt_Key)AC_AssetClassAlt_Key,NCIF_Id  INTO #NCIF_ASSET
FROM #TEMP
WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) 
AND ISNULL(AC_AssetClassAlt_Key,'')<>'' 
AND (AC_AssetClassAlt_Key NOT IN(7)  and ISNULL(#TEMP.ProductAlt_Key,0)<>3200  )----EXCLUDE LOSS AND WRITE OFF
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
									 AND (A.AC_AssetClassAlt_Key NOT IN(7)
									 OR ISNULL(A.ProductAlt_Key,0)<>3200 )
									 AND ISNULL(A.AuthorisationStatus,'A')='A'
		GROUP BY A.NCIF_Id,A.AC_AssetClassAlt_Key

)B  ON		(EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
		AND (A.NCIF_Id=B.NCIF_Id)
		--AND ISNULL(A.AC_AssetClassAlt_Key,'')<>''
		AND ( A.AC_AssetClassAlt_Key NOT IN(7) and ISNULL(ProductAlt_Key,0)<>3200 )
		AND ISNULL(A.AuthorisationStatus,'A')='A'

OPTION(RECOMPILE)
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
			AND  NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7) and  ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200 
			  AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
			  AND (NPA_IntegrationDetails.NCIF_AssetClassAlt_Key IS NOT NULL AND NCIF_AssetClassAlt_Key<>1)
)A

OPTION(RECOMPILE)


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
				  AND NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7)  and  ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200 ---6 is removed----16_11_2017
				    AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
					  AND NPA_IntegrationDetails.NCIF_AssetClassAlt_Key IS NOT NULL

				 ) 
			
)B


OPTION(RECOMPILE)

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

,ISNULL(ImpactedAccounts.ActualPrincipleOutstanding,0)/@Cost AS IPOS

,DENSE_RANK() over(Partition by ImpactedAccounts.NCIF_Id order by ImpactedAccounts.CustomerACID	)	AS rank
															
,ISNULL(ImpactedAccounts.SanctionedLimit,0)/@Cost			AS LIMIT,
															
ISNULL(ImpactedAccounts.Balance,0)/@Cost					AS BALANCE,

ISNULL(ImpactedAccounts.DrawingPower,0)/@Cost				AS IDP,

IDimproduct.ProductCode									    AS IProduct,

IDimproduct.ProductName										AS IProductDescription,
															
ImpactedAccounts.MaxDPD										AS DPD,

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

,ISNULL(PerculatedAccounts.ActualPrincipleOutstanding,0)/@Cost	AS PPOS
										
,ISNULL(PerculatedAccounts.SanctionedLimit,0)/@Cost			AS PLIMIT,

ISNULL(PerculatedAccounts.Balance,0)/@Cost					AS PBALANCE,

ISNULL(PerculatedAccounts.DrawingPower,0)/@Cost				AS PDP,

PDimproduct.ProductCode									    AS PProduct,

PDimproduct.ProductName										AS PProductDescription,
		
PerculatedAccounts.MaxDPD									AS PDPD,

PerculatedAccounts.SubSegment								AS PSegment,

PerculatedAccounts.DPD_Renewals								AS PDPD_Renewal,

PerculatedAsset.AssetClassShortNameEnum						AS PAsset		---AS PER DISCUSSION WITH SHISHIR SIR			

,PerculatedAccounts.AC_AssetClassAlt_Key					As PAssetAlt

,CONVERT(VARCHAR(25),PerculatedAccounts.AC_NPA_Date,103)	AS PAC_NPA_Date

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

ORDER BY ENTCIF

OPTION(RECOMPILE)

DROP TABLE #TEMP,#IMPACTED,#NCIF_ASSET,#PERCOLATED





GO