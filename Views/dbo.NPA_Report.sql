SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE VIEW [dbo].[NPA_Report]
AS
Select NCIF_Id,c.SourceName,CustomerId,CustomerName,PrincipleOutstanding, balance,overdue,PAN,NCIF_AssetClassAlt_Key ,NCIF_NPA_Date,AC_NPA_Date ,AC_AssetClassAlt_Key ,CustomerACID,DPD_Overdue_Loans,DPD_Interest_Not_Serviced,DPD_Overdrawn,DPD_Renewals,MaxDPD
 ,ProductCode,ProductDesc,Segment,SubSegment,SecurityValue,SecuredAmt,UnSecuredAmt,TotalProvision,b.ProvisionName,b.ProvisionSecured * 100 as provision_secured_percentage  ,IntOverdue,IntAccrued,FacilityType
 ,b.ProvisionUnSecured * 100 as unsecured_provison_percentage,UNSERVED_INTEREST,SecuredFlag,IsFunded
 from NPA_IntegrationDetails a, DimProvision b , DimSourceSystem c,DimAssetClass d where
 ISNULL(a.ProvisionAlt_Key,1)=ISNULL(b.ProvisionAlt_key,1)
 and a.SrcSysAlt_Key=c.SourceAlt_Key
 --and a.AC_AssetClassAlt_Key=d.AssetClassAlt_Key
 and a.NCIF_AssetClassAlt_Key=d.AssetClassAlt_Key
 and  a.EffectiveFromTimeKey=26084 and NCIF_AssetClassAlt_Key !=1 ;
GO