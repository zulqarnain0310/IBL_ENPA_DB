CREATE TABLE [dbo].[DimDesignation] (
  [Designation_Key] [smallint] NOT NULL,
  [DesignationAlt_Key] [smallint] NOT NULL,
  [DesignationName] [varchar](50) NULL,
  [DesignationShortName] [varchar](20) NULL,
  [DesignationShortNameEnum] [varchar](20) NULL,
  [DesignationGroup] [varchar](50) NULL,
  [DesignationSubGroup] [varchar](50) NULL,
  [DesignationSegment] [varchar](50) NULL,
  [DesignationValidCode] [char](1) NULL,
  [SrcSysDesignationCode] [varchar](50) NULL,
  [SrcSysDesignationName] [varchar](50) NULL,
  [DestSysDesignationCode] [varchar](10) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp]
)
ON [PRIMARY]
GO