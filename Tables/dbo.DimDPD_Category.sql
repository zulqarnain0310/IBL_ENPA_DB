CREATE TABLE [dbo].[DimDPD_Category] (
  [DPD_CatAtl_Key] [smallint] NOT NULL,
  [DPD_CatAlt_Key] [smallint] NULL,
  [DPD_CatSubGroupOrderKey] [tinyint] NULL,
  [DPD_CatOrderKey] [tinyint] NULL,
  [DPD_CatName] [varchar](50) NULL,
  [DPD_CatShortName] [varchar](20) NULL,
  [DPD_CatShortNameEnum] [varchar](20) NULL,
  [DPD_CatGroup] [varchar](50) NULL,
  [DPD_CatSubGroup] [varchar](50) NULL,
  [DPD_CatSegment] [varchar](50) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModifie] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp]
)
ON [PRIMARY]
GO