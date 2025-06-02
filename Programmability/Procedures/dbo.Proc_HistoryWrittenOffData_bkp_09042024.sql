SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create Proc [dbo].[Proc_HistoryWrittenOffData_bkp_09042024]
(@Date Date)
As
Begin
Declare @Ext_Date Date=@Date
Declare @TimeKey INT =(Select TimeKey From SysDataMatrix WHERE cast(date as date)=@Ext_Date)
Declare @TimeKey_1 INT =@TimeKey-1

drop table if exists #npa_integrationdetails_curnt
Select * into #npa_integrationdetails_curnt from 
NPA_IntegrationDetails
where  EffectiveFromTimeKey<= @Timekey and EffectiveToTimeKey>=@Timekey
and (isnull(IsTWO,'N')='Y' or ISNULL(NCIF_AssetClassAlt_Key,1)=7)
and WriteOffDate>'2022-12-31'

select 1 
drop table if exists #AdvAcRestructureDetail_curnt
Select * into #AdvAcRestructureDetail_curnt from 
CURDAT.AdvAcRestructureDetail
where  EffectiveFromTimeKey<=@Timekey and EffectiveToTimeKey>=@Timekey
AND RefCustomer_CIF IN (SELECT NCIF_Id FROM #npa_integrationdetails_curnt)

select 2

delete from HistoryWrittenOffData where AsonDate=@Ext_Date
Insert into HistoryWrittenOffData
 Select 
 GETDATE() InsertDate 
,@Ext_Date Datadate
,SourceName
,CustomerACID 
,CustomerID 
,NCIF_Id 
,Pan
,CustomerName
,DPD_Overdue_Loans
,DPD_Interest_Not_Serviced  
,DPD_Interest_Not_Serviced 
,DPD_Overdrawn
,DPD_PrincOverdue 
,DPD_OtherOverdueSince 
,DPD_Renewals
,DPD_StockStmt 
,MaxDPD 
,WriteOffDate 
,PrincipleOutstanding 
,IntOverdue 
,AC_NPA_Date  
,AC_AssetClassAlt_Key 
,FacilityType  ---ProductType /* producttype column is null in the table */
,ProductCode  
,ProductDesc 
,Segment
,MOC_Status 
,ReviewDueDt 
,StkStmtDate 
,DCCO_Date 
,RestructureDate 
,NCIF_NPA_Date 
,IsFraud 
,IsTWO 
,IsARC_Sale 
,IsOTS 
,WriteOffAmount  
,MocReasonName
From #npa_integrationdetails_curnt NPD left join 
#AdvAcRestructureDetail_curnt ADV
ON NPD.CustomerACID=ADV.RefSystemAcId
--and NPD.EffectiveFromTimeKey<=@TimeKey and NPD.EffectiveToTimeKey>=@TimeKey -- commented by satish as it was creating duplicate accts in the table did as on date 170202023
and ADV.EffectiveFromTimeKey<=@TimeKey and ADV.EffectiveToTimeKey>=@TimeKey
Left join DimSourceSystem DS on NPD.SrcSysAlt_Key=DS.SourceAlt_Key
left join DimMocReason res on npd.MOC_ReasonAlt_Key=res.MocReasonAlt_Key
and res.EffectiveFromTimeKey<=@TimeKey and res.EffectiveToTimeKey>=@TimeKey
where NPD.EffectiveFromTimeKey<=@TimeKey and NPD.EffectiveToTimeKey>=@TimeKey -- added by satish as it was creating duplicate accts in the table did as on date 170202023
 and CustomerACID IN	(	Select CustomerACID
							From #npa_integrationdetails_curnt 
							except
							Select [Account No] from HistoryWrittenOffData
						)

select 3
drop table if exists #npa_integrationdetails_archive
Select arc.* into #npa_integrationdetails_archive from 
NPA_IntegrationDetails_Archive(nolock) arc inner join #npa_integrationdetails_curnt cnt on 
arc.NCIF_ID=cnt.NCIF_Id
where  arc.EffectiveFromTimeKey<=(Select @Timekey-1) and arc.EffectiveToTimeKey>=(Select @Timekey-1)

select 4
drop table if exists #AdvAcRestructureDetail_archive
Select arc.* into #AdvAcRestructureDetail_archive from 
CURDAT.AdvAcRestructureDetail_archive(nolock) arc inner join #AdvAcRestructureDetail_curnt cnt on 
arc.RefCustomer_CIF=cnt.RefCustomer_CIF
where  arc.EffectiveFromTimeKey<=(Select @Timekey-1) and arc.EffectiveToTimeKey>=(Select @Timekey-1)

Create nonclustered index idx_npa_integrationdetails_archive 
on #npa_integrationdetails_archive(CustomerAcid)

/* History write off detail table T-1 days update */
  Declare @Prevtimekey int=(select @Timekey-1)

  Update HOWD set 
  HOWD.DPD_Overdue_Loans=b.DPD_Overdue_Loans
 ,HOWD.DPD_Interest_Not_Serviced=b.DPD_Interest_Not_Serviced
 ,HOWD.[DPD_Overdue Interest]=b.DPD_IntService
 ,HOWD.DPD_Overdrawn=b.DPD_Overdrawn
 ,HOWD.[DPD_Principal Overdue]=b.DPD_PrincOverdue
 ,HOWD.[DPD_Other Overdue]=b.DPD_OtherOverdueSince
 ,HOWD.DPD_Renewals=b.DPD_Renewals
 ,HOWD.[DPD_Stock Statement]=b.DPD_StockStmt
 ,HOWD.[Max DPD on date of write off]=b.MaxDPD
 ,HOWD.[Asset class prior to Write off]=b.AC_AssetClassAlt_Key
 ,HOWD.[Renewal Date]=b.ReviewDueDt
 ,HOWD.[Stock Statement date]=b.StkStmtDate
 ,HOWD.[DCCO date]=b.DCCO_Date
 ,HOWD.[Restructuring date]=b.RestructureDt
--  Select HOWD.[Date of Write off by D2K],Date, * 
from HistoryWrittenOffData HOWD inner join 
                                          (Select adr.RestructureDt,Date,arc.* 
										  from #npa_integrationdetails_archive arc 
                                          Left Join #AdvAcRestructureDetail_archive adr  ---- archive question for this
                                          on arc.customeracid=adr.RefSystemAcId
										  and arc.EffectiveFromTimeKey<=@Prevtimekey and arc.EffectiveToTimeKey>=@Prevtimekey
										  and adr.EffectiveFromTimeKey<=@Prevtimekey and adr.EffectiveToTimeKey>=@Prevtimekey
                                          Left Join sysdatamatrix dy on 
                                          arc.EffectiveFromTimeKey=dy.TimeKey) b 
on HOWD.[Account No]=b.CustomerACID
and HOWD.AsonDate=@Ext_Date  ----t-1 date	
END
GO