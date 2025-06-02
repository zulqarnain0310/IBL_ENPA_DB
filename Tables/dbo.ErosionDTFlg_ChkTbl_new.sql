CREATE TABLE [dbo].[ErosionDTFlg_ChkTbl_new] (
  [DataDate] [varchar](50) NULL,
  [EffectiveFromTimeKey] [varchar](50) NULL,
  [SrcSysAlt_Key] [varchar](50) NULL,
  [NCIF_Id] [varchar](50) NULL,
  [CustomerId] [varchar](50) NULL,
  [CustomerACID] [varchar](50) NULL,
  [NCIF_AssetClassAlt_Key] [varchar](50) NULL,
  [NCIF_NPA_Date] [varchar](50) NULL,
  [AC_AssetClassAlt_Key] [varchar](50) NULL,
  [AC_NPA_Date] [varchar](50) NULL,
  [FlgErosion] [varchar](50) NULL,
  [ErosionDT] [varchar](50) NULL,
  [DbtDT] [varchar](50) NULL,
  [LossDT] [varchar](50) NULL,
  [Status] [varchar](50) NULL,
  [remark] [varchar](50) NULL
)
ON [PRIMARY]
GO