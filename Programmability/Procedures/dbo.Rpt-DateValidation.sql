SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE  proc [dbo].[Rpt-DateValidation]
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

SELECT @From1 FromDate,@to1 ToDate
GO