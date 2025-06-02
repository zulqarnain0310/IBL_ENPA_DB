CREATE TABLE [dbo].[UploadStatus] (
  [EntityKey] [int] IDENTITY,
  [FileNames] [varchar](max) NULL,
  [UploadedBy] [varchar](50) NULL,
  [UploadDateTime] [datetime] NULL,
  [UploadType] [varchar](500) NULL,
  [ValidationOfSheetNames] [char](1) NULL,
  [ValidationOfSheetCompletedOn] [datetime] NULL,
  [ValidationOfData] [char](1) NULL,
  [ValidationOfDataCompletedOn] [datetime] NULL,
  [InsertionOfData] [char](1) NULL,
  [InsertionCompletedOn] [datetime] NULL,
  [TruncateTable] [char](1) NULL,
  [TruncateTableCompletedOn] [datetime] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO