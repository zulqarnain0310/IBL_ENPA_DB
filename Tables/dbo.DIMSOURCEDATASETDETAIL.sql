CREATE TABLE [dbo].[DIMSOURCEDATASETDETAIL] (
  [Entity_Key] [smallint] IDENTITY,
  [SourceAlt_Key] [smallint] NULL,
  [SourceName] [varchar](50) NULL,
  [DataSet1] [varchar](100) NULL,
  [DataSet2] [varchar](100) NULL,
  [DataSet3] [varchar](100) NULL,
  [DataSet4] [varchar](100) NULL,
  [DataSet5] [varchar](100) NULL,
  [DataSet6] [varchar](100) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ApprovedByFirstLevel] [varchar](100) NULL,
  [DateApprovedFirstLevel] [datetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp]
)
ON [PRIMARY]
GO