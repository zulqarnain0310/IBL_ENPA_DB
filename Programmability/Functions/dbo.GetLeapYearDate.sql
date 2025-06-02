SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


create function [dbo].[GetLeapYearDate] (@Date date, @Year int)
returns date
as 
begin
SET @DATE=CASE WHEN @DATE IN('1900-01-01','2099-01-01')   THEN NULL ELSE @DATE END

return(
select DATEADD(DD,CASE WHEN DATEPART(dd,@Date)=29 AND DATEPART(MM,@Date)=2 THEN 1 ELSE 0 END ,DATEADD(YEAR, @Year, @Date))
)
end
GO