SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[History_UPgrade_DowngradeData]
as
Declare @Timekey int=(Select Timekey from sysdatamatrix where CurrentStatus='C') --27421
Declare @Ext_Date Date=(select cast(Date as Date) from sysdatamatrix where  TimeKey=@Timekey)
Declare @Last_Day_of_month_Timekey int=(Select Timekey from sysdatamatrix 
										where Date=(Select MonthLastDate from sysdatamatrix where CurrentStatus='C')
										)
print @Last_Day_of_month_Timekey
 Declare @Prev_Month_End_Timekey int=(Select Timekey from sysdatamatrix 
										where Date=(Select dateadd(day,-1,MonthfirstDate) from sysdatamatrix where CurrentStatus='C')
										)--27394
print @Prev_Month_End_Timekey


  /*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED*/
	DROP TABLE IF EXISTS #npa_integrationdetails_MonthEnd
  		Select * into #npa_integrationdetails_MonthEnd
		from [dbo].[NPA_IntegrationDetails] WHERE 1=2

	IF @Timekey<>@Last_Day_of_month_Timekey
		BEGIN
			
				INSERT into #npa_integrationdetails_MonthEnd(EntityKey,	NCIF_Id,	NCIF_Changed,	SrcSysAlt_Key,	NCIF_EntityID,	CustomerId,	CustomerName,	PAN,	NCIF_AssetClassAlt_Key,	NCIF_NPA_Date,	AccountEntityID,	CustomerACID,	SanctionedLimit,	DrawingPower,	PrincipleOutstanding,	Balance,	Overdue,	DPD_Overdue_Loans,	DPD_Interest_Not_Serviced,	DPD_Overdrawn,	DPD_Renewals,	MaxDPD,	WriteOffFlag,	Segment,	SubSegment,	ProductCode,	ProductDesc,	Settlement_Status,	AC_AssetClassAlt_Key,	AC_NPA_Date,	AstClsChngByUser,	AstClsChngDate,	AstClsChngRemark,	MOC_Status,	MOC_Date,	MOC_ReasonAlt_Key,	MOC_AssetClassAlt_Key,	MOC_NPA_Date,	AuthorisationStatus,	EffectiveFromTimeKey,	EffectiveToTimeKey,	CreatedBy,	DateCreated,	ModifiedBy,	DateModified,	ApprovedBy,	DateApproved,	MOC_Remark,	ProductType,	ActualOutStanding,	MaxDPD_Type,	ProductAlt_Key,	AstClsAppRemark,	MocAppRemark,	PNPA_Status,	PNPA_ReasonAlt_Key,	PNPA_Date,	ActualPrincipleOutstanding,	UNSERVED_INTEREST,	CUSTOMER_IDENTIFIER,	ACCOUNT_LEVEL_CODE,	NF_PNPA_Date,	Remark,	WriteOffDate,	DbtDT,	ErosionDT,	FlgErosion,	IntOverdue,	IntAccrued,	OtherOverdue,	PrincOverdue,	IsRestructured,	IsOTS,	IsTWO,	IsARC_Sale,	IsFraud,	IsWiful,	IsNonCooperative,	IsSuitFiled,	IsRFA,	IsFITL,	IsCentral_GovGty,	Is_Oth_GovGty,	BranchCode,	FacilityType,	SancDate,	Region,	State,	Zone,	NPA_TagDate,	PS_NPS,	Retail_Corpo,	Area,	FraudAmt,	FraudDate,	GovtGtyAmt,	GtyRepudiated,	RepudiationDate,	OTS_Amt,	WriteOffAmount,	ARC_SaleDate,	ARC_SaleAmt,	PrincOverdueSinceDt,	IntNotServicedDt,	ContiExcessDt,	ReviewDueDt,	OtherOverdueSinceDt,	IntOverdueSinceDt,	SecuredFlag,	StkStmtDate,	SecurityValue,	DFVAmt,	CoverGovGur,	CreditsinceDt,	DegReason,	NetBalance,	ApprRV,	SecuredAmt,	UnSecuredAmt,	ProvDFV,	Provsecured,	ProvUnsecured,	ProvCoverGovGur,	AddlProvision,	TotalProvision,	BankProvsecured,	BankProvUnsecured,	BankTotalProvision,	RBIProvsecured,	RBIProvUnsecured,	RBITotalProvision,	SMA_Dt,	UpgDate,	ProvisionAlt_Key,	PNPA_Reason,	SMA_Class,	SMA_Reason,	CommonMocTypeAlt_Key,	FlgDeg,	FlgSMA,	FlgPNPA,	FlgUpg,	FlgFITL,	FlgAbinitio,	NPA_Days,	AppGovGur,	UsedRV,	ComputedClaim,	NPA_Reason,	PnpaAssetClassAlt_key,	SecApp,	ProvPerSecured,	ProvPerUnSecured,	AddlProvisionPer,	FlgINFRA,	MOCTYPE,	DPD_IntService,	DPD_StockStmt,	DPD_FinMaxType,	DPD_PrincOverdue,	DPD_OtherOverdueSince,	IsPUI,	AC_Closed_Date,	SECTOR,	LossDT,	IsFunded,	UploadFlag,	FlgProcessing,	DCCO_Date,	ACMOC_ReasonAlt_Key,	FlgMOC,	PROJ_COMPLETION_DATE,	OPEN_DATE,	UploadID,	STD_ASSET_CAT_Alt_key,	NatureofClassification,	DateofImpacting,	ImpactingAccountNo,	ImpactingSourceSystemName,	Co_borrower_impacted,	PBos_Culprit_Impact,	SEC_PROVPER_OLD,	UNSEC_PROVPER_OLD)
				SELECT EntityKey,	NCIF_Id,	NCIF_Changed,	SrcSysAlt_Key,	NCIF_EntityID,	CustomerId,	CustomerName,	PAN,	NCIF_AssetClassAlt_Key,	NCIF_NPA_Date,	AccountEntityID,	CustomerACID,	SanctionedLimit,	DrawingPower,	PrincipleOutstanding,	Balance,	Overdue,	DPD_Overdue_Loans,	DPD_Interest_Not_Serviced,	DPD_Overdrawn,	DPD_Renewals,	MaxDPD,	WriteOffFlag,	Segment,	SubSegment,	ProductCode,	ProductDesc,	Settlement_Status,	AC_AssetClassAlt_Key,	AC_NPA_Date,	AstClsChngByUser,	AstClsChngDate,	AstClsChngRemark,	MOC_Status,	MOC_Date,	MOC_ReasonAlt_Key,	MOC_AssetClassAlt_Key,	MOC_NPA_Date,	AuthorisationStatus,	EffectiveFromTimeKey,	EffectiveToTimeKey,	CreatedBy,	DateCreated,	ModifiedBy,	DateModified,	ApprovedBy,	DateApproved,	MOC_Remark,	ProductType,	ActualOutStanding,	MaxDPD_Type,	ProductAlt_Key,	AstClsAppRemark,	MocAppRemark,	PNPA_Status,	PNPA_ReasonAlt_Key,	PNPA_Date,	ActualPrincipleOutstanding,	UNSERVED_INTEREST,	CUSTOMER_IDENTIFIER,	ACCOUNT_LEVEL_CODE,	NF_PNPA_Date,	Remark,	WriteOffDate,	DbtDT,	ErosionDT,	FlgErosion,	IntOverdue,	IntAccrued,	OtherOverdue,	PrincOverdue,	IsRestructured,	IsOTS,	IsTWO,	IsARC_Sale,	IsFraud,	IsWiful,	IsNonCooperative,	IsSuitFiled,	IsRFA,	IsFITL,	IsCentral_GovGty,	Is_Oth_GovGty,	BranchCode,	FacilityType,	SancDate,	Region,	State,	Zone,	NPA_TagDate,	PS_NPS,	Retail_Corpo,	Area,	FraudAmt,	FraudDate,	GovtGtyAmt,	GtyRepudiated,	RepudiationDate,	OTS_Amt,	WriteOffAmount,	ARC_SaleDate,	ARC_SaleAmt,	PrincOverdueSinceDt,	IntNotServicedDt,	ContiExcessDt,	ReviewDueDt,	OtherOverdueSinceDt,	IntOverdueSinceDt,	SecuredFlag,	StkStmtDate,	SecurityValue,	DFVAmt,	CoverGovGur,	CreditsinceDt,	DegReason,	NetBalance,	ApprRV,	SecuredAmt,	UnSecuredAmt,	ProvDFV,	Provsecured,	ProvUnsecured,	ProvCoverGovGur,	AddlProvision,	TotalProvision,	BankProvsecured,	BankProvUnsecured,	BankTotalProvision,	RBIProvsecured,	RBIProvUnsecured,	RBITotalProvision,	SMA_Dt,	UpgDate,	ProvisionAlt_Key,	PNPA_Reason,	SMA_Class,	SMA_Reason,	CommonMocTypeAlt_Key,	FlgDeg,	FlgSMA,	FlgPNPA,	FlgUpg,	FlgFITL,	FlgAbinitio,	NPA_Days,	AppGovGur,	UsedRV,	ComputedClaim,	NPA_Reason,	PnpaAssetClassAlt_key,	SecApp,	ProvPerSecured,	ProvPerUnSecured,	AddlProvisionPer,	FlgINFRA,	MOCTYPE,	DPD_IntService,	DPD_StockStmt,	DPD_FinMaxType,	DPD_PrincOverdue,	DPD_OtherOverdueSince,	IsPUI,	AC_Closed_Date,	SECTOR,	LossDT,	IsFunded,	UploadFlag,	FlgProcessing,	DCCO_Date,	ACMOC_ReasonAlt_Key,	FlgMOC,	PROJ_COMPLETION_DATE,	OPEN_DATE,	UploadID,	STD_ASSET_CAT_Alt_key,	NatureofClassification,	DateofImpacting,	ImpactingAccountNo,	ImpactingSourceSystemName,	Co_borrower_impacted,	PBos_Culprit_Impact,	SEC_PROVPER_OLD,	UNSEC_PROVPER_OLD 
					FROM [DBO].[NPA_INTEGRATIONDETAILS]
				WHERE EFFECTIVEFROMTIMEKEY<= @PREV_MONTH_END_TIMEKEY AND EFFECTIVETOTIMEKEY>=@PREV_MONTH_END_TIMEKEY   --- 20230817 ADDED'<'AND '>' SIGN IN EFFECTIVEFROMTIMEKEY & EFFECTIVETOTIMEKEY 
				AND FLGMOC='Y'
		END
  /*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED END*/

  Drop Table if exists #npa_integrationdetails_Curnt
  Select * into #npa_integrationdetails_Curnt
  from [dbo].[NPA_IntegrationDetails]
  where EffectiveFromTimeKey<= @Timekey and EffectiveToTimeKey>=@Timekey   --- 20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
  and NCIF_AssetClassAlt_Key=1 

 Insert into AuditUPGDEGCheck(StepID,StepName,strartTime)
 select '2','Previous Npa table data into temp',getdate()

 DROP TABLE IF EXISTS #npa_integrationdetails_archive
 Select * into #npa_integrationdetails_archive from [dbo].[NPA_IntegrationDetails_Archive] 
 where  
 /*REMOVED THIS CONDITION BY ZAIN ON 20250325 AS ARCHIVE TABLE CONSIST ONLY ONE DAY DATA*/
 --EffectiveFromTimeKey<=(Select @Timekey-1) and EffectiveToTimeKey>=(Select @Timekey-1)--- 20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 --and 
 /*REMOVED THIS CONDITION BY ZAIN ON 20250325 AS ARCHIVE TABLE CONSIST ONLY ONE DAY DATA*/
 NCIF_AssetClassAlt_Key<>1 

 Update AuditUPGDEGCheck set Endtime=getdate() where StepID=2

select 2

 Insert into AuditUPGDEGCheck(StepID,StepName,strartTime)
 select '3','Index creation onto the both tables',getdate()

Create nonclustered index idx_npa_integrationdetails_archive 
on #npa_integrationdetails_archive(CustomerAcid)

Create nonclustered index idx_npa_integrationdetails_Curnt 
on #npa_integrationdetails_Curnt(CustomerAcid)

Update AuditUPGDEGCheck set Endtime=getdate() where StepID=3

--------------------------------------- Upgradation data working below this query --------------------------------------------


 Insert into AuditUPGDEGCheck(StepID,StepName,strartTime)
 select '4','Insertion into HistoryUpgradationData',getdate()

 Print 'insert start'

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
,(CASE WHEN ISNULL(NPD.FLGMOC,'')='Y' THEN (SELECT DATE FROM SysDataMatrix WHERE TimeKey=@Timekey) ELSE npd.UpgDate END )UpgDate --ADDED BY ZAIN ON 20250327 TO ADD UPGDATE AS MONTH-END DATE IN REPORT
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
 Left Join DimsourceSystem ds 
 on NPD.srcsysalt_key=ds.sourcealt_key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_latest
 on NPD.NCIF_AssetClassAlt_Key=DAC_latest.AssetClassAlt_Key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_prev
 on NPDArc.NCIF_AssetClassAlt_Key=DAC_prev.AssetClassAlt_Key
 where NPD.EffectiveFromTimeKey<=@Timekey and NPD.EffectiveToTimeKey>=@Timekey--- 20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 

/*REMOVED THIS CONDITION BY ZAIN ON 20250325 AS ARCHIVE TABLE CONSIST ONLY ONE DAY DATA*/
--and NPDArc.EffectiveFromTimeKey<=(Select @Timekey-1) and NPDArc.EffectiveToTimeKey>=(Select @Timekey-1)--- 20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
/*REMOVED THIS CONDITION BY ZAIN ON 20250325 AS ARCHIVE TABLE CONSIST ONLY ONE DAY DATA END*/
-- and NPD.NCIF_AssetClassAlt_Key=1 and NPDArc.NCIF_AssetClassAlt_Key<>1 

/*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED*/
AND NPD.NCIF_Id NOT IN (SELECT NCIF_Id FROM #npa_integrationdetails_MonthEnd)
/*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED END*/

Update AuditUPGDEGCheck set Endtime=getdate() where StepID=4

 select 3

 Insert into AuditUPGDEGCheck(StepID,StepName,strartTime)
 select '5','#AccountAdditionalforUpgrade temp table',getdate()

 Drop table if exists #AccountAdditionalforUpgrade
 Select CustomerACID into #AccountAdditionalforUpgrade 
 from #npa_integrationdetails_Curnt where 
 EffectiveFromTimeKey<=@Timekey and EffectiveToTimeKey>=@Timekey--- 20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 and NCIF_Id in (
 Select NCIF from HistoryUpgradationData where AsonDate=@Ext_Date)
 and isnull(CustomerACID,'') not in (Select Account from HistoryUpgradationData where AsonDate=@Ext_Date)
 Update AuditUPGDEGCheck set Endtime=getdate() where StepID=5

 select 4

  Insert into AuditUPGDEGCheck(StepID,StepName,strartTime)
 select '6','Insert into HistoryUpgradationData from #AccountAdditionalforUpgrade',getdate()


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
,npd.MaxDPD --Uncommented for insert issue Mayuresh on 20241125
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
 where NPD.EffectiveFromTimeKey<=@Timekey and NPD.EffectiveToTimeKey>=@Timekey--- 20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 --and NPDArc.EffectiveFromTimeKey<=(Select @Timekey-1) and NPDArc.EffectiveToTimeKey>=(Select @Timekey-1)
 --and NPD.NCIF_AssetClassAlt_Key=1 and NPDArc.NCIF_AssetClassAlt_Key<>1  
  and npd.CustomerACID in (select CustomerACID from #AccountAdditionalforUpgrade) /* handeled for accounts left for degrade as on date 20 march 2023 */
 /*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED*/
AND NPD.NCIF_Id NOT IN (SELECT NCIF_Id FROM #npa_integrationdetails_MonthEnd)
/*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED END*/

 Update AuditUPGDEGCheck set Endtime=getdate() where StepID=6

 select 5
 --SELECT * FROM HistoryUpgradationData WHERE AsOnDate=@Ext_Date

     ------------------------------------------- Downgradation data working below this query --------------------------------------------
  Drop Table if exists #npa_integrationdetails_Curnt1
  Select * into #npa_integrationdetails_Curnt1
  from [dbo].[NPA_IntegrationDetails]
  where EffectiveFromTimeKey<= @Timekey and EffectiveToTimeKey>=@Timekey   --- 20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
  and NCIF_AssetClassAlt_Key<>1 
 
   DROP TABLE IF EXISTS #npa_integrationdetails_archive1
 Select * into #npa_integrationdetails_archive1 from [dbo].[NPA_IntegrationDetails_Archive] 
 where  EffectiveFromTimeKey<=(Select @Timekey-1) and EffectiveToTimeKey>=(Select @Timekey-1)--- 20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 and NCIF_AssetClassAlt_Key=1 


Insert into AuditUPGDEGCheck(StepID,StepName,strartTime)
 select '7','Insert into HistoryDownGradeData from prev and currnt tbl',getdate()

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
from #npa_integrationdetails_Curnt1 NPD 
 inner join #npa_integrationdetails_archive1 NPDArc 
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
   where EffectiveFromTimeKey<=@TIMEKEY  and EffectiveToTimeKey>=@TIMEKEY) Res--20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 on NPD.customeracid=Res.refsystemacid
 and res.RN=1
   Left JOIN DimParameter PAR
 ON PAR.EffectiveFromTimeKey<=@TIMEKEY AND PAR.EffectiveToTimeKey>=@TIMEKEY--20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 AND ParameterAlt_Key=RES.RestructureTypeAlt_Key
 and PAR.DimParameterName='TypeofRestructuring'
 where NPD.EffectiveFromTimeKey<=@Timekey and NPD.EffectiveToTimeKey>=@Timekey--20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 and NPDArc.EffectiveFromTimeKey<=(Select @Timekey-1) and NPDArc.EffectiveToTimeKey>=(Select @Timekey-1)--20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 and NPD.NCIF_AssetClassAlt_Key<>1 and NPDArc.NCIF_AssetClassAlt_Key=1 
/*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED*/
AND NPD.NCIF_Id NOT IN (SELECT NCIF_Id FROM #npa_integrationdetails_MonthEnd)
/*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED END*/

 
  Update AuditUPGDEGCheck set Endtime=getdate() where StepID=7

  Insert into AuditUPGDEGCheck(StepID,StepName,strartTime)
 select '8','creation of table #AccountAdditionalforDegrade from curnt',getdate()

 Drop table if exists #AccountAdditionalforDegrade   
 Select CustomerACID into #AccountAdditionalforDegrade
 from #npa_integrationdetails_Curnt1 where 
 --ncif_id='73275311' and 
 NCIF_Id in (
 Select NCIF from HistoryDownGradeData where AsonDate=@Ext_Date)
 and isnull(CustomerACID,'') not in (Select Account from HistoryDownGradeData where AsonDate=@Ext_Date)

 Update AuditUPGDEGCheck set Endtime=getdate() where StepID=8

 Insert into AuditUPGDEGCheck(StepID,StepName,strartTime)
 select '9','Insert into HistoryDownGradeData from #AccountAdditionalforDegrade',getdate()

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
 from #npa_integrationdetails_Curnt1 NPD 
 left join #npa_integrationdetails_archive1 NPDArc 
 on NPD.customeracid=NPDArc.customeracid
 and NPD.srcsysalt_key= NPDArc.srcsysalt_key
 and NPDArc.EffectiveFromTimeKey<=(Select @Timekey-1) and NPDArc.EffectiveToTimeKey>=(Select @Timekey-1)--20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
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
   where EffectiveFromTimeKey<=@TIMEKEY  and EffectiveToTimeKey>=@TIMEKEY) Res
 on NPD.customeracid=Res.refsystemacid
 and res.RN=1
   Left JOIN DimParameter PAR
 ON PAR.EffectiveFromTimeKey<=@TIMEKEY AND PAR.EffectiveToTimeKey>=@TIMEKEY
 AND ParameterAlt_Key=RES.RestructureTypeAlt_Key
 and PAR.DimParameterName='TypeofRestructuring'
 where NPD.EffectiveFromTimeKey<=@Timekey and NPD.EffectiveToTimeKey>=@Timekey
 and npd.CustomerACID in (select CustomerACID from #AccountAdditionalforDegrade) /* handeled for accounts left for degrade as on date 20 march 2023 */
 /*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED*/
AND NPD.NCIF_Id NOT IN (SELECT NCIF_Id FROM #npa_integrationdetails_MonthEnd)
/*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED END*/


 --------------------------------------TO ADD RECORD IN DOWNGRADE TABLE WHERE ACCOUNT NEWLY ADDED AS NPA-----------------------------------MOHIT20241119
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
--,[Yesterday Principal OS]
--,[Yesterday Interest OS]
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
,DAC_prev.AssetClassShortNameEnum [Classification of source system]
,DAC_latest.AssetClassShortNameEnum [Homogenized_Classification]
,NPD.PrincipleOutstanding [Principal OS] 
,NPD.IntOverdue [Interest OS]
--,NPDArc.PrincipleOutstanding [Yesterday Principal OS] 
--,NPDArc.IntOverdue  [Yesterday Interest OS]
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
from #npa_integrationdetails_Curnt1 NPD 
  Left Join DimsourceSystem ds 
 on NPD.srcsysalt_key=ds.sourcealt_key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_latest
 on NPD.NCIF_AssetClassAlt_Key=DAC_latest.AssetClassAlt_Key
 Left join (Select AssetClassAlt_Key,AssetClassShortNameEnum from DimAssetClass) DAC_prev  --- 
 on NPD.AC_AssetClassAlt_Key=DAC_prev.AssetClassAlt_Key
 left join  (Select RefSystemAcId,DateCreated,DateModified,RestructureTypeAlt_Key,RestructureDt,
          ROW_NUMBER() over (partition by RefSystemAcId order by COALESCE(isnull(DateCreated,''),isnull(DateModified,'')) desc)  RN
   from curdat.advacrestructuredetail
   where EffectiveFromTimeKey<=@TIMEKEY  and EffectiveToTimeKey>=@TIMEKEY) Res--20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 on NPD.customeracid=Res.refsystemacid
 and res.RN=1
   Left JOIN DimParameter PAR
 ON PAR.EffectiveFromTimeKey<=@TIMEKEY AND PAR.EffectiveToTimeKey>=@TIMEKEY--20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 AND ParameterAlt_Key=RES.RestructureTypeAlt_Key
 and PAR.DimParameterName='TypeofRestructuring'
 where NPD.EffectiveFromTimeKey<=@Timekey and NPD.EffectiveToTimeKey>=@Timekey--20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 AND NPD.NCIF_Id NOT IN (SELECT NCIF_Id FROM [NPA_IntegrationDetails_Archive] WHERE EffectiveFromTimeKey<=(Select @Timekey-1) and EffectiveToTimeKey>=(Select @Timekey-1))
 /*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED*/
AND NPD.NCIF_Id NOT IN (SELECT NCIF_Id FROM #npa_integrationdetails_MonthEnd)
/*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED END*/

 ----------------------------------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------TO ADD RECORD WHERE CUSTOMERACID IS DIFFERENT BUT NCIF IS SAME ------------------------------------------MOHIT20241119

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
from #npa_integrationdetails_Curnt1 NPD 
 inner join #npa_integrationdetails_archive1 NPDArc 
 --on NPD.customeracid=NPDArc.customeracid  -----MOHIT20241119
  ON NPD.NCIF_Id=NPDArc.NCIF_Id -----MOHIT20241119
 AND NPD.customeracid <> NPDArc.customeracid -----MOHIT20241119
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
   where EffectiveFromTimeKey<=@TIMEKEY  and EffectiveToTimeKey>=@TIMEKEY) Res--20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 on NPD.customeracid=Res.refsystemacid
 and res.RN=1
   Left JOIN DimParameter PAR
 ON PAR.EffectiveFromTimeKey<=@TIMEKEY AND PAR.EffectiveToTimeKey>=@TIMEKEY--20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 AND ParameterAlt_Key=RES.RestructureTypeAlt_Key
 and PAR.DimParameterName='TypeofRestructuring'
 where NPD.EffectiveFromTimeKey<=@Timekey and NPD.EffectiveToTimeKey>=@Timekey--20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 and NPDArc.EffectiveFromTimeKey<=(Select @Timekey-1) and NPDArc.EffectiveToTimeKey>=(Select @Timekey-1)--20230817 added'<'and '>' sign in EffectiveFromTimeKey & EffectiveToTimeKey 
 and NPD.NCIF_AssetClassAlt_Key<>1 and NPDArc.NCIF_AssetClassAlt_Key=1 
 And NPD.NCIF_Id not in (Select NCIF from HistoryDownGradeData where AsonDate = @Ext_Date)
 /*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED*/
AND NPD.NCIF_Id NOT IN (SELECT NCIF_Id FROM #npa_integrationdetails_MonthEnd)
/*ADDED BY ZAIN ON 20250312 FOR UPGRADE DOWNGRADE REPORT EXCLUSION OF CUSTOMERS WHOSE MOC IS PASSED END*/


 --------------------------------------------------------------------------------------------------------------------------------------------------------------

 Update AuditUPGDEGCheck set Endtime=getdate() where StepID=9

  Insert into AuditUPGDEGCheck(StepID,StepName,strartTime)
  select '10','Updating the culprit system and sourcename part2',getdate()

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

  Update AuditUPGDEGCheck set Endtime=getdate() where StepID=10
  
   Insert into AuditUPGDEGCheck(StepID,StepName,strartTime)
  select '11','Updating the culprit system and sourcename part2',getdate()

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
	 Update AuditUPGDEGCheck set Endtime=getdate() where StepID=11
  
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
HistoryDownGradeData(nolock) 
where ([Principal OS] + [Interest OS]) <> 0 --Added by Mayuresh on 20241113 for excluding records with 0 outstanding
and AsonDate=@Ext_Date
--order by 3
)
select * from cte --group by Account having count(1)>1
GO