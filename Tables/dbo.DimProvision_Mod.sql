CREATE TABLE [dbo].[DimProvision_Mod] (
  [Provision_Key] [smallint] IDENTITY,
  [ProvisionAlt_key] [varchar](10) NOT NULL,
  [ProvisionName] [varchar](100) NULL,
  [ProvisionShortName] [varchar](100) NULL,
  [ProvisionShortNameEnum] [varchar](100) NULL,
  [ProvisionGroup] [varchar](50) NULL,
  [ProvisionSubGroup] [varchar](50) NULL,
  [ProvisionSegment] [varchar](50) NULL,
  [ProvisionValidCode] [char](1) NULL,
  [ProvisionSecured] [decimal](5, 4) NULL,
  [ProvisionUnSecured] [decimal](5, 4) NULL,
  [AssetClassDuration] [smallint] NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [ApprovedByFirstLevel] [varchar](100) NULL,
  [DateApprovedFirstLevel] [datetime] NULL,
  [D2KTimeStamp] [timestamp],
  [ChangeFields] [varchar](1000) NULL
)
ON [PRIMARY]
GO