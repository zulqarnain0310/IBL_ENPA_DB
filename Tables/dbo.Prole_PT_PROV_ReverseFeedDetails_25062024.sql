CREATE TABLE [dbo].[Prole_PT_PROV_ReverseFeedDetails_25062024] (
  [AsOnDate] [date] NULL,
  [SourceName] [varchar](20) NULL,
  [UCIF_ID] [varchar](20) NULL,
  [CIF_ID] [varchar](20) NULL,
  [AccountNo] [varchar](20) NULL,
  [SOL_ID] [varchar](10) NULL,
  [Scheme_Type] [varchar](20) NULL,
  [Scheme_Code] [varchar](20) NULL,
  [Prov_Amount] [decimal](16, 2) NULL,
  [UNSERVED_INTEREST] [decimal](16, 2) NULL,
  [IS_MOC] [char](1) NULL
)
ON [PRIMARY]
GO