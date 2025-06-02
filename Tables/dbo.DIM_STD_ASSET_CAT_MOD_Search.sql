CREATE TABLE [dbo].[DIM_STD_ASSET_CAT_MOD_Search] (
  [STD_ASSET_CATName] [nvarchar](50) NOT NULL,
  [STD_ASSET_CATShortNameEnum] [nvarchar](50) NOT NULL,
  [STD_ASSET_CAT_Prov] [decimal](22, 4) NULL,
  [AuthorisationStatus] [nvarchar](50) NULL
)
ON [PRIMARY]
GO