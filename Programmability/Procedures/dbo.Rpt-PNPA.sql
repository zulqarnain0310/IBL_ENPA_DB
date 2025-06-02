SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


----------------MODIFIED PNPA---------------------------
/*
ALTERD BY:- VEDIKA
ALTERD DATE :- 06-10-2017
REPORT NAME :- Potential NPA 
*/

CREATE Proc [dbo].[Rpt-PNPA]
@DtEnter as varchar(20)
,@Cost as Float
,@DimsourceSystem as int
with recompile
AS

--DECLARE	
--@DtEnter as varchar(20)='31/03/2018'
--,@Cost AS FLOAT=1
--,@DimsourceSystem as int=0

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
--Print @TimeKey 

Declare @MonthEndDate as date =(Select MonthLastDate from SysDataMatrix where MonthLastDate=@DtEnter1)

 Declare @MonthEndDate1 as date = (SELECT EOMONTH ( @MonthEndDate, 1 ))
 --print @MonthEndDate1


  IF OBJECT_ID ('tempdb..#PNPA') is not null
   DROP TABLE #PNPA

SELECT * INTO #PNPA
FROM
(
SELECT COUNT(DISTINCT SrcSysAlt_Key)SrcSysAlt_Key,NCIF_Id 
	FROM NPA_IntegrationDetails 
	WHERE NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
	AND PNPA_Status='Y'
	GROUP BY NCIF_Id
	HAVING COUNT(DISTINCT SrcSysAlt_Key)>1
)PNPA

OPTION(RECOMPILE)

IF OBJECT_ID('tempdb..#temptable21') is not null
 DROP TABLE #temptable21


SELECT CustomerID,customerACID,Split.a.value('.', 'VARCHAR(100)') AS PNPAReason into #temptable21   FROM (
Select CustomerID,CustomerACID,CAST ('<M>' + REPLACE(PNPA_ReasonAlt_Key, ',', '</M><M>') + '</M>' AS XML) AS AdvocateList  
  from NPA_IntegrationDetails  where NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
  ) D CROSS APPLY AdvocateList.nodes ('/M') AS Split(a)  

OPTION(RECOMPILE)

---------------------------------PNPA REASON-----------------------------------   
if object_id('tempdb..#PNPAReason') is not null
 drop table #PNPAReason

select * into #PNPAReason
FROM
(
SELECT  
D2.CustomerID CustomerID, DA.CustomerACID,D2.PNPAReason  
FROM  NPA_IntegrationDetails DA
INNER JOIN #temptable21  D2 ON D2.CustomerACID =DA.CustomerACID
AND DA.EffectiveFromTimeKey<=@TimeKey AND DA.EffectiveToTimeKey>=@TimeKey
  )Reason

OPTION(RECOMPILE)

CREATE  CLUSTERED INDEX IX_CUSTOMERACID ON #PNPAReason(cUSTOMERACID)


SELECT * INTO #TEMP

FROM

(
SELECT NPA_IntegrationDetails.NCIF_Id,
		NPA_IntegrationDetails.CustomerID,
		DimSourceSystem.SourceName	,
		NPA_IntegrationDetails.CustomerName,
		NPA_IntegrationDetails.CustomerACID ACID,
		case when len(NPA_IntegrationDetails.CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end CustomerACID
				,
		''						as BillNo,
		Segment,
		NPA_IntegrationDetails.ProductCode,
		NPA_IntegrationDetails.ProductType,
		NPA_IntegrationDetails.SanctionedLimit,
		NPA_IntegrationDetails.DrawingPower,
		NPA_IntegrationDetails.Balance,
		NPA_IntegrationDetails.ActualPrincipleOutstanding,
		Overdue,
		UNSERVED_INTEREST,
		DIMPRODUCT.ProductName,
		NPA_IntegrationDetails.DPD,
		NPA_IntegrationDetails.DPD_Overdue_Loans,
		NPA_IntegrationDetails.DPD_Interest_Not_Serviced,
		NPA_IntegrationDetails.DPD_Overdrawn,
		NPA_IntegrationDetails.DPD_Renewals,
		NPA_IntegrationDetails.PNPA_Date,
		NPA_IntegrationDetails.NF_PNPA_Date,
		NPA_IntegrationDetails.SubSegment,
	    NPA_IntegrationDetails.MaxDPD,
		NPA_IntegrationDetails.SrcSysAlt_Key,
		NPA_IntegrationDetails.ProductAlt_Key,
		NPA_IntegrationDetails.AC_AssetClassAlt_Key,
		PNPA_Status,
		#PNPAReason.PNPAReason PNPA_ReasonAlt_Key,
		DimAssetClass.AssetClassName,
		DimPNPA_Reason.PNPA_ReasonName	,
		----0				SRNO,
		@MonthEndDate1 date,
		CUSTOMER_IDENTIFIER,
		PrincipleOutstanding,
	    ActualOutStanding

		FROM NPA_IntegrationDetails
		
		INNER JOIN #PNPAReason					ON #PNPAReason.CustomerACID=NPA_IntegrationDetails.CustomerACID
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
													
		INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
												----AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0

		INNER JOIN DimAssetClass			    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
												AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey


		LEFT join DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										        AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

		INNER JOIN DimPNPA_Reason				ON DimPNPA_Reason.PNPA_ReasonAlt_Key=#PNPAReason.PNPAReason
												AND DimPNPA_Reason.EffectiveFromTimeKey<=@TimeKey AND DimPNPA_Reason.EffectiveToTimeKey>=@TimeKey
												AND DimPNPA_Reason.PNPA_ReasonAlt_Key<>90
----INNER JOIN  SysDataMatrix				ON SysDataMatrix.TimeKey=NPA_IntegrationDetails.EffectiveToTimeKey


WHERE 

NPA_IntegrationDetails.PNPA_Status='Y'
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)

)TEMP

OPTION(RECOMPILE)
CREATE  CLUSTERED INDEX IX_CustomerEntityID ON #TEMP(NCIF_Id)

CREATE NONCLUSTERED INDEX IX_BranchCode ON #TEMP(NCIF_Id)
INCLUDE (CustomerID,CustomerName,CustomerACID,Segment,ProductCode,ProductType,SanctionedLimit,DrawingPower,Balance,Overdue,DPD,DPD_Overdue_Loans,DPD_Interest_Not_Serviced,DPD_Overdrawn,DPD_Renewals,PNPA_Date,MaxDPD,SrcSysAlt_Key,ProductAlt_Key,AC_AssetClassAlt_Key,PNPA_Status,PNPA_ReasonAlt_Key)

--select * from #TEMP where NCIF_Id='1281950'

---------------------------------------------------ECBF & TRADEPROT-------------------------------

SELECT * INTO #TEMP1

FROM

(
SELECT NPA_IntegrationDetails.NCIF_Id,
		NPA_IntegrationDetails.CustomerID,
		DimSourceSystem.SourceName	,
		NPA_IntegrationDetails.CustomerName,
		NPA_IntegrationDetails.CustomerACID ACID,
		case when len(NPA_IntegrationDetails.CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID + '''' 
				else NPA_IntegrationDetails.CustomerACID
				end CustomerACID,
		NPA_IntegrationBillDetails.BillNo,
		----ROW_NUMBER() over( partition by NPA_IntegrationBillDetails.CustomerACID order by NPA_IntegrationBillDetails.CustomerACID)sr_no,
		NPA_IntegrationDetails.Segment,
		NPA_IntegrationDetails.ProductCode,
		NPA_IntegrationDetails.ProductType,
		NPA_IntegrationDetails.SanctionedLimit,
		NPA_IntegrationDetails.DrawingPower,
		NPA_IntegrationBillDetails.Balance,
		NPA_IntegrationBillDetails.Overdue,
		0 UNSERVED_INTEREST	,		
		NPA_IntegrationDetails.ActualPrincipleOutstanding,
		DIMPRODUCT.ProductName,
		NPA_IntegrationDetails.DPD,
		NPA_IntegrationDetails.DPD_Overdue_Loans,
		NPA_IntegrationDetails.DPD_Interest_Not_Serviced,
		NPA_IntegrationDetails.DPD_Overdrawn,
		NPA_IntegrationDetails.DPD_Renewals,
		NPA_IntegrationDetails.PNPA_Date,
		NPA_IntegrationDetails.NF_PNPA_Date,
		NPA_IntegrationDetails.SubSegment,
	    NPA_IntegrationDetails.MaxDPD,
		NPA_IntegrationDetails.SrcSysAlt_Key,
		NPA_IntegrationDetails.ProductAlt_Key,
		NPA_IntegrationDetails.AC_AssetClassAlt_Key,
		PNPA_Status,
		#PNPAReason.PNPAReason PNPA_ReasonAlt_Key,
		DimAssetClass.AssetClassName,
		DimPNPA_Reason.PNPA_ReasonName	,
		@MonthEndDate1 date,
		CUSTOMER_IDENTIFIER,
		NPA_IntegrationDetails.PrincipleOutstanding,
	    ActualOutStanding

		FROM NPA_IntegrationDetails
		
		INNER JOIN  NPA_IntegrationBillDetails	ON NPA_IntegrationBillDetails.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
												AND NPA_IntegrationDetails.CustomerACID=NPA_IntegrationBillDetails.CustomerACID
												AND NPA_IntegrationBillDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationBillDetails.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												and NPA_IntegrationBillDetails.MaxDPD=NPA_IntegrationDetails.DPD_Overdue_Loans		---It should be change as dpd_overdue_loan because at client side maxdpd gets updated into overdue_loan
												--and NPA_IntegrationBillDetails.NCIF_Id='14364262'
												----AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0

		
		INNER JOIN #PNPAReason					ON #PNPAReason.CustomerACID=NPA_IntegrationDetails.CustomerACID

		INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationBillDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey


		INNER JOIN DimAssetClass			    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
												AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey


		left join DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										        AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

		INNER JOIN DimPNPA_Reason				ON DimPNPA_Reason.PNPA_ReasonAlt_Key=#PNPAReason.PNPAReason
												AND DimPNPA_Reason.EffectiveFromTimeKey<=@TimeKey AND DimPNPA_Reason.EffectiveToTimeKey>=@TimeKey
												AND DimPNPA_Reason.PNPA_ReasonAlt_Key=90
----INNER JOIN  SysDataMatrix				ON SysDataMatrix.TimeKey=NPA_IntegrationDetails.EffectiveToTimeKey


WHERE 

NPA_IntegrationDetails.PNPA_Status='Y'
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)
)TEMP

OPTION(RECOMPILE)

CREATE  CLUSTERED INDEX IX_CustomerEntityID ON #TEMP1(NCIF_Id)

CREATE NONCLUSTERED INDEX IX_BranchCode ON #TEMP1(NCIF_Id)
INCLUDE (CustomerID,CustomerName,CustomerACID,Segment,ProductCode,ProductType,SanctionedLimit,DrawingPower,Balance,Overdue,DPD,DPD_Overdue_Loans,DPD_Interest_Not_Serviced,DPD_Overdrawn,DPD_Renewals,PNPA_Date,MaxDPD,SrcSysAlt_Key,ProductAlt_Key,AC_AssetClassAlt_Key,PNPA_Status,PNPA_ReasonAlt_Key)


-------------------------------------MAIN QUERY-------------------------------------------

SELECT 

distinct 

NPA_IntegrationDetails.NCIF_Id									AS 'Dedup NCIF'

,NPA_IntegrationDetails.SourceName								AS 'SourceSystem'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'

,NPA_IntegrationDetails.CustomerACID							AS 'Account No.'

,''																AS 'BillNo'

----,0																AS 'SRNO'

,Segment														AS 'Customer Segment'

,NPA_IntegrationDetails.ProductCode								AS 'Scheme_ProductCode'

,NPA_IntegrationDetails.ProductName								AS 'Scheme_ProductCodeDescription'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost			AS 'DrawingPower'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost AS 'POS'

,CASE WHEN SrcSysAlt_Key=10 AND ProductType='ODA'
	  THEN ( CASE WHEN ISNULL(Overdue,0)>ISNULL(UNSERVED_INTEREST,0)
				THEN ISNULL(Overdue,0)
				ELSE ISNULL(UNSERVED_INTEREST,0)
				END)
      ELSE ISNULL(Overdue,0)
	  END														AS 'IrregularAmount'			

--ISNULL (CASE WHEN ISNULL(Overdue,0)>ISNULL(UNSERVED_INTEREST,0)
--	  THEN Overdue
--	  ELSE UNSERVED_INTEREST 
--	  END,0)/@Cost												AS 'IrregularAmount'

,NPA_IntegrationDetails.DPD										AS 'DPD'

,NPA_IntegrationDetails.DPD_Overdue_Loans						AS 'DPD_Overdue_Loan'

,NPA_IntegrationDetails.DPD_Interest_Not_Serviced				AS 'DPD_InterestNotService'

,NPA_IntegrationDetails.DPD_Overdrawn							AS 'DPD_Overdrawn'

,NPA_IntegrationDetails.DPD_Renewals							AS 'DPD_Renewals'

,convert(varchar(20),NPA_IntegrationDetails.PNPA_Date,103)		AS 'PNPA_Date'

,CONVERT(varchar(25),NPA_IntegrationDetails.NF_PNPA_Date,103)	AS 'NF_PNPA_Date'

,NPA_IntegrationDetails.SubSegment
	
,MaxDPD															AS 'MaxDPD'

,NPA_IntegrationDetails.AssetClassName							AS 'AssetClass'

,case when PNPA_ReasonAlt_Key=80
	  then NPA_IntegrationDetails.PNPA_ReasonName + ' ' +  cast(MaxDPD as varchar(25))						
	  else NPA_IntegrationDetails.PNPA_ReasonName
	  end														
	  AS	'ReasonForDefault'

,date

,CUSTOMER_IDENTIFIER

,ISNULL(ActualOutStanding,0) ActualOutStanding

,ISNULL(PrincipleOutstanding,0) PrincipleOutstanding

,NPA_IntegrationDetails.SrcSysAlt_Key

FROM  #TEMP  NPA_IntegrationDetails

--where  NPA_IntegrationDetails.NCIF_Id='17710096'

----------------------------------------ECBF & TRADEPRO---------------------------

UNION ALL


SELECT 

distinct 

NPA_IntegrationDetails.NCIF_Id									AS 'Dedup NCIF'

,NPA_IntegrationDetails.SourceName								AS 'SourceSystem'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'

,NPA_IntegrationDetails.CustomerACID							AS 'Account No.'

,NPA_IntegrationDetails.BillNo									AS 'BillNo'

----,sr_no															AS 'SRNO'

,Segment														AS 'Customer Segment'

,NPA_IntegrationDetails.ProductCode								AS 'Scheme_ProductCode'

,NPA_IntegrationDetails.ProductName								AS 'Scheme_ProductCodeDescription'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost			AS 'DrawingPower'

,ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost					AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost AS 'POS'

,ISNULL(Overdue,0)/@Cost										AS 'IrregularAmount'

,NPA_IntegrationDetails.DPD										AS 'DPD'

,NPA_IntegrationDetails.DPD_Overdue_Loans						AS 'DPD_Overdue_Loan'

,NPA_IntegrationDetails.DPD_Interest_Not_Serviced				AS 'DPD_InterestNotService'

,NPA_IntegrationDetails.DPD_Overdrawn							AS 'DPD_Overdrawn'

,NPA_IntegrationDetails.DPD_Renewals							AS 'DPD_Renewals'

,convert(varchar(20),NPA_IntegrationDetails.PNPA_Date,103)		AS 'PNPA_Date'

,CONVERT(varchar(25),NPA_IntegrationDetails.NF_PNPA_Date,103)	AS 'NF_PNPA_Date'

,NPA_IntegrationDetails.SubSegment
	
,MaxDPD															AS 'MaxDPD'

,NPA_IntegrationDetails.AssetClassName							AS 'AssetClass'

,case when PNPA_ReasonAlt_Key=80
	  then NPA_IntegrationDetails.PNPA_ReasonName + ' ' +  cast(MaxDPD as varchar(25))						
	  else NPA_IntegrationDetails.PNPA_ReasonName
	  end														
	  AS	'ReasonForDefault'

,date

,CUSTOMER_IDENTIFIER

,ISNULL(ActualOutStanding,0) ActualOutStanding

,ISNULL(PrincipleOutstanding,0) PrincipleOutstanding

,NPA_IntegrationDetails.SrcSysAlt_Key
FROM  #TEMP1  NPA_IntegrationDetails
 --where  NPA_IntegrationDetails.NCIF_Id='1281950'
--WHERE sr_no=1
--where  NPA_IntegrationDetails.NCIF_Id='17710096'
UNION ALL
--------------------------------CROSS MAPPED (Single ENTCIF with Multiple Sources)------------------------------------------

SELECT 

DISTINCT 

NPA_IntegrationDetails.NCIF_Id									AS 'Dedup NCIF'

,DimSourceSystem.SourceName										AS 'SourceSystem'

,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'

,NPA_IntegrationDetails.CustomerACID							AS 'Account No.'

,NPA_IntegrationBillDetails.BillNo								AS 'BillNo'

----,0																AS 'SRNO'

,NPA_IntegrationDetails.Segment									AS 'Customer Segment'

,NPA_IntegrationDetails.ProductCode								AS 'Scheme_ProductCode'

,DIMPRODUCT.ProductName											AS 'Scheme_ProductCodeDescription'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost			AS 'DrawingPower'

,case when DimPNPA_Reason.PNPA_ReasonAlt_Key<>90
	  then ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost
	  else isnull(NPA_IntegrationBillDetails.Balance,0)/@Cost
	 end 														AS 'Outstanding'


,CASE WHEN NPA_IntegrationDetails.SrcSysAlt_Key=10 AND NPA_IntegrationDetails.ProductType='ODA'
	  THEN ( CASE WHEN ISNULL(NPA_IntegrationDetails.Overdue,0)>ISNULL(UNSERVED_INTEREST,0)
				THEN ISNULL(NPA_IntegrationDetails.Overdue,0)
				ELSE ISNULL(UNSERVED_INTEREST,0)
				END)
      ELSE ISNULL(NPA_IntegrationDetails.Overdue,0)
	  END														AS 'IrregularAmount'		

--,ISNULL(CASE WHEN ISNULL(NPA_IntegrationDetails.Overdue,0)>ISNULL(NPA_IntegrationDetails.UNSERVED_INTEREST,0)
--	  THEN NPA_IntegrationDetails.Overdue
--	  ELSE NPA_IntegrationDetails.UNSERVED_INTEREST 
--	  END,0)/@Cost													AS 'IrregularAmount'

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost AS 'POS'

,NPA_IntegrationDetails.DPD										AS 'DPD'

,NPA_IntegrationDetails.DPD_Overdue_Loans						AS 'DPD_Overdue_Loan'

,NPA_IntegrationDetails.DPD_Interest_Not_Serviced				AS 'DPD_InterestNotService'

,NPA_IntegrationDetails.DPD_Overdrawn							AS 'DPD_Overdrawn'

,NPA_IntegrationDetails.DPD_Renewals							AS 'DPD_Renewals'

,convert(varchar(20),NPA_IntegrationDetails.PNPA_Date,103)		AS 'PNPA_Date'

,CONVERT(varchar(25),NPA_IntegrationDetails.NF_PNPA_Date,103)	AS 'NF_PNPA_Date'


,NPA_IntegrationDetails.SubSegment
	
,NPA_IntegrationDetails.MaxDPD									AS 'MaxDPD'

,DimAssetClass.AssetClassName									AS 'AssetClass'

,case when DimPNPA_Reason.PNPA_ReasonAlt_Key=80
	  then DimPNPA_Reason.PNPA_ReasonName + ' ' +  cast(NPA_IntegrationDetails.MaxDPD as varchar(25))						
	  else DimPNPA_Reason.PNPA_ReasonName
	  end														
	  AS	'ReasonForDefault'

,@MonthEndDate1 date

,CUSTOMER_IDENTIFIER

,ISNULL(ActualOutStanding,0) ActualOutStanding

,ISNULL(NPA_IntegrationDetails.PrincipleOutstanding,0) PrincipleOutstanding
,NPA_IntegrationDetails.SrcSysAlt_Key
FROM  #PNPA  PNPA 

INNER JOIN NPA_IntegrationDetails				ON NPA_IntegrationDetails.NCIF_Id=PNPA.NCIF_Id
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												----AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0


LEFT JOIN NPA_IntegrationBillDetails			ON NPA_IntegrationBillDetails.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
												AND NPA_IntegrationBillDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationBillDetails.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationBillDetails.MaxDPD=NPA_IntegrationDetails.DPD_Overdue_Loans


INNER JOIN DimSourceSystem						ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey


INNER JOIN DimAssetClass						ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
												AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey


left join DIMPRODUCT							ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
												AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

INNER JOIN DimPNPA_Reason						ON DimPNPA_Reason.PNPA_ReasonAlt_Key=NPA_IntegrationDetails.PNPA_ReasonAlt_Key
												AND DimPNPA_Reason.EffectiveFromTimeKey<=@TimeKey AND DimPNPA_Reason.EffectiveToTimeKey>=@TimeKey						

WHERE @DimsourceSystem=1

OPTION(RECOMPILE)

DROP TABLE #TEMP,#TEMP1,#PNPA,#PNPAReason






GO