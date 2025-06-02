CREATE TABLE [dbo].[Error_Log] (
  [Entitykey] [int] IDENTITY,
  [ErrorLine] [varchar](100) NULL,
  [ErrorMessage] [varchar](max) NULL,
  [ErrorNumber] [varchar](100) NULL,
  [ErrorProcedure] [varchar](100) NULL,
  [ErrorSeverity] [varchar](100) NULL,
  [ErrorState] [varchar](100) NULL,
  [ErrorDateTime] [datetime] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO