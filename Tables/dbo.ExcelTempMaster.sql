CREATE TABLE [dbo].[ExcelTempMaster] (
  [EntityKey] [int] IDENTITY,
  [MenuId] [int] NULL,
  [UploadType] [varchar](50) NULL,
  [ColumnName] [varchar](50) NULL,
  [SheetName] [varchar](50) NULL,
  [SRNO] [int] NULL
)
ON [PRIMARY]
GO