CREATE TABLE [dbo].[BuyoutDetails_stg] (
  [EntityKey] [int] IDENTITY,
  [SrNo] [varchar](max) NULL,
  [UploadID] [int] NULL,
  [AsOnDate] [varchar](max) NULL,
  [PAN] [varchar](max) MASKED WITH (FUNCTION = 'default()') NULL,
  [NCIF_Id] [varchar](max) NULL,
  [CustomerName] [varchar](max) NULL,
  [AccountNo] [varchar](max) NULL,
  [LoanAgreementNo] [varchar](max) NULL,
  [IndusindLoanAccountNo] [varchar](max) NULL,
  [TotalOutstanding] [varchar](max) NULL,
  [UnrealizedInterest] [varchar](max) NULL,
  [PrincipalOutstanding] [varchar](max) NULL,
  [AssetClassification] [varchar](max) NULL,
  [NPADate] [varchar](max) NULL,
  [DPD] [varchar](max) NULL,
  [SecurityAmount] [varchar](max) NULL,
  [Action] [varchar](max) NULL,
  [filname] [varchar](max) NULL,
  [AdditionalProvisionAmount] [varchar](max) NULL,
  [AcceleratedProvisionPercentage] [varchar](max) NULL,
  [SecuredStatus] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO