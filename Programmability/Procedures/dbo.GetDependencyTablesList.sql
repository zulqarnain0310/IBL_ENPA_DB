SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
/*  CREATED BY DF627 ON 24-05-24 FOR DISPLAYING DEPENDENCY OF THE TABLES USED IN THE SP */

CREATE PROC [dbo].[GetDependencyTablesList]
AS
BEGIN
   
    -- Select all records from TableDependencyDtls table
    SELECT * FROM DBO.TableDependencyDtls 
	WHERE CAST(ProcessDate AS DATE)=DATEADD(DD,-1,CAST(GETDATE() AS date))
    ORDER BY [SpName];

END;
GO