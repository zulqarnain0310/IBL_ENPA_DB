CREATE TABLE [dbo].[RestructureDataForCorrection_29092023] (
  [Date] [varchar](10) NOT NULL,
  [TimeKey] [int] NOT NULL,
  [NCIF_ID] [varchar](100) NULL,
  [AccountEntityId] [int] NOT NULL,
  [CustomerACID] [varchar](20) NULL,
  [AC_AssetClassAlt_Key] [smallint] NULL,
  [AC_NPA_Date] [date] NULL,
  [FlgErosion] [varchar](1) NULL,
  [ErosionDT] [date] NULL,
  [DbtDT] [date] NULL,
  [LossDT] [date] NULL
)
ON [PRIMARY]
GO