CREATE TABLE [dbo].[asset2] (
  [SrcSysAlt_Key] [smallint] NULL,
  [NCIF_Id] [varchar](100) NULL,
  [CustomerACID] [varchar](20) NULL,
  [NCIF_AssetClassAlt_Key] [smallint] NULL,
  [NCIF_NPA_Date] [date] NULL,
  [DbtDT] [date] NULL,
  [ErosionDT] [date] NULL,
  [FlgErosion] [varchar](1) NULL,
  [LossDT] [date] NULL
)
ON [PRIMARY]
GO