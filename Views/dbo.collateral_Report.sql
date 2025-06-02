SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

 CREATE  VIEW [dbo].[collateral_Report]
 AS
 select distinct  e.SourceName,c.NCIF_AssetClassAlt_Key as final_assset_class,c.PrincipleOutstanding,c.Balance, a.CollateralID,a.CollateralType,c.NCIF_Id,c.CustomerId,c.CustomerACID,b.Prev_ValuationDate,b.Prev_Value,b.ValuationDate,
b.ValuationExpiryDate,ValuationSourceAlt_Key ,c.Provsecured,c.ProvUnsecured,c.TotalProvision,c.ProvisionAlt_Key,d.ProvisionName,d.ProvisionSecured * 100 as provision_secured_percentage  
 ,d.ProvisionUnSecured * 100 as unsecured_provison_percentage,b.CurrentValue,c.SecurityValue
from CURDAT.AdvSecurityDetail a , CURDAT.AdvSecurityValueDetail b , NPA_IntegrationDetails c ,DimProvision d ,DimSourceSystem e
where a.SecurityEntityID=b.SecurityEntityID and
 c.ProvisionAlt_Key=d.ProvisionAlt_key
and c.NCIF_Id=a.RefCustomer_CIF
and c.CustomerId=a.RefCustomerid
and c.CustomerACID=a.RefSystemAcId
and c.SrcSysAlt_Key=e.SourceAlt_Key
and c.NCIF_AssetClassAlt_Key !=1
GO