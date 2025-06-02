CREATE TABLE [dbo].[reverse_feed] (
  [AsOnDate] [datetime] NULL,
  [SourceName] [varchar](50) NULL,
  [UCIF_ID] [varchar](50) NULL,
  [CIF_ID] [varchar](50) NULL,
  [AccountNo] [varchar](50) NULL,
  [SOL_ID] [varchar](50) NULL,
  [Scheme_Type] [varchar](50) NULL,
  [Scheme_Code] [varchar](50) NULL,
  [SrcAssetClass] [varchar](50) NULL,
  [HomogenizedAssetClass] [varchar](50) NULL,
  [HomogenizedNpaDt] [datetime] NULL
)
ON [PRIMARY]
GO