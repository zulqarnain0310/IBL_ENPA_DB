CREATE TABLE [dbo].[RestructureGapData] (
  [EntityKey] [int] IDENTITY,
  [NCIF_ID] [varchar](30) NULL,
  [SecondRestrDate] [date] NULL,
  [AggregateExposure] [varchar](100) NULL,
  [CreditRating1] [varchar](10) NULL,
  [CreditRating2] [varchar](10) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [datetime] NULL,
  [ApprovedByFirstLevel] [varchar](50) NULL,
  [DateApprovedFirstLevel] [datetime] NULL,
  [ModifyBy] [varchar](20) NULL,
  [DateModified] [datetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [datetime] NULL,
  [D2KTimeStamp] [timestamp],
  [UploadID] [int] NULL
)
ON [PRIMARY]
GO