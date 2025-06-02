CREATE TABLE [dbo].[DimMocReason] (
  [MocReason_Key] [int] IDENTITY,
  [MocReasonAlt_Key] [int] NULL,
  [MocReasonName] [varchar](80) NULL,
  [MocReasonShortName] [varchar](20) NULL,
  [MocReasonShortNameEnum] [varchar](20) NULL,
  [MocReasonGroup] [varchar](50) NULL,
  [MocReasonSubGroup] [varchar](50) NULL,
  [MocReasonSegment] [varchar](50) NULL,
  [AuthorisationStatus] [char](2) NULL,
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
  [D2Ktimestamp] [timestamp],
  [MocReasonCategory] [varchar](250) NULL
)
ON [PRIMARY]
GO