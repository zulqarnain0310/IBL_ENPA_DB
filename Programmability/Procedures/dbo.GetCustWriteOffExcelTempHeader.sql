SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GetCustWriteOffExcelTempHeader]
--ALTER PROCEDURE [dbo].[GetCust360ViewExcelTempHeader]
@TimeKey int,
@UserID varchar(50)
AS
BEGIN
       SELECT
       [ColumnName]
       --'ExcelTempHeader' as TableName	   
       FROM [dbo].[ExcelTempMaster] WHERE [UploadType]='Writeoff_Incremental_Upload'

	   SELECT top 1
       [SheetName],
       'ExcelSheetName' as TableName	   
       FROM [dbo].ExcelTempMaster WHERE [UploadType]='Writeoff_Incremental_Upload'

	

	  
END 

GO