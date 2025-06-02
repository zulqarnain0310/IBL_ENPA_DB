SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/* Below table has to be created only once for insertion */
Create Proc [dbo].[PROC_HistoryUpgradationData_09042024]
as
Begin

 Declare @Timekey int=(Select Timekey from sysdatamatrix where currentstatus='c') 
 Declare @Ext_Date Date=(select cast(Date as Date) from sysdatamatrix where currentstatus='c')
 
  Drop Table if exists #npa_integrationdetails_Curnt
  Select * into #npa_integrationdetails_Curnt
  from [dbo].[NPA_IntegrationDetails]
  where EffectiveFromTimeKey= @Timekey and EffectiveToTimeKey=@Timekey   --- 14 dec 2022

  select 1
 DROP TABLE IF EXISTS #npa_integrationdetails_archive
 Select * into #npa_integrationdetails_archive from [dbo].[NPA_IntegrationDetails_Archive] 
 where  EffectiveFromTimeKey=(Select @Timekey-1) and EffectiveToTimeKey=(Select @Timekey-1)

 select 2
Create nonclustered index idx_npa_integrationdetails_archive 
on #npa_integrationdetails_archive(CustomerAcid)

 Insert into HistoryUpgradationData
 Select --a.EffectiveFromTimeKey,b.EffectiveFromTimeKey,a.NCIF_AssetClassAlt_Key,b.NCIF_AssetClassAlt_Key,* 
 @Ext_Date
,DS.SourceName 
,npd.NCIF_Id 
,npd.CustomerACID 
,npd.IsFunded 
,npd.CustomerId 
,npd.PAN 
,npd.CustomerName 
,npd.MaxDPD 
,npd.UpgDate 
,npd.PrincipleOutstanding 
,npd.IntOverdue 
,NPDArc.MaxDPD [Yesterday Max DPD] 
,NPDArc.PrincipleOutstanding [Yesterday Principal OS]
,npd.IntOverdue [Yesterday Interest OS] 
--,npdarc.NCIF_AssetClassAlt_Key [Asset class prior to upgrade]
,DAC_prev.AssetClassShortNameEnum  [Asset class prior to upgrade]
,NPDArc.NCIF_NPA_DATE
--,NPD.NCIF_AssetClassAlt_Key
,DAC_latest.AssetClassShortNameEnum [Asset class on upgrade date]
,NPD.FacilityType [Scheme Type]
,NPD.ProductDesc [Scheme Description]
,NPD.ProductCode [Scheme Code]
,NPD.Segment
,NPD.SubSegment [Sub Segment]
,NPD.MOC_Status IS_MOC
,NPD.ReviewDueDt [Renewal Date]
,NPD.StkStmtDate [Stock statement date]
,NPD.DCCO_Date [DCCO date]
,NPD.PROJ_COMPLETION_DATE [Project Completion Date]
 from #npa_integrationdetails_Curnt NPD 
 inner join #npa_integrationdetails_archive NPDArc 
 on NPD.customeracid=NPDArc.customeracid
 and NPD.SrcSysAlt_Key=NPDArc.SrcSysAlt_Key
 And NPD.NCIF_Id not in (Select NCIF_Id from #npa_integrationdetails_archive WHERE NCIF_AssetClassAlt_Key=1) --- NCIF ID TO BE REMOVED FROM  YESTERDAY --- /* 24062023 *
Left Join DimsourceSystem ds 
 on NPD.srcsysalt_key=ds.sourcealt_key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_latest
 on NPD.NCIF_AssetClassAlt_Key=DAC_latest.AssetClassAlt_Key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_prev
 on NPDArc.NCIF_AssetClassAlt_Key=DAC_prev.AssetClassAlt_Key
 where NPD.EffectiveFromTimeKey=@Timekey and NPD.EffectiveToTimeKey=@Timekey
 and NPDArc.EffectiveFromTimeKey=(Select @Timekey-1) and NPDArc.EffectiveToTimeKey=(Select @Timekey-1)
 and NPD.NCIF_AssetClassAlt_Key=1 and NPDArc.NCIF_AssetClassAlt_Key<>1 

 select 3
 Drop table if exists #AccountAdditionalforUpgrade
 Select CustomerACID into #AccountAdditionalforUpgrade 
 from #npa_integrationdetails_Curnt where 
 EffectiveFromTimeKey=@Timekey and EffectiveToTimeKey=@Timekey
 and NCIF_Id in (
 Select NCIF from HistoryUpgradationData where AsonDate=@Ext_Date)
 and isnull(CustomerACID,'') not in (Select Account from HistoryUpgradationData where AsonDate=@Ext_Date)

 select 4
 Insert into HistoryUpgradationData
 Select --a.EffectiveFromTimeKey,b.EffectiveFromTimeKey,a.NCIF_AssetClassAlt_Key,b.NCIF_AssetClassAlt_Key,* 
 @Ext_Date
,DS.SourceName 
,npd.NCIF_Id 
,npd.CustomerACID 
,npd.IsFunded 
,npd.CustomerId 
,npd.PAN 
,npd.CustomerName 
,npd.MaxDPD 
,npd.UpgDate 
,npd.PrincipleOutstanding 
,npd.IntOverdue 
,NPDArc.MaxDPD [Yesterday Max DPD] 
,NPDArc.PrincipleOutstanding [Yesterday Principal OS]
,npd.IntOverdue [Yesterday Interest OS] 
--,npdarc.NCIF_AssetClassAlt_Key [Asset class prior to upgrade]
,DAC_prev.AssetClassShortNameEnum  [Asset class prior to upgrade]
,NPDArc.NCIF_NPA_DATE
--,NPD.NCIF_AssetClassAlt_Key
,DAC_latest.AssetClassShortNameEnum [Asset class on upgrade date]
,NPD.FacilityType [Scheme Type]
,NPD.ProductDesc [Scheme Description]
,NPD.ProductCode [Scheme Code]
,NPD.Segment
,NPD.SubSegment [Sub Segment]
,NPD.MOC_Status IS_MOC
,NPD.ReviewDueDt [Renewal Date]
,NPD.StkStmtDate [Stock statement date]
,NPD.DCCO_Date [DCCO date]
,NPD.PROJ_COMPLETION_DATE [Project Completion Date]
 from #npa_integrationdetails_Curnt NPD 
 Left join #npa_integrationdetails_archive NPDArc 
 on NPD.customeracid=NPDArc.customeracid
 and NPD.SrcSysAlt_Key=NPDArc.SrcSysAlt_Key
 Left Join DimsourceSystem ds 
 on NPD.srcsysalt_key=ds.sourcealt_key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_latest
 on NPD.NCIF_AssetClassAlt_Key=DAC_latest.AssetClassAlt_Key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_prev
 on NPDArc.NCIF_AssetClassAlt_Key=DAC_prev.AssetClassAlt_Key
 where NPD.EffectiveFromTimeKey=@Timekey and NPD.EffectiveToTimeKey=@Timekey
 --and NPDArc.EffectiveFromTimeKey=(Select @Timekey-1) and NPDArc.EffectiveToTimeKey=(Select @Timekey-1)
 --and NPD.NCIF_AssetClassAlt_Key=1 and NPDArc.NCIF_AssetClassAlt_Key<>1 ?
  and npd.CustomerACID in (select CustomerACID from #AccountAdditionalforUpgrade) /* handeled for accounts left for degrade as on date 20 march 2023 */
 
 select 5
 SELECT * FROM HistoryUpgradationData WHERE AsOnDate=@Ext_Date

 END
GO