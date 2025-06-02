SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



--------/*=========================================
------ AUTHER : Chetan Amborkar
------ CREATE DATE : 08-march-2024
------ MODIFY DATE : 
------ DESCRIPTION :Standard provision categorymaster
 -------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[Rpt-Standard_provision_category_master] 
@StartDate AS VARCHAR(20),
@EndDate AS VARCHAR(20)
AS

--Declare 
--@StartDate AS VARCHAR(20)='01/07/2022',
--@EndDate   AS VARCHAR(20)=''

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



 select
     STD_ASSET_CAT_Key	                    AS [STD ASSET CAT Key]      
    --,STD_ASSET_CATAlt_key                   AS [STD ASSET CATAlt key]
    ,STD_ASSET_CATName	                    AS [STD ASSET CAT Name]
    ,STD_ASSET_CATShortName                 AS[STD ASSET CAT Short Name]
    --,STD_ASSET_CATShortNameEnum             AS [STD ASSET CAT Short Name Enum]
	--,STD_ASSET_CATGroup	                    AS[STD ASSET CAT Group]
	--,STD_ASSET_CATValidCode	                AS[STD ASSET CAT Valid Code]
	,(STD_ASSET_CAT_Prov)                     AS [STD ASSET CAT Prov]
	--,STD_ASSET_CAT_Prov_Unsecured           AS [STD ASSET CAT Prov Unsecured]
	,AuthorisationStatus	                AS [Authorisation Status]
	,CreatedBy                              AS [Created By]	
	,CASE WHEN DateCreated IS NULL THEN NULL
	 ELSE (FORMAT(CAST(DateCreated AS DATE),'dd-MM-yyyy hh:mm:ss')) end  AS  [Date Created]
	,ModifyBy	                            AS [Modified By]
	--,CASE WHEN DateModified IS NULL THEN NULL
	,CASE WHEN DateModified IS NULL or DateModified='null' THEN NULL
	 ELSE (FORMAT(CAST(DateModified AS DATE),'dd-MM-yyyy hh:mm:ss')) END AS  [Date Modified]
	,ApprovedBy								 AS [Approved By]
	--,CASE WHEN DateApproved IS NULL THEN NULL
	,CASE WHEN DateApproved IS NULL or DateApproved='null' THEN NULL -----Changed due to conversion failure 
	ELSE (FORMAT(CAST(DateApproved AS DATE),'dd-MM-yyyy hh:mm:ss')) END  AS  [Date Approved]


from  DIM_STD_ASSET_CAT A
where 
--A.EffectiveFromTimeKey<=@TimeKey and A.EffectiveToTimeKey>=@TimeKey

(((ISNULL(CAST(DateCreated AS DATE),'1900-01-01') BETWEEN @From1 AND @to1 AND @From1 IS NOT NULL AND @to1 IS NOT NULL)
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



--OPTION(RECOMPILE)



GO