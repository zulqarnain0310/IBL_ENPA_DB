CREATE TABLE [dbo].[DimArea] (
  [Area_Key] [smallint] NOT NULL,
  [AreaAlt_Key] [smallint] NULL,
  [AreaName] [varchar](50) NOT NULL,
  [AreaNameOrderKey] [tinyint] NULL,
  [AreaShortName] [varchar](20) NULL,
  [AreaShortNameEnum] [varchar](20) NULL,
  [AreaGroup] [varchar](50) NULL,
  [AreaSubGroup] [varchar](50) NULL,
  [AreaSegment] [varchar](50) NULL,
  [AreaValidCode] [char](1) NULL,
  [SrcSysAreaCode] [varchar](50) NULL,
  [SrcSysAreaName] [varchar](50) NULL,
  [DestSysAreaCode] [varchar](10) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
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