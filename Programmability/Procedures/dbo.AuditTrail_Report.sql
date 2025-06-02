SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE Proc [dbo].[AuditTrail_Report]
    @FromDate  AS Date,
    @ToDate  AS Date,
    @Cost AS FLOAT=1
AS
Begin


   Select
 Report_Date
,Iteration_Cnt
,Insert_date
,IsUpload
,UploadId
, [Accelerated Provision Amount] 
, [Accelerated Provision Percentage] 
, [MOC reason]
,[Name of Maker]
, [Designation of Maker]
,[Name of First Level Approver]
, [Designation of First Level Approver]
,[Date of First Level Approval]	
, [Name of Second Level Approver]
, [Designation of Second Level Approver]
, [Date of Second Level Approval]	
,EntityKey1 as EntityKey  -- for UAT purpose only
,NCIF_Id
,NCIF_Changed
,SrcSysAlt_Key
,NCIF_EntityID
,CustomerId
,CustomerName
,PAN
,NCIF_AssetClassAlt_Key
,NCIF_NPA_Date
,AccountEntityID
,CustomerACID
,SanctionedLimit
,DrawingPower
,PrincipleOutstanding
,Balance
,Overdue
,DPD_Overdue_Loans
,DPD_Interest_Not_Serviced
,DPD_Overdrawn
,DPD_Renewals
,MaxDPD
,WriteOffFlag
,Segment
,SubSegment
,ProductCode
,ProductDesc
,Settlement_Status
,AC_AssetClassAlt_Key
,AC_NPA_Date
,AstClsChngByUser
,AstClsChngDate
,AstClsChngRemark
,MOC_Status
,MOC_Date
,MOC_ReasonAlt_Key
,MOC_AssetClassAlt_Key
,MOC_NPA_Date
,AuthorisationStatus
,EffectiveFromTimeKey
,EffectiveToTimeKey
,CreatedBy
,DateCreated
,ModifiedBy
,DateModified
,ApprovedBy
,DateApproved
,MOC_Remark
,D2Ktimestamp
,ProductType
,ActualOutStanding
,MaxDPD_Type
,ProductAlt_Key
,AstClsAppRemark
,MocAppRemark
,PNPA_Status
,PNPA_ReasonAlt_Key
,PNPA_Date
,ActualPrincipleOutstanding
,UNSERVED_INTEREST
,CUSTOMER_IDENTIFIER
,ACCOUNT_LEVEL_CODE
,NF_PNPA_Date
,Remark
,WriteOffDate
,DbtDT
,ErosionDT
,FlgErosion
,IntOverdue
,IntAccrued
,OtherOverdue
,PrincOverdue
,IsRestructured
,IsOTS
,IsTWO
,IsARC_Sale
,IsFraud
,IsWiful
,IsNonCooperative
,IsSuitFiled
,IsRFA
,IsFITL
,IsCentral_GovGty
,Is_Oth_GovGty
,BranchCode
,FacilityType
,SancDate
,Region
,State
,Zone
,NPA_TagDate
,PS_NPS
,Retail_Corpo
,Area
,FraudAmt
,FraudDate
,GovtGtyAmt
,GtyRepudiated
,RepudiationDate
,OTS_Amt
,WriteOffAmount
,ARC_SaleDate
,ARC_SaleAmt
,PrincOverdueSinceDt
,IntNotServicedDt
,ContiExcessDt
,ReviewDueDt
,OtherOverdueSinceDt
,IntOverdueSinceDt
,SecuredFlag
,StkStmtDate
,SecurityValue
,DFVAmt
,CoverGovGur
,CreditsinceDt
,DegReason
,NetBalance
,ApprRV
,SecuredAmt
,UnSecuredAmt
,ProvDFV
,Provsecured
,ProvUnsecured
,ProvCoverGovGur
,AddlProvision
,TotalProvision
,BankProvsecured
,BankProvUnsecured
,BankTotalProvision
,RBIProvsecured
,RBIProvUnsecured
,RBITotalProvision
,SMA_Dt
,UpgDate
,ProvisionAlt_Key
,PNPA_Reason
,SMA_Class
,SMA_Reason
,CommonMocTypeAlt_Key
,FlgDeg
,FlgSMA
,FlgPNPA
,FlgUpg
,FlgFITL
,FlgAbinitio
,NPA_Days
,AppGovGur
,UsedRV
,ComputedClaim
,NPA_Reason
,PnpaAssetClassAlt_key
,SecApp
,ProvPerSecured
,ProvPerUnSecured
,AddlProvisionPer
,FlgINFRA
,MOCTYPE
,DPD_IntService
,DPD_StockStmt
,DPD_FinMaxType
,DPD_PrincOverdue
,DPD_OtherOverdueSince
,IsPUI
,AC_Closed_Date
,SECTOR
,LossDT
,IsFunded
,UploadFlag
,FlgProcessing
,DCCO_Date
,ACMOC_ReasonAlt_Key
,FlgMOC

from AuditTrailTable 
WHERE Iteration_Cnt in (select max(Iteration_Cnt) from AuditTrailTable
where Report_Date between (Case When @FromDate='' Then '2023-04-01' Else @FromDate end) and 
(Case When @ToDate='' Then (SELECT convert(varchar(10),EOMONTH(getdate()),23)) Else @ToDate end)
group  by Report_Date)   --Iteration_Cnt removed by ssk
order by Report_Date,UploadId,NCIF_Id,CustomerId,CustomerACID 


end
GO