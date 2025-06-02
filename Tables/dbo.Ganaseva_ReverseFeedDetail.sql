CREATE TABLE [dbo].[Ganaseva_ReverseFeedDetail] (
  [SNo] [int] NULL,
  [SourceSystemName] [varchar](20) NULL,
  [SourceName] [varchar](20) NULL,
  [NCIF_Id] [varchar](20) NULL,
  [ClientID] [varchar](20) NULL,
  [AccountNumber] [varchar](20) NULL,
  [FinalSystemAssetClass] [int] NULL,
  [FinalAssetClassDesc] [varchar](20) NULL,
  [FinalNPA_Date] [varchar](20) NULL
)
ON [PRIMARY]
GO