CREATE TABLE [dbo].[DimMocReason_UATbkp20240320] (
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
  [DateCreated] [datetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [datetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp],
  [ApprovedByFirstLevel] [varchar](100) NULL,
  [DateApprovedFirstLevel] [datetime] NULL,
  [MocReasonCategory] [varchar](100) NULL
)
ON [PRIMARY]
GO