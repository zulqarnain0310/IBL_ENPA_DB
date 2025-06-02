CREATE TABLE [dbo].[DimMaxLoginAllow] (
  [EntityKey] [smallint] NOT NULL,
  [UserLocationCode] [varchar](10) NULL,
  [UserLocation] [varchar](4) NULL,
  [UserLocationName] [varchar](50) NULL,
  [MaxUserLogin] [smallint] NULL,
  [UserLoginCount] [smallint] NULL,
  [MaxUserCustom] [char](1) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifyBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp]
)
ON [PRIMARY]
GO