CREATE TABLE [dbo].[BuyoutDetails_Stg_New] (
  [Entity_Key] [int] IDENTITY,
  [SrNo] [int] NULL,
  [AsOnDate] [varchar](10) NULL,
  [PAN] [varchar](max) MASKED WITH (FUNCTION = 'default()') NULL,
  [DedupeIDUCICEnterpriseCIF] [varchar](max) NULL,
  [CustomerName] [varchar](max) NULL,
  [CustomerAccountNo] [varchar](max) NULL,
  [LoanAgreementNo] [varchar](max) NULL,
  [IndusindLoanAccountNo] [varchar](max) NULL,
  [UnrealizedInterest] [varchar](max) NULL,
  [PrincipalOutstanding] [varchar](max) NULL,
  [TotalOutstanding] [varchar](max) NULL,
  [AssetClassification] [varchar](max) NULL,
  [NPADate] [varchar](10) NULL,
  [DPD] [varchar](max) NULL,
  [SecurityAmount] [varchar](max) NULL,
  [Action] [char](1) NULL,
  [filname] [varchar](max) NULL,
  [SummaryID] [varchar](max) NULL,
  [UploadID] [varchar](50) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO