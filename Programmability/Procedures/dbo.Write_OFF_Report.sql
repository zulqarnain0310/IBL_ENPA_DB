SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[Write_OFF_Report]
AS
Declare @DtEnter as varchar(20)='31/05/2021'
Declare @Cost as float =1



DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDataMatrix where date=@DtEnter1)
Print @TimeKey 

IF OBJECT_ID('TempDB..#NCIF_ID') IS NOT NULL
DROP TABLE #NCIF_ID

Select Distinct NCIF_Id into #NCIF_ID from NPA_IntegrationDetails 
Where EffectiveFromTimeKey<=@Timekey
And EffectiveToTimeKey>=@Timekey
AND ISNULL(Writeoffflag,'N')='Y'
And ISNULL(WriteOffDate,'1900-01-01')>='2019-04-01'
And ISNULL(AC_AssetClassAlt_Key,'')=7

IF OBJECT_ID('TempDB..#Original') IS NOT NULL
Drop Table #Original

Select A.* INTO #Original from NPA_IntegrationDetails A
INNER JOIN #NCIF_ID B ON A.NCIF_Id=B.NCIF_Id
--Inner Join DIMPRODUCT C On C.ProductCode=A.ProductCode
--And C.EffectiveFromTimeKey<=@Timekey
--And C.EffectiveToTimeKey>=@Timekey
Where A.EffectiveFromTimeKey<=@Timekey
And A.EffectiveToTimeKey>=@Timekey


IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
DROP TABLE #TEMP

Select * into #TEMP from #Original

---------For WriteOFF Accounts AC_AssetClassAlt_Key Change in #TEMP

--update #TEMP set AC_AssetClassAlt_Key=
--(Case  
--			when WriteOffFlag='Y' and 
--					DATEDIFF(day, AC_NPA_Date,(select ExtDate from IndusInd_UAT_Test.dbo.SysDataMatrix  where CurrentStatus='C'))between 0 and 365 then 2
--			when WriteOffFlag='Y' and 
--					DATEDIFF(day, AC_NPA_Date,(select ExtDate from IndusInd_UAT_Test.dbo.SysDataMatrix  where CurrentStatus='C'))between 366 and 730 then 3
--			when WriteOffFlag='Y' and 
--					DATEDIFF(day, AC_NPA_Date,(select ExtDate from IndusInd_UAT_Test.dbo.SysDataMatrix  where CurrentStatus='C'))between 731 and 1460 then 4
--			when WriteOffFlag='Y' and 
--					DATEDIFF(day, AC_NPA_Date,(select ExtDate from IndusInd_UAT_Test.dbo.SysDataMatrix  where CurrentStatus='C'))between 1461 and 99997 then 5
--			when WriteOffFlag='Y' and 
--					DATEDIFF(day, AC_NPA_Date,(select ExtDate from IndusInd_UAT_Test.dbo.SysDataMatrix  where CurrentStatus='C'))=99998 then 6
--			ELSE AC_AssetClassAlt_Key
--			END )

-- from #TEMP where WriteOffFlag='Y'

---------------------------------------------------


IF OBJECT_ID('TEMPDB..#IMPACTED')IS NOT NULL
DROP TABLE #IMPACTED



SELECT * INTO #IMPACTED FROM
(
select *  
			from #TEMP NPA_IntegrationDetails 
			WHERE   AC_AssetClassAlt_Key=NCIF_AssetClassAlt_Key
			and NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey and NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
			and iSnulL(AC_NPA_Date,'')=iSnULl(NCIF_NPA_Date,'')
			 AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
			  AND (NPA_IntegrationDetails.NCIF_AssetClassAlt_Key IS NOT NULL AND NCIF_AssetClassAlt_Key<>1)
			  AND (Case When NPA_IntegrationDetails.AC_AssetClassAlt_Key in (1,2,3,4,5,6) Then 1
						When  isnull(NPA_IntegrationDetails.writeoffdate,'1900-01-01')>='2019-04-01' and isnull(NPA_IntegrationDetails.WriteOffFlag,'N')='Y' then 1 else 0 end)=1
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
				  AND ISNULL(NPA_IntegrationDetails.MOC_AssetClassAlt_Key,0)<>1
					AND NPA_IntegrationDetails.NCIF_AssetClassAlt_Key IS NOT NULL
					AND (Case When NPA_IntegrationDetails.AC_AssetClassAlt_Key in (1,2,3,4,5,6) Then 1
						When  isnull(NPA_IntegrationDetails.writeoffdate,'1900-01-01')>='2019-04-01' and isnull(NPA_IntegrationDetails.WriteOffFlag,'N')='Y' then 1 else 0 end)=1

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

,DENSE_RANK() over(Partition by ImpactedAccounts.NCIF_Id order by ImpactedAccounts.CustomerACID,Original.Ac_AssetClassAlt_Key Desc	)	AS rank
															
,ISNULL(ImpactedAccounts.SanctionedLimit,0)/@Cost			AS LIMIT,
															
ISNULL(ImpactedAccounts.Balance,0)/@Cost					AS BALANCE,

ISNULL(ImpactedAccounts.DrawingPower,0)/@Cost				AS IDP,

--IDimproduct.ProductCode									    AS IProduct,

--IDimproduct.ProductName										AS IProductDescription,
															
															
ImpactedAccounts.DPD_Overdue_Loans										AS DPD_OverdueLoans,

ImpactedAccounts.DPD_PrincOverdue										AS DPD_PrincOverdue,

ImpactedAccounts.DPD_OtherOverdueSince										AS DPD_OtherOverdue,

ImpactedAccounts.DPD_IntService										AS DPD_IntService,

ImpactedAccounts.DPD_Interest_Not_Serviced										AS DPD_Interest_Not_Serviced,

ImpactedAccounts.DPD_Overdrawn										AS DPD_Overdrawn,

ImpactedAccounts.DPD_StockStmt										AS DPD_StockStmt,

ImpactedAccounts.DPD_Renewals								AS IDPD_Renewal,

ImpactedAccounts.SubSegment									AS ISegment,
															
--ImpactedAsset.AssetClassShortNameEnum						AS IAsset	---- as per discussion with shishir sir-03-11-2017		
OriginalAsset.AssetClassShortNameEnum						AS IAsset															

--,ImpactedAccounts.AC_AssetClassAlt_Key						As IAssetAlt
,Original.AC_AssetClassAlt_Key								AS IAssetAlt


,CONVERT(VARCHAR(25),ImpactedAccounts.AC_NPA_Date,103)		AS IAC_NPA_Date

,CONVERT(VARCHAR(25),Original.WriteOffDate,103)		AS IWriteOffDate

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

--PDimproduct.ProductCode									    AS PProduct,

--PDimproduct.ProductName										AS PProductDescription,
		
		
PerculatedAccounts.DPD_Overdue_Loans									AS PDPD_Overdue_Loans,

PerculatedAccounts.DPD_OtherOverdueSince									AS PDPD_OtherOverdueSince,

PerculatedAccounts.DPD_PrincOverdue									AS PDPD_PrincOverdue,
PerculatedAccounts.DPD_IntService									AS PDPD_IntService,

PerculatedAccounts.DPD_Interest_Not_Serviced									AS PDPD_Interest_Not_Serviced,

PerculatedAccounts.DPD_Overdrawn									AS PDPD_Overdrawn,

PerculatedAccounts.DPD_StockStmt									AS PDPD_StockStmt,
PerculatedAccounts.SubSegment								AS PSegment,

PerculatedAccounts.DPD_Renewals								AS PDPD_Renewal,

--PerculatedAsset.AssetClassShortNameEnum						AS PAsset		---AS PER DISCUSSION WITH SHISHIR SIR			
----OriginalAsset1.AssetClassShortNameEnum						AS PAsset

--,PerculatedAccounts.NCIF_AssetClassAlt_Key					As PAssetAlt
----,Original1.AC_AssetClassAlt_Key								AS PAssetAlt

--,CONVERT(VARCHAR(25),PerculatedAccounts.NCIF_NPA_Date,103)	AS PAC_NPA_Date

--,ImpactedAccounts.MOC_Status								AS MOC_STATUS

--,CONVERT(VARCHAR(25),ImpactedAccounts.MOC_NPA_Date,103)		AS MOC_NPA_Date

--,MOCASSET.AssetClassName									AS MOC_ASSET_Class
	

--,MOC_Freeze 

--,
Original1.AC_AssetClassAlt_Key								AS OAssetAlt

,CONVERT(VARCHAR(25),Original1.AC_NPA_Date,103)				AS OAC_NPA_Date

,CONVERT(VARCHAR(25),Original1.WriteOffDate,103)				AS OWriteOffDate

,PerculatedAsset.AssetClassShortNameEnum						AS PAsset		---AS PER DISCUSSION WITH SHISHIR SIR			
--OriginalAsset1.AssetClassShortNameEnum						AS PAsset

,PerculatedAccounts.NCIF_AssetClassAlt_Key					As PAssetAlt
--,Original1.AC_AssetClassAlt_Key								AS PAssetAlt

,CONVERT(VARCHAR(25),PerculatedAccounts.NCIF_NPA_Date,103)	AS PAC_NPA_Date

,CONVERT(VARCHAR(25),PerculatedAccounts.WriteOffDate,103)	AS PWriteOffDate

fROM #IMPACTED   ImpactedAccounts                


INNER JOIN  #PERCOLATED PerculatedAccounts			ON ImpactedAccounts.NCIF_Id=PerculatedAccounts.NCIF_Id
													
INNER JOIN #Original Original						ON 	ImpactedAccounts.CustomerACID=Original.CustomerACID

INNER JOIN #Original Original1						ON PerculatedAccounts.CustomerACID=Original1.CustomerACID

INNER JOIN DimSourceSystem  ImpactedSource			ON ImpactedSource.SourceAlt_Key=ImpactedAccounts.SrcSysAlt_Key
													and ImpactedSource.EffectiveFromTimeKey<=@TimeKey and ImpactedSource.EffectiveToTimeKey>=@TimeKey


INNER JOIN DimSourceSystem  PerculatedSource		ON PerculatedSource.SourceAlt_Key=PerculatedAccounts.SrcSysAlt_Key
													and PerculatedSource.EffectiveFromTimeKey<=@TimeKey and PerculatedSource.EffectiveToTimeKey>=@TimeKey
	
																											
INNER  jOIN DIMASSETCLASS	ImpactedAsset			ON ImpactedAsset.AssetClassAlt_Key=ImpactedAccounts.AC_AssetClassAlt_Key
													and ImpactedAsset.EffectiveFromTimeKey<=@TimeKey and ImpactedAsset.EffectiveToTimeKey>=@TimeKey


INNER  JOIN DIMASSETCLASS	PerculatedAsset			ON PerculatedAsset.AssetClassAlt_Key=PerculatedAccounts.NCIF_AssetClassAlt_Key
													and PerculatedAsset.EffectiveFromTimeKey<=@TimeKey and PerculatedAsset.EffectiveToTimeKey>=@TimeKey

INNER JOIN DIMASSETCLASS OriginalAsset1				ON OriginalAsset1.AssetClassAlt_Key=Original1.AC_AssetClassAlt_Key
													and OriginalAsset1.EffectiveFromTimeKey<=@TimeKey and OriginalAsset1.EffectiveToTimeKey>=@TimeKey

INNER JOIN DIMASSETCLASS OriginalAsset				ON OriginalAsset.AssetClassAlt_Key=Original.AC_AssetClassAlt_Key
													and OriginalAsset.EffectiveFromTimeKey<=@TimeKey and OriginalAsset.EffectiveToTimeKey>=@TimeKey


INNER JOIN	SysDataMatrix						    ON SysDataMatrix.TimeKey=@TimeKey						

--LEFT JOIN DimProduct	IDimproduct					ON IDimproduct.ProductAlt_Key=ImpactedAccounts.ProductAlt_Key
--													AND IDimproduct.EffectiveFromTimeKey<=@TimeKey AND IDimproduct.EffectiveToTimeKey>=@TimeKey

--LEFT JOIN DimProduct	PDimproduct					 ON PDimproduct.ProductAlt_Key=PerculatedAccounts.ProductAlt_Key
--													 AND PDimproduct.EffectiveFromTimeKey<=@TimeKey AND PDimproduct.EffectiveToTimeKey>=@TimeKey													

left JOIN DimAssetClass  MOCASSET					ON MOCASSET.AssetClassAlt_Key=ImpactedAccounts.MOC_AssetClassAlt_Key
													AND MOCASSET.EffectiveFromTimeKey<=@TimeKey AND MOCASSET.EffectiveToTimeKey>=@TimeKey

		  
)A
	
)

SELECT * FROM CTE2
where rank=1

ORDER BY ENTCIF



OPTION(RECOMPILE)
GO