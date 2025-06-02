SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

-----client
--------------------MODIFIED 19_03_2018---------------------
----------------------Changed---------
---------------------------------MODIFIED PNPA---------------------------
/*
ALTERD BY:- VEDIKA
ALTERD DATE :- 06-10-2017
REPORT NAME :- Potential NPA 
*/

CREATE    proc [dbo].[Rpt-PNPA_Impacted_Impacting]
@DtEnter as varchar(20)
,@Cost as Float
,@DimsourceSystem as int
AS

--DECLARE	
--@DtEnter as varchar(20)='31/03/2018'
--,@Cost AS FLOAT=1000
--,@DimsourceSystem as int=0

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
Print @TimeKey 

Declare @MonthEndDate as date =(Select MonthLastDate from SysDataMatrix where MonthLastDate=@DtEnter1)

 Declare @MonthEndDate1 as date = (SELECT EOMONTH ( @MonthEndDate, 1 ))
 print @MonthEndDate1

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

  --select * from #PNPAReason

---------------------------------------------------------------------------------
SELECT * INTO #TEMP FROM
(
SELECT NPA_IntegrationDetails.NCIF_Id,
		NPA_IntegrationDetails.CustomerID,
		DimSourceSystem.SourceName	,
		NPA_IntegrationDetails.CustomerName,		
		case when len(NPA_IntegrationDetails.CustomerACID)=16
				then + ''''+ NPA_IntegrationDetails.CustomerACID 
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
		NPA_IntegrationDetails.PrincipleOutstanding,
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
		0				SRNO,
		DENSE_RANK() over(Partition by NCIF_Id order by NPA_IntegrationDetails.CustomerACID) Isr_no,
		@MonthEndDate1 date,
		NPA_IntegrationDetails.ActualOutStanding,
		NPA_IntegrationDetails.CUSTOMER_IDENTIFIER
		FROM NPA_IntegrationDetails
		
		INNER JOIN #PNPAReason					ON #PNPAReason.CustomerACID=NPA_IntegrationDetails.CustomerACID
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey

		INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
											
												AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0      -----uncommented on 02/08/2020

		INNER JOIN DimAssetClass			    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
												AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey


		left join DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										        AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

		INNER JOIN DimPNPA_Reason				ON DimPNPA_Reason.PNPA_ReasonAlt_Key=#PNPAReason.PNPAReason
												AND DimPNPA_Reason.EffectiveFromTimeKey<=@TimeKey AND DimPNPA_Reason.EffectiveToTimeKey>=@TimeKey
												AND DimPNPA_Reason.PNPA_ReasonAlt_Key<>90
----INNER JOIN  SysDataMatrix				ON SysDataMatrix.TimeKey=NPA_IntegrationDetails.EffectiveToTimeKey


WHERE 

NPA_IntegrationDetails.PNPA_Status='Y'
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)
AND NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7)  and  ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200 
)A




OPTION(RECOMPILE)
--CREATE  CLUSTERED INDEX IX_CustomerEntityID ON #TEMP(NCIF_Id)

--CREATE NONCLUSTERED INDEX IX_BranchCode ON #TEMP(NCIF_Id)
--INCLUDE (CustomerID,CustomerName,CustomerACID,Segment,ProductCode,ProductType,SanctionedLimit,DrawingPower,Balance,Overdue,DPD,DPD_Overdue_Loans,DPD_Interest_Not_Serviced,DPD_Overdrawn,DPD_Renewals,PNPA_Date,MaxDPD,SrcSysAlt_Key,ProductAlt_Key,AC_AssetClassAlt_Key,PNPA_Status,PNPA_ReasonAlt_Key,ActualOutStanding,CUSTOMER_IDENTIFIER)

--select * from #TEMP
--DROP TABLE #TEMP


--DROP TABLE #TEMP
--drop table #PNPA
--drop table #PNPAReason
------drop table #TEMP

----==================================Percolated Accounts===================---------------------

SELECT * INTO #PTEMP 
FROM
(
SELECT NPA_IntegrationDetails.NCIF_Id,
		NPA_IntegrationDetails.CustomerID,
		DimSourceSystem.SourceName	,
		NPA_IntegrationDetails.CustomerName,
		case when len(NPA_IntegrationDetails.CustomerACID)=16
				then '''' + NPA_IntegrationDetails.CustomerACID 
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
		NPA_IntegrationDetails.PrincipleOutstanding,
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
		0				SRNO,
		@MonthEndDate1 date,
		NPA_IntegrationDetails.ActualOutStanding,
		NPA_IntegrationDetails.CUSTOMER_IDENTIFIER
		FROM NPA_IntegrationDetails
		
		
		LEFT JOIN #PNPAReason					ON #PNPAReason.CustomerACID=NPA_IntegrationDetails.CustomerACID

		INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												----AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0

		INNER JOIN DimAssetClass			    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
												AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

		left join DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										        AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

----INNER JOIN  SysDataMatrix				ON SysDataMatrix.TimeKey=NPA_IntegrationDetails.EffectiveToTimeKey


WHERE 

ISNULL(NPA_IntegrationDetails.PNPA_Status,'')<>'Y'
and ( ISNULL(MOC_AssetClassAlt_Key,0)=1 OR ISNULL(NCIF_AssetClassAlt_Key,0)=1)
AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
AND NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7)  and  ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200 


)B

OPTION(RECOMPILE)
--CREATE  CLUSTERED INDEX IX_CustomerEntityID ON #PTEMP(NCIF_Id)

--CREATE NONCLUSTERED INDEX IX_BranchCode ON #PTEMP(NCIF_Id)
--INCLUDE (CustomerID,CustomerName,CustomerACID,Segment,ProductCode,ProductType,SanctionedLimit,DrawingPower,Balance,Overdue,DPD,DPD_Overdue_Loans,DPD_Interest_Not_Serviced,DPD_Overdrawn,DPD_Renewals,PNPA_Date,MaxDPD,SrcSysAlt_Key,ProductAlt_Key,AC_AssetClassAlt_Key,PNPA_Status,PNPA_ReasonAlt_Key,ActualOutStanding,CUSTOMER_IDENTIFIER)


--select * from #PTEMP


---------------------------------------------------ECBF & TRADEPROT-------------------------------

SELECT * INTO #TEMP1
FROM
(
SELECT NPA_IntegrationDetails.NCIF_Id,
		NPA_IntegrationDetails.CustomerID,
		DimSourceSystem.SourceName	,
		NPA_IntegrationDetails.CustomerName,
		NPA_IntegrationDetails.CustomerACID,
		NPA_IntegrationBillDetails.BillNo,
		ROW_NUMBER() over( partition by NPA_IntegrationBillDetails.CustomerACID order by NPA_IntegrationBillDetails.CustomerACID)sr_no,
		NPA_IntegrationDetails.Segment,
		NPA_IntegrationDetails.ProductCode,
		NPA_IntegrationDetails.ProductType,
		NPA_IntegrationDetails.SanctionedLimit,
		NPA_IntegrationDetails.DrawingPower,
		NPA_IntegrationBillDetails.Balance,
		NPA_IntegrationDetails.ActualPrincipleOutstanding,
		NPA_IntegrationDetails.PrincipleOutstanding,
		NPA_IntegrationBillDetails.Overdue,
		0 UNSERVED_INTEREST,
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
		NPA_IntegrationDetails.ActualOutStanding,
		NPA_IntegrationDetails.CUSTOMER_IDENTIFIER
		FROM NPA_IntegrationDetails
		
		INNER JOIN  NPA_IntegrationBillDetails	ON NPA_IntegrationBillDetails.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
												AND NPA_IntegrationDetails.CustomerACID=NPA_IntegrationBillDetails.CustomerACID
												AND NPA_IntegrationBillDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationBillDetails.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												and NPA_IntegrationBillDetails.MaxDPD=NPA_IntegrationDetails.DPD_Overdue_Loans		---It should be change as dpd_overdue_loan because at client side maxdpd gets updated into overdue_loan
												--and NPA_IntegrationBillDetails.NCIF_Id='14364262'
												----AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0
		
		INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationBillDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey


		INNER JOIN DimAssetClass			    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
												AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

		
		INNER JOIN #PNPAReason					ON #PNPAReason.CustomerACID=NPA_IntegrationDetails.CustomerACID

		left join DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										        AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

		INNER JOIN DimPNPA_Reason				ON DimPNPA_Reason.PNPA_ReasonAlt_Key=#PNPAReason.PNPAReason
												AND DimPNPA_Reason.EffectiveFromTimeKey<=@TimeKey AND DimPNPA_Reason.EffectiveToTimeKey>=@TimeKey
												AND DimPNPA_Reason.PNPA_ReasonAlt_Key=90
----INNER JOIN  SysDataMatrix				ON SysDataMatrix.TimeKey=NPA_IntegrationDetails.EffectiveToTimeKey


WHERE 

NPA_IntegrationDetails.PNPA_Status='Y'
AND (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)
AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
AND NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7)  and  ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200 
)A

OPTION(RECOMPILE)
--CREATE  CLUSTERED INDEX IX_CustomerEntityID ON #TEMP1(NCIF_Id)

--CREATE NONCLUSTERED INDEX IX_BranchCode ON #TEMP1(NCIF_Id)
--INCLUDE (CustomerID,CustomerName,CustomerACID,Segment,ProductCode,ProductType,SanctionedLimit,DrawingPower,Balance,Overdue,DPD,DPD_Overdue_Loans,DPD_Interest_Not_Serviced,DPD_Overdrawn,DPD_Renewals,PNPA_Date,MaxDPD,SrcSysAlt_Key,ProductAlt_Key,AC_AssetClassAlt_Key,PNPA_Status,PNPA_ReasonAlt_Key,ActualOutStanding,CUSTOMER_IDENTIFIER)


--------------------------------------PERCOLATED ACCOUNTS--------------------------------------------


SELECT * INTO #PTEMP1
FROM
(
SELECT NPA_IntegrationDetails.NCIF_Id,
		NPA_IntegrationDetails.CustomerID,
		DimSourceSystem.SourceName	,
		NPA_IntegrationDetails.CustomerName,
		NPA_IntegrationDetails.CustomerACID,
		NPA_IntegrationBillDetails.BillNo,
		ROW_NUMBER() over( partition by NPA_IntegrationBillDetails.CustomerACID order by NPA_IntegrationBillDetails.CustomerACID)sr_no,
		NPA_IntegrationDetails.Segment,
		NPA_IntegrationDetails.ProductCode,
		NPA_IntegrationDetails.ProductType,
		NPA_IntegrationDetails.SanctionedLimit,
		NPA_IntegrationDetails.DrawingPower,
		NPA_IntegrationBillDetails.Balance,
		NPA_IntegrationDetails.ActualPrincipleOutstanding,
		NPA_IntegrationDetails.PrincipleOutstanding,
		NPA_IntegrationBillDetails.Overdue,
		0 UNSERVED_INTEREST,
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
		@MonthEndDate1 date,
		NPA_IntegrationDetails.ActualOutStanding,
		NPA_IntegrationDetails.CUSTOMER_IDENTIFIER
		FROM NPA_IntegrationDetails
		
		INNER JOIN  NPA_IntegrationBillDetails	ON NPA_IntegrationBillDetails.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
												AND NPA_IntegrationDetails.CustomerACID=NPA_IntegrationBillDetails.CustomerACID
												AND NPA_IntegrationBillDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationBillDetails.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												and NPA_IntegrationBillDetails.MaxDPD=NPA_IntegrationDetails.DPD_Overdue_Loans		---It should be change as dpd_overdue_loan because at client side maxdpd gets updated into overdue_loan
												--and NPA_IntegrationBillDetails.NCIF_Id='14364262'
													------AND ISNULL(NPA_IntegrationDetails.Balance,0)<>0
		
		LEFT JOIN #PNPAReason					ON #PNPAReason.CustomerACID=NPA_IntegrationDetails.CustomerACID

		INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationBillDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey


		INNER JOIN DimAssetClass			    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
												AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey


		left join DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										        AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

		
----INNER JOIN  SysDataMatrix				ON SysDataMatrix.TimeKey=NPA_IntegrationDetails.EffectiveToTimeKey


WHERE 

ISNULL(NPA_IntegrationDetails.PNPA_Status,'')<>'Y'
and (  ISNULL(NCIF_AssetClassAlt_Key,0)=1)
AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
AND NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7)  and  ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200 
)C

OPTION(RECOMPILE)

--CREATE  CLUSTERED INDEX IX_CustomerEntityID ON #PTEMP1(NCIF_Id)

--CREATE NONCLUSTERED INDEX IX_BranchCode ON #PTEMP1(NCIF_Id)
--INCLUDE (CustomerID,CustomerName,CustomerACID,Segment,ProductCode,ProductType,SanctionedLimit,DrawingPower,Balance,Overdue,DPD,DPD_Overdue_Loans,DPD_Interest_Not_Serviced,DPD_Overdrawn,DPD_Renewals,PNPA_Date,MaxDPD,SrcSysAlt_Key,ProductAlt_Key,AC_AssetClassAlt_Key,PNPA_Status,PNPA_ReasonAlt_Key,ActualOutStanding,CUSTOMER_IDENTIFIER)


-------------------------------------MAIN QUERY-------------------------------------------

SELECT 

distinct 

ImpactedAccounts.NCIF_Id									AS 'Dedup NCIF'

,ImpactedAccounts.SourceName								AS 'SourceSystem'

,ImpactedAccounts.CustomerID								AS 'CustomerID'

,ImpactedAccounts.CustomerName								AS 'CustomerName'

,ImpactedAccounts.CustomerACID								AS 'Account No.'

,''															AS 'BillNo'

,0															AS 'SRNO'

,ImpactedAccounts.Segment									AS 'Customer Segment'

,ImpactedAccounts.ProductCode								AS 'Scheme_ProductCode'

,ImpactedAccounts.ProductName								AS 'Scheme_ProductCodeDescription'

,ImpactedAccounts.ProductType								AS 'Facility'

,ISNULL(ImpactedAccounts.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(ImpactedAccounts.DrawingPower,0)/@Cost				AS 'DrawingPower'

,ISNULL(ImpactedAccounts.Balance,0)/@Cost						AS 'Outstanding'

,ISNULL(CASE WHEN ImpactedAccounts.SrcSysAlt_Key=10 AND ImpactedAccounts.ProductType='ODA'
	  THEN ( CASE WHEN ISNULL(ImpactedAccounts.Overdue,0)>ISNULL(ImpactedAccounts.UNSERVED_INTEREST,0)
				THEN ISNULL(ImpactedAccounts.Overdue,0)
				ELSE ISNULL(ImpactedAccounts.UNSERVED_INTEREST,0)
				END)
      ELSE ISNULL(ImpactedAccounts.Overdue,0)
	  END,0)/@Cost											AS 'IrregularAmount'

,ISNULL(ImpactedAccounts.ActualPrincipleOutstanding,0)/@Cost	AS 'IPOS'

,ImpactedAccounts.DPD										AS 'DPD'

,ImpactedAccounts.DPD_Overdue_Loans						AS 'DPD_Overdue_Loan'

,ImpactedAccounts.DPD_Interest_Not_Serviced				AS 'DPD_InterestNotService'

,ImpactedAccounts.DPD_Overdrawn							AS 'DPD_Overdrawn'

,ImpactedAccounts.DPD_Renewals							AS 'DPD_Renewals'

,convert(varchar(20),ImpactedAccounts.PNPA_Date,103)		AS 'PNPA_Date'

,CONVERT(varchar(20),ImpactedAccounts.NF_PNPA_Date,103)		AS 'NF_PNPA_DATE'

,ImpactedAccounts.SubSegment
	
,ImpactedAccounts.MaxDPD									AS 'MaxDPD'

,ImpactedAccounts.AssetClassName							AS 'AssetClass'

,case when ImpactedAccounts.PNPA_ReasonAlt_Key=80
	  then ImpactedAccounts.PNPA_ReasonName + ' ' +  cast(ImpactedAccounts.MaxDPD as varchar(25))						
	  else ImpactedAccounts.PNPA_ReasonName
	  end														
	  AS	'ReasonForDefault'

,ImpactedAccounts.date

-----===================================PERCOLATD Accounts==================
,PercolatedAccounts.NCIF_Id									AS 'PDedup NCIF'

,PercolatedAccounts.SourceName								AS 'PSourceSystem'


,PercolatedAccounts.CustomerID								AS 'PCustomerID'


,PercolatedAccounts.CustomerName							AS 'PCustomerName'

,PercolatedAccounts.CustomerACID							AS 'PAccount No.'

,''																AS 'PBillNo'

,0																AS 'PSRNO'

,PercolatedAccounts.Segment										AS 'PCustomer Segment'

,PercolatedAccounts.ProductCode								AS 'PScheme_ProductCode'

,PercolatedAccounts.ProductName								AS 'PScheme_ProductCodeDescription'

,PercolatedAccounts.ProductType								AS 'PFacility'

,ISNULL(PercolatedAccounts.SanctionedLimit,0)/@Cost			AS 'PLimit'

,ISNULL(PercolatedAccounts.DrawingPower,0)/@Cost				AS 'PDrawingPower'

,ISNULL(PercolatedAccounts.Balance,0)/@Cost						AS 'POutstanding'

,ISNULL(PercolatedAccounts.ActualPrincipleOutstanding,0)/@Cost  AS 'PPOS'

,ISNULL(CASE WHEN PercolatedAccounts.SrcSysAlt_Key=10 AND PercolatedAccounts.ProductType='ODA'
	  THEN ( CASE WHEN ISNULL(PercolatedAccounts.Overdue,0)>ISNULL(PercolatedAccounts.UNSERVED_INTEREST,0)
				THEN ISNULL(PercolatedAccounts.Overdue,0)
				ELSE ISNULL(PercolatedAccounts.UNSERVED_INTEREST,0)
				END)
      ELSE ISNULL(PercolatedAccounts.Overdue,0)
	  END,0)/@Cost													AS 'PIrregularAmount'

,PercolatedAccounts.DPD										AS 'PDPD'

,PercolatedAccounts.DPD_Overdue_Loans						AS 'PDPD_Overdue_Loan'

,PercolatedAccounts.DPD_Interest_Not_Serviced				AS 'PDPD_InterestNotService'

,PercolatedAccounts.DPD_Overdrawn							AS 'PDPD_Overdrawn'

,PercolatedAccounts.DPD_Renewals							AS 'PDPD_Renewals'

,PercolatedAccounts.SubSegment								As 'PSubSegment'
	
,PercolatedAccounts.MaxDPD									AS 'PMaxDPD'

,PercolatedAccounts.AssetClassName							AS 'PAssetClass'


FROM  #TEMP  ImpactedAccounts

Inner join #PTEMP PercolatedAccounts			ON ImpactedAccounts.NCIF_Id=PercolatedAccounts.NCIF_Id
												--and Isr_no=1
												------AND ISNULL(PercolatedAccounts.ActualPrincipleOutstanding,0)<>0

----------------------------------------ECBF & TRADEPRO---------------------------

UNION ALL

SELECT 

distinct 

ImpactedAccount.NCIF_Id									AS 'Dedup NCIF'

,ImpactedAccount.SourceName								AS 'SourceSystem'


,ImpactedAccount.CustomerID								AS 'CustomerID'


,ImpactedAccount.CustomerName							AS 'CustomerName'

,ImpactedAccount.CustomerACID							AS 'Account No.'

,ImpactedAccount.BillNo									AS 'BillNo'

,ImpactedAccount.sr_no															AS 'SRNO'

,ImpactedAccount.Segment														AS 'Customer Segment'

,ImpactedAccount.ProductCode								AS 'Scheme_ProductCode'

,ImpactedAccount.ProductName								AS 'Scheme_ProductCodeDescription'

,ImpactedAccount.ProductType								AS 'Facility'

,ISNULL(ImpactedAccount.SanctionedLimit,0)/@Cost			AS 'Limit'

,ISNULL(ImpactedAccount.DrawingPower,0)/@Cost			AS 'DrawingPower'

,ISNULL(ImpactedAccount.Balance,0)/@Cost					AS 'Outstanding'

,ISNULL(ImpactedAccount.Overdue,0)/@Cost										AS 'IrregularAmount'

,ISNULL(ImpactedAccount.ActualPrincipleOutstanding,0)/@Cost	AS 'IPOS'

,ImpactedAccount.DPD										AS 'DPD'

,ImpactedAccount.DPD_Overdue_Loans						AS 'DPD_Overdue_Loan'

,ImpactedAccount.DPD_Interest_Not_Serviced				AS 'DPD_InterestNotService'

,ImpactedAccount.DPD_Overdrawn							AS 'DPD_Overdrawn'

,ImpactedAccount.DPD_Renewals							AS 'DPD_Renewals'

,convert(varchar(20),ImpactedAccount.PNPA_Date,103)		AS 'PNPA_Date'

,CONVERT(varchar(20),ImpactedAccount.NF_PNPA_Date,103)	AS 'NF_PNPA_DATE'

,ImpactedAccount.SubSegment
	
,ImpactedAccount.MaxDPD															AS 'MaxDPD'

,ImpactedAccount.AssetClassName							AS 'AssetClass'

,case when ImpactedAccount.PNPA_ReasonAlt_Key=80
	  then ImpactedAccount.PNPA_ReasonName + ' ' +  cast(ImpactedAccount.MaxDPD as varchar(25))						
	  else ImpactedAccount.PNPA_ReasonName
	  end														
	  AS	'ReasonForDefault'

,ImpactedAccount.date

--------------================PERCOLATED ACCOUNTS================-----------------

,PercolatedAccount.NCIF_Id									AS 'PDedup NCIF'

,PercolatedAccount.SourceName								AS 'PSourceSystem'


,PercolatedAccount.CustomerID								AS 'PCustomerID'


,PercolatedAccount.CustomerName								AS 'PCustomerName'

,PercolatedAccount.CustomerACID								AS 'PAccount No.'

,PercolatedAccount.BillNo									AS 'PBillNo'

,PercolatedAccount.sr_no									AS 'PSRNO'

,PercolatedAccount.Segment									AS 'PCustomer Segment'

,PercolatedAccount.ProductCode								AS 'PScheme_ProductCode'

,PercolatedAccount.ProductName								AS 'PScheme_ProductCodeDescription'

,PercolatedAccount.ProductType								AS 'PFacility'

,ISNULL(PercolatedAccount.SanctionedLimit,0)/@Cost			AS 'PLimit'

,ISNULL(PercolatedAccount.DrawingPower,0)/@Cost				AS 'PDrawingPower'

,ISNULL(PercolatedAccount.Balance,0)/@Cost						AS 'POutstanding'

,ISNULL(PercolatedAccount.Overdue,0)/@Cost						AS 'PIrregularAmount'

,ISNULL(PercolatedAccount.ActualPrincipleOutstanding,0)/@Cost	AS 'PPOS'

,PercolatedAccount.DPD										AS 'PDPD'

,PercolatedAccount.DPD_Overdue_Loans						AS 'PDPD_Overdue_Loan'

,PercolatedAccount.DPD_Interest_Not_Serviced				AS 'PDPD_InterestNotService'

,PercolatedAccount.DPD_Overdrawn							AS 'PDPD_Overdrawn'

,PercolatedAccount.DPD_Renewals								AS 'PDPD_Renewals'

,PercolatedAccount.SubSegment
	
,PercolatedAccount.MaxDPD									AS 'PMaxDPD'

,PercolatedAccount.AssetClassName							AS 'PAssetClass'

FROM  #TEMP1  ImpactedAccount

INNER JOIN #PTEMP1	PercolatedAccount			ON PercolatedAccount.NCIF_Id=ImpactedAccount.NCIF_Id

--WHERE ImpactedAccount.sr_no=1
------aND ISNULL(PercolatedAccount.ActualPrincipleOutstanding,0)<>0

UNION ALL
--------------------------------CROSS MAPPED (Single ENTCIF with Multiple Sources)------------------------------------------

SELECT 

DISTINCT 

NPA_IntegrationDetails.NCIF_Id										AS 'Dedup NCIF'

,DimSourceSystem.SourceName											AS 'SourceSystem'

,NPA_IntegrationDetails.CustomerID									AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName								AS 'CustomerName'

,NPA_IntegrationDetails.CustomerACID								AS 'Account No.'

,NPA_IntegrationBillDetails.BillNo									AS 'BillNo'

,0																	AS 'SRNO'

,NPA_IntegrationDetails.Segment										AS 'Customer Segment'

,NPA_IntegrationDetails.ProductCode									AS 'Scheme_ProductCode'

,DIMPRODUCT.ProductName												AS 'Scheme_ProductCodeDescription'

,NPA_IntegrationDetails.ProductType									AS 'Facility'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)/@Cost				AS 'Limit'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)/@Cost				AS 'DrawingPower'


,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost	AS 'IPOS'

,CASE WHEN DimPNPA_Reason.PNPA_ReasonAlt_Key<>90
	  THEN ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost
	  ELSE isnull(NPA_IntegrationBillDetails.Balance,0)/@Cost
	 END 															AS 'Outstanding'

,ISNULL(CASE WHEN DimPNPA_Reason.PNPA_ReasonAlt_Key<>90
	  THEN CASE WHEN ISNULL(NPA_IntegrationDetails.Overdue,0)>ISNULL(NPA_IntegrationDetails.UNSERVED_INTEREST,0)
				THEN NPA_IntegrationDetails.Overdue
				ELSE NPA_IntegrationDetails.UNSERVED_INTEREST
				END 
	  WHEN DimPNPA_Reason.PNPA_ReasonAlt_Key=90  THEN isnull(NPA_IntegrationBillDetails.Overdue,0)
	 END,0)/@Cost 													AS 'IrregularAmount'

,NPA_IntegrationDetails.DPD										AS 'DPD'

,NPA_IntegrationDetails.DPD_Overdue_Loans						AS 'DPD_Overdue_Loan'

,NPA_IntegrationDetails.DPD_Interest_Not_Serviced				AS 'DPD_InterestNotService'

,NPA_IntegrationDetails.DPD_Overdrawn							AS 'DPD_Overdrawn'

,NPA_IntegrationDetails.DPD_Renewals							AS 'DPD_Renewals'

,convert(varchar(20),NPA_IntegrationDetails.PNPA_Date,103)		AS 'PNPA_Date'

,CONVERT(varchar(20),NPA_IntegrationDetails.NF_PNPA_Date,103)	AS 'NF_PNPA_DATE'

,NPA_IntegrationDetails.SubSegment
	
,NPA_IntegrationDetails.MaxDPD									AS 'MaxDPD'

,DimAssetClass.AssetClassName									AS 'AssetClass'

,case when DimPNPA_Reason.PNPA_ReasonAlt_Key=80
	  then DimPNPA_Reason.PNPA_ReasonName + ' ' +  cast(NPA_IntegrationDetails.MaxDPD as varchar(25))						
	  else DimPNPA_Reason.PNPA_ReasonName
	  end														
	  AS	'ReasonForDefault'

,@MonthEndDate1 date

-----------=========================PERCOLATED ACCOUNTS=========================-----------------------

,PERCOLATEDACCOUNTS.NCIF_Id									AS 'PDedup NCIF'

,PERCOLATEDACCOUNTS.SourceName								AS 'PSourceSystem'

,PERCOLATEDACCOUNTS.CustomerID								AS 'PCustomerID'

,PERCOLATEDACCOUNTS.CustomerName							AS 'PCustomerName'

,PERCOLATEDACCOUNTS.CustomerACID							AS 'PAccount No.'

,PERCOLATEDACCOUNTS.BillNo									AS 'PBillNo'

,0															AS 'PSRNO'

,PERCOLATEDACCOUNTS.Segment									AS 'PCustomer Segment'

,PERCOLATEDACCOUNTS.ProductCode								AS 'PScheme_ProductCode'

,PERCOLATEDACCOUNTS.ProductName								AS 'PScheme_ProductCodeDescription'

,PERCOLATEDACCOUNTS.ProductType								AS 'PFacility'

,ISNULL(PERCOLATEDACCOUNTS.SanctionedLimit,0)/@Cost			AS 'PLimit'

,ISNULL(PERCOLATEDACCOUNTS.DrawingPower,0)/@Cost			AS 'PDrawingPower'

,ISNULL(PERCOLATEDACCOUNTS.ActualPrincipleOutstanding,0)/@Cost	AS 'PPOS'

,case when DimPNPA_Reason.PNPA_ReasonAlt_Key<>90
	  then ISNULL(PERCOLATEDACCOUNTS.Balance,0)/@Cost
	  else isnull(NPA_IntegrationBillDetails.Balance,0)/@Cost
	 end 														AS 'POutstanding'


,ISNULL(CASE WHEN DimPNPA_Reason.PNPA_ReasonAlt_Key<>90
	  THEN CASE WHEN ISNULL(PERCOLATEDACCOUNTS.Overdue,0)>ISNULL(PERCOLATEDACCOUNTS.UNSERVED_INTEREST,0)
				THEN PERCOLATEDACCOUNTS.Overdue
				ELSE PERCOLATEDACCOUNTS.UNSERVED_INTEREST
				END 
	  WHEN DimPNPA_Reason.PNPA_ReasonAlt_Key=90  THEN isnull(NPA_IntegrationBillDetails.Overdue,0)
		END,0)/@Cost 											AS 'PIrregularAmount'


,NPA_IntegrationDetails.DPD										AS 'PDPD'

,NPA_IntegrationDetails.DPD_Overdue_Loans						AS 'PDPD_Overdue_Loan'

,NPA_IntegrationDetails.DPD_Interest_Not_Serviced				AS 'PDPD_InterestNotService'

,NPA_IntegrationDetails.DPD_Overdrawn							AS 'PDPD_Overdrawn'

,NPA_IntegrationDetails.DPD_Renewals							AS 'PDPD_Renewals'

,NPA_IntegrationDetails.SubSegment								AS 'PSUBSEGMENT'
		
,NPA_IntegrationDetails.MaxDPD									AS 'PMaxDPD'

,DimAssetClass.AssetClassName									AS 'PAssetClass'


FROM  #PNPA  PNPA 

INNER JOIN NPA_IntegrationDetails				ON NPA_IntegrationDetails.NCIF_Id=PNPA.NCIF_Id
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
												----AND iSNULL(NPA_IntegrationDetails.Balance,0)<>0

INNER JOIN #PNPAReason							ON #PNPAReason.CustomerACID=NPA_IntegrationDetails.CustomerACID

INNER JOIN #PTEMP PERCOLATEDACCOUNTS			ON PERCOLATEDACCOUNTS.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
												 ------and ISNULL(PERCOLATEDACCOUNTS.ActualPrincipleOutstanding,0)<>0 
										
LEFT JOIN NPA_IntegrationBillDetails			ON NPA_IntegrationBillDetails.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
												AND NPA_IntegrationBillDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationBillDetails.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationBillDetails.MaxDPD=NPA_IntegrationDetails.DPD_Overdue_Loans


INNER JOIN DimSourceSystem						ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey


INNER JOIN DimAssetClass						ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
												AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey


left join DIMPRODUCT							ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
												AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

INNER JOIN DimPNPA_Reason						ON DimPNPA_Reason.PNPA_ReasonAlt_Key=#PNPAReason.PNPAReason
												AND DimPNPA_Reason.EffectiveFromTimeKey<=@TimeKey AND DimPNPA_Reason.EffectiveToTimeKey>=@TimeKey						



WHERE @DimsourceSystem=1
AND NPA_IntegrationDetails.AC_AssetClassAlt_Key NOT IN (7)  and  ISNULL(NPA_IntegrationDetails.ProductAlt_Key,0)<>3200 

ORDER BY ImpactedAccounts.NCIF_Id

OPTION(RECOMPILE)

DROP TABLE #TEMP,#TEMP1,#PTEMP,#PNPA,#PTEMP1,#PNPAReason




GO