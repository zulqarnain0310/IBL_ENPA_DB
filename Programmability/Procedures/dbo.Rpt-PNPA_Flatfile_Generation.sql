SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

-------------------------------------------------MODIFIED PNPA---------------------------
--------------------------------------------/*
--------------------------------------------ALTERD BY:- krishna
--------------------------------------------ALTERD DATE :- 14-05-2018
--------------------------------------------REPORT NAME :- Potential Flatfile_Generation 
--------------------------------------------*/

CREATE Proc [dbo].[Rpt-PNPA_Flatfile_Generation] 
@DtEnter as varchar(20)

AS

 --DECLARE	
 --@DtEnter as varchar(20)='31/03/2018'


DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)

Declare @MonthEndDate as date =(Select MonthLastDate from SysDataMatrix where MonthLastDate=@DtEnter1)

Declare @MonthEndDate1 as date = (SELECT EOMONTH ( @MonthEndDate, 1 ))


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

IF OBJECT_ID('tempdb..#temptable21') is not null
 DROP TABLE #temptable21


SELECT CustomerID,customerACID,Split.a.value('.', 'VARCHAR(100)') AS PNPAReason into #temptable21   FROM (
Select CustomerID,CustomerACID,CAST ('<M>' + REPLACE(PNPA_ReasonAlt_Key, ',', '</M><M>') + '</M>' AS XML) AS AdvocateList  
  from NPA_IntegrationDetails  where NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
  ) D CROSS APPLY AdvocateList.nodes ('/M') AS Split(a)  


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
		@MonthEndDate1 date1,
		CUSTOMER_IDENTIFIER,
		PrincipleOutstanding,
	    ActualOutStanding

		FROM NPA_IntegrationDetails
		
		INNER JOIN #PNPAReason					ON #PNPAReason.CustomerACID=NPA_IntegrationDetails.CustomerACID
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
													
		INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
										
		INNER JOIN DimAssetClass			    ON DimAssetClass.AssetClassAlt_Key=NPA_IntegrationDetails.AC_AssetClassAlt_Key
												AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey

		LEFT join DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										        AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey

		INNER JOIN DimPNPA_Reason				ON DimPNPA_Reason.PNPA_ReasonAlt_Key=#PNPAReason.PNPAReason
												AND DimPNPA_Reason.EffectiveFromTimeKey<=@TimeKey AND DimPNPA_Reason.EffectiveToTimeKey>=@TimeKey
												AND DimPNPA_Reason.PNPA_ReasonAlt_Key<>90


WHERE 

NPA_IntegrationDetails.PNPA_Status='Y'
AND DimSourceSystem.SourceAlt_Key=10

)TEMP

option(recompile)
CREATE  CLUSTERED INDEX IX_CustomerEntityID ON #TEMP(NCIF_Id)

CREATE NONCLUSTERED INDEX IX_BranchCode ON #TEMP(NCIF_Id)
INCLUDE (CustomerID,CustomerName,CustomerACID,Segment,ProductCode,ProductType,SanctionedLimit,DrawingPower,Balance,Overdue,DPD,DPD_Overdue_Loans,DPD_Interest_Not_Serviced,DPD_Overdrawn,DPD_Renewals,PNPA_Date,MaxDPD,SrcSysAlt_Key,ProductAlt_Key,AC_AssetClassAlt_Key,PNPA_Status,PNPA_ReasonAlt_Key)

-------------------------------------MAIN QUERY-------------------------------------------

insert into PNPA_FlatfileGeneRation(
 [Dedup NCIF],SourceSystem,CustomerID,CustomerName
,[Account No.],BillNo,[Customer Segment],Scheme_ProductCode,Scheme_ProductCodeDescription,Facility,Limit
,DrawingPower,Outstanding,POS,IrregularAmount,DPD,DPD_Overdue_Loan,DPD_InterestNotService,DPD_Overdrawn
,DPD_Renewals,PNPA_Date,NF_PNPA_Date,SubSegment,MaxDPD,AssetClass,ReasonForDefault,date1
,CUSTOMER_IDENTIFIER,ActualOutStanding,PrincipleOutstanding,SrcSysAlt_Key)

SELECT 

distinct 

NPA_IntegrationDetails.NCIF_Id									AS 'Dedup NCIF'

,NPA_IntegrationDetails.SourceName								AS 'SourceSystem'


,NPA_IntegrationDetails.CustomerID								AS 'CustomerID'


,NPA_IntegrationDetails.CustomerName							AS 'CustomerName'

,NPA_IntegrationDetails.CustomerACID							AS 'Account No.'

,''																AS 'BillNo'

,Segment														AS 'Customer Segment'

,NPA_IntegrationDetails.ProductCode								AS 'Scheme_ProductCode'

,NPA_IntegrationDetails.ProductName								AS 'Scheme_ProductCodeDescription'

,NPA_IntegrationDetails.ProductType								AS 'Facility'

,ISNULL(NPA_IntegrationDetails.SanctionedLimit,0)			AS 'Limit'

,ISNULL(NPA_IntegrationDetails.DrawingPower,0)			AS 'DrawingPower'

,ISNULL(NPA_IntegrationDetails.Balance,0)					AS 'Outstanding'

,ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0) AS 'POS'

,ISNULL(CASE WHEN ISNULL(Overdue,0)>ISNULL(UNSERVED_INTEREST,0)
	  THEN Overdue
	  ELSE UNSERVED_INTEREST 
	  END,0)												AS 'IrregularAmount'

,NPA_IntegrationDetails.DPD										AS 'DPD'

,NPA_IntegrationDetails.DPD_Overdue_Loans						AS 'DPD_Overdue_Loan'

,NPA_IntegrationDetails.DPD_Interest_Not_Serviced				AS 'DPD_InterestNotService'

,NPA_IntegrationDetails.DPD_Overdrawn							AS 'DPD_Overdrawn'

,NPA_IntegrationDetails.DPD_Renewals							AS 'DPD_Renewals'

,convert(varchar(20),NPA_IntegrationDetails.PNPA_Date,105)		AS 'PNPA_Date'

,CONVERT(varchar(25),NPA_IntegrationDetails.NF_PNPA_Date,105)	AS 'NF_PNPA_Date'

,NPA_IntegrationDetails.SubSegment
	
,MaxDPD															AS 'MaxDPD'

,NPA_IntegrationDetails.AssetClassName							AS 'AssetClass'

,case when PNPA_ReasonAlt_Key=80
	  then NPA_IntegrationDetails.PNPA_ReasonName + ' ' +  cast(MaxDPD as varchar(25))						
	  else NPA_IntegrationDetails.PNPA_ReasonName
	  end														
	  AS	'ReasonForDefault'

,CONVERT(VARCHAR(20),date1,105) AS Date

,CUSTOMER_IDENTIFIER

,ISNULL(ActualOutStanding,0) ActualOutStanding

,ISNULL(PrincipleOutstanding,0) PrincipleOutstanding

,NPA_IntegrationDetails.SrcSysAlt_Key

FROM  #TEMP  NPA_IntegrationDetails

DROP TABLE #TEMP
DROP TABLE #PNPA
drop table #PNPAReason






GO