SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE Proc[dbo].[Rpt-Date_12-08-2021]

As

select CAST(Convert(Varchar(20),MonthLastDate,105) AS VARCHAR(25)) as label, Timekey as value from SysDataMatrix
Where CurrentStatus in('C','U')

ORDER BY value DESC



GO