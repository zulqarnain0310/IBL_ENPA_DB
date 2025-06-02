CREATE TABLE [dbo].[ErosionDTFlg_ChkTbl_20230615] (
  [DataDate] [date] NULL,
  [EffectiveFromTimeKey] [smallint] NULL,
  [SrcSysAlt_Key] [tinyint] NULL,
  [NCIF_Id] [varchar](100) NULL,
  [CustomerId] [varchar](50) NOT NULL,
  [CustomerACID] [varchar](50) NOT NULL,
  [NCIF_AssetClassAlt_Key] [tinyint] NOT NULL,
  [NCIF_NPA_Date] [date] NULL,
  [AC_AssetClassAlt_Key] [tinyint] NOT NULL,
  [AC_NPA_Date] [date] NULL,
  [FlgErosion] [varchar](50) NULL,
  [ErosionDT] [varchar](50) NULL,
  [DbtDT] [date] NULL,
  [LossDT] [varchar](50) NULL,
  [Status] [varchar](1) NULL,
  [remark] [varchar](100) NULL
)
ON [PRIMARY]
GO