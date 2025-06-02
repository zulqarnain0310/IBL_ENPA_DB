CREATE TABLE [dbo].[DimSourceSystem_bKP_17042023] (
  [Source_Key] [smallint] IDENTITY,
  [SourceAlt_Key] [smallint] NULL,
  [SourceOrderKey] [tinyint] NULL,
  [SourceName] [varchar](50) NULL,
  [SourceShortName] [varchar](20) NULL,
  [SourceShortNameEnum] [varchar](20) NULL,
  [SourceGroup] [varchar](50) NULL,
  [SourceSubGroup] [varchar](50) NULL,
  [SourceSegment] [varchar](50) NULL,
  [SourceValidCode] [char](1) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp],
  [SourceFilePath] [varchar](250) NULL,
  [FileExist] [char](1) NULL,
  [ApprovedByFirstLevel] [varchar](100) NULL,
  [DateApprovedFirstLevel] [datetime] NULL
)
ON [PRIMARY]
GO