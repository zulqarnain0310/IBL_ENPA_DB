SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

------------------------------/*
------------------------------ALTERD BY:- VEDIKA MAM
------------------------------ALTERD DATE :- 30-11-2017
------------------------------REPORT NAME :- TradePro & eCBF-Transaction-wise Overdue
------------------------------*/

CREATE  proc [dbo].[Rpt-TransactionWiseOverdue]
@DtEnter as varchar(20)
,@Cost as Float
,@DimsourceSystem as int
,@NPA AS INT

AS

--DECLARE	
--@DtEnter as varchar(20)='30/09/2017'
--,@Cost AS FLOAT=1000
--,@DimsourceSystem as int=0
--,@NPA AS INT=2

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
Print @TimeKey 

DECLARE
 @ProcessingDt  DATE
,@PNPA_Dt		DATE

SET @ProcessingDt=(SELECT MonthLastDate FROM SysDataMatrix WHERE CurrentStatus='C')  ----CURRENT PROCESSING DATE 

SET @PNPA_Dt=(SELECT DATEADD(MONTH,1,@ProcessingDt))   ----NEXT MONTH END DATE

DECLARE @DAYS  INT 

SELECT @DAYS=DATEDIFF(DAY,@ProcessingDt,@PNPA_Dt)
--SELECT @DAYS,@ProcessingDt,@PNPA_Dt


SELECT DISTINCT 	NPA_IntegrationBillDetails.NCIF_Id,

					NPA_IntegrationBillDetails.CustomerID,

					DimSourceSystem.SourceName	,

					NPA_IntegrationBillDetails.CustomerName,

					NPA_IntegrationBillDetails.ProductType						AS ProductType,

					NPA_IntegrationBillDetails.Segment							AS segment,

					case when len(NPA_IntegrationBillDetails.CustomerACID)=16
						 then '''' + NPA_IntegrationBillDetails.CustomerACID + '''' 
						 else NPA_IntegrationBillDetails.CustomerACID
						 end																AS accountno,

					NPA_IntegrationBillDetails.BillNo							AS BillNo,
					
					ISNULL(NPA_IntegrationBillDetails.Overdue,0)/@Cost			AS BillBalance,

					ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost				AS BalanceOutstanding, 

					ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost		AS POS,

					NPA_IntegrationBillDetails.MaxDPD							 AS DPDCOUNT,

					DIMPRODUCT.AgriFlag,

					CASE WHEN NPA_IntegrationBillDetails.MaxDPD>90
						 THEN 'Y'
						 ELSE 'N'
						 END													AS 'NPA'
					
					
				

		FROM NPA_IntegrationDetails
		

		INNER JOIN NPA_IntegrationBillDetails	ON NPA_IntegrationBillDetails.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
												AND NPA_IntegrationBillDetails.CustomerACID=NPA_IntegrationDetails.CustomerACID
												AND NPA_IntegrationBillDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationBillDetails.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey	
												AND (NPA_IntegrationDetails.AC_AssetClassAlt_Key<>7 OR ProductAlt_Key<>3200)

		INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationBillDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
												and DimSourceSystem.SourceAlt_Key in (30,50)

		INNER join DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										        AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey



WHERE (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0) 
AND (NPA_IntegrationBillDetails.MaxDPD>0 )
AND @NPA=0

UNION ALL


SELECT DISTINCT 	NPA_IntegrationBillDetails.NCIF_Id,

					NPA_IntegrationBillDetails.CustomerID,

					DimSourceSystem.SourceName	,

					NPA_IntegrationBillDetails.CustomerName,

					NPA_IntegrationBillDetails.ProductType						AS ProductType,

					NPA_IntegrationBillDetails.Segment							AS segment,

					case when len(NPA_IntegrationBillDetails.CustomerACID)=16
						 then '''' + NPA_IntegrationBillDetails.CustomerACID + '''' 
						 else NPA_IntegrationBillDetails.CustomerACID
						 end													AS accountno,

					NPA_IntegrationBillDetails.BillNo							AS BillNo,

					ISNULL(NPA_IntegrationBillDetails.Overdue,0)/@Cost			AS BillBalance,

					ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost				AS BalanceOutstanding, 

					ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost		AS POS,

					NPA_IntegrationBillDetails.MaxDPD							 AS DPDCOUNT,

					DIMPRODUCT.AgriFlag,

					CASE WHEN NPA_IntegrationBillDetails.MaxDPD>90
						 THEN 'Y'
						 ELSE 'N'
						 END													AS 'NPA'
					
					
				

		FROM NPA_IntegrationDetails
		

		INNER JOIN NPA_IntegrationBillDetails	ON NPA_IntegrationBillDetails.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
												AND NPA_IntegrationBillDetails.CustomerACID=NPA_IntegrationDetails.CustomerACID
												AND NPA_IntegrationBillDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationBillDetails.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey	
												AND (NPA_IntegrationDetails.AC_AssetClassAlt_Key<>7 OR ProductAlt_Key<>3200)

		INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationBillDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
												and DimSourceSystem.SourceAlt_Key in (30,50)

		INNER join DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										        AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey



WHERE (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0) 
AND (NPA_IntegrationBillDetails.MaxDPD>0 and NPA_IntegrationBillDetails.MaxDPD>90)
AND @NPA=1


UNION ALL

SELECT DISTINCT 	NPA_IntegrationBillDetails.NCIF_Id,

					NPA_IntegrationBillDetails.CustomerID,

					DimSourceSystem.SourceName	,

					NPA_IntegrationBillDetails.CustomerName,

					NPA_IntegrationBillDetails.ProductType						AS ProductType,

					NPA_IntegrationBillDetails.Segment							AS segment,

					case when len(NPA_IntegrationBillDetails.CustomerACID)=16
						 then '''' + NPA_IntegrationBillDetails.CustomerACID + '''' 
						 else NPA_IntegrationBillDetails.CustomerACID
						 end													AS accountno,

					NPA_IntegrationBillDetails.BillNo							AS BillNo,

					ISNULL(NPA_IntegrationBillDetails.Overdue,0)/@Cost			AS BillBalance,

					ISNULL(NPA_IntegrationDetails.Balance,0)/@Cost				AS BalanceOutstanding, 

					ISNULL(NPA_IntegrationDetails.ActualPrincipleOutstanding,0)/@Cost		AS POS,

					NPA_IntegrationBillDetails.MaxDPD							 AS DPDCOUNT,

					DIMPRODUCT.AgriFlag,

					CASE WHEN NPA_IntegrationBillDetails.MaxDPD>90
						 THEN 'Y'
						 ELSE 'N'
						 END													AS 'NPA'
					
					
				

		FROM NPA_IntegrationDetails
		

		INNER JOIN NPA_IntegrationBillDetails	ON NPA_IntegrationBillDetails.NCIF_Id=NPA_IntegrationDetails.NCIF_Id
												AND NPA_IntegrationBillDetails.CustomerACID=NPA_IntegrationDetails.CustomerACID
												AND NPA_IntegrationBillDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationBillDetails.EffectiveToTimeKey>=@TimeKey
												AND NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey AND NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey	
												AND (NPA_IntegrationDetails.AC_AssetClassAlt_Key<>7 OR ProductAlt_Key<>3200)

		INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=NPA_IntegrationBillDetails.SrcSysAlt_Key
												AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey
												and DimSourceSystem.SourceAlt_Key in (30,50)

		INNER join DIMPRODUCT					ON DIMPRODUCT.ProductAlt_Key=NPA_IntegrationDetails.ProductAlt_Key
										        AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey



WHERE (DimSourceSystem.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0) 
AND (ISNULL(NPA_IntegrationBillDetails.MaxDPD,0)>60  AND ISNULL(NPA_IntegrationBillDetails.MAXDPD,0)<=91)
AND  ((AgriFlag='N'AND (@DAYS+ISNULL(NPA_IntegrationBillDetails.MaxDPD,0))>90)
		OR (AgriFlag='Y' AND ((@DAYS+ISNULL(NPA_IntegrationBillDetails.MaxDPD,0))>365)))
AND @NPA=2
--AND NPA_IntegrationDetails.PNPA_Status='Y'
ORDER BY NCIF_Id
OPTION(RECOMPILE)


GO