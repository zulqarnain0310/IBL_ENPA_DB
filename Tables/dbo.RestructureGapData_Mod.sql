CREATE TABLE [dbo].[RestructureGapData_Mod] (
  [EntityKey] [bigint] IDENTITY,
  [NCIF_Id] [varchar](30) NULL,
  [SecondRestrDate] [date] NULL,
  [AggregateExposure] [varchar](100) NULL,
  [CreditRating1] [varchar](10) NULL,
  [CreditRating2] [varchar](10) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NOT NULL,
  [EffectiveToTimeKey] [int] NOT NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [datetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [datetime] NULL,
  [ApprovedByFirstLevel] [varchar](50) NULL,
  [DateApprovedFirstLevel] [datetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [datetime] NULL,
  [D2Ktimestamp] [timestamp],
  [Remark] [varchar](500) NULL,
  [UploadID] [int] NULL,
  [ChangeField] [varchar](250) NULL,
  [IsUpload] [char](1) NULL,
  [UploadFlag] [char](1) NULL,
  [AsOnDate] [date] NULL
)
ON [PRIMARY]
GO