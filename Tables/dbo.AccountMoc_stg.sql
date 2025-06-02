CREATE TABLE [dbo].[AccountMoc_stg] (
  [EntityKey] [varchar](max) NULL,
  [SrNo] [varchar](max) NULL,
  [AsOnDate] [varchar](max) NULL,
  [NCIF_Id] [varchar](max) NULL,
  [CustomerId] [varchar](max) NULL,
  [SourceSystem] [varchar](max) NULL,
  [CustomerName] [varchar](max) NULL,
  [AccountNo] [varchar](max) NULL,
  [GrossBalance] [varchar](max) NULL,
  [PrincipalOutstanding] [varchar](max) NULL,
  [UnservicedInterestAmount] [varchar](max) NULL,
  [Additionalprovisionpercentage] [varchar](max) NULL,
  [AdditionalprovisionAmount] [varchar](max) NULL,
  [Acceleratedprovisionamount] [varchar](max) NULL,
  [MOCReason] [varchar](max) NULL,
  [Remark] [varchar](max) NULL,
  [filname] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO