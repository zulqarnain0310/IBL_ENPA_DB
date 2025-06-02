CREATE TABLE [dbo].[CustMOCSummary_Stg] (
  [Entity_Key] [int] IDENTITY,
  [NCIF_Id] [varchar](max) NULL,
  [CustomerID] [varchar](max) NULL,
  [CustomerName] [varchar](max) NULL,
  [NoOfCounts] [varchar](max) NULL,
  [TotalSecurityValue] [varchar](max) NULL,
  [UploadID] [varchar](max) NULL,
  [SummaryID] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO