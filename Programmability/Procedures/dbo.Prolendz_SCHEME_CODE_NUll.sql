﻿SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE Proc [dbo].[Prolendz_SCHEME_CODE_NUll]
as
Begin
insert into ETL_Validation_Details(
SYSTEM,ENTERPRISE_CIF,CLIENT_ID,CUSTOMER_NAME,ACCOUNT_NUMBER,LIMIT,TOTAL_OUTSTANDING,PRINCIPAL_OUTSTANDING
,DPD,CLASSIFICATION,NPA_DATE,SETTLEMENT_STATUS,WRITE_OFF_FLAG,GROUP_ID,GROUP_CODE,GROUP_DESC,SEGMENT
,SUB_SEGMENT,PAN,AADHAR_UID,SCHEME_TYPE,SCHEME_CODE,SCHEME_DESCRIPTION,DRAWING_POWER,DPD_OVERDUE_LOANS
,DPD_INTEREST_NOT_SERVICED,DPD_OVERDRAWN,DPD_RENEWALS,OVERDUE_AMOUNT)
select System
,Cross_Dedupe_Match_Id,Customer_Code,Customer_Name,Deal_No,Sanc_Limit,Outstanding,Principle_Outstanding
,DPD,NPA_Status,NPA_Date,Settlement_Status,Write_Off_Flag,Group_Id,Group_Code,Group_Desc,Segment,Sub_Segment
,PAN,Aadhaar_UID,Scheme_Type,Scheme_Code,Scheme_Code_Desc,Drawing_Power,DPD_Overdue_Loans,DPD_Interest_Not_Serviced
,DPD_OverDrawn,DPD_Renewals,Overdue_Amount from Induslnd_Stg.dbo.Prolendz_Stg where Scheme_Code is null
END
GO