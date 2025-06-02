CREATE TABLE [dbo].[WriteOffSummary] (
  [Entity_Key] [int] IDENTITY,
  [UploadID] [int] NULL,
  [SummaryID] [int] NULL,
  [NoofAccounts] [int] NULL,
  [TotalWriteOffAmtinRS] [decimal](18, 2) NULL,
  [TotalIntSacrificeinRS] [decimal](18, 2) NULL,
  [AuthorisationStatus] [varchar](5) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](100) NULL,
  [DateCreated] [datetime] NULL,
  [ModifyBy] [varchar](100) NULL,
  [DateModified] [date] NULL,
  [ApprovedBy] [varchar](100) NULL,
  [DateApproved] [date] NULL
)
ON [PRIMARY]
GO