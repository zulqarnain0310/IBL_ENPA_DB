SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

--/* Below table has to be created only once for insertion */
create Proc [dbo].[PROC_HistoryDownGradationData_backup_01032023]
as
Begin
 Declare @Timekey int=(Select Timekey from sysdatamatrix where currentstatus='c') 
 Declare @Ext_Date Date=(select cast(Date as Date) from sysdatamatrix where currentstatus='c') ---15 dec 2022
  
  Drop Table if exists #npa_integrationdetails_archive
  Select * into #npa_integrationdetails_archive
  from NPA_IntegrationDetails_Archive
  where EffectiveFromTimeKey=(Select @Timekey-1) and EffectiveToTimeKey=(Select @Timekey-1)   --- 14 dec 2022

 Create  NOnclustered index idx_npa_integrationdetails_archive on #npa_integrationdetails_archive(customeracid)

Insert into HistoryDownGradeData(
  AsonDate
,[SourceName]
,[Account]
,[Funded Non Funded Flag]
,[CIF]
,[NCIF]
,[PAN No]
,[Name]
,[DPD_Overdue_Loans]
,[DPD_Interest_Not_Serviced]
,[DPD_Overdue Interest]
,[DPD_Overdrawn]
,[DPD_Principal Overdue]
,[DPD_Other Overdue]
,[DPD_Renewals]
,[DPD_Stock Statement]
,[Max DPD on date of downgrade]
,[Date of downgrade]
,[Date of NPA of source system]
,[Homogenized_Date of NPA]
,[Classification of source system]
,[Homogenized_Classification]
,[Principal OS]
,[Interest OS]
,[Yesterday Principal OS]
,[Yesterday Interest OS]
,[Scheme Type]
,[Scheme_Code]
,[Scheme Description]
,[Segment]
,[IS_MOC]
,[Renewal Date]
,[Stock statement date1]
,[DCCO date]
,[Restructuring date]
,[Restructuring Flag]
,[Restructuring Type]
,[Fraud flag]
)
 Select --a.EffectiveFromTimeKey,b.EffectiveFromTimeKey,a.NCIF_AssetClassAlt_Key,b.NCIF_AssetClassAlt_Key,* 
 @Ext_Date AsonDate
,ds.SourceName
,NPD.customeracid Account
,NPD.IsFunded [Funded Non Funded Flag]
,NPD.CustomerId CIF
,NPD.NCIF_Id  NCIF
,NPD.PAN [PAN No]
,NPD.CustomerName Name
,NPD.DPD_Overdue_Loans
,NPD.DPD_Interest_Not_Serviced
,NPD.DPD_IntService [DPD_Overdue Interest]
,NPD.DPD_Overdrawn
,NPD.DPD_PrincOverdue [DPD_Principal Overdue]
,NPD.DPD_OtherOverdueSince [DPD_Other Overdue]
,NPD.DPD_Renewals DPD_Renewals
,NPD.DPD_StockStmt [DPD_Stock Statement]
,NPD.maxdpd [Max DPD on date of downgrade]
,Dateadd(dd,-1,cast(getdate() as Date)) [Date of downgrade]
,NPD.AC_NPA_Date [Date of NPA of source system]
,NPD.NCIF_NPA_Date [Homogenized_Date of NPA]
,DAC_prev.AssetClassShortNameEnum [Classification of source system]
,DAC_latest.AssetClassShortNameEnum [Homogenized_Classification]
,NPD.PrincipleOutstanding [Principal OS] 
,NPD.IntOverdue [Interest OS]
,NPDArc.PrincipleOutstanding [Yesterday Principal OS] 
,NPDArc.IntOverdue  [Yesterday Interest OS]
,NPD.FacilityType [Scheme Type]
,NPD.ProductCode [Scheme_Code]
,NPD.ProductDesc [Scheme Description]
,NPD.Segment
,NPD.MOC_Status IS_MOC
,NPD.ReviewDueDt [Renewal Date]
--,NPD.DPD_StockStmt [Stock statement date]
,NPD.StkStmtDate [Stock statement date] -- corrected by satish as on 31 dec 2022
,NPD.DCCO_Date [DCCO date]
,res.Restructuredt [Restructuring date]
,NPD.IsRestructured [Restructuring Flag]
,PAR.ParameterShortNameEnum [Restructuring Type]
,NPD.isfraud [Fraud flag]
 from NPA_IntegrationDetails NPD 
 inner join #npa_integrationdetails_archive NPDArc 
 on NPD.customeracid=NPDArc.customeracid
 and NPD.NCIF_Id not in (Select NCIF from HistoryDownGradeData WHERE DATEADD(DD,-1,@Ext_Date)=AsonDate) --- NCIF ID TO BE REMOVED FROM  YESTERDAY  DATA
 Left Join DimsourceSystem ds 
 on NPD.srcsysalt_key=ds.sourcealt_key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_latest
 on NPD.NCIF_AssetClassAlt_Key=DAC_latest.AssetClassAlt_Key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_prev  --- 
 on NPD.NCIF_AssetClassAlt_Key=DAC_prev.AssetClassAlt_Key
 left join curdat.advacrestructuredetail Res
 on NPD.customeracid=Res.refsystemacid
 and res.EffectiveFromTimeKey<=@Timekey and res.EffectiveToTimeKey>=@Timekey
 Left JOIN DimParameter PAR
 ON PAR.EffectiveFromTimeKey<=@TIMEKEY AND PAR.EffectiveToTimeKey>=@TIMEKEY
 AND ParameterAlt_Key=RES.RestructureTypeAlt_Key
 where NPD.EffectiveFromTimeKey<=@Timekey and NPD.EffectiveToTimeKey>=@Timekey
 and NPD.NCIF_AssetClassAlt_Key<>1 and NPDArc.NCIF_AssetClassAlt_Key=1 	

  --Select ncif_id from NPA_IntegrationDetails where EffectiveFromTimeKey<=@TIMEKEY and EffectiveToTimeKey>=@TIMEKEY
  --and customeracid in (
  --Select account from HistoryDownGradeData where AsonDate=@Ext_Date)
 
    Drop table if exists #NPA_IntegrationDetails_Agg
    Select * into #NPA_IntegrationDetails_Agg  from NPA_IntegrationDetails where 
	EffectiveFromTimeKey<=@TIMEKEY and EffectiveToTimeKey>=@TIMEKEY  
	and ncif_id in (
   (Select distinct ncif_id from NPA_IntegrationDetails a
   left join HistoryDownGradeData b
   on a.customeracid=b.account
   where EffectiveFromTimeKey<=@TIMEKEY and EffectiveToTimeKey>=@TIMEKEY 
   and b.AsonDate=@Ext_Date))


  --select  Ncif_id,STRING_AGG (CONVERT(NVARCHAR(max),CustomerACID),',') CustomerACID,
  --         STRING_AGG (CONVERT(NVARCHAR(max),Sourcename),',') Sourcename
  ----CustomerACID,NCIF_AssetClassAlt_Key,AC_AssetClassAlt_Key,NCIF_NPA_Date,AC_NPA_Date,Sourcename 
  --from  #NPA_IntegrationDetails_Agg a left join dimsourcesystem b  on a.SrcSysAlt_Key=b.SourceAlt_Key
  --where NCIF_AssetClassAlt_Key<>AC_AssetClassAlt_Key or isnull(NCIF_NPA_Date,'')<>Isnull(AC_NPA_Date,'')
  --group by ncif_id

  
  Update a set a.[Culprit System]=b.Sourcename,a.[Culprit System Account No]=b.CustomerACID
  from HistoryDownGradeData a left join
  (select  Ncif_id,STRING_AGG (CONVERT(NVARCHAR(max),CustomerACID),',') CustomerACID,
           STRING_AGG (CONVERT(NVARCHAR(max),Sourcename),',') Sourcename
  --CustomerACID,NCIF_AssetClassAlt_Key,AC_AssetClassAlt_Key,NCIF_NPA_Date,AC_NPA_Date,Sourcename 
  from  #NPA_IntegrationDetails_Agg a left join dimsourcesystem b  on a.SrcSysAlt_Key=b.SourceAlt_Key
  where NCIF_AssetClassAlt_Key<>AC_AssetClassAlt_Key or isnull(NCIF_NPA_Date,'')<>Isnull(AC_NPA_Date,'')
  group by ncif_id) b on a.NCIF=b.Ncif_id
  where AsonDate=@Ext_Date

  
;with cte as
(
select   
AsonDate	
,SourceName	
,Account	
,[Funded Non Funded Flag]
,CIF	
,NCIF	
,[PAN No]
,Name	
,DPD_Overdue_Loans	
,DPD_Interest_Not_Serviced	
,[DPD_Overdue Interest]	
,DPD_Overdrawn	
[DPD_Principal Overdue]	
,[DPD_Other Overdue]	
,DPD_Renewals	
,[DPD_Stock Statement]	
[Max DPD on date of downgrade]	
,[Date of downgrade]	
,[Date of NPA of source system]
,[Homogenized_Date of NPA]	
,[Classification of source system]	
,[Homogenized_Classification]	
,[Principal OS]
,[Interest OS]	
--,[Yesterday Principal OS]	
--,[Yesterday Interest OS]	
,[Scheme Type]	
,[Scheme_Code]	
,[Scheme Description]	
,Segment	
,IS_MOC	
,[Renewal Date]	
,[Stock statement date1] [Stock statement date]
,[DCCO date],
[Restructuring date]	
,[Restructuring Flag]	
,[Restructuring Type]	
,[Fraud flag]	
,[Culprit System]
,[Culprit System Account No]	
from
HistoryDownGradeData(nolock) where AsonDate=@Ext_Date
--order by 3
)
select * from cte --group by Account having count(1)>1
end


 
   
 

GO