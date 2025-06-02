CREATE TABLE [dbo].[BuyoutSummary] (
  [Entity_Key] [int] IDENTITY,
  [PAN] [varchar](max) MASKED WITH (FUNCTION = 'default()') NULL,
  [NCIF_Id] [varchar](max) NULL,
  [CustomerName] [varchar](max) NULL,
  [CustomerACID] [varchar](max) MASKED WITH (FUNCTION = 'default()') NULL,
  [LoanAgreementNo] [varchar](max) NULL,
  [BuyoutPartyLoanNo] [varchar](max) NULL,
  [TotalNoofBuyoutParty] [varchar](max) NULL,
  [TotalPrincipalOutstandinginRs] [varchar](max) NULL,
  [TotalInterestReceivableinRs] [varchar](max) NULL,
  [GrandTotalOutstanding] [varchar](max) NULL,
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
  [D2KTimeStamp] [timestamp] NULL,
  [AdditionalProvisionAmount] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO