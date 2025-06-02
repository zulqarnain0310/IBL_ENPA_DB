SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GetCust360ViewExcelTempHeader_13082021]
--ALTER PROCEDURE [dbo].[GetCust360ViewExcelTempHeader]
@TimeKey int,
@UserID varchar(50)
AS
BEGIN
       SELECT
       [ColumnName]
       --'ExcelTempHeader' as TableName	   
       FROM [dbo].[ExcelTempMaster] WHERE [UploadType]='Cust360ViewUpload'

	   SELECT top 1
       [SheetName],
       'ExcelSheetName' as TableName	   
       FROM [dbo].ExcelTempMaster WHERE [UploadType]='Cust360ViewUpload'

	

	  
END 

GO