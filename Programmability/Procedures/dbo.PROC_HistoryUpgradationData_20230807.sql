SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/* Below table has to be created only once for insertion */
CREATE Proc [dbo].[PROC_HistoryUpgradationData_20230807]
as
Begin

 Declare @Timekey int=(Select Timekey from sysdatamatrix where currentstatus='c') 
 Declare @Ext_Date Date=(select cast(Date as Date) from sysdatamatrix where currentstatus='c')
 Select * into #npa_integrationdetails_archive from 
NPA_IntegrationDetails_Archive
where  EffectiveFromTimeKey=(Select @Timekey-1) and EffectiveToTimeKey=(Select @Timekey-1)

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
 from NPA_IntegrationDetails NPD 
 inner join #npa_integrationdetails_archive NPDArc 
 on NPD.customeracid=NPDArc.customeracid
 and NPD.SrcSysAlt_Key=NPDArc.SrcSysAlt_Key
 Left Join DimsourceSystem ds 
 on NPD.srcsysalt_key=ds.sourcealt_key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_latest
 on NPD.NCIF_AssetClassAlt_Key=DAC_latest.AssetClassAlt_Key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_prev
 on NPDArc.NCIF_AssetClassAlt_Key=DAC_prev.AssetClassAlt_Key
 where NPD.EffectiveFromTimeKey=@Timekey and NPD.EffectiveToTimeKey=@Timekey
 and NPDArc.EffectiveFromTimeKey=(Select @Timekey-1) and NPDArc.EffectiveToTimeKey=(Select @Timekey-1)
 and NPD.NCIF_AssetClassAlt_Key=1 and NPDArc.NCIF_AssetClassAlt_Key<>1  
end

 

 


GO