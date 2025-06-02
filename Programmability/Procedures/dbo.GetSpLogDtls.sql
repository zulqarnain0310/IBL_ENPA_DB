SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/* CREATED BY DF627 ON 18-07-24 FOR GETTING SP LOG DETAILS*/

CREATE PROC [dbo].[GetSpLogDtls]
AS

BEGIN

   SELECT
   ObjectID
  ,SchemaID
  ,SPName
  ,SpDateModified_V1
  ,SpDateModified_V2
  ,ScriptStatus
  ,ProcessDate 
  FROM DBO.SpLogDtls
  order by SPName,ProcessDate 

END
GO