CREATE TABLE [dbo].[ErrorLog] (
  [ErrorKey] [int] IDENTITY,
  [ErrorNumber] [int] NULL,
  [ErrorMsg] [varchar](500) NULL,
  [ErrorProc] [varchar](50) NULL,
  [ErrorCrDt] [datetime] NULL
)
ON [PRIMARY]
GO