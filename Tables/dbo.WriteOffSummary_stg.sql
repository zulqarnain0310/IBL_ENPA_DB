CREATE TABLE [dbo].[WriteOffSummary_stg] (
  [Entity_Key] [int] IDENTITY,
  [UploadID] [varchar](max) NULL,
  [SummaryID] [varchar](max) NULL,
  [NoofAccounts] [varchar](max) NULL,
  [TotalWriteOffAmtinRS] [decimal](18, 2) NULL,
  [TotalIntSacrificeinRS] [decimal](18, 2) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO