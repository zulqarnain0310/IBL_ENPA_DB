CREATE TABLE [dbo].[MasterUploadData] (
  [SR_No] [varchar](100) NULL,
  [ColumnName] [varchar](max) NULL,
  [ErrorData] [varchar](max) NULL,
  [ErrorType] [varchar](max) NULL,
  [FileNames] [varchar](500) NULL,
  [Flag] [varchar](500) NULL,
  [Srnooferroneousrows] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO