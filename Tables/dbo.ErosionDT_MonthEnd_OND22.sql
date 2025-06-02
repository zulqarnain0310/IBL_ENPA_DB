CREATE TABLE [dbo].[ErosionDT_MonthEnd_OND22] (
  [Date] [date] NULL,
  [EffectiveFromTimeKey] [int] NOT NULL,
  [SrcSysAlt_Key] [smallint] NULL,
  [NCIF_Id] [varchar](100) NULL,
  [CustomerId] [varchar](20) NULL,
  [CustomerACID] [varchar](20) NULL,
  [NCIF_AssetClassAlt_Key] [smallint] NULL,
  [NCIF_NPA_Date] [date] NULL,
  [AC_AssetClassAlt_Key] [smallint] NULL,
  [AC_NPA_Date] [date] NULL,
  [FlgErosion] [varchar](1) NULL,
  [ErosionDT] [date] NULL,
  [DbtDT] [date] NULL,
  [LossDT] [date] NULL,
  [Balance] [decimal](16, 2) NULL,
  [SecuredFlag] [varchar](1) NULL,
  [SecurityValue] [decimal](24) NULL,
  [SecuredAmt] [decimal](16, 2) NULL,
  [UnSecuredAmt] [decimal](16, 2) NULL
)
ON [PRIMARY]
GO