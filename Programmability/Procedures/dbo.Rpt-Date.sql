SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE Proc[dbo].[Rpt-Date]

As

select CAST(Convert(Varchar(20),D.DATE,105) AS VARCHAR(25)) as label, D.Timekey as value 
from SysDayMatrix  D 
INNER JOIN SysDataMatrix SDM                ON SDM.TimeKey=D.TimeKey

Where CurrentStatus in('C','U')

ORDER BY value DESC





GO