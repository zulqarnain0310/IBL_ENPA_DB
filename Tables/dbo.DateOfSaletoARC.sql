CREATE TABLE [dbo].[DateOfSaletoARC] (
  [EntityKey] [int] IDENTITY,
  [SrNo] [varchar](max) NULL,
  [UploadID] [int] NULL,
  [AccountID] [varchar](max) NULL,
  [CustomerID] [varchar](max) NULL,
  [PrincipalOutstandinginRs] [varchar](max) NULL,
  [InterestReceivableinRs] [varchar](max) NULL,
  [BalanceOSinRs] [varchar](max) NULL,
  [ExposuretoARCinRs] [varchar](max) NULL,
  [DateOfSaletoARC] [varchar](max) NULL,
  [DateOfApproval] [varchar](max) NULL,
  [filname] [varchar](max) NULL,
  [ErrorMessage] [varchar](max) NULL,
  [ErrorinColumn] [varchar](max) NULL,
  [Srnooferroneousrows] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO