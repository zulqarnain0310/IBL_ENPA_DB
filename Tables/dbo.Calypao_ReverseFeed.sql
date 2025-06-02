CREATE TABLE [dbo].[Calypao_ReverseFeed] (
  [SrNo] [int] NULL,
  [CounterParty.ID] [varchar](20) NULL,
  [CounterParty.Short Name] [varchar](80) NULL,
  [CounterParty.Attribute.UCIC] [varchar](50) NULL,
  [CounterParty.Attribute.Asset_Class_Description] [varchar](10) NULL,
  [CounterParty.Attribute.Asset_Classification_Code] [int] NULL,
  [CounterParty.Attribute.NPA Date] [date] NULL,
  [CounterParty.Attribute.UCIC_pcrd] [varchar](50) NULL
)
ON [PRIMARY]
GO