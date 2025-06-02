CREATE TABLE [dbo].[SaletoARC_Stg] (
  [EntityKey] [int] IDENTITY,
  [SrNo] [varchar](max) NULL,
  [UploadID] [int] NULL,
  [AsOnDate] [varchar](10) NULL,
  [SourceSystem] [varchar](max) NULL,
  [NCIF_Id] [varchar](50) NULL,
  [CustomerID] [varchar](max) NULL,
  [AccountNo] [varchar](max) NULL,
  [DateOfSaletoARC] [varchar](max) NULL,
  [TotalSaleConsideration] [varchar](max) NULL,
  [PrincipalConsideration] [varchar](max) NULL,
  [InterestConsideration] [varchar](max) NULL,
  [Action] [varchar](max) NULL,
  [filname] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO