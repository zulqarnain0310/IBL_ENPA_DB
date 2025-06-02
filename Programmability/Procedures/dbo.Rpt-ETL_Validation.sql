SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
--USE [IndusInd_New]
--GO
--/****** Object:  StoredProcedure [dbo].[Rpt-ETL_Validation]    Script Date: 4/21/2018 6:10:54 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
----USE [IndusInd_New]
----GO
----/****** Object:  StoredProcedure [dbo].[Rpt-ETL_Validation]    Script Date: 3/29/2018 12:23:01 PM ******/
----SET ANSI_NULLS ON
----GO
----SET QUOTED_IDENTIFIER ON
----GO


create PROC [dbo].[Rpt-ETL_Validation]
@Selection as int,
@NPA AS INT,
@Source int=0
AS


--Declare
--@Selection as int=0,
--@NPA INT=4,
--@Source int=10

-------------------------------- CLASSIFICATION CODE IS NULL------------------------------------------------
SELECT 
SYSTEM,
ENTERPRISE_CIF,
CLIENT_ID,
CUSTOMER_NAME,
ACCOUNT_NUMBER,
CLASSIFICATION,
NPA_DATE,
ISNULL(limit,0)limit,
ISNULL(TOTAL_OUTSTANDING,0)TOTAL,
DPD,
DPD_INTEREST_NOT_SERVICED,
DPD_OVERDRAWN,
DPD_OVERDUE_LOANS,
DPD_RENEWALS,
0
FROM 
InduslndStg.DBO.Finacle_Stg
WHERE ( @Selection=0 AND ISNULL(CLASSIFICATION,'')='' and SCHEME_TYPE not in ('TDA'))  AND @NPA=0 and @Source=10

UNION ALL

SELECT 
SYSTEM,
Cross_Dedupe_Match_Id,
Customer_Code,
CUSTOMER_NAME,
Deal_No,
NPA_Status,
NPA_DATE,
ISNULL(Sanc_Limit,0)limit,
ISNULL(Outstanding,0)TOTAL,
DPD,
DPD_INTEREST_NOT_SERVICED,
DPD_OVERDRAWN,
DPD_OVERDUE_LOANS,
DPD_RENEWALS,
0
FROM 
InduslndStg.DBO.Prolendz_Stg
WHERE ( @Selection=0 AND ISNULL(NPA_Status,'')='')  AND @NPA=0 and @Source=60

--------------------------------AC IS NPA BUT NPA DATE IS NULL----------------------------------
UNION ALL

SELECT 
SYSTEM,
ENTERPRISE_CIF,
CLIENT_ID,
CUSTOMER_NAME,
ACCOUNT_NUMBER,
CLASSIFICATION,
NPA_DATE,
ISNULL(limit,0)limit,
ISNULL(TOTAL_OUTSTANDING,0)TOTAL,
DPD,
DPD_INTEREST_NOT_SERVICED,
DPD_OVERDRAWN,
DPD_OVERDUE_LOANS,
DPD_RENEWALS,
0
FROM 
InduslndStg.DBO.Finacle_Stg
WHERE ( @Selection=1 AND ISNULL(CLASSIFICATION,'') IN ('002','003','004','005','006') 
      AND ISNULL(NPA_DATE,'')='' and SCHEME_TYPE not in ('TDA')) AND @NPA=0 AND @Source=10

UNION ALL


SELECT 
SYSTEM,
Cross_Dedupe_Match_Id,
Customer_Code,
CUSTOMER_NAME,
Deal_No,
NPA_Status,
NPA_DATE,
ISNULL(Sanc_Limit,0)limit,
ISNULL(Outstanding,0)TOTAL,
DPD,
DPD_INTEREST_NOT_SERVICED,
DPD_OVERDRAWN,
DPD_OVERDUE_LOANS,
DPD_RENEWALS,
0
FROM 
InduslndStg.DBO.Prolendz_Stg
WHERE ( @Selection=1 AND ISNULL(NPA_Status,'') IN ('DF-1','DF-2','DF-3','SS') AND ISNULL(NPA_DATE,'')='') AND @NPA=0 and @Source=60


--------------------------------ASSET CLASS IN( 1,2,3,4,5) But Write Off Column Flag is 'Y'---------------------------

UNION ALL

SELECT 
SYSTEM,
ENTERPRISE_CIF,
CLIENT_ID,
CUSTOMER_NAME,
ACCOUNT_NUMBER,
CLASSIFICATION,
NPA_DATE,
ISNULL(limit,0)limit,
ISNULL(TOTAL_OUTSTANDING,0)TOTAL,
DPD,
DPD_INTEREST_NOT_SERVICED,
DPD_OVERDRAWN,
DPD_OVERDUE_LOANS,
DPD_RENEWALS,
0
FROM 
InduslndStg.DBO.Finacle_Stg
WHERE ( @Selection=2 AND ISNULL(CLASSIFICATION,'') IN ('001','002','003','004','005','006') AND WRITE_OFF_FLAG='Y' and SCHEME_TYPE not in ('TDA') ) AND @NPA=0 and @Source=10


UNION ALL

SELECT 
SYSTEM,
Cross_Dedupe_Match_Id,
Customer_Code,
CUSTOMER_NAME,
Deal_No,
NPA_Status,
NPA_DATE,
ISNULL(Sanc_Limit,0)limit,
ISNULL(Outstanding,0)TOTAL,
DPD,
DPD_INTEREST_NOT_SERVICED,
DPD_OVERDRAWN,
DPD_OVERDUE_LOANS,
DPD_RENEWALS,
0
FROM 
InduslndStg.DBO.Prolendz_Stg
WHERE ( @Selection=2 AND ISNULL(NPA_Status,'') IN ('DF-1','DF-2','DF-3','S','SS') AND WRITE_OFF_FLAG='Y' ) AND @NPA=0 and @Source=60

-----------------------------------ASSET CLASS IN( 1,2,3,4,5) But  Scheme Code 'CX999'  ---------------------------

UNION ALL

SELECT 
SYSTEM,
ENTERPRISE_CIF,
CLIENT_ID,
CUSTOMER_NAME,
ACCOUNT_NUMBER,
CLASSIFICATION,
NPA_DATE,
ISNULL(limit,0)limit,
ISNULL(TOTAL_OUTSTANDING,0)TOTAL,
DPD,
DPD_INTEREST_NOT_SERVICED,
DPD_OVERDRAWN,
DPD_OVERDUE_LOANS,
DPD_RENEWALS,
0
FROM 
InduslndStg.DBO.Finacle_Stg
WHERE ( @Selection=3 AND ISNULL(CLASSIFICATION,'') IN ('001','002','003','004','005') AND SCHEME_CODE='CX999') AND @NPA=0 and  @Source=10

UNION ALL

SELECT 
SYSTEM,
Cross_Dedupe_Match_Id,
Customer_Code,
CUSTOMER_NAME,
Deal_No,
NPA_Status,
NPA_DATE,
ISNULL(Sanc_Limit,0)limit,
ISNULL(Outstanding,0)TOTAL,
DPD,
DPD_INTEREST_NOT_SERVICED,
DPD_OVERDRAWN,
DPD_OVERDUE_LOANS,
DPD_RENEWALS,
0
FROM 
InduslndStg.DBO.Prolendz_Stg
WHERE ( @Selection=3 AND ISNULL(NPA_Status,'') IN  ('DF-1','DF-2','DF-3','S','SS') AND SCHEME_CODE='CX999' ) AND @NPA=0 and @Source=60





----------------------------------- Duplicate Records ---------------------------

UNION ALL

SELECT 
Sourcename,
'',
'',
'',
AccountNumber,
'',
'',
'',
'',
'',
'',
'',
'',
'',
Row_num

FROM 
InduslndStg.DBO.Duplicate_Records

WHERE ( @Selection=4 ) AND @NPA=0 and @Source in(10,20,30,40,50,60,70)
GO