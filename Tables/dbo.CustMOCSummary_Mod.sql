CREATE TABLE [dbo].[CustMOCSummary_Mod] (
  [Entity_Key] [int] IDENTITY,
  [NCIF_Id] [varchar](max) NULL,
  [CustomerID] [varchar](max) NULL,
  [CustomerName] [varchar](max) NULL,
  [NoOfCounts] [varchar](max) NULL,
  [TotalSecurityValue] [varchar](max) NULL,
  [UploadID] [varchar](max) NULL,
  [SummaryID] [varchar](max) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](100) NULL,
  [DateCreated] [datetime] NULL,
  [ModifyBy] [varchar](100) NULL,
  [DateModified] [date] NULL,
  [ApprovedBy] [varchar](100) NULL,
  [DateApproved] [date] NULL,
  [D2KTimeStamp] [timestamp] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO