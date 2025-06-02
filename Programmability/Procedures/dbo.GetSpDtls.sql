SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/* CREATED BY DF627 ON 18-07-24 FOR GETTING DATE WISE SP SCRIPTS */

CREATE PROC [dbo].[GetSpDtls]
AS
BEGIN
    -- Select data from SpDtls where the ProcessDate is today's date
    SELECT * 
    FROM [dbo].[SpDtls] 
    WHERE CAST(ProcessDate AS DATE) = DATEADD(DD,-1,CAST(GETDATE() AS DATE))
    ORDER BY Spname, ProcessDate DESC;
END
GO