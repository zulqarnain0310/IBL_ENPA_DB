SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



CREATE PROC [dbo].[Rpt-MissedNPA]
@DtEnter as varchar(20)
,@Cost as Float
,@DimsourceSystem as int
AS


--DECLARE	
--@DtEnter as varchar(20)='31/05/2021'
--,@Cost AS FLOAT=1000
--,@DimsourceSystem as int=0


DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
Print @TimeKey 

BEGIN
	
	--DROP TABLE IF EXISTS #NCIF_ASSET
	--DECLARE @Timekey INT= 24927
 IF OBJECT_ID('TEMPDB..#NCIF_ASSET') IS NOT NULL
    DROP TABLE #NCIF_ASSET	

	SELECT	 *
	INTO #NCIF_ASSET
	FROM NPA_IntegrationDetails
	WHERE (EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
	AND ISNULL(AC_AssetClassAlt_Key,'')<>'' 
	AND AC_AssetClassAlt_Key <>7  ----EXCLUDE  WRITE OFF
	AND ISNULL(ProductAlt_Key,0)<>3200    ----Exclude Write Off product as discusseda with Shihsir sir on 19/12/2017
	AND ISNULL(AuthorisationStatus,'A')='A'
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

OPTION(RECOMPILE)
END	


CREATE NONCLUSTERED INDEX NCI_NCIF_ASSET ON #NCIF_ASSET(NCIF_Id)

 IF OBJECT_ID('TEMPDB..#MISSEDNPA') IS NOT NULL
    DROP TABLE #MISSEDNPA


SELECT COUNT(DISTINCT SrcSysAlt_Key)SrcSysAlt_Key,NCIF_Id  INTO #MISSEDNPA
	FROM  #NCIF_ASSET NPA_IntegrationDetails 

	INNER join DIMPRODUCT					ON DIMPRODUCT.ProductCode=NPA_IntegrationDetails.ProductCode
										    AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey
	
	WHERE NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
	----AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0
	AND  AC_AssetClassAlt_Key=1
	AND 
	(
		CASE WHEN  AgriFlag='N' and ( ISNULL(NPA_IntegrationDetails.MaxDPD,0)>90  OR ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)>180) THEN 1
									
				WHEN AgriFlag='Y' and	(ISNULL(NPA_IntegrationDetails.MaxDPD,0)>365 OR   ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)>180) tHeN 1							
											
		END =1 
	)
	GROUP BY NCIF_Id
	HAVING COUNT(DISTINCT SrcSysAlt_Key)>1

OPTION(RECOMPILE)

IF OBJECT_ID('TeMPDB..#NPA_IntegrationDetails') IS NOT NUlL
   DROp TABLE #NPA_IntegrationDetails

SELECT NCIF_Id,CustomerID,CustomerName,ProductType,CustomerACID,SanctionedLimit,ActualPrincipleOutstanding
,Balance,MaxDPD,DPD_Renewals,AC_AssetClassAlt_Key,AC_NPA_Date,SubSegment,DrawingPower
,SrcSysAlt_Key,ProductCode,ActualOutStanding,CUSTOMER_IDENTIFIER,PrincipleOutstanding
 INtO #NPA_IntegrationDetails
FROM  #NCIF_ASSET  A
WHErE NOT  ExISTS(SELECT 1 FROM NPA_IntegrationBillDetails B 
                     WHERE a.CustomerACID=B.CustomerACID AND EffectiveFromTimeKey<=@TimeKey 
					 AnD EffectiveToTimeKey>=@TimeKey
				 ) AND (A.EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
				 ----AND ISNULL(A.Balance,0)<>0
OPTION(RECOMPILE)

;WITH CTE AS 
(

SELECT 
DISTINCT
 
DimSourceSystem.SourceName										AS 'SourceSystem'


,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'

,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end											AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost					AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost							AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost		AS 'POS'

,NPA_IntegrationDetails.MaxDPD															AS 'MAXDPD'
														
,NPA_IntegrationDetails.DPD_Renewals													AS 'DPD_Renewals'

,NPA_IntegrationDetails.AC_AssetClassAlt_Key					AS 'ac_AssetClassAlt'

,DimAssetClass.AssetClassName									AS 'AssetClass'

,CONVERT(VARCHAR(20),NPA_IntegrationDetails.AC_NPA_Date,103)	AS 'NPADate'

,AgriFlag

,NPA_IntegrationDetails.SubSegment														AS 'Segment'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost									AS 'DP'

,ActualOutStanding,
CUSTOMER_IDENTIFIER,SrcSysAlt_Key,NPA_IntegrationDetails.PrincipleOutstanding

FROM #NPA_IntegrationDetails NPA_IntegrationDetails

INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey


INNER JOIN DimAssetClass				ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductCode=NPA_IntegrationDetails.ProductCode
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

INNER JOIN	SysDataMatrix				ON SysDataMatrix.TimeKey=@TimeKey													

--WHERE CustomerId='1000004'

WHERE 

AC_AssetClassAlt_Key=1
AND 
(
 CASE WHEN  AgriFlag='N' and ( ISNULL(NPA_IntegrationDetails.MaxDPD,0)>90  OR ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)>180) THEN 1
									
	   WHEN AgriFlag='Y' and	(ISNULL(NPA_IntegrationDetails.MaxDPD,0)>365 OR   ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)>180) tHeN 1							
											
								END =1 
)
--and 
--NPA_IntegrationDetails.CustomerACID='830001926593'
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)

--ORDER BY NCIF,NPA_IntegrationDetails.CustomerId,NPA_IntegrationDetails.AccountEntityID

UNION ALL 

SELECT 
DISTINCT
BILLSOURCE.SourceName											AS SourceSystem

,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'

,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(NPA_IntegrationDetails.CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost					AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost							AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost		AS 'POS'

,NPA_IntegrationDetails.MaxDPD															AS 'MAXDPD'
														
,NPA_IntegrationDetails.DPD_Renewals													AS 'DPD_Renewals'

,NPA_IntegrationDetails.AC_AssetClassAlt_Key					AS 'ac_AssetClassAlt'

,DimAssetClass.AssetClassName									AS 'AssetClass'

,CONVERT(VARCHAR(20),NPA_IntegrationDetails.AC_NPA_Date,103)	AS 'NPADate'

,AgriFlag

,NPA_IntegrationDetails.SubSegment														AS 'Segment'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost									AS 'DP'

,ActualOutStanding,
CUSTOMER_IDENTIFIER,NPA_IntegrationDetails.SrcSysAlt_Key,NPA_IntegrationDetails.PrincipleOutstanding

FROM NPA_IntegrationDetails


INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										 ----AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0

INNER JOIN DimAssetClass				ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductCode=NPA_IntegrationDetails.ProductCode
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

INNER JOIN	SysDataMatrix				ON SysDataMatrix.TimeKey=@TimeKey													
														--------------------Added after Discussion with Shishir sir---------------  
													--AND PreProcessingFreeze='Y'
													--AND PreProcessingFreezeDate IS NOT NULL
													--AND PreProcessingFreezeBy IS NOT NULL
inner JOIN NPA_IntegrationBillDetails	ON NPA_IntegrationBillDetails.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
										AND NPA_IntegrationBillDetails.CustomerACID=NPA_IntegrationDetails.CustomerACID

INNER JOIN DimSourceSystem BILLSOURCE	ON BILLSOURCE.SourceAlt_Key=NPA_IntegrationBillDetails.SrcSysAlt_Key
										AND BILLSOURCE.EffectiveFromTimeKey<@TimeKey AND BILLSOURCE.EffectiveToTimeKey>=@TimeKey


--WHERE CustomerId='1000004'

WHERE AC_AssetClassAlt_Key=1
AND 
(
 CASE WHEN  AgriFlag='N' and ( ISNULL(NPA_IntegrationDetails.MaxDPD,0)>90  OR ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)>180) THEN 1
									
	   WHEN AgriFlag='Y' and	(ISNULL(NPA_IntegrationDetails.MaxDPD,0)>365 OR   ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)>180) tHeN 1							
											
								END =1 
)
--and NPA_IntegrationDetails.CustomerACID='830001926593'
AND (BILLSOURCE.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)


-----------------------------------------CROSS MAPPED----------------------------------------------------------

UNION ALL


SELECT 
DISTINCT
 
DimSourceSystem.SourceName										AS 'SourceSystem'


,NPA_IntegrationDetails.NCIF_Id									AS 'NCIF'

,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,case when len(NPA_IntegrationDetails.CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost					AS 'Limit'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost							AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost		AS 'POS'

,NPA_IntegrationDetails.MaxDPD															AS 'MAXDPD'
														
,NPA_IntegrationDetails.DPD_Renewals													AS 'DPD_Renewals'

,NPA_IntegrationDetails.AC_AssetClassAlt_Key					AS 'ac_AssetClassAlt'

,DimAssetClass.AssetClassName									AS 'AssetClass'

,CONVERT(VARCHAR(20),NPA_IntegrationDetails.AC_NPA_Date,103)	AS 'NPADate'

,AgriFlag

,NPA_IntegrationDetails.SubSegment														AS 'Segment'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost									AS 'DP'

,ActualOutStanding,
CUSTOMER_IDENTIFIER,NPA_IntegrationDetails.SrcSysAlt_Key,NPA_IntegrationDetails.PrincipleOutstanding

FROM NPA_IntegrationDetails


INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
										AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										----AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0

INNER JOIN #MissedNPA MissedNPA			ON MissedNPA.NCIF_Id=NPA_IntegrationDetails.NCIF_Id


INNER JOIN DimAssetClass				ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
										AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DIMPRODUCT					ON DIMPRODUCT.ProductCode=NPA_IntegrationDetails.ProductCode
										AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

INNER JOIN	SysDataMatrix				ON SysDataMatrix.TimeKey=@TimeKey													

--WHERE CustomerId='1000004'

WHERE AC_AssetClassAlt_Key=1
AND 
(
 CASE WHEN  AgriFlag='N' and ( ISNULL(NPA_IntegrationDetails.MaxDPD,0)>90  OR ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)>180) THEN 1
									
	   WHEN AgriFlag='Y' and	(ISNULL(NPA_IntegrationDetails.MaxDPD,0)>365 OR   ISNULL(NPA_IntegrationDetails.DPD_Renewals,0)>180) tHeN 1							
											
								END =1 
)AND ( @DimsourceSystem=1)

)


SELECT * FROM CTE

OPTION(RECOMPILE)

DROP TABLE #MISSEDNPA,#NPA_IntegrationDetails,#NCIF_ASSET

GO