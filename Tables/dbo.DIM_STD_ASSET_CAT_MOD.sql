CREATE TABLE [dbo].[DIM_STD_ASSET_CAT_MOD] (
  [STD_ASSET_CAT_Key] [smallint] NOT NULL,
  [STD_ASSET_CATAlt_key] [smallint] NOT NULL,
  [STD_ASSET_CATName] [nvarchar](50) NOT NULL,
  [STD_ASSET_CATShortName] [nvarchar](50) NULL,
  [STD_ASSET_CATShortNameEnum] [nvarchar](50) NOT NULL,
  [STD_ASSET_CATGroup] [nvarchar](50) NULL,
  [STD_ASSET_CATSubGroup] [nvarchar](50) NULL,
  [STD_ASSET_CATSegment] [nvarchar](50) NULL,
  [STD_ASSET_CATValidCode] [nvarchar](50) NULL,
  [STD_ASSET_CAT_Prov] [decimal](18, 4) NULL,
  [AssetClassDuration] [nvarchar](50) NULL,
  [AuthorisationStatus] [nvarchar](50) NULL,
  [EffectiveFromTimeKey] [smallint] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [nvarchar](50) NULL,
  [DateCreated] [nvarchar](50) NULL,
  [ModifyBy] [nvarchar](50) NULL,
  [DateModified] [nvarchar](50) NULL,
  [ApprovedBy] [nvarchar](50) NULL,
  [DateApproved] [nvarchar](50) NULL,
  [STD_ASSET_CAT_Prov_Unsecured] [decimal](18, 4) NULL,
  [ApprovedByFirstLevel] [varchar](30) NULL,
  [DateApprovedFirstLevel] [datetime] NULL
)
ON [PRIMARY]
GO