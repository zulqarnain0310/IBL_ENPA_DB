CREATE TABLE [CURDAT].[ReverseFeedDetails_Archive_Check] (
  [EntityKey] [int] NULL,
  [AsOnDate] [date] NOT NULL,
  [SourceName] [varchar](30) NULL,
  [UCIF_ID] [varchar](20) NULL,
  [CIF_ID] [varchar](20) NULL,
  [AccountNo] [varchar](50) NOT NULL,
  [SOL_ID] [varchar](10) NULL,
  [Scheme_Type] [varchar](20) NULL,
  [Scheme_Code] [varchar](20) NULL,
  [SrcAssetClass] [varchar](20) NULL,
  [HomogenizedAssetClass] [varchar](20) NULL,
  [HomogenizedNpaDt] [date] NULL,
  [IS_MOC] [char](1) NULL DEFAULT ('N'),
  CONSTRAINT [ReverseFeedDetails_Archive_Check_PK] PRIMARY KEY NONCLUSTERED ([AccountNo], [AsOnDate]) WITH (FILLFACTOR = 90),
  CHECK ([AsOnDate]='2099-10-30')
)
ON [PRIMARY]
GO