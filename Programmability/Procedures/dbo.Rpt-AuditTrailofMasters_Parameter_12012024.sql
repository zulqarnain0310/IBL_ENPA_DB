SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



/*
Created By		:- Baijayanti
Created Date	:- 12/07/2022
Report Name		:- Audit Trail of Masters (Parameter)
*/

Create  proc [dbo].[Rpt-AuditTrailofMasters_Parameter_12012024]
@StartDate AS VARCHAR(20),
@EndDate AS VARCHAR(20)

AS

--DECLARE 
--@StartDate AS VARCHAR(20)='01/07/2022',
--@EndDate AS VARCHAR(20)=''

---------------------------------------------------

IF @StartDate=''
BEGIN
	SET @StartDate=NULL
END
IF @EndDate=''
BEGIN
	SET @EndDate=NULL
END

DECLARE	@From1		DATE=(SELECT Rdate FROM dbo.DateConvert(@StartDate))
DECLARE @to1		DATE=(SELECT Rdate FROM dbo.DateConvert(@EndDate))



SELECT
DimParameterName	                                        AS [Main Parameter Name]
,ParameterAlt_Key                                           AS [Parameter Code]	
,ParameterName                                              AS [Parameter Name]	
,ParameterShortName	                                        AS [Parameter Short Name]
,ParameterShortNameEnum	                                    AS [Parameter ShortName Enum]
,AuthorisationStatus                                        AS [Authorisation Status]	
,CreatedBy	                                                AS [Created By]
,CONVERT(VARCHAR(20),DateCreated,103)	                    AS [Date Created]
,ModifiedBy	                                                AS [Modified By]
,CONVERT(VARCHAR(20),DateModified,103)                      AS [Date Modifie]	
,ApprovedBy	                                                AS [Approved By]
,CONVERT(VARCHAR(20),DateApproved,103)                      AS [Date Approved] 
										

FROM  DimParameter_MOD		
WHERE (((ISNULL(CAST(DateCreated AS DATE),'1900-01-01') BETWEEN @From1 AND @to1 AND @From1 IS NOT NULL AND @to1 IS NOT NULL)
       OR (@From1 IS NULL AND @to1 IS NOT NULL AND ISNULL(CAST(DateCreated AS DATE),'1900-01-01')<=@to1)
	   OR (@From1 IS NOT NULL AND @to1 IS  NULL AND ISNULL(CAST(DateCreated AS DATE),'1900-01-01')>=@From1)
	   OR (@From1 IS  NULL AND @to1 IS  NULL))

OR ((ISNULL(CAST(DateModified AS DATE),'1900-01-01') BETWEEN @From1 AND @to1 AND @From1 IS NOT NULL AND @to1 IS NOT NULL)
       OR (@From1 IS NULL AND @to1 IS NOT NULL AND ISNULL(CAST(DateModified AS DATE),'1900-01-01')<=@to1)
	   OR (@From1 IS NOT NULL AND @to1 IS  NULL AND ISNULL(CAST(DateModified AS DATE),'1900-01-01')>=@From1)
	   OR (@From1 IS  NULL AND @to1 IS  NULL))

OR ((ISNULL(CAST(DateApproved AS DATE),'1900-01-01') BETWEEN @From1 AND @to1 AND @From1 IS NOT NULL AND @to1 IS NOT NULL)
       OR (@From1 IS NULL AND @to1 IS NOT NULL AND ISNULL(CAST(DateApproved AS DATE),'1900-01-01')<=@to1)
	   OR (@From1 IS NOT NULL AND @to1 IS  NULL AND ISNULL(CAST(DateApproved AS DATE),'1900-01-01')>=@From1)
	   OR (@From1 IS  NULL AND @to1 IS  NULL)))	 


OPTION(RECOMPILE)



GO