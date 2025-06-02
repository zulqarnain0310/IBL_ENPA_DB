SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE Proc [dbo].[AuditTrail_bckup_06122022]
    @FromDate  AS VARCHAR(20),
      @ToDate  AS VARCHAR(20),
      @Cost AS FLOAT=1
AS
Begin
 Declare @Timekey int=(Select Timekey from SysDataMatrix where CurrentStatus='C')
 Declare @MonthEndDate int=(Select timekey from SysDataMatrix where date='2022-10-31')
Select
npamod.IsUpload
,npamod.UploadId
,AccProvPer [Accelerated Provision Percentage] 
,MocReasonName [MOC reason]
,Maker_Name.UserName [Name of Maker]
,Maker_Name.DesignationName [Designation of Maker]
,First_Approver.UserName [Name of First Level Approver]
,First_Approver.DesignationName [Designation of First Level Approver]
,EUH.DateApprovedFirstLevel [Date of First Level Approval]	
,Second_Approver.UserName [Name of Second Level Approver]
,Second_Approver.DesignationName [Designation of Second Level Approver]
,EUH.DateApproved [Date of Second Level Approval]	
,npa.EntityKey
,npa.NCIF_Id
,npa.NCIF_Changed
,npa.SrcSysAlt_Key
,npa.NCIF_EntityID
,npa.CustomerId
,npa.CustomerName
,npa.PAN
,npa.NCIF_AssetClassAlt_Key
,npa.NCIF_NPA_Date
,npa.AccountEntityID
,npa.CustomerACID
,npa.SanctionedLimit
,npa.DrawingPower
,npa.PrincipleOutstanding
,npa.Balance
,npa.Overdue
,npa.DPD_Overdue_Loans
,npa.DPD_Interest_Not_Serviced
,npa.DPD_Overdrawn
,npa.DPD_Renewals
,npa.MaxDPD
,npa.WriteOffFlag
,npa.Segment
,npa.SubSegment
,npa.ProductCode
,npa.ProductDesc
,npa.Settlement_Status
,npa.AC_AssetClassAlt_Key
,npa.AC_NPA_Date
,npa.AstClsChngByUser
,npa.AstClsChngDate
,npa.AstClsChngRemark
,npa.MOC_Status
,npa.MOC_Date
,npa.MOC_ReasonAlt_Key
,npa.MOC_AssetClassAlt_Key
,npa.MOC_NPA_Date
,npa.AuthorisationStatus
,npa.EffectiveFromTimeKey
,npa.EffectiveToTimeKey
,npa.CreatedBy
,npa.DateCreated
,npa.ModifiedBy
,npa.DateModified
,npa.ApprovedBy
,npa.DateApproved
,npa.MOC_Remark
,npa.D2Ktimestamp
,npa.ProductType
,npa.ActualOutStanding
,npa.MaxDPD_Type
,npa.ProductAlt_Key
,npa.AstClsAppRemark
,npa.MocAppRemark
,npa.PNPA_Status
,npa.PNPA_ReasonAlt_Key
,npa.PNPA_Date
,npa.ActualPrincipleOutstanding
,npa.UNSERVED_INTEREST
,npa.CUSTOMER_IDENTIFIER
,npa.ACCOUNT_LEVEL_CODE
,npa.NF_PNPA_Date
,npa.Remark
,npa.WriteOffDate
,npa.DbtDT
,npa.ErosionDT
,npa.FlgErosion
,npa.IntOverdue
,npa.IntAccrued
,npa.OtherOverdue
,npa.PrincOverdue
,npa.IsRestructured
,npa.IsOTS
,npa.IsTWO
,npa.IsARC_Sale
,npa.IsFraud
,npa.IsWiful
,npa.IsNonCooperative
,npa.IsSuitFiled
,npa.IsRFA
,npa.IsFITL
,npa.IsCentral_GovGty
,npa.Is_Oth_GovGty
,npa.BranchCode
,npa.FacilityType
,npa.SancDate
,npa.Region
,npa.State
,npa.Zone
,npa.NPA_TagDate
,npa.PS_NPS
,npa.Retail_Corpo
,npa.Area
,npa.FraudAmt
,npa.FraudDate
,npa.GovtGtyAmt
,npa.GtyRepudiated
,npa.RepudiationDate
,npa.OTS_Amt
,npa.WriteOffAmount
,npa.ARC_SaleDate
,npa.ARC_SaleAmt
,npa.PrincOverdueSinceDt
,npa.IntNotServicedDt
,npa.ContiExcessDt
,npa.ReviewDueDt
,npa.OtherOverdueSinceDt
,npa.IntOverdueSinceDt
,npa.SecuredFlag
,npa.StkStmtDate
,npa.SecurityValue
,npa.DFVAmt
,npa.CoverGovGur
,npa.CreditsinceDt
,npa.DegReason
,npa.NetBalance
,npa.ApprRV
,npa.SecuredAmt
,npa.UnSecuredAmt
,npa.ProvDFV
,npa.Provsecured
,npa.ProvUnsecured
,npa.ProvCoverGovGur
,npa.AddlProvision
,npa.TotalProvision
,npa.BankProvsecured
,npa.BankProvUnsecured
,npa.BankTotalProvision
,npa.RBIProvsecured
,npa.RBIProvUnsecured
,npa.RBITotalProvision
,npa.SMA_Dt
,npa.UpgDate
,npa.ProvisionAlt_Key
,npa.PNPA_Reason
,npa.SMA_Class
,npa.SMA_Reason
,npa.CommonMocTypeAlt_Key
,npa.FlgDeg
,npa.FlgSMA
,npa.FlgPNPA
,npa.FlgUpg
,npa.FlgFITL
,npa.FlgAbinitio
,npa.NPA_Days
,npa.AppGovGur
,npa.UsedRV
,npa.ComputedClaim
,npa.NPA_Reason
,npa.PnpaAssetClassAlt_key
,npa.SecApp
,npa.ProvPerSecured
,npa.ProvPerUnSecured
,npa.AddlProvisionPer
,npa.FlgINFRA
,npa.MOCTYPE
,npa.DPD_IntService
,npa.DPD_StockStmt
,npa.DPD_FinMaxType
,npa.DPD_PrincOverdue
,npa.DPD_OtherOverdueSince
,npa.IsPUI
,npa.AC_Closed_Date
,npa.SECTOR
,npa.LossDT
,npa.IsFunded
,npa.UploadFlag
,npa.FlgProcessing
,npa.DCCO_Date
--,npa.ACMOC_ReasonAlt_Key
--,npa.FlgMOC
--,PROJ_COMPLETION_DATE
--,OPEN_DATE
--select distinct  npamod.UploadId UploadId_mod ,EUH.UniqueUploadID UniqueUploadID_upld
from NPA_IntegrationDetails_Archive_31OCT2022 (nolock) npa INNER JOIN 
NPA_IntegrationDetails_Mod(nolock) npamod on 
npa.CustomerACID = npamod.CustomerACID
and npamod.EffectiveFromTimeKey=@MonthEndDate
LEFT JOIN [CURDAT].[AcceleratedProv](nolock) AccProv
on npa.CustomerACID=AccProv.CustomerACID
and AccProv.EffectiveFromTimeKey<=@MonthEndDate and AccProv.EffectiveToTimeKey>=@MonthEndDate
LEFT JOIN [dbo].[DimMocReason](nolock) DOR
on npamod.MOC_ReasonAlt_Key=DOR.MocReasonAlt_Key
and DOR.EffectiveFromTimeKey<=@MonthEndDate  and DOR.EffectiveToTimeKey>=@MonthEndDate
LEFT JOIN IBL_ENPA_DB_LOCAL_DEV.dbo.ExcelUploadHistory(nolock) EUH
ON npamod.UploadId=EUH.UniqueUploadID
AND EUH.EffectiveFromTimeKey<=@MonthEndDate  and EUH.EffectiveToTimeKey>=@MonthEndDate
LEFT JOIN   (SELECT DISTINCT UserLoginID,UserName,DesignationName FROM DimUserInfo DUI inner join
             DimDesignation DDG on DUI.DesignationAlt_Key=DDG.DesignationAlt_Key
             WHERE DUI.EffectiveFromTimeKey<=@MonthEndDate AND DUI.EffectiveToTimeKey>=@MonthEndDate
			 and DDG.EffectiveFromTimeKey<=@MonthEndDate AND DDG.EffectiveToTimeKey>=@MonthEndDate) Maker_Name
on EUH.UploadedBy=Maker_Name.UserLoginID
LEFT JOIN (SELECT DISTINCT UserLoginID,UserName,DesignationName FROM DimUserInfo DUI inner join
             DimDesignation DDG on DUI.DesignationAlt_Key=DDG.DesignationAlt_Key
             WHERE DUI.EffectiveFromTimeKey<=@MonthEndDate AND DUI.EffectiveToTimeKey>=@MonthEndDate
			 and DDG.EffectiveFromTimeKey<=@MonthEndDate AND DDG.EffectiveToTimeKey>=@MonthEndDate)  First_Approver
on EUH.ApprovedByFirstLevel=First_Approver.UserLoginID
LEFT JOIN (SELECT DISTINCT UserLoginID,UserName,DesignationName FROM DimUserInfo DUI inner join
             DimDesignation DDG on DUI.DesignationAlt_Key=DDG.DesignationAlt_Key
             WHERE DUI.EffectiveFromTimeKey<=@MonthEndDate AND DUI.EffectiveToTimeKey>=@MonthEndDate
			 and DDG.EffectiveFromTimeKey<=@MonthEndDate AND DDG.EffectiveToTimeKey>=@MonthEndDate)  Second_Approver
on EUH.ApprovedBy=Second_Approver.UserLoginID
Where npa.EffectiveFromTimeKey=@MonthEndDate and npa.EffectiveToTimeKey=@MonthEndDate
and CAST (npa.MOC_Date as date) BETWEEN @FromDate AND  @ToDate
end
GO