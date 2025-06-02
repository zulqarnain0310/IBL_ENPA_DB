SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

--/* Below table has to be created only once for insertion */
CREATE Proc [dbo].[PROC_HistoryDownGradationData_20230807]
as
Begin
 Declare @Timekey int=(Select Timekey from sysdatamatrix where currentstatus='c') 
 Declare @Ext_Date Date=(select cast(Date as Date) from sysdatamatrix where currentstatus='c') ---15 dec 2022
  
  Drop Table if exists #npa_integrationdetails_archive
  Select * into #npa_integrationdetails_archive
  from NPA_IntegrationDetails_Archive
  where EffectiveFromTimeKey=(Select @Timekey-1) and EffectiveToTimeKey=(Select @Timekey-1)   --- 14 dec 2022

 Create  NOnclustered index idx_npa_integrationdetails_archive on #npa_integrationdetails_archive(customeracid)

  Delete from HistoryDownGradeData where AsonDate=@Ext_Date
  Insert into HistoryDownGradeData
  (
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
,flgdeg
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
,@Ext_Date [Date of downgrade]
,NPD.AC_NPA_Date [Date of NPA of source system]
,NPD.NCIF_NPA_Date [Homogenized_Date of NPA]
--,DAC_prev.AssetClassShortNameEnum [Classification of source system]
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
,NPD.flgdeg
--count(1)
from NPA_IntegrationDetails NPD 
 inner join #npa_integrationdetails_archive NPDArc 
 on NPD.customeracid=NPDArc.customeracid
 and NPD.srcsysalt_key= NPDArc.srcsysalt_key
 and NPD.NCIF_Id not in (Select NCIF from HistoryDownGradeData WHERE DATEADD(DD,-1,@Ext_Date)=AsonDate) --- NCIF ID TO BE REMOVED FROM  YESTERDAY  DATA
 --and NPD.NCIF_Id not in (Select NCIF from [dbo].[DOWN_NCIF] WHERE DATEADD(DD,-1,@Ext_Date)=AsonDate) -- HAVE TO REMOVE THIS AND HAVE TO USE THE UP QUERY
 Left Join DimsourceSystem ds 
 on NPD.srcsysalt_key=ds.sourcealt_key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_latest
 on NPD.NCIF_AssetClassAlt_Key=DAC_latest.AssetClassAlt_Key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_prev  --- 
 on NPD.AC_AssetClassAlt_Key=DAC_prev.AssetClassAlt_Key
 left join  (Select RefSystemAcId,DateCreated,DateModified,RestructureTypeAlt_Key,RestructureDt,
          ROW_NUMBER() over (partition by RefSystemAcId order by COALESCE(isnull(DateCreated,''),isnull(DateModified,'')) desc)  RN
   from curdat.advacrestructuredetail
   where EffectiveFromTimeKey=@TIMEKEY  and EffectiveToTimeKey=@TIMEKEY) Res
 on NPD.customeracid=Res.refsystemacid
 and res.RN=1
   Left JOIN DimParameter PAR
 ON PAR.EffectiveFromTimeKey<=@TIMEKEY AND PAR.EffectiveToTimeKey>=@TIMEKEY
 AND ParameterAlt_Key=RES.RestructureTypeAlt_Key
 and PAR.DimParameterName='TypeofRestructuring'
 where NPD.EffectiveFromTimeKey<=@Timekey and NPD.EffectiveToTimeKey>=@Timekey
 and NPDArc.EffectiveFromTimeKey=(Select @Timekey-1) and NPDArc.EffectiveToTimeKey=(Select @Timekey-1)
 and NPD.NCIF_AssetClassAlt_Key<>1 and NPDArc.NCIF_AssetClassAlt_Key=1 	


 Drop table if exists #AccountAdditionalforDegrade
 Select CustomerACID into #AccountAdditionalforDegrade 
 from NPA_IntegrationDetails where 
 EffectiveFromTimeKey=@Timekey and EffectiveToTimeKey=@Timekey
 and NCIF_Id in (
 Select NCIF from HistoryDownGradeData where AsonDate=@Ext_Date)
 and isnull(CustomerACID,'') not in (Select Account from HistoryDownGradeData where AsonDate=@Ext_Date)

 Insert into HistoryDownGradeData
  (
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
,flgdeg
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
,@Ext_Date [Date of downgrade]
,NPD.AC_NPA_Date [Date of NPA of source system]
,NPD.NCIF_NPA_Date [Homogenized_Date of NPA]
--,DAC_prev.AssetClassShortNameEnum [Classification of source system]
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
,NPD.flgdeg
 from NPA_IntegrationDetails NPD 
 left join #npa_integrationdetails_archive NPDArc 
 on NPD.customeracid=NPDArc.customeracid
 and NPD.srcsysalt_key= NPDArc.srcsysalt_key
 and NPDArc.EffectiveFromTimeKey=(Select @Timekey-1) and NPDArc.EffectiveToTimeKey=(Select @Timekey-1)
 and NPD.NCIF_Id not in (Select NCIF from HistoryDownGradeData WHERE DATEADD(DD,-1,@Ext_Date)=AsonDate) --- NCIF ID TO BE REMOVED FROM  YESTERDAY  DATA
 --and NPD.NCIF_Id not in (Select NCIF from [dbo].[DOWN_NCIF] WHERE DATEADD(DD,-1,@Ext_Date)=AsonDate) -- HAVE TO REMOVE THIS AND HAVE TO USE THE UP QUERY
 Left Join DimsourceSystem ds 
 on NPD.srcsysalt_key=ds.sourcealt_key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_latest
 on NPD.NCIF_AssetClassAlt_Key=DAC_latest.AssetClassAlt_Key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_prev  --- 
 on NPD.AC_AssetClassAlt_Key=DAC_prev.AssetClassAlt_Key
 left join  (Select RefSystemAcId,DateCreated,DateModified,RestructureTypeAlt_Key,RestructureDt,
          ROW_NUMBER() over (partition by RefSystemAcId order by COALESCE(isnull(DateCreated,''),isnull(DateModified,'')) desc)  RN
   from curdat.advacrestructuredetail
   where EffectiveFromTimeKey=@TIMEKEY  and EffectiveToTimeKey=@TIMEKEY) Res
 on NPD.customeracid=Res.refsystemacid
 and res.RN=1
   Left JOIN DimParameter PAR
 ON PAR.EffectiveFromTimeKey<=@TIMEKEY AND PAR.EffectiveToTimeKey>=@TIMEKEY
 AND ParameterAlt_Key=RES.RestructureTypeAlt_Key
 and PAR.DimParameterName='TypeofRestructuring'
 where NPD.EffectiveFromTimeKey=@Timekey and NPD.EffectiveToTimeKey=@Timekey
 and npd.CustomerACID in (select CustomerACID from #AccountAdditionalforDegrade) /* handeled for accounts left for degrade as on date 20 march 2023 */

  
  Update A set [Culprit System]=a.SourceName,[Culprit System Account No]=a.Account from HistoryDownGradeData(nolock) A where AsonDate=@Ext_Date and NCIF in (
  select NCIF from  HistoryDownGradeData(nolock)  where AsonDate=@Ext_Date
  group by NCIF
  having count(1)=1)

  
   Update a set [Culprit System]=b.SourceName,[Culprit System Account No]=b.Account from
  (select CIF,NCIF,Account,[Date of NPA of source system],[Homogenized_Date of NPA],[Classification of source system],[Homogenized_Classification],[Culprit System],[Culprit System Account No]
  from HistoryDownGradeData(nolock) A where 
  (isnull([Classification of source system],1)<>isnull([Homogenized_Classification],1) or
    isnull([Date of NPA of source system],'')<>isnull([Homogenized_Date of NPA],''))
  and AsonDate=@Ext_Date and NCIF in (
  Select NCIF from  HistoryDownGradeData(nolock)  where AsonDate=@Ext_Date
  group by NCIF
  having count(1)>1)) a 
  inner join
   (select NCIF, STRING_AGG (CONVERT(NVARCHAR(max),Sourcename),',') Sourcename,STRING_AGG (CONVERT(NVARCHAR(max),Account),',') Account
  from HistoryDownGradeData(nolock) A where 
   ( isnull([Classification of source system],1)=isnull([Homogenized_Classification],1) or
    isnull([Date of NPA of source system],'')=isnull([Homogenized_Date of NPA],''))
    and AsonDate=@Ext_Date and NCIF in (
  Select NCIF from  HistoryDownGradeData(nolock)  where AsonDate=@Ext_Date
  group by NCIF
  having count(1)>1) group by NCIF) b on a.NCIF=b.NCIF
  
  Update a set [Culprit System]=b.SourceName,[Culprit System Account No]=b.Account from
  (select CIF,NCIF,Account,[Date of NPA of source system],[Homogenized_Date of NPA],[Classification of source system],[Homogenized_Classification],[Culprit System],[Culprit System Account No]
  from HistoryDownGradeData(nolock) A where 
  (isnull([Classification of source system],1)=isnull([Homogenized_Classification],1) or
    isnull([Date of NPA of source system],'')=isnull([Homogenized_Date of NPA],''))
  and AsonDate=@Ext_Date and NCIF in (
  Select NCIF from  HistoryDownGradeData(nolock)  where AsonDate=@Ext_Date
  group by NCIF
  having count(1)>1)) a 
  inner join
   (select NCIF, STRING_AGG (CONVERT(NVARCHAR(max),Sourcename),',') Sourcename,STRING_AGG (CONVERT(NVARCHAR(max),Account),',') Account
  from HistoryDownGradeData(nolock) A where 
   ( isnull([Classification of source system],1)=isnull([Homogenized_Classification],1) or
    isnull([Date of NPA of source system],'')=isnull([Homogenized_Date of NPA],''))
    and AsonDate=@Ext_Date and NCIF in (
  Select NCIF from  HistoryDownGradeData(nolock)  where AsonDate=@Ext_Date
  group by NCIF
  having count(1)>1) group by NCIF) b on a.NCIF=b.NCIF
  

    Update Fin set [Culprit System]=prev.Sourcename,[Culprit System Account No]=prev.Account 
	--select Fin.*,prev.*
	from
	(Select NCIF,[Culprit System], [Culprit System Account No] from HistoryDownGradeData where asondate=@Ext_Date and [Culprit System] is null) Fin
	 inner join
	 (Select a.NCIF,Sourcename,Account from 
	(select NCIF,Count(1) cnt,'STD' Assets from HistoryDownGradeData where asondate=@Ext_Date  
	group by NCIF) a inner join 
    (select NCIF,Count(1) cnt,'STD' Assets from HistoryDownGradeData where asondate=@Ext_Date and [Classification of source system]='STD'
    group by NCIF) b
	on a.NCIF=b.NCIF
	inner join (Select NCIF,STRING_AGG (CONVERT(NVARCHAR(max),Sourcename),',') Sourcename,STRING_AGG (CONVERT(NVARCHAR(max),account),',') Account 
	from HistoryDownGradeData 
	where asondate=@Ext_Date and isnull(flgdeg,'N')='Y' group by NCIF) c
	on b.NCIF=c.NCIF) prev
	on Fin.NCIF=prev.NCIF

  
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
,[Max DPD on date of downgrade]	
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