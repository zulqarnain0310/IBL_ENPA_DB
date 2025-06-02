SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE procedure [dbo].[GetDistrictData] 

@StateAlt_Key int = '',
--@BranchStateAlt_Key int = '',
@BranchDistrictAlt_Key int = '',

@TalukaAlt_Key int = '',
@TimeKey int =''
as

if(@StateAlt_Key <> '')
BEGIN
select distinct DistrictAlt_Key as Code,PincodeDistrict as Description -- DistrictAlt_Key,PincodeDistrict

  from DimPincode where StateAlt_Key=@StateAlt_Key
  END

  if(@BranchDistrictAlt_Key <> '')
BEGIN
select distinct Pincode as Code, Pincode as Description--Pritika-10072020
--select distinct
-- Pincode as Code,
--  cast(Pincode as varchar(20) )  + '-' + PincodeOfficeName as Description,
 --Pincode_Key,Pincode 

  from DimPincode where DistrictAlt_Key=@BranchDistrictAlt_Key
    END



--  if(@TalukaAlt_Key <> '')
--BEGIN
--  select distinct Pincode_Key,Pincode_Key, 
--  Pincode_Key as Code,Pincode_Key as Description

--  from DimPincode where TalukaAlt_Key=@TalukaAlt_Key

--      END
GO