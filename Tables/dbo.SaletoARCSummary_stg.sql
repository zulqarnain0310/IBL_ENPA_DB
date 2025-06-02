CREATE TABLE [dbo].[SaletoARCSummary_stg] (
  [Entity_Key] [int] IDENTITY,
  [UploadID] [varchar](max) NULL,
  [SummaryID] [varchar](max) NULL,
  [NoofAccounts] [varchar](max) NULL,
  [TotalPOSinRs] [varchar](max) NULL,
  [TotalInttReceivableinRs] [varchar](max) NULL,
  [TotaloutstandingBalanceinRs] [varchar](max) NULL,
  [ExposuretoARCinRs] [varchar](max) NULL,
  [DateOfSaletoARC] [varchar](max) NULL,
  [DateOfApproval] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO