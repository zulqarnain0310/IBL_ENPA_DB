CREATE TABLE [dbo].[BuyoutSummary_Stg] (
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
  [TotalAdditionalProvisionAmount] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO