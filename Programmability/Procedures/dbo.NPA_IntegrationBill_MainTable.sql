SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create proc [dbo].[NPA_IntegrationBill_MainTable]

AS

begin


INSERT INTO NPA_IntegrationBillDetails
 (NCIF_Id
,NCIF_Changed
,SrcSysAlt_Key
,NCIF_EntityID
,CustomerId
,CustomerName
,PAN
,AddharNo
,BillNo
,GroupId
,GroupCode
,GroupDesc
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
,DPD
,MaxDPD
,WriteOffFlag
,Segment
,SubSegment
,ProductCode
,ProductDesc
,ProductType
,Settlement_Status
,AuthorisationStatus
,EffectiveFromTimeKey
,EffectiveToTimeKey
,CreatedBy
,DateCreated
,ModifiedBy
,DateModified
,ApprovedBy
,DateApproved)
SELECT 
NCIF_Id
,NCIF_Changed
,SrcSysAlt_Key
,NCIF_EntityID
,CustomerId
,CustomerName
,PAN
,AddharNo
,BillNo
,GroupId
,GroupCode
,GroupDesc
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
,DPD
,MaxDPD
,WriteOffFlag
,Segment
,SubSegment
,ProductCode
,ProductDesc
,ProductType
,Settlement_Status
,AuthorisationStatus
,EffectiveFromTimeKey
,EffectiveToTimeKey
,CreatedBy
,DateCreated
,ModifiedBy
,DateModified
,ApprovedBy
,DateApproved FROM NPA_IntegrationBillDetails_Temp

end
GO