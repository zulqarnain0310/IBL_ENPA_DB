SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GetExcelTempHeader]
@TimeKey int,
@UserID varchar(50)
AS
BEGIN
       SELECT
       [ColumnName]
       --'ExcelTempHeader' as TableName	   
       FROM [IndusInd_New].[dbo].[ExcelTempMaster] WHERE [UploadType]='MOCUpload'

	   SELECT top 1
       [SheetName],
       'ExcelSheetName' as TableName	   
       FROM [IndusInd_New].[dbo].[ExcelTempMaster] WHERE [UploadType]='MOCUpload'

	

	  
END 
GO