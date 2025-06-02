CREATE TABLE [dbo].[WriteOffUpload_Stg] (
  [EntityKey] [int] IDENTITY,
  [SrNo] [varchar](max) NULL,
  [UploadID] [int] NULL,
  [AsOnDate] [varchar](10) NULL,
  [SourceSystem] [varchar](max) NULL,
  [NCIF_Id] [varchar](max) NULL,
  [CustomerID] [varchar](max) NULL,
  [CustomerAcID] [varchar](max) MASKED WITH (FUNCTION = 'default()') NULL,
  [WriteOffDate] [varchar](10) NULL,
  [WriteOffType] [varchar](max) NULL,
  [WriteOffAmtPrincipal] [varchar](max) NULL,
  [WriteOffAmtInterest] [varchar](max) NULL,
  [Action] [varchar](max) NULL,
  [filname] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO