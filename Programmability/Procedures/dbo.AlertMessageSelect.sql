SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create PROCEDURE [dbo].[AlertMessageSelect]
    @AlertMessageAlt_key int,
    @Timekey int  
AS
   

	BEGIN
	Select 

	AlertMessageAlt_key
	,MessageFor
	,Location
	,Convert(varchar(10),[FromDate],103) AS [FromDate]
      ,Convert(varchar(10),[ToDate],103)  AS [ToDate]
	,Active
	,MessageDesc
	,LocationListAlt_key

	from DimAlertMessage where (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey)
	AND AlertMessageAlt_key=@AlertMessageAlt_key

	END
GO