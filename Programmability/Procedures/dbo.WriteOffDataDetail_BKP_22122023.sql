SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create PROC [dbo].[WriteOffDataDetail_BKP_22122023]
      @FromDate  AS VARCHAR(20),
      @ToDate  AS VARCHAR(20),
      @Cost AS FLOAT=1
AS 
Begin
Declare @Timekey int=(Select TimeKey from SysDatamatrix where CurrentStatus='C')
Declare @Date Date=(Select Cast(DATE as date) from SysDatamatrix where CurrentStatus='C' )
;with cte
as
(
Select 
1 as SR_NO
,CONVERT(VARCHAR(20),@Date,103) AS AsOnDate 
,SourceName
,CustomerACID [Account No]
,CustomerID CIF
,NCIF_Id NCIF
,Pan
,CustomerName
,DPD_Overdue_Loans
,DPD_Interest_Not_Serviced  DPD_Interest_Not_Serviced
,DPD_Interest_Not_Serviced [DPD_Overdue Interest]
,DPD_Overdrawn
,DPD_PrincOverdue [DPD_Principal Overdue]
,DPD_OtherOverdueSince [DPD_Other Overdue]
,DPD_Renewals
,DPD_StockStmt [DPD_Stock Statement]
,MaxDPD [Max DPD on date of write off]
,WriteOffDate [Date of Write off by D2K]
,PrincipleOutstanding [Principal OS]
,IntOverdue [Interest OS]
,AC_NPA_Date [NCIF NPA date prior to write off]
,AC_AssetClassAlt_Key [Asset class prior to write off]
,ProductType Scheme_Type
,ProductCode Scheme_Code 
,ProductDesc [Scheme Description]
,Segment
,MOC_Status IS_MOC
,ReviewDueDt [Renewal Date]
,StkStmtDate [Stock statement date]
,DCCO_Date [DCCO date]
,RestructureDate [Restructuring date] 
,NCIF_NPA_Date [NPA Date NCIF]
,IsFraud [Fraud Flag]
,IsTWO [Woff Flag]
,IsARC_Sale [ARC Flag]
,IsOTS [OTS Flag]
from NPA_IntegrationDetails NI
inner Join DimSourceSystem DS
on NI.SrcSysAlt_Key=DS.SourceAlt_Key
Left join curdat.AdvAcRestructureDetail ARD
on ARD.RefSystemAcId=NI.CustomerAcid
and ARD.EffectiveFromTimeKey<=@TimeKey AND ARD.EffectiveToTimeKey>=@TimeKey
where (IsTWO='y' or ISNULL(NCIF_AssetClassAlt_Key,1)=7) and
NI.EffectiveFromTimeKey<=@Timekey and NI.EffectiveToTimeKey>=@Timekey and 
 WriteOffDate between @FromDate and @ToDate 

UNION

SELECT
 2 as SR_NO
,CONVERT(VARCHAR(20),[DATE],103)  AS AsOnDate 
,SourceName
,ACWOD.CustomerACID [Account No]
,ACWOD.CustomerID CIF
,ACWOD.NCIF_Id NCIF
,NULL Pan
,ACWOD.CustomerName
,NULL DPD_Overdue_Loans
,NULL DPD_Interest_Not_Serviced  
,NULL [DPD_Overdue Interest]
,NULL DPD_Overdrawn
,NULL [DPD_Principal Overdue]
,NULL [DPD_Other Overdue]
,NULL DPD_Renewals
,NULL [DPD_Stock Statement]
,NULL [Max DPD on date of write off]
,NULL [Date of Write off by D2K]
,NULL [Principal OS]
,NULL [Interest OS]
,ACWOD.NPADt [NCIF NPA date prior to write off]
,ACWOD.AssetClassAlt_Key [Asset class prior to write off]
,NULL Scheme_Type
,NULL Scheme_Code 
,NULL [Scheme Description]
,NULL Segment
,NULL IS_MOC
,NULL [Renewal Date]
,NULL [Stock statement date]
,NULL [DCCO date]
,NULL [Restructuring date] 
,NULL [NPA Date NCIF]
,NULL [Fraud Flag]
,NULL [Woff Flag]
,NULL [ARC Flag]
,NULL [OTS Flag]
FROM [dbo].[AdvAcWODetail]    ACWOD
LEFT JOIN DimSourceSystem     DSS                           ON  DSS.SourceAlt_Key=ACWOD.SrcSysAlt_Key
                                                                              AND DSS.EffectiveToTimeKey=49999
                                                                            AND ACWOD.EffectiveToTimeKey=49999
and ACWOD.EffectiveFromTimeKey<=@Timekey and ACWOD.EffectiveToTimeKey>=@Timekey
LEFT JOIN SysDayMatrix   SDM                   ON ACWOD.EffectiveFromTimeKey=SDM.TimeKey
Left join curdat.AdvAcRestructureDetail ARD
on ARD.RefSystemAcId=ACWOD.CustomerAcid
and ARD.EffectiveFromTimeKey<=@TimeKey AND ARD.EffectiveToTimeKey>=@TimeKey
WHERE --ACWOD.EffectiveFromTimeKey BETWEEN @FromDate AND  @ToDate
       ACWOD.WriteOffDt BETWEEN @FromDate AND  @ToDate
and ACWOD.CustomerACID not in (
Select NI.CustomerACID
from NPA_IntegrationDetails NI
where (IsTWO='y' or ISNULL(NCIF_AssetClassAlt_Key,1)=7) and
NI.EffectiveFromTimeKey<=@Timekey and Ni.EffectiveToTimeKey>=@Timekey and 
 WriteOffDate between @FromDate and @ToDate) 
 )
 Select     
 AsOnDate
,[SourceName]
,[Account No]
,[CIF]
,[NCIF]
,[Pan]
,[CustomerName]
,[DPD_Overdue_Loans]
,[DPD_Interest_Not_Serviced]
,[DPD_Overdue Interest]
,[DPD_Overdrawn]
,[DPD_Principal Overdue]
,[DPD_Other Overdue]
,[DPD_Renewals]
,[DPD_Stock Statement]
,[Max DPD on date of write off]
,[Date of Write off by D2K]
,[Principal OS]
,[Interest OS]
,[NCIF NPA date prior to write off]
,[Asset class prior to write off]
,[Scheme_Type]
,[Scheme_Code]
,[Scheme Description]
,[Segment]
,[IS_MOC]
,[Renewal Date]
,[Stock statement date]
,[DCCO date]
,[Restructuring date]
,[NPA Date NCIF]
,[Fraud Flag]
,[Woff Flag]
,[ARC Flag]
,[OTS Flag]
 from cte order by SR_No,PAN desc

END
  
GO