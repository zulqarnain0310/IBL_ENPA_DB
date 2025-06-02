CREATE TABLE [dbo].[DIM_STD_ASSET_CAT] (
  [STD_ASSET_CAT_Key] [smallint] NOT NULL,
  [STD_ASSET_CATAlt_key] [smallint] NOT NULL,
  [STD_ASSET_CATName] [nvarchar](50) NOT NULL,
  [STD_ASSET_CATShortName] [nvarchar](50) NOT NULL,
  [STD_ASSET_CATShortNameEnum] [nvarchar](50) NOT NULL,
  [STD_ASSET_CATGroup] [nvarchar](50) NOT NULL,
  [STD_ASSET_CATSubGroup] [nvarchar](50) NOT NULL,
  [STD_ASSET_CATSegment] [nvarchar](50) NOT NULL,
  [STD_ASSET_CATValidCode] [nvarchar](50) NOT NULL,
  [STD_ASSET_CAT_Prov] [decimal](18, 4) NULL,
  [AssetClassDuration] [nvarchar](50) NOT NULL,
  [AuthorisationStatus] [nvarchar](50) NOT NULL,
  [EffectiveFromTimeKey] [smallint] NOT NULL,
  [EffectiveToTimeKey] [int] NOT NULL,
  [CreatedBy] [nvarchar](50) NOT NULL,
  [DateCreated] [nvarchar](50) NOT NULL,
  [ModifyBy] [nvarchar](50) NOT NULL,
  [DateModified] [nvarchar](50) NOT NULL,
  [ApprovedBy] [nvarchar](50) NOT NULL,
  [DateApproved] [nvarchar](50) NOT NULL,
  [STD_ASSET_CAT_Prov_Unsecured] [decimal](18, 4) NULL
)
ON [PRIMARY]
GO