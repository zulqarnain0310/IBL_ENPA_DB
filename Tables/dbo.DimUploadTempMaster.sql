CREATE TABLE [dbo].[DimUploadTempMaster] (
  [EntityKey] [int] IDENTITY,
  [MenuId] [int] NULL,
  [UploadType] [varchar](50) NULL,
  [ColumnName] [varchar](50) NULL,
  [SheetName] [varchar](50) NULL,
  [Department] [varchar](100) NULL,
  [DataType] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO