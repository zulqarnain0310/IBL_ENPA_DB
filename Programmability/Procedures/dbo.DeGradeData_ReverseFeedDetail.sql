SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


create Proc [dbo].[DeGradeData_ReverseFeedDetail]	
@FromDt Date,
@ToDt   Date,
@Cost AS FLOAT=1000
AS
Begin
DECLARE 
--@MonthStartDate AS Date =(Select MonthFirstDate from SysDataMatrix where TimeKey=@TimeKey)
--,@MonthEndDate AS Date =(Select MonthLastDate from SysDataMatrix where TimeKey=@TimeKey)
@TimeKey INT=(Select TimeKey from SysDataMatrix where CurrentStatus='C'),
@Date Date=(Select Date from SysDataMatrix where CurrentStatus='C')

---------------------------------------------
IF OBJECT_ID('tempdb..#DownGrade') IS NOT NULL 
	DROP TABLE #DownGrade	
SELECT * into #DownGrade from [dbo].[ReverseFeedDetails_Archive_Check]
Where AsOnDate between @FromDt And @ToDt
And SrcAssetClass in ('001','1','S') And HomogenizedAssetClass not in ('001','1','S')

--UNION

--SELECT *  FROM ReverseFeedDetails_Archive Where AsOnDate between @MonthStartDate And @MonthEndDate
--And SrcAssetClass in ('001','1','S') And HomogenizedAssetClass not in ('001','1','S')

UNION ALL

SELECT ROW_NUMBER() over( order by AccountNo) Rn ,*  FROM ReverseFeedDetails Where AsOnDate between @FromDt And @ToDt
And SrcAssetClass in ('001','1','S') And HomogenizedAssetClass not in ('001','1','S')

OPTION(RECOMPILE)

--------------------------------
SELECT  
----DG.AsOnDate																AS AsOnDate,
----NPAID.NCIF_Id                                                         AS NCIF,
----DSS.SourceName															AS Source_System,
----NPAID.CustomerID                                                      AS CLient_ID,
----NPAID.CustomerName                                                    AS CLient_Name,
----NPAID.SubSegment														AS SubSegment,
----NPAID.ProductCode														AS Product,
----NPAID.ProductDesc														AS ProductDesc,
----NPAID.CustomerACID														AS Account_Number,
----NPAID.SanctionedLimit                                                 AS Limit,
----NPAID.DrawingPower                                                    AS DrawingPower,
----NPAID.Balance                                                         AS OutStanding,
----NPAID.PrincipleOutstanding                                            AS POS,
----NPAID.AC_NPA_Date														AS Account_Level_NPA_Date_Original,
----DAC1.AssetClassName														AS Account_Level_Asset_Class_Original,
----DG.HomogenizedNpaDt														AS DEDUP_ENTCIF_NPA_Date_Final,
----DAC.AssetClassName														AS DEDUP_ENTCIF_Asset_Class_Final
 DG.AsOnDate	
,DG.SourceName 
,dg.AccountNo [Account]
,IsFunded [Funded Non Funded Flag]
,DG.CIF_ID CIF
,DG.UCIF_ID NCIF
,DG.SOL_ID BranchCode
,PAN [PAN No]
,CustomerName [Name]
,DPD_Overdue_Loans
,DPD_Interest_Not_Serviced
,DPD_Interest_Not_Serviced [DPD_Overdue Interest]
,DPD_Overdrawn
,DPD_PrincOverdue [DPD_Principal Overdue]
,DPD_OtherOverdueSince [DPD_Other Overdue]
,DPD_Renewals
,DPD_StockStmt [DPD_Stock Statement]
,MaxDPD [Max DPD on date of downgrade]
,AsonDate [Date of downgrade picked for this report]
,AC_NPA_Date [Date of NPA of source system]
,HomogenizedNpaDt [Homogenized_Date of NPA]
,SrcAssetClass [Classification of source system]
,HomogenizedAssetClass [Homogenized_Classification]
,PrincipleOutstanding [Principal OS] 
,IntOverdue [Interest OS]
,ProductType [Scheme Type]
,ProductCode [Scheme_Code]
,ProductDesc [Scheme Description]
,Segment
,IS_MOC
,ReviewDueDt [Renewal Date]
,DPD_StockStmt [Stock statement date]
,DCCO_Date [DCCO date]
,RestructureDate [Restructuring date]
,IsRestructured [Restructuring Flag]
,RestructureTypeAlt_Key [Restructuring Type]
,IsFraud [Fraud flag]
,DG.SourceName [Culprit System]
,AccountNo [Culprit System Account No]
FROM  #DownGrade DG left join
NPA_IntegrationDetails NPAID	with (nolock)
ON	DG.UCIF_ID = NPAID.NCIF_ID And DG.CIF_ID = NPAID.CustomerId 
							   AND DG.AccountNo = NPAID.CustomerACID
 AND NPAID.EffectiveFromTimeKey<=@TimeKey AND NPAID.EffectiveToTimeKey>=@TimeKey
Left join curdat.AdvAcRestructureDetail ARD
on ARD.RefSystemAcId=NPAID.CustomerAcid
and ARD.EffectiveFromTimeKey<=@TimeKey AND ARD.EffectiveToTimeKey>=@TimeKey
LEFT JOIN DimAssetClass DAC					ON Case When DG.SourceName='Finacle' Then DAC.FinacleAssetClassCode
														When DG.SourceName='ECBF' Then DAC.eCBFAssetClassCode 
														When DG.SourceName='GanaSeva' Then DAC.GanasevaAssetClassCode 
														When DG.SourceName='Prolendz' Then DAC.ProlendzAssetClassCode
														When DG.SourceName='PT Smart' Then DAC.PTSmartAssetClassCode
														When DG.SourceName='Vision Plus' Then DAC.VP_AssetClassCode
														When DG.SourceName='Calyso' Then DAC.CalypsoAssetClassCode
														When DG.SourceName='TradePro' Then DAC.TradeProAssetClassCode END=DG.HomogenizedAssetClass
												    AND DAC.EffectiveFromTimeKey<=@TimeKey 
													AND DAC.EffectiveToTimeKey>=@TimeKey 
LEFT JOIN DimAssetClass DAC1					ON  DAC1.AssetClassAlt_Key=NPAID.AC_AssetClassAlt_Key 
												    AND DAC1.EffectiveFromTimeKey<=@TimeKey 
													AND DAC1.EffectiveToTimeKey>=@TimeKey 
												    
LEFT JOIN DimSourceSystem	DSS					ON  DSS.SourceAlt_Key=NPAID.SrcSysAlt_Key
												    AND DSS.EffectiveFromTimeKey<=@TimeKey 
													AND DSS.EffectiveToTimeKey>=@TimeKey
ORDER BY DG.AsOnDate,NPAID.CustomerName


OPTION(RECOMPILE)
END
GO