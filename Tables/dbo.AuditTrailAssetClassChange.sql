CREATE TABLE [dbo].[AuditTrailAssetClassChange] (
  [NCIF_Id] [varchar](200) NULL,
  [CustomerId] [varchar](200) NULL,
  [CustomerACID] [varchar](200) NULL,
  [SrcSysAlt_Key] [int] NULL,
  [Source_AC_AssetClassAlt_Key] [tinyint] NULL,
  [Source_AC_NPA_Date] [date] NULL,
  [Source_dbtdt] [date] NULL,
  [Calc_AC_AssetClassAlt_Key] [tinyint] NULL,
  [Calc_AC_NPA_Date] [date] NULL,
  [Calc_dbtdt] [date] NULL,
  [InsertDate] [datetime] NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL
)
ON [PRIMARY]
GO