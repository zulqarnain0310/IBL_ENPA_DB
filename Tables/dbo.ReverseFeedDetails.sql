CREATE TABLE [dbo].[ReverseFeedDetails] (
  [AsOnDate] [date] NULL,
  [SourceName] [varchar](30) NULL,
  [UCIF_ID] [varchar](20) NULL,
  [CIF_ID] [varchar](20) NULL,
  [AccountNo] [varchar](20) MASKED WITH (FUNCTION = 'default()') NULL,
  [SOL_ID] [varchar](10) NULL,
  [Scheme_Type] [varchar](20) NULL,
  [Scheme_Code] [varchar](20) NULL,
  [SrcAssetClass] [varchar](20) NULL,
  [HomogenizedAssetClass] [varchar](20) NULL,
  [HomogenizedNpaDt] [date] NULL,
  [IS_MOC] [char](1) NULL DEFAULT ('N'),
  [NatureofClassification] [char](1) NULL,
  [DateofImpacting] [date] NULL,
  [ImpactingAccountNo] [varchar](5000) NULL,
  [ImpactingSourceSystemName] [varchar](500) NULL
)
ON [PRIMARY]
GO