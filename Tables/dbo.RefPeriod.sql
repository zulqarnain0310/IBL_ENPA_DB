CREATE TABLE [dbo].[RefPeriod] (
  [Rule_Key] [smallint] IDENTITY,
  [RuleAlt_Key] [smallint] NULL,
  [RuleType] [varchar](50) NULL,
  [BusinessRule] [varchar](1000) NULL,
  [BusienssRuleName] [varchar](1000) NULL,
  [ColumnName] [varchar](1000) NULL,
  [RefValue] [varchar](1000) NULL,
  [RefUnit] [varchar](1000) NULL,
  [LogicSql] [varchar](5000) NULL,
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
  [D2Ktimestamp] [timestamp]
)
ON [PRIMARY]
GO