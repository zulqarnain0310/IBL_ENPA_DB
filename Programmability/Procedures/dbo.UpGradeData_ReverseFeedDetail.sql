SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


create Proc [dbo].[UpGradeData_ReverseFeedDetail]	
@FromDt Date,
@ToDt   Date,
@Cost AS FLOAT=1
AS
Begin

DECLARE 
--@MonthStartDate AS Date =(Select MonthFirstDate from SysDataMatrix where TimeKey=@TimeKey)
--,@MonthEndDate AS Date =(Select MonthLastDate from SysDataMatrix where TimeKey=@TimeKey)
@TimeKey INT=(Select TimeKey from SysDataMatrix where CurrentStatus='C'),
@Date Date=(Select Date from SysDataMatrix where CurrentStatus='C')
---------------------------------------------
IF OBJECT_ID('tempdb..#UpGrade') IS NOT NULL 
	DROP TABLE #UpGrade	
SELECT * into #UpGrade FROM [dbo].[ReverseFeedDetails_Archive_Check]
Where AsOnDate between @FromDt And @ToDt
And SrcAssetClass not in ('001','1','S') And HomogenizedAssetClass  in ('001','1','S')

--UNION

--SELECT *  FROM ReverseFeedDetails_Archive Where AsOnDate between @MonthStartDate And @MonthEndDate
--And SrcAssetClass not in ('001','1','S') And HomogenizedAssetClass  in ('001','1','S')  --- commeneted by satish as all data will be in 1 archive dbo

UNION ALL

SELECT ROW_NUMBER() over( order by AccountNo) Rn ,*  FROM ReverseFeedDetails Where AsOnDate between @FromDt And @ToDt
And SrcAssetClass not in ('001','1','S') And HomogenizedAssetClass  in ('001','1','S')

OPTION(RECOMPILE)

 --  select top 1 * from  #UpGrade

--------------------------------

SELECT 
 UG.AsOnDate 
,UG.SourceName 
,UG.UCIF_ID  NCIF_Id
,UG.AccountNo  Account
,NPAID.IsFunded  [Funded Non Funded Flag]
,UG.CIF_ID CIF
,UG.SOL_ID as Branch_code
,Pan
,CustomerName [Customer Name]
,MaxDPD [Max DPD on date of upgrade]
,UpgDate [Date of upgrade by D2K]
,(PrincipleOutstanding/@Cost) [Principal OS] 
,IntOverdue [Interest OS]
,UG.SrcAssetClass [Asset class prior to upgrade]
,AC_NPA_Date [NCIF NPA Date prior to upgrade]
,1 as [Asset class on upgrade date]
,ProductType [Scheme Type]
,ProductDesc [Scheme Description]
,ProductCode [Scheme Code]
,Segment
,SubSegment [Sub Segment]
,IS_MOC
,ReviewDueDt [Renewal Date]
,StkStmtDate [Stock statement date]
,DCCO_Date [DCCO date]
,PROJ_COMPLETION_DATE [Project Completion Date]

FROM #UpGrade UG
Left JOIN 
NPA_IntegrationDetails	NPAID	with (nolock)
ON	UG.UCIF_ID = NPAID.NCIF_ID And UG.CIF_ID = NPAID.CustomerId 
AND UG.AccountNo = NPAID.CustomerACID
and  NPAID.EffectiveFromTimeKey=@TimeKey 
AND NPAID.EffectiveToTimeKey=@TimeKey --And UG.SourceName='Vision Plus'

Left JOIN DimAssetClass DAC					ON Case When UG.SourceName='Finacle' Then DAC.FinacleAssetClassCode
														When UG.SourceName='ECBF' Then DAC.eCBFAssetClassCode 
														When UG.SourceName='GanaSeva' Then DAC.GanasevaAssetClassCode 
														When UG.SourceName='Prolendz' Then DAC.ProlendzAssetClassCode
														When UG.SourceName='PT Smart' Then DAC.PTSmartAssetClassCode
														When UG.SourceName='Vision Plus' Then DAC.VP_AssetClassCode
														When UG.SourceName='Calyso' Then DAC.CalypsoAssetClassCode
														When UG.SourceName='TradePro' Then DAC.TradeProAssetClassCode END=UG.HomogenizedAssetClass
												    AND DAC.EffectiveFromTimeKey<=@TimeKey 
													AND DAC.EffectiveToTimeKey>=@TimeKey 
												    

Left JOIN DimAssetClass DAC1					ON  DAC1.AssetClassAlt_Key=NPAID.AC_AssetClassAlt_Key
												    AND DAC1.EffectiveFromTimeKey<=@TimeKey 
													AND DAC1.EffectiveToTimeKey>=@TimeKey 
												    
Left JOIN DimSourceSystem	DSS					ON  DSS.SourceAlt_Key=NPAID.SrcSysAlt_Key
												    AND DSS.EffectiveFromTimeKey<=@TimeKey 
													AND DSS.EffectiveToTimeKey>=@TimeKey
							
ORDER BY NPAID.CustomerName


OPTION(RECOMPILE)
end
GO