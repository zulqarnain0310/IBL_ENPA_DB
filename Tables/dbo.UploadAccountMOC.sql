CREATE TABLE [dbo].[UploadAccountMOC] (
  [SrNo] [varchar](max) NULL,
  [AsOnDate] [varchar](max) NULL,
  [NCIF_Id] [varchar](max) NULL,
  [CustomerId] [varchar](max) NULL,
  [SourceSystem] [varchar](max) NULL,
  [CustomerName] [varchar](max) NULL,
  [AccountID] [varchar](max) NULL,
  [GrossBalance] [varchar](max) NULL,
  [PrincipalOutstanding] [varchar](max) NULL,
  [UnservicedInterestAmount] [varchar](max) NULL,
  [Additionalprovisionpercentage] [varchar](max) NULL,
  [AdditionalprovisionAmount] [varchar](max) NULL,
  [Acceleratedprovisionpercentage] [varchar](max) NULL,
  [MOCReason] [varchar](max) NULL,
  [SecurityValue] [varchar](max) NULL,
  [Remark] [varchar](max) NULL,
  [filname] [varchar](max) NULL,
  [EntityKey] [int] IDENTITY,
  [ErrorMessage] [varchar](max) NULL,
  [ErrorinColumn] [varchar](max) NULL,
  [Srnooferroneousrows] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO