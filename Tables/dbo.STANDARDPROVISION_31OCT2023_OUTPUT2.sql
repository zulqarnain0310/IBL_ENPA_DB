CREATE TABLE [dbo].[STANDARDPROVISION_31OCT2023_OUTPUT2] (
  [SrcSysAlt_Key] [smallint] NULL,
  [SourceName] [varchar](50) NULL,
  [STD_ASSET_CAT_Alt_key] [smallint] NULL,
  [STD_ASSET_CATName] [nvarchar](50) NOT NULL,
  [Cnt] [int] NULL,
  [PrincipleOutstanding] [decimal](38, 2) NULL,
  [Balance] [decimal](38, 2) NULL,
  [STD_ASSET_CAT_Prov] [decimal](22, 4) NULL,
  [TotalProvision] [decimal](38, 2) NULL
)
ON [PRIMARY]
GO