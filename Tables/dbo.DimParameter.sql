CREATE TABLE [dbo].[DimParameter] (
  [DimParameter_Key] [smallint] IDENTITY,
  [DimParameterName] [varchar](50) NULL,
  [Parameter_Key] [int] NULL,
  [ParameterAlt_Key] [smallint] NULL,
  [ParameterName] [varchar](50) NULL,
  [ParameterShortName] [varchar](50) NULL,
  [ParameterShortNameEnum] [varchar](50) NULL,
  [SrcSysParameterCode] [varchar](50) NULL,
  [SrcSysParameterName] [varchar](50) NULL,
  [DestSysarameterCode] [varchar](10) NULL,
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
  [CibilCode] [varchar](5) NULL,
  [ApprovedByFirstLevel] [varchar](100) NULL,
  [DateApprovedFirstLevel] [datetime] NULL
)
ON [PRIMARY]
GO